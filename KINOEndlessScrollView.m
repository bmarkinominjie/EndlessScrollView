//
//  HomeViewController.m
//  GCHShoppingGuide
//
//  Created by 观潮汇 on 16/9/22.
//  Copyright © 2016年 观潮汇. All rights reserved.
//
#import "HomeViewController.h"
#import "LMJEndlessLoopScrollView.h"
#import "MJRefresh.h"
#import "IconView.h"
#import "PopularView.h"
#import "DiscountView.h"
#import "NewsProductView.h"
#import "MasterView.h"
#import "ManagerStoryView.h"
#import "RecommendView.h"
#import "CardItemView.h"

static NSString *collectionID = @"MItem";

@interface HomeViewController () <LMJEndlessLoopScrollViewDelegate, UIScrollViewDelegate>
{
    CGFloat ratio;     // 屏幕比率
    CGFloat space;     // 模块间隙
    CGFloat _offsetY;  // 高度偏移
    int currentPage;
}
@property (nonatomic, strong) UILabel       *foundLB;

@property (strong, nonatomic) LMJEndlessLoopScrollView *banner;
@property (strong, nonatomic) LMJEndlessLoopScrollView *foundBanner;      //发现生活
@property (strong, nonatomic) LMJEndlessLoopScrollView *chooseBanner;     //生活真选
@property (strong, nonatomic) LMJEndlessLoopScrollView *specialBanner;    //专题资讯

@property (nonatomic, strong) NSMutableArray *list;                      //13个模块的排列顺序
@property (nonatomic, strong) NSMutableDictionary *dataDic;              //数据源
@property (nonatomic, strong) NSMutableDictionary *titleValueDic;        //配置标题

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UICollectionView *homeCollectionV;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) UIView *headerView;

//各个模块的视图
@property (nonatomic, strong) IconView              *iconView;           //模块
@property (nonatomic, strong) PopularView           *popularView;        //人气王
@property (nonatomic, strong) DiscountView          *discountView;       //真选私惠
@property (nonatomic, strong) NewsProductView       *newsProductView;    //资讯分类产品
@property (nonatomic, strong) PopularView           *numActivityView; //多多易善 视图

@property (nonatomic, strong) PopularView           *onekeyView;         //一键全齐
@property (nonatomic, strong) MasterView            *masterView;         //达人说
@property (nonatomic, strong) ManagerStoryView      *managerView;        //管家故事
@property (nonatomic, strong) RecommendView         *recommendView;      //商品推荐
@property (nonatomic, strong) CardItemView          *cardItemView;       //G+模块
@property (nonatomic, strong) RecommendView         *quarteHotView;       //时节热点

@end

@implementation HomeViewController

#pragma mark - LMJEndlessLoopScrollView Delegate
- (NSInteger)numberOfContentViewsInLoopScrollView:(LMJEndlessLoopScrollView *)loopScrollView{
}

- (UIView *)loopScrollView:(LMJEndlessLoopScrollView *)loopScrollView contentViewAtIndex:(NSInteger)index{
}

- (void)loopScrollView:(LMJEndlessLoopScrollView *)loopScrollView currentContentViewAtIndex:(NSInteger)index
{
}

- (void)loopScrollView:(LMJEndlessLoopScrollView *)loopScrollView didSelectContentViewAtIndex:(NSInteger)index{
}

#pragma mark ----Data---------懒加载方法
- (NSMutableDictionary *)dataDic
{
    if (!_dataDic) {
        _dataDic = [NSMutableDictionary dictionary];
    }
    return _dataDic;
}

- (NSMutableArray *)list
{
    if (!_list) {
        _list = [NSMutableArray array];
    }
    return _list;
}

- (NSMutableDictionary *)titleValueDic
{
    if (!_titleValueDic) {
        _titleValueDic = [NSMutableDictionary dictionary];
    }
    return _titleValueDic;
}

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight-kScreenDrawIOS7FrameY-kBottomBarHeight-44)];
        _scrollView.delegate = self;
        _scrollView.backgroundColor = UIColorFromRGB(0xe6e6e6);
    }
    return _scrollView;
}

#pragma mark --SysytemLoad
- (void)viewDidLoad {
    [super viewDidLoad];

    ratio = [GlobalConfigs shareGlobalConfigs].ratio;
    space = ratio*12;
    _offsetY = 0;
    currentPage = 1;

    [self.view addSubview:self.scrollView];
    __weak typeof(self) weakself = self;

    MJRefreshStateHeader *header = [MJRefreshStateHeader headerWithRefreshingBlock:^{
        currentPage = 1;
        [weakself getListData:^{
            [weakself.scrollView.header endRefreshing];
        }];
    }];

    [header.lastUpdatedTimeLabel setHidden:YES];
#pragma mark ------- warning -------
    //添加ScrollView 的下拉刷新操作
    [self.scrollView setHeader:header];
}

- (void)getListData:(void (^)(void))requestComplete
{
    __weak typeof(self) weakself = self;
    [[HttpRequestTool sharedInstance] getWithURLString:kBase_url(@"tMainPageController.do?getHomePage") parameters:@{@"curPage": [NSString stringWithFormat:@"%d", currentPage], @"retailerId": User_Info[@"retailId"]} success:^(id responseObject) {

        if (currentPage == 1) {

            [weakself.list removeAllObjects];
            [weakself.dataDic removeAllObjects];
            [weakself.list addObjectsFromArray:responseObject[@"list"]];
            [weakself clearData];
            [weakself configUI];
        }
        if ([responseObject objectForKey:@"data"] && [responseObject[@"data"] isKindOfClass:[NSDictionary class]]) {
            [weakself.dataDic addEntriesFromDictionary:responseObject[@"data"]];
            [weakself configData:responseObject[@"data"]];
        }

        if (currentPage <= weakself.list.count/4) {
            currentPage ++;
            [self getListData:nil];
        }
        if (requestComplete) {
            requestComplete();
        }

    } failure:^(NSError *error) {

        if (requestComplete) {
            requestComplete();
        }
    }];
}

- (void)configUI
{
    _offsetY = 0;
    for (int i = 0; i < self.list.count; i ++) {
        NSDictionary *dic = [self.list objectAtIndex:i];
        int code = [[dic objectForKey:@"typecode"] intValue];
        [self.titleValueDic setObject:dic[@"typename"] forKey:dic[@"typecode"]];
        switch (code) {
            case 101101101:
            {
                [self.scrollView addSubview:self.banner];
                self.banner.frame = CGRectMake(0, _offsetY, kScreenWidth, ratio*446);
                _offsetY += (CGRectGetHeight(_banner.frame) + space);
            }
                break;
            case 101101102:
            {
                [self.scrollView addSubview:self.iconView];
                self.iconView.frame = CGRectMake(0, _offsetY , kScreenWidth, ratio*182);
                _offsetY += (CGRectGetHeight(_iconView.frame) + space);
            }
                break;
            case 101101103:
            {
                [self.scrollView addSubview:self.popularView];
                self.popularView.frame = CGRectMake(0, _offsetY, kScreenWidth, ratio*600);
                self.popularView.contentId = [_list[i][@"contentId"] stringValue];
                _offsetY += (CGRectGetHeight(_popularView.frame) + space);
            }
                break;
            case 101101104:
            {
                [self.scrollView addSubview:self.discountView];
                self.discountView.frame = CGRectMake(0, _offsetY, kScreenWidth, ratio*260);
                _offsetY += (CGRectGetHeight(_discountView.frame) + space);

            }
                break;
            case 101101105:
            {
                [self.scrollView addSubview:self.chooseBanner];
                self.chooseBanner.frame = CGRectMake(space, _offsetY, kScreenWidth - 2*space, ratio*432);
                _offsetY += (CGRectGetHeight(_chooseBanner.frame) + space);
            }
                break;
            case 101101106:
            {
                [self.scrollView addSubview:self.newsProductView];
                self.newsProductView.frame = CGRectMake(0, _offsetY, kScreenWidth, ratio*312);
                //                _offsetY += (CGRectGetHeight(_newsProductView.frame) + space);
                _offsetY += (CGRectGetHeight(self.newsProductView.frame) + 5);
            }
                break;
            case 101101107:
            {
                [self.scrollView addSubview:self.numActivityView];
                self.numActivityView.frame = CGRectMake(0, _offsetY, kScreenWidth, ratio*600);
                _offsetY += (CGRectGetHeight(_numActivityView.frame) + space);
                self.numActivityView.news_dic = self.list[i];

            }
                break;
            case 101101108:
            {
                [self.scrollView addSubview:self.foundLB];
                self.foundLB.frame = CGRectMake(0, _offsetY, kScreenWidth, ratio*100);
                _offsetY += CGRectGetHeight(_foundLB.frame);

                [self.scrollView addSubview:self.foundBanner];
                self.foundBanner.frame = CGRectMake(space, _offsetY, kScreenWidth-2*space, ratio*860);
                _offsetY += (CGRectGetHeight(_foundBanner.frame) + space);

            }
                break;
            case 101101109:
            {
                [self.scrollView addSubview:self.onekeyView];
                self.onekeyView.frame = CGRectMake(0, _offsetY, kScreenWidth, ratio*600);
                _offsetY += (CGRectGetHeight(_onekeyView.frame) + space);

                self.onekeyView.news_dic = self.list[i];
            }
                break;
            case 101101110:
            {
                [self.scrollView addSubview:self.specialBanner];
                self.specialBanner.frame = CGRectMake(space, _offsetY, kScreenWidth-2*space, ratio*432);
                _offsetY += (CGRectGetHeight(_specialBanner.frame) + space);


            }
                break;
            case 101101111:
            {
                [self.scrollView addSubview:self.masterView];
                self.masterView.frame = CGRectMake(0, _offsetY, kScreenWidth, ratio*664);
                _offsetY += (CGRectGetHeight(_masterView.frame) + space);


            }
                break;
            case 101101112:
            {
                [self.scrollView addSubview:self.managerView];
                _offsetY += (CGRectGetHeight(_managerView.frame) + space);


            }
                break;
            case 101101115:
            {
                [self.scrollView addSubview:self.cardItemView];
                _offsetY += (CGRectGetHeight(_cardItemView.frame) + space);


            }
                break;
            case 101101113:
            {
                [self.scrollView addSubview:self.recommendView];
                _offsetY += (CGRectGetHeight(_recommendView.frame) + space);


            }
                break;
            case 101101116:
            {
                [self.scrollView addSubview:self.quarteHotView];
                self.quarteHotView.news_dic = self.list[i];
                //               _offsetY += (CGRectGetHeight(_quarteHotView.frame) + space);
            }
                break;
            default:
                break;
        }
    }
    [self.scrollView setContentSize:CGSizeMake(0, _offsetY)];
    //    _offsetY = 0;
}

- (void)clearData
{
    if (_banner) {
        [_banner reloadData];
    }
    if (_popularView) {
        _popularView.title = @"";
        _popularView.sourceArray = nil;
    }
    if (_discountView) {
        _discountView.sourceArray = nil;
    }
    if (_chooseBanner) {
        [_chooseBanner reloadData];
    }
    if (_newsProductView) {
        _newsProductView.sourceArray = nil;
    }
    if (_numActivityView) {
        _numActivityView.sourceArray = nil;
        _numActivityView.news_dic = nil;//设置web详情参数
    }
    if (_foundLB) {
        _foundLB.text = @"";
    }
    if (_foundBanner) {
        [_foundBanner reloadData];
    }
    if (_onekeyView) {
        _onekeyView.title = nil;
        _onekeyView.sourceArray = nil;
        _onekeyView.news_dic = nil;//设置web详情参数
    }
    if (_specialBanner) {
        [_specialBanner reloadData];
    }
    if (_masterView) {
        _masterView.title = @"";
        _masterView.sourceArray = nil;
    }
    if (_managerView) {
        _managerView.title = @"";
        _managerView.sourceArray = nil;
    }
    if (_recommendView) {
        _recommendView.title = nil;
        _recommendView.sourceArray = nil;
    }
    if (_quarteHotView) {
        _quarteHotView.title = nil;
        _quarteHotView.sourceArray = nil;
        _quarteHotView.news_dic = nil;//设置web详情参数

    }
}

- (void)configData:(NSDictionary *)dataDic
{
    if ([dataDic objectForKey:@"101101101"]) {
        [self.banner reloadData];
    }
    if ([dataDic objectForKey:@"101101103"]) {
        self.popularView.title = [self.titleValueDic objectForKey:@"101101103"];
        self.popularView.isSingle = [NSString stringWithFormat:@"YES"];
        self.popularView.sourceArray = self.dataDic[@"101101103"];
    }
    if ([dataDic objectForKey:@"101101104"]) {
        self.discountView.sourceArray = self.dataDic[@"101101104"];
    }
    if ([dataDic objectForKey:@"101101105"]) {
        [self.chooseBanner reloadData];
    }
    if ([dataDic objectForKey:@"101101106"]) {
        self.newsProductView.sourceArray = self.dataDic[@"101101106"];
    }
    if ([dataDic objectForKey:@"101101107"]) {
        self.numActivityView.sourceArray = self.dataDic[@"101101107"];
        self.numActivityView.title =[self.titleValueDic objectForKey:@"101101107"];
        self.numActivityView.isSingle = [NSString stringWithFormat:@"YES"];//箭头设置
        //        [self.scrollView addSubview:_numActivityView];
        //        heightSV += ratio*600;
    }
    if ([dataDic objectForKey:@"101101108"]) {
        if ([self.dataDic objectForKey:@"101101108"] && [self.dataDic[@"101101108"] isKindOfClass:[NSArray class]] && [self.dataDic[@"101101108"] count] > 0) {
            _foundLB.text = self.dataDic[@"101101108"][0][@"title"];
            [self.foundBanner reloadData];
        }
    }
    if ([dataDic objectForKey:@"101101109"]) {
        self.onekeyView.title = [self.titleValueDic objectForKey:@"101101109"];
        self.onekeyView.isSingle = [NSString stringWithFormat:@"YES"];
        self.onekeyView.sourceArray = self.dataDic[@"101101109"];
    }
    if ([dataDic objectForKey:@"101101110"]) {
        [self.specialBanner reloadData];
    }
    if ([dataDic objectForKey:@"101101111"]) {
        self.masterView.title = [self.titleValueDic objectForKey:@"101101111"];
        self.masterView.sourceArray = self.dataDic[@"101101111"];
    }
    if ([dataDic objectForKey:@"101101112"]) {
        self.managerView.title = [self.titleValueDic objectForKey:@"101101112"];
        self.managerView.sourceArray = self.dataDic[@"101101112"];
    }
    if ([dataDic objectForKey:@"101101113"]) {
        CGFloat itemWidth = (SC_APP_SIZE.width-30)/2;
        CGFloat itemHeight = 475.0/340.0*itemWidth;
        self.recommendView.frame = CGRectMake(0, self.cardItemView.frame.origin.y+self.cardItemView.frame.size.height+space, kScreenWidth, ratio*100+(itemHeight+10)*ceilf((float)[self.dataDic[@"101101113"] count]/2.0));
        self.recommendView.title = [self.titleValueDic objectForKey:@"101101113"];
        self.recommendView.isSingle = [NSString stringWithFormat:@"NO"];
        self.recommendView.sourceArray = self.dataDic[@"101101113"];

        [self.scrollView setContentSize:CGSizeMake(0, CGRectGetMaxY(self.recommendView.frame))];
    }
    if ([dataDic objectForKey:@"101101115"]) {
        self.cardItemView.imageUrl = [self.dataDic objectForKey:@"101101115"];
    }
    if ([dataDic objectForKey:@"101101116"]) {
        CGFloat itemWidth = (SC_APP_SIZE.width-30)/2;
        CGFloat itemHeight = 475.0/340.0*itemWidth;
        self.quarteHotView.frame = CGRectMake(0, self.recommendView.frame.origin.y+space+self.recommendView.frame.size.height, kScreenWidth, ratio*100+(itemHeight+10)*ceilf((float)[self.dataDic[@"101101116"] count]/2.0));
        self.quarteHotView.title = [self.titleValueDic objectForKey:@"101101116"];
        self.quarteHotView.sourceArray = self.dataDic[@"101101116"];
        self.quarteHotView.isSingle = [NSString stringWithFormat:@"YES"];

        [self.scrollView setContentSize:CGSizeMake(0, CGRectGetMaxY(self.quarteHotView.frame))];
    }
}

#pragma mark -----功能模块-----懒加载方法
//精选视图循环
- (LMJEndlessLoopScrollView *)banner
{
    if (!_banner) {

        _banner = [[LMJEndlessLoopScrollView alloc] initWithFrame:CGRectMake(0, _offsetY, kScreenWidth, ratio*446) animationScrollDuration:3];
        _banner.delegate        = self;
    }
    return _banner;
}

- (IconView *)iconView
{
    if (!_iconView) {
        _iconView = [[IconView alloc] initWithFrame:CGRectMake(0, _offsetY , kScreenWidth, ratio*182) showViewController:self.parentController sourceArray:[NSArray arrayWithObjects:@"新品", @"畅品",@"活动", @"组合", @"实体店", nil]];
    }
    return _iconView;
}

- (PopularView *)popularView
{
    if (!_popularView) {
        _popularView = [[PopularView alloc] initWithFrame:CGRectMake(0, _offsetY, kScreenWidth, ratio*600) showViewController:self.parentController];
    }
    return _popularView;
}

- (DiscountView *)discountView
{
    if (!_discountView) {
        _discountView = [[DiscountView alloc] initWithFrame:CGRectMake(0, _offsetY, kScreenWidth, ratio*260) showViewController:self.parentController];
    }
    return _discountView;
}
//定时器负默认不滚动
- (LMJEndlessLoopScrollView *)chooseBanner
{
    if (!_chooseBanner) {
        _chooseBanner = [[LMJEndlessLoopScrollView alloc] initWithFrame:CGRectMake(space, _offsetY, kScreenWidth - 2*space, ratio*432) animationScrollDuration:-1];
        _chooseBanner.delegate        = self;
    }
    return _chooseBanner;
}

- (NewsProductView *)newsProductView
{
    if (!_newsProductView) {
        _newsProductView = [[NewsProductView alloc] initWithFrame:CGRectMake(0, _offsetY, kScreenWidth, ratio*312) showViewController:self.parentController];
    }
    return _newsProductView;
}

- (PopularView *)numActivityView
{
    if (!_numActivityView) {
        _numActivityView = [[PopularView alloc] initWithFrame:CGRectMake(0, _offsetY, kScreenWidth, ratio*600) showViewController:self.parentController];
    }
    return _numActivityView;
}

- (UILabel *)foundLB
{
    if (!_foundLB) {
        _foundLB = [[UILabel alloc] initWithFrame:CGRectMake(0, _offsetY, kScreenWidth, ratio*100)];
        _foundLB.font = Font(14);
        _foundLB.backgroundColor = WhiteColor;
        _foundLB.textColor = Level2Color;
        _foundLB.textAlignment = NSTextAlignmentCenter;
    }
    return _foundLB;
}

- (LMJEndlessLoopScrollView *)foundBanner
{
    if (!_foundBanner) {
        _foundBanner = [[LMJEndlessLoopScrollView alloc] initWithFrame:CGRectMake(space, _offsetY, kScreenWidth-2*space, ratio*860) animationScrollDuration:-1];
        _foundBanner.delegate        = self;
    }
    return _foundBanner;
}

- (PopularView *)onekeyView
{
    if (!_onekeyView) {
        _onekeyView = [[PopularView alloc] initWithFrame:CGRectMake(0, _offsetY, kScreenWidth, ratio*60) showViewController:self.parentController];
    }
    return _onekeyView;
}

- (LMJEndlessLoopScrollView *)specialBanner
{
    if (!_specialBanner) {
        _specialBanner = [[LMJEndlessLoopScrollView alloc] initWithFrame:CGRectMake(space, _offsetY, kScreenWidth-2*space, ratio*432) animationScrollDuration:-1];
        _specialBanner.delegate        = self;
    }
    return _specialBanner;
}

- (MasterView *)masterView
{
    if (!_masterView) {
        _masterView = [[MasterView alloc] initWithFrame:CGRectMake(0, _offsetY, kScreenWidth, ratio*664) showViewController:self.parentController];
    }
    return _masterView;
}

- (ManagerStoryView *)managerView
{
    if (!_managerView) {
        _managerView = [[ManagerStoryView alloc] initWithFrame:CGRectMake(0, _offsetY, kScreenWidth, ratio*360) showViewController:self.parentController];
    }
    return _managerView;
}

- (RecommendView *)recommendView
{
    if (!_recommendView) {
        _recommendView = [[RecommendView alloc] initWithFrame:CGRectMake(0, _offsetY, kScreenWidth, 0) showViewController:self.parentController];
    }
    return _recommendView;
}
- (RecommendView *)quarteHotView
{
    if (!_quarteHotView) {
        _quarteHotView = [[RecommendView alloc] initWithFrame:CGRectMake(0, _offsetY, kScreenWidth, 0) showViewController:self.parentController];
    }
    return _quarteHotView;
}
- (CardItemView *)cardItemView
{
    if (!_cardItemView) {
        _cardItemView = [[CardItemView alloc] initWithFrame:CGRectMake(0, _offsetY, kScreenWidth-2*space, ratio*970) showViewController:self.parentController];
    }
    return _cardItemView;
}

@end
