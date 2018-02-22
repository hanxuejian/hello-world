# HTML 知识小结
## HTML 概述
超文本标记语言（HyperText Markup Language，HTML）是一种用于创建网页的标准标记语言，可以使用 HTML 来建立 Web 站点，HTML 运行在浏览器上，由浏览器来解析。

HTML 作为一种标记语言，其是由一套标记标签组成，这些标签由尖括号包裹一个关键字构成，或由尖括号包裹一个斜杠及关键字构成，如 `<html>、</html>` 等，一般标签成对出现，分别为开始标签与结束标签（亦叫开放标签与闭合标签），两个标签之间包裹着要显示的内容。

一个 HTML 文档，后缀名是 html/htm ，其通常包含 `<html> 、<head> 、<body>` 三个标签，其中 body 标签中是具体要显示的内容，而对于中文网页，为了避免出现乱码，应该在 `<head>` 标签中将编码声明为 UTF-8 ，如下：

```
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>网页标题</title>
</head>
<body>
 
<h1>文本标题</h1>
 
<p>段落</p>
 
</body>
</html>
```
> <!DOCTYPE> 实际并不是 HTML 标签，其只是放在 HTML 文档首部，用于告知 Web 浏览器 HTML 的版本，有利于文档的解析。

## HTML 基础标签简介
1. 标题，HTML 提供了 `h1、h2、h3、h4、h5、h6` 共6个标题标签，序号越大，字体越小。
	 
	```
	<h1>标题1</h1>
	<h2>标题2</h2>
	<h3>标题3</h3>
	```
	 
2. 段落，HTML 使用 `<p>` 表示段落。
	
	```
	<p>段落内容</p>
	```
	 
3. 链接，HTML 使用 `<a>` 表示链接。 
	 
	```
	<a href = "http://www.baidu.com">百度</a>
	```
	
4. 图像，HTML 使用 `<img>` 表示图像。 
	
	* src 表示图片路径，alt 表示图片加载失败时的替代文本，width/height 表示显示图片的宽高（单位：像素）
	   
		```
		<img src = "/images/logo.png" alt="logo" width = "76" height = "76" />
		```
	 
	* 图像链接
	 
		```
		<a href="http://www.runoob.com/html/html-tutorial.html">
		<img  border="10" src="smiley.gif" alt="HTML 教程" width="32" height="32">
		</a>
		```
		
	* 设置图像映射，使得图像不同区域链接不同的地址
	 
		```
		<img src="test.png" width="145" height="126" alt="Planets" usemap="#mapID">
			
		<map name="mapID">
		<area shape="rect" coords="0,0,82,126" alt="test1" href="test1.htm">
		<area shape="circle" coords="90,58,3" alt="test2" href="test2.htm">
		<area shape="circle" coords="124,58,8" alt="test3" href="test3.htm">
		</map>
		```

5. 水平线，HTMl 使用 `<hr>` 插入水平线。
6. 换行，HTML 使用 `<br>` 进行换行，否则源码中的多行会被解析为一个空格。
7. 注释，HTML 使用 `<!-- -->` 进行注释。
8. 粗体，HTML 使用 `<b>、<strong>` 将文本粗体显示。
9. 斜体，HTML 使用 `<i>、<em>` 将文本斜体显示。
10. 下标，HTML 使用 `<sub>` 显示下标。
11. 上标，HTML 使用 `<sup>` 显示上标。
12. `<title>` 定义 HTML 文档的标题。
13. `<base>` 标签描述了基本的链接地址，其是 HTML 文档中所有链接标签的默认链接。

 ```
 <head>
  <base href="http://www.baidu.com/" target="_blank">
 </head>
 ```
14. `<link>` 标签定义了文档与外部资源之间的关系，通常用于链接到样式表。

	```
	<head>
	 <link rel="stylesheet" type="text/css" href="mystyle.css">
	</head>
	```
15. `<style>` 标签定义了HTML文档的样式文件引用地址，当然在 `<style>` 元素中也可以直接添加样式。

	```
	<head>
	 <style type="text/css">
	  body {background-color:yellow}
	  p {color:blue}
	 </style>
	</head>
	```
16. `<script>` 用于添加脚本文件，`<noscript>` 中的内容在浏览器不支持脚本时显示。

	```
	<script>
	document.write("Hello World!")
	</script>
	<noscript>抱歉，你的浏览器不支持 JavaScript!</noscript>
	```
17. `<meta>` 用于添加描述 HTML 文档的元数据。

18. CSS (Cascading Style Sheets)层叠样式表，用于描述 HTML 文档中元素标签的样式。为了更好的渲染 HTML 元素，从 HTML 4 开始引入 CSS ，将样式加入 HTML 文档中，有下面3种方式：
	* 内联样式，在 HTML 元素中使用 **style** 属性
	* 内部样式表，在 HTML 文档的 `<head>` 标签中使用 `<head>` 标签包含 CSS
	* 外部引用，使用 `<link>` 标签引用外部 CSS 文件

	```
	<html>
	<head>
	<meta charset="utf-8">
	<style type="text/css">
	 body {background-color: blue}
	 p {color:blue;}
	</style>
	<link rel="stylesheet" type="text/css" href="mystyle.css">
	</head>
	
	<body style = "background-color:yellow;">
	 <h1 style = "background-color:green;text-align:center;">标题1</h1>
	 <p style="font-family:arial;font-size:20px;">段落</p>
	</body>
	</html>
	```

19. 表格，HTML 中使用标签 `<table>` 进行表格的定义，一般分为页眉 `<thead>`、主体 `<tbody>`、和页脚 `<tfoot>` 三部分。

	|标签|含义|
	|:---:|:---:|
	|`<table>`|定义整个表格|
	|`<thead>`|定义表格的页眉|
	|`<tbody>`|定义表格的主体|
	|`<tfoot>`|定义表格的页脚|
	|`<caption>`|定义表格的标题|
	|`<tr>`| 定义表格的行|
	|`<td>`| 定义单元格，单元格里可以放表格、列表、文本等内容|
	|`<th>`| 定义表头，如同一个特殊的单元格|
	|`<colgroup>`|用于包含列的属性标签 `<col>`|
	|`<col>`|用于定义列的属性|

	|属性|含义|
	|:---:|:---:|
	|cellspacing|单元格之间的距离|
	|cellpadding|单元格中内容距单元格边框的距离|
	|colspan|该单元格是由几列最小单元格组成的|
	|rowspan|该单元格是由几行最小单元格组成的|

	```
	<html>
	<head>
	<meta charset="utf-8">
	<style type="text/css">
	
	.tabtop13 {
		margin-top: 13px;
	}
	.tabtop13 td{
		background-color:#ffffff;
		height:25px;
		line-height:150%;
	}
	.font-center{ text-align:center}
	.btbg{background:#e9faff !important;}
	.btbg1{background:#f2fbfe !important;}
	.btbg2{background:#f3f3f3 !important;}
	.biaoti{
		font-family: 微软雅黑;
		font-size: 26px;
		font-weight: bold;
		border-bottom:1px dashed #CCCCCC;
		color: #255e95;
	}
	.titfont {
		
		font-family: 微软雅黑;
		font-size: 16px;
		font-weight: bold;
		color: #255e95;
		background: url(../images/ico3.gif) no-repeat 15px center;
		background-color:#e9faff;
	}
	.tabtxt2 {
		font-family: 微软雅黑;
		font-size: 14px;
		font-weight: bold;
		text-align: right;
		padding-right: 10px;
		color:#327cd1;
	}
	.tabtxt3 {
		font-family: 微软雅黑;
		font-size: 14px;
		padding-left: 15px;
		color: #000;
		margin-top: 10px;
		margin-bottom: 10px;
		line-height: 20px;
	}
	</style>
	
	<table width="100%" border="0" cellspacing="0" cellpadding="0" align="center">
	  <tr>
	    <td align="center" class="biaoti" height="60">受理员业务统计表</td>
	  </tr>
	  <tr>
	    <td align="right" height="25">2017-01-02---2017-05-02</td>
	  </tr>
	</table>
	
	<table width="100%" border="0" cellspacing="1" cellpadding="4" bgcolor="#cccccc" class="tabtop13" align="center">
	  <tr>
	    <td colspan="2" class="btbg font-center titfont" rowspan="2">受理员</td>
	    <td width="10%" class="btbg font-center titfont" rowspan="2">受理数</td>
	    <td width="10%" class="btbg font-center titfont" rowspan="2">自办数</td>
	    <td width="10%" class="btbg font-center titfont" rowspan="2">直接解答</td>
	    <td colspan="2" class="btbg font-center titfont">拟办意见</td>
	    <td colspan="2" class="btbg font-center titfont">返回修改</td>
	    <td colspan="3" class="btbg font-center titfont">工单类型</td>
	  </tr>
	  <tr>
	    
	    <td width="8%" class="btbg font-center">同意</td>
	    <td width="8%" class="btbg font-center">比例</td>
	    <td width="8%" class="btbg font-center">数量</td>
	    <td width="8%" class="btbg font-center">比例</td>
	    <td width="8%" class="btbg font-center">建议件</td>
	    <td width="8%" class="btbg font-center">诉求件</td>
	    <td width="8%" class="btbg font-center">咨询件</td>
	    
	  </tr>
	 
	</table>
	
	</body>
	</html>
	```
	
20. 列表	
	
	|标签|含义|
	|:---:|:---:|
	|`<ol>`|定义有序列表|
	|`<ul>`|定义无序列表|
	|`<li>`|定义列表项|
	|`<dl>`|定义自定义列表|
	|`<dt>`|定义自定义列表项|
	|`<dd>`|定义自定义列表项描述|
	
	|属性|含义|
	|:---:|:---:|
	|start|设置有序列表开始的数值|
	|type|设置有序列表的数值类型，1、A、a、I、i|
	|style|设置无序列表的标识类型，style="list-style-type:disc"、circle、square|
	
	```
	<h4>嵌套列表：</h4>
	<ul>
	  <li>Coffee</li>
	  <li>Tea
	    <ul>
	      <li>Black tea</li>
	      <li>Green tea
	        <ul>
	          <li>China</li>
	          <li>Africa</li>
	        </ul>
	      </li>
	    </ul>
	  </li>
	  <li>Milk</li>
	</ul>
	
	<h4>一个自定义列表：</h4>
	<dl>
	  <dt>Coffee</dt>
	  <dd>- black hot drink</dd>
	  <dt>Milk</dt>
	  <dd>- white cold drink</dd>
	</dl>
	```
	
21. 区块元素，HTML 中的元素大致分为块级元素与内联元素两种，前者在浏览器中显示时，通常会开始新的一行显示，如 `<h1> <p> <table> <ul>`，而后者通常不会，如 `<b> <td> <img>`。**`<div>`** 是块级元素，作为整合其他元素的容器，没有实际的意义，但是可以同于设置整个内容块的样式。**`<span>`** 是内联样式，作为单行内容的容器，亦没有实际意义，多用于包裹文本，利于文本样式的设置。
	
22. 表单元素，通过表单，可以使用户输入数据，使用标签 **`<form>`** 表示表单，表单中最常使用的是 `<input>` 标签，通过修改该标签的 **type** 属性，可以实现输入框、单选按钮、复选框、提交按钮等。其中提交按钮的动作是由表单的 **action** 属性定义的。

	```
	<form action="test2.html">
	<input type="text" size="50"><br>
	
	<input type="radio" name="sex" value="male">Male<br>
	<input type="radio" name="sex" value="female" checked="checked">Female<br>
	
	<input type="checkbox" name="pet" value="cat">cat<br>
	<input type="checkbox" name="pet" value="dog">dog<br>
	
	<select name="cars">
	<option value="volvo">Volvo</option>
	<option value="saab">Saab</option>
	<option value="fiat" selected>Fiat</option>
	<option value="audi">Audi</option>
	</select>
	<br>
	
	<textarea rows="10" cols="30">我是一个文本框。</textarea><br>
	<input type="button" value="Hello world!"><br>
	<input type="submit" value="提交">
	<input type="reset" value="重置">
	</form>
	```
23. **iframe** 框架，使用标签 **`<iframe>`** 来实现一个 HTML 文档中显示子页面，也可将其设置为链接的显示容器。

	```
	<iframe src="test1.html" name="iframe_a" width="200" height="200"></iframe>
	<p><a href="http://www.baidu.com" target="iframe_a">百度</a></p>
	```
24. 颜色，在设置标签的颜色相关的属性时，可使用以下4种方式：

	* rgb()，如：`<p style = "background-color:rgb(100,0,100)">段落</p>`
	* rgba()，如：`<p style = "background-color:rgba(100,0,100,0.5)">段落</p>`
	* 16进制，如：`<p style = "background-color:#FF0088">段落</p>` 等同于 `<p style = "background-color:#F08">段落</p>`
	* 颜色名称，如：`<p style = "background-color:gray">段落</p>`

25. 在 HTML 中，多个空格会被解析为一个空格，若要显示不间断空格（Non-breaking Space）需要使用字符实体 `&nbsp;` ，还有一些其他的特殊字符，如大于号、小于号等，需要使用字符实体进行描述，如下：
	
	|特殊字符|实体名称|实体编号|
	|:---:|:---:|:---:|
	|<|`&lt;`|`&#60;`|
	|>|`&gt;`|`&#62;`|
	|&|`&amp;`|`&#38;`|
	|&copy;|`&copy;`|`&#169;`|
	|&reg;|`&reg;`|`&#174;`|
	|&trade;|`&trade;`|`&#8482;`|
	
	> 注意字符实体的分号不能省略
	
	
	
	