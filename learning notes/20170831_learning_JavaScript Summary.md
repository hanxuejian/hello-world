# JavaScript 小结
JavaScript 是一门轻量级脚本语言，其是可以插入 HTML 文档中由浏览器执行的代码，与 Java 无关。将 JavaScript 代码插入 HTML 文档中，需要将代码使用标签 `<script> </script>` 进行包裹，而后其可以放在 HTML 文档中的任意位置。

## JavaScript 输出数据

|方法|含义|
|:---:|:---:|
|window.alert()|弹出警告框|
|document.write()|向 HTML 文档写入内容，若在文档加载完毕后再调用该方法，则会覆盖文档的内容|
|document.getElementById("elementID").innerHTML|向指定的 HTML 元素中写入内容|
|console.log()|向控制器中写入内容|

## JavaScript 变量类型

JavaScript 变量类型有 String、Number、Boolean、Array、Object，这些变量均是对象，声明一个变量就是创建了一个对象，如下：

```
var name = new String;
var count = new Number;
var isClose = new Boolean;
var person = new Object;
var persopns = new Array;
```
> undefined 表示变量不含值，通常使用 null 清空变量的值。
> 使用未声明的变量，其会被默认为全局变量。
> 所有的变量都属于 window 对象。
 
## JavaScript 对象
javaScript 对象是变量的容器，键值对的集合。键，称为对象的属性，值，则是对象的属性值。属性值可以是任意的 JavaScript 变量类型，也可以是方法定义。即 JavaScript 对象的方法是以属性值的形式存储在对象属性中的，在使用这种属性时，添加括号表示调用方法，如下：

```
<script>
var person = {
    firstName: "John",
    lastName : "Doe",
    fullName : function() 
	{
       return this.firstName + " " + this.lastName;
    }
};
document.getElementById("demo1").innerHTML = "不加括号输出函数表达式：" + person.fullName;
document.getElementById("demo2").innerHTML = "加括号输出函数执行结果：" + person.fullName();
</script>
```

## HTML 常见事件
|事件|含义|
|:---:|:---:|
|onchange|元素改变|
|onclick|鼠标点击|
|onmouseover|鼠标在元素上移动|
|onmouseout|鼠标移开元素|
|onkeydown|键盘按键按下|
|onload|加载完成|

通常，当界面加载完成，或图片加载完成后，可执行 JavaScript 代码，如下：

```
//在 HTML 标签中定义元素内容加载完成后要执行的方法
<body onload="···">

//在 JavaScript 中定义界面加载完成后要执行的方法
window.onload = function(){···};

//图片加载
<img src="test.png" onload="···" width="336" height="36">

```

## JavaScript 严格模式
通常，JavaScript 解释器在解释 JavaScript 代码的过程中会将变量与方法的声明提升至代码的头部进行解释，所以对于先使用，后声明的代码，执行时并不会出错。

但是，当使用 `"use strict";` 指令使得 JavaScript 处于严格模式时，使用未经声明的变量，便会出错。该指令除了放在脚本开头外，也可以放在函数的开头，表示该函数使用严格模式。

## JavaScript 函数
在 JavaScript 中，使用关键字 function 来声明定义函数。

* 常见的声明方式

	```
	function functionName(parameter1,parameter2,···){
		···
	}
	//调用
	functionName(a,b,···);
	```
* 匿名函数

	```
	var func = function(parameters){···}
	//调用
	var result = func(parameters);
	
	```
* 构造函数

	```
	var func = new Function("parameter1","parameter2","···");
	//调用
	var result = func(a,b);
	```
* 自调用函数

	```
	(function(){···})(); //匿名自调用函数
	```
* 内嵌函数

	```
	function funcA(){
		···
		function funcB(){···}
		funcB();
		···
	}
	```
* 闭包，利用嵌套函数能够访问上层函数变量的特性，来实现函数多次调用时访问同一个变量的目的

	```
	var add = (function () {
	    var counter = 0;
	    return function () {return counter += 1;}
	})();
	
	add();
	add();
	add();
	
	//多次调用 counter 的值持续累加
	```

## HTML DOM
DOM（Document Object Model）文档对象模型，浏览器加载页面时，会创建相应的文档对象模型，根据该模型，JavaScript 可以操作 HTML 的元素及其属性，改变其 CSS 样式，并监听页面中的事件从而作出反应。DOM 的基本用法如下：

|方法名|含义|样例|
|:----:|:---:|:----:|
|getElementById()|通过 id 查找页面中的元素|var x = document.getElementById("testDiv");|
|getElementsByTagName()|通过标签查找页面中的元素|var y = x.getElementsByTagName("p");|
|getElementsByClassName()|通过类名查找页面中的元素|var x = document.getElementsByClassName("test");|
|write()|文档输出流|write(Date());|
|innerHTML|改变元素内容|document.getElementById("p1").innerHTML="hello world!"|
|element.attribute = propertyValue|修改元素的属性值|document.getElementById("img").src="test.png"|
|element.style.property = propertyValue|修改元素的样式|document.getElementById("p1").style.color="red"|

为元素添加监听事件：**element.addEventListener(event, function, useCapture);**

* event 是事件类型（click、mousedown 等）
* function 是事件发生时调用的函数
* useCapture 使用冒泡模式（false），或捕获模式（true），对于相同的事件，冒泡模式下，内部元素先响应，捕获模式下，外部元素先响应

```
<script>
document.getElementById("p1").addEventListener("click", function() {
    alert("点击了 p1 元素!");
},false);
document.getElementById("div1").addEventListener("click", function() {
    alert("点击了 div1 元素 !");
},false);
document.getElementById("p2").addEventListener("click", function() {
    alert("点击了 p2 元素!");
},true);
document.getElementById("div2").addEventListener("click", function() {
    alert("点击了 div2 元素 !");
},true);
</script>
```
> 添加多个事件，后添加的事件不会覆盖前面添加的事件

移除元素的监听事件：**element.removeEventListener(event, function);**

* event 是事件类型（click、mousedown 等）
* function 是事件发生时调用的函数