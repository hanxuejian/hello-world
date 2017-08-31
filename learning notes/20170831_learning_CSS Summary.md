# CSS 小结
CSS(Cascading Style Sheets)，层叠样式表，用来定义 HTML 中的元素的显示方式。CSS 从 HTML 4.0 开始引入，实现了 HTML 中内容与内容显示方式的分离，大大提高了工作效率。通常，我们将样式表单独存储在 CSS 文件中，然后通过链接的形式引入 HTML 文件中。

## CSS 语法
### 语法规则
CSS 的语法规则主要由两部分组成，**选择器**和**属性键值对**，形如：`h1 {color:red;font-size:20px;}`

选择器通常有3种：**元素名称**、**#id**、**.class**，但是，可以通过组合的方式灵活使用，如 **元素名称.class** 则是选择了某一种元素的所有相同的类名的元素，**#id.class** 则是选择了某一个ID的所有相同类名的元素，使用方法如下：

```
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"> 
<title>test</title> 
<style>
p {background-color:yellow;}
#para {margin-left:20px;}
.center {color:red;}
p.center {text-align:center;}
#para.green {background-color:green;}
</style>
</head>

<body>
<h1 class="center">这个标题不受影响</h1>
<p class="center">这个段落居中对齐。</p> 
<p id="para">这个段落向右侧移动20px</p>
<p id="para" class="green">背景色为绿色</p>
</body>
</html>
```
另外，上面5种选择器的形式，可以通过使用 **","** 隔开，从而将一样的样式写在一起，以减少代码量。使用空格将它们分隔，则表示选择器的嵌套，即在前一个选择器选择出的元素中筛选元素，如下：

```
<style>
h1,p,#test.className
{
color:green;
}
div div #test.className 
{
	background-color:yellow;	
}
</style>
```

### 创建方式
1. 外部样式表，将样式表单独保存在一个 CSS 文件中，而后在 HTML 文档中使用 `<link>` 标签进行引用，当浏览器读取 CSS 文件中的样式表后，变化使用其格式化 HTML 文档的内容。对于多个 HTML 文档需要使用同一种样式时，可采取这种方法，引用方式如下：

	```
	<head>
	<link rel="stylesheet" type="text/css" href="testStyle.css">
	</head>
	```
2. 内部样式表，对于单个 HTML 文档使用特殊样式时，可以在 HTML 文档中使用 `<style>` 标签进行样式表的定义，格式如下：

	```
	<head>
	<style>
	hr {color:sienna;}
	p {margin-left:10px;}
	body {background-image:url("images/test.png");}
	</style>
	</head>
	```
3. 内联样式，对于某个样式应用于一个单一的元素，则可以定义该元素标签的 **style** 属性来定义其特殊样式，如下：

	```
	<p style="background-color:green;margin-left:20px">段落</p>
	```	
> 当这三种样式重叠时，即多种样式应用于同一个元素时，浏览器会将解析得到的样式覆盖已经存在的样式。

### 基本样式
#### 背景
|样式属性|属性值|含义|样例|
|:---:|:----:|:---:|:---:|
|background-color|颜色值，如白色：white、#FFF、#FFFFFF、rgb(255,2555,255)、rgba(255,255,255,1)|设置元素背景色|body{background-color:white;}|
|background-image|图片路径，如：test.png|设置背景图片|body{background-image:url('test.png');}|
|background-repeat|repeat、repeat-x、repeat-y、no-repeat、inherit|设置图片的平铺方向或不平铺|body{background-image:url('test.png');background-repeat:no-repeat;}|
|background-image|left right center top bottom 两两组合，x% y% 使用百分比进行设置|设置背景图片的起始位置|body{background-image:url('test.png');background-position:right top;}|
|background-attachment|fixed|图片固定，不随界面滚动而滚动|body{background-image:url('test.png');background-attachment:fixed;}|
#### 文本
|样式属性|属性值|含义|样例|
|:---:|:----:|:---:|:---:|
|color|white、#FFFFFF、rgb(255,255,255)|设置文本的颜色|p{color:blue;}|
|text-align|left、right、center、justify|设置文本的对齐方式|p{text-align:left;}|
|text-decoration|none、overline、line-through、underline|设置文本的删除线|p{text-decoration:none;}|
|text-transform|uppercase、lowercase、capitalize|设置文本字母大小写|p{text-transform:capitalize;}|
|text-indent|像素值、相对父元素宽度的百分比|设置文本缩进长度|p {text-indent:50px;}|
|letter-spacing|像素值、可以为负|设置文本字符之间的间距|h1 {letter-spacing:20px;}|
|line-height|像素值、相对文本字体尺寸的倍数或百分比|设置文本的行间距|p{line-height:70%;}|
|direction|ltr、rtl|设置文本的方向|p{direction:rtl;unicode-bidi:bidi-override;}|
|unicode-bidi|normal、embed、bidi-override、inherit|与 direction 属性一起使用来设置文本是否重写|p{direction:rtl;unicode-bidi:bidi-override;}|
|word-spacing|像素值|设置单词的间距，对中文无效|p{word-spacing:30px;}|
|white-space|normal、pre、nowrap、pre-wrap、pre-line、inherit|设置空白及换行是否保留|p{white-space:pre;}|
|text-shadow|水平阴影偏移量、垂直阴影偏移量、模糊的距离、阴影的颜色，后两个参数可选|设置文本的阴影|p{text-shadow:2px 2px 8px #FF0000;}|

#### 字体
|样式属性|属性值|含义|样例|
|:---:|:----:|:---:|:---:|
|font-family|"Times New Roman"、Arial、"宋体"|设置文本的字体系列|p{font-family:"Times New Roman", Times, serif;}|
|font-style|normal、italic、oblique|设置文本的字体样式|p{font-style:italic;}|
|font-size|16px、1em、110%|设置文本的字体大小|p{font-size:0.5em;}|
|font-variant|normal、small-caps|将文本小写字母转为大写，但其字母尺寸较小|p{font-variant:small-caps;}|
|font-weight|normal、bold、bolder、lighter、100～900|设置文本字体粗细，400=normal，700=bold|p{font-weight:800;}|

#### 链接
|链接状态|含义|样例|
|:---:|:----:|:---:|
|a:link|未访问过的链接|a:link{color:#789;}|
|a:visited|用户已经访问过的链接|a:visited{text-decoration:none;}|
|a:hover|鼠标放在链接上时|a:hover{font-size:150%;}|
|a:active|点击链接时|a:active{background-color:red;}
> 注意设置这些状态时，顺序不能改变。

#### 列表
|样式属性|属性值|含义|样例|
|:---:|:----:|:---:|:---:|
|list-style-type|circle、square、upper-roman、lower-alpha|设置列表项标记|ul{list-style-type:circle;}|
|list-style-image|图片路径|设置列表标记为图片|ol{list-style-image: url('test.gif');}|
|list-style-position|outside、inside|设置列表项位置|ul{list-style-position:inside;}|

### 盒模型
在 HTML 文档中，所有的元素都可以看作一个盒子。在 CSS 中，盒模型（box model）用来设计与布局。
其包括下面4个部分：

* 外边距（Margin），盒模型边框外的区域，是透明的。
* 边框（Border），围绕内边距与内容的边界线。
* 内边距（Padding），内容与边框之间的区域，是透明的。
* 内容（Content），盒模型的内容，显示元素的文本或图像。

在 HTML 文档中，要将元素的宽度与高度设置正确，应按照盒模型进行计算并设置，如设置一个 div 元素的宽度为300px，设置如下：

```
div {
	width:250px;
	padding:10px;
	border:5px;
	margin:10px;
}
```

#### 边框
|样式属性|属性值|含义|样例|
|:---:|:----:|:---:|:---:|
|border-style|none、dotted、dashed、solid、double、groove、ridge、inset、outset|设置边框样式|p{border-style:solid;}|
|border-width|像素值、thin、medium、thick|设置边框宽度|p{border-style:dotted;border-width:10px;}|
|border-color|red、rgb(255,0,0)、#FF0000|设置边框的颜色|p{border-style:solid;border-color:red;}|
|border|样式、颜色、宽度|设置边框的属性|p{border:yellow 10px dotted;}|
|border-bottom、border-bottom-color、border-bottom-width、border-bottom-style|样式、颜色、宽度|设置下边框的属性|p{border-bottom:thin red double;} div{border-bottom-color:transparent;}|
|border-left、border-left-color、border-left-width、border-left-style|样式、颜色、宽度|设置下边框的属性|p{border-left:thin red double;} div{border-left-color:transparent;}|
|border-right、border-right-color、border-right-width、border-right-style|样式、颜色、宽度|设置下边框的属性|p{border-right:thin red double;} div{border-right-color:transparent;}|
|border-top、border-top-color、border-top-width、border-top-style|样式、颜色、宽度|设置下边框的属性|p{border-top:thin red double;} div{border-top-color:transparent;}|

<a id="边框"></a>
> 对于 border-style、border-color、border-width，可以接受1～4个值。1个值时，定义所有边框的属性；2个值时，第一个值定义上下边框的属性，第二个值定义左右边框的属性；3个值时，第一个定义上边框的属性，第二个定义左右边框的属性，第三个定义下边框的属性；4个值时，从上边框开始，顺时针方向，分别定义4个边框的属性。

#### 轮廓
|样式属性|属性值|含义|样例|
|:---:|:----:|:---:|:---:|
|outline-style|none、dashed、solid、double、groove、ridge、inset、outset、inherit|设置轮廓的样式|p{outline-style:double;}|
|outline-color|red、rgb(255,0,0)、#F00、invert|设置轮廓的颜色|p{border:2px solid yellow; outline-style:solid; outline-color:red;}|
|outline-width|像素值、thin、medium、thick|设置轮廓的宽度|p{border-style:dotted; outline-style:solid; outline-width:10px;}|
|outline|样式、颜色、宽度|设置轮廓属性的简写形式|p{border-style:dotted; outline:solid red 10px;}|
> 轮廓是围绕在边框外的线，而不是外边距，但是轮廓不属于元素

#### 外边距
|样式属性|属性值|含义|样例|
|:---:|:----:|:---:|:---:|
|margin|10px、2cm、25%、auto|设置元素的外边距，可以有1～4个值，各个值的含义参见<a href="#边框" style="text-decoration:none;">边框</a>|p{margin:10px 15px 23px 10px;}|
|margin-left、margin-right、margin-top、margin-bottom|像素值|设置元素指定的外边距|p{margin-top:10px;}|

#### 内填充
|样式属性|属性值|含义|样例|
|:---:|:----:|:---:|:---:|
|padding|10px、25%|设置元素的填充，可以有1～4个值，各个值的含义参见<a href="#边框" style="text-decoration:none;">边框</a>|p{padding:10px 15px 23px 10px;}|
|padding-left、padding-right、padding-top、padding-bottom|像素值|设置元素指定的外边距|p{padding-left:10px;}|

### 元素尺寸
|样式属性|属性值|含义|样例|
|:---:|:----:|:---:|:---:|
|height|像素值、百分比|设置元素高度|p{height:400px; width:100%;}|
|width|像素值、百分比|设置元素宽度|p{height:400px; width:100%;}|
|max-height|像素值、百分比|设置元素最大高度|p{max-height:500px; min-height:100px;}|
|min-height|像素值、百分比|设置元素最小高度|p{max-height:500px; min-height:100px;}|
|max-width|像素值、百分比|设置元素最大宽度|p{max-width:500px; min-width:100px;}|
|min-width|像素值、百分比|设置元素最小宽度|p{max-width:500px; min-width:100px;}|

### 元素布局与隐藏
|样式属性|属性值|含义|样例|
|:---:|:----:|:---:|:---:|
|display|none、block、inline、list-item、table等|设置元素布局样式，是块、内联、列表、表或者其他样式|p{display:block;}|
|visibility|visible、hidden、collapse、inherit|设置元素是否可见|p{visibility:hidden;}|
> display:none; 与 visibility:hidden; 的区别在于前者并不会布局在页面上，而后者只是不可见，其仍然在页面上占用空间，而影响着页面的布局。

### 元素的定位
元素可以通过设置属性 position 并且配合 top、left、right、bottom 进行元素的定位，其可取的属性值如下：

|属性值|含义|样例|
|:----:|:---:|:---:|
|static|默认值，按元素流进行定位|p{position:static;}|
|relative|相对其在父元素或 html 元素中的正常位置|h2{position:relative;left:-20px;}|
|fixed|相对与浏览器的窗口是固定的|p{position:fixed;top:20px;left:20px;}|
|absolute|绝对定位，相对于父元素或 html 元素|p{position:absolute;left:100px;top:10px;}|

另外，属性 position 还可以和其他属性一起使用，如下：

|样式属性|属性值|含义|样例|
|:---:|:----:|:---:|:---:|
|z-index|-1、0、1|定位与文档流无关，元素可以重叠，所以可以设置其显示的前后顺序|img{position:absolute;left:0px;top:0px;z-index:-1;}|
|clip|rect(10px,10px,20px,0px);|设置裁剪范围|img{position:absolute; clip:rect(10px,10px,20px,0px);}|
|overflow|visible、hidden、scroll、auto、inherit|设置内容超出元素范围时的处理方式|div{position:absolute;width:100px;	height:100px;	overflow:scroll;}|

### 鼠标样式
通过设置样式属性 **cursor** 的值，可以使鼠标在移动到不同的元素上时，显示不同的图标，其可取的值如下：

|属性值|含义|
|:----:|:---:|
|default|默认光标，通常为一个箭头|
|auto|浏览器默认的光标|
|crosshair|十字形状的光标|
|point|手形状的光标，通常表示当前元素为超链接|
|move|十字箭头形状的光标，通常表示当前元素可以移动|
|text|I形状的光标，通常表示文本|
|wait、progress|圆圈或者沙漏形状的光标，通常表示等待|
|help|问号形状的光标，通常表示帮助|
|e-resize、ne-resize|箭头形状的光标，通常表示可以向某个方向移动|

### 浮动
浏览器在解析 HTML 文档，生成页面的过程中，会按照文档中的元素流进行布局，使用 **float** 样式属性可以改变布局，使其他元素围绕着浮动元素，float 的值有 none、left、right。若是元素不允许周围有浮动元素，则可设置样式属性 **clear** 的值为 both、left、right 表示两侧、左侧、右侧不允许有浮动元素，其默认值为 none ，表示周围允许有浮动元素。

```
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"> 
<title>浮动</title> 
<style>
img {float:left;}
p.clear {clear:both;}
</style>
</head>
<body>

<img src="test.png" width="100" height="100" />
<p>This is some text. This is some text. This is some text. This is some text. This is some text. This is some text.</p>
<p class="clear">This is also some text. This is also some text. This is also some text. This is also some text. This is also some text. This is also some text.</p>

</body>
</html>
```