# EndlessScrollView
own diary for endlessScrollView

###1.为scrollView添加MJRefreshStateHeader
###2.移除排列顺序数据
###3.移除模块数据
###4.移除以前的控件
###5.根据顺序绘制UI
###6.根据模块数据从新布局
###7.每页4个模块,根据当前页判断是否需要再加载数据
<pre><code>currentPage <= weakself.list.count/4</code></pre>
###8.数据全部完成请求时，刷新页面
