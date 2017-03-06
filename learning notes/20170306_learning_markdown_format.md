[文件顶部，这是一个锚点，此段文字可省略](id:top)

标题1-标题内容下紧跟至少3个‘=’
===

标题2-标题内容下紧跟至少3个‘-’
---------
===
当3个及以上的‘=’的上一行没有内容或非显示的格式字符时，则生成一个分隔线，如上面和下面这两条分隔线

=====

---
当3个及以上的‘-’的上一行没有内容或非显示的格式字符时，则生成一个分隔线，如上面和下面这两条分隔线

---
另外3个或多个下划线或星号，可以显示分隔线
_______
*******

# 标题1-‘#’ 标题内容
## 标题2-‘##’ 标题内容
### 标题3-‘###’ 标题内容
#### 标题4-‘####’ 标题内容
##### 标题5-‘#####’ 标题内容
###### 标题6-‘######’ 标题内容
用1到6个‘#’来表示6个级别的标题的大小

-----
*斜体字：内容的前后分别加个 \*实现斜体格式，注意与\*之间不能有空格*

_使用 \_ 也可以实现斜体字效果_

** 粗体字：内容前后用两个 \* 包裹，实现粗体字，可以有空格 **

__ 使用两个 \_ 也可以实现粗体字格式 __

_** 斜体与粗体混用（ \_ 和 \* 混用） **_

*** 斜体与粗体混用（3个 \* 包裹内容） ***

---
这个角标必须是从小到大的顺序，而且不能重复[^1]
*****

![baidu](http://www.baidu.com/img/bdlogo.gif "百度logo")

![baidu][baidulogo]
[baidulogo]:http://www.baidu.com/img/bdlogo.gif "百度logo"

  
  <br/>这个id如果有重复，以第一个为准

[www.hao123.com](http://www.hao123.com "hao123")

[baidu][baidu]
[baidu]:http://www.baidu.com "baidu"

# This text is testing for file extesioned with .markdown 

## The usage of character '#'

```
The usage of characters \` ` `
```

*this is test*[^2]

**this is test**

|   Maki    |  BOb    |   Mary    |  Lantin    |   Rose    |  Jack    |
|-----------|---------|:-----------|---------:|:-----------:|---------|
|你觉得他会是怎样的对齐方式？|这个谁他妈知道呢！|你猜|I do not care|let me have a try!|he he|
|笨，你不会试试么！|擦，你等着，孩儿们，动起来|我左边有冒号|我右边有冒号|我两边都有冒号|我没有冒号✌️|
|啥结果？|你瞎呀！|靠左|靠右|中间|标题在中间，内容靠左边|

`{	
	NSString *value = @"this is a test string."
}`

***

```
{
	int i = 0;
	for (;i<5;i++){
		//code
	}
}
```
*[anchor](#anchor)*

**[back to top ](#top)**


~~what is this~~


[^1]:这个有什么用？
[^2]:这个挺有用的。

------
这里地文字会出现在哪里呢？

看来脚注始终显示在文档底部，不管他写着文档的哪里！


听说多个空格     可以换行？<span> &nbsp;&nbsp;&nbsp;&nbsp;       </span>怎么不行呢？  
好吧，要在上一行敲两个及以上空格才行！


> this is list1
>> this is list2
>>> this is list3
	
	* item1
	* item2
		* item
		* item
		* item
			1. 1111
			2. 2222
			3. 3333
			
>>> this is list4
