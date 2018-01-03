# Quartz 2D 学习总结

Quartz 2D 是 Core Graphics 框架的一部分，可用于编辑、绘制图像，创建或显示位图图像，并且可操作 PDF 文档。

> 位图文件（Bitmap），扩展名可以是.bmp或者.dib。位图是Windows标准格式图形文件，它将图像定义为由点（像素）组成，每个点可以由多种色彩表示，包括2、4、8、16、24和32位色彩。例如，一幅1024×768分辨率的32位真彩图片，其所占存储字节数为：1024×768×32/(8*1024)=3072KB
位图文件图像效果好，但是非压缩格式的，需要占用较大存储空间，不利于在网络上传送。jpg格式则恰好弥补了位图文件这个缺点。

Quartz 2D 使用绘图者模式进行图像的绘制，在该模式下，每一次成功绘制动作都会为画布添加一个图层，画布通常也称作页面，页面上绘制的图像无法修改，除非再一次进行绘制，将原图层覆盖。由此可见，后绘制的图形可能覆盖先绘制的图形，所以，在绘制者模式下，绘制图形的先后顺序很重要。另外，绘制的页面可能是真实的纸（如果输出设备是打印机），也可能是虚拟纸张（如果输出设备是 PDF 文件），甚至可以是位图文件，而具体是哪一种，则取决于你所使用的是哪一种图形上下文。

图形上下文是一个不透明的数据结构（CGContextRef），该数据结构包含了 Quartz 绘制图形所需的信息，包含绘制图形的输出设备、绘制图形时使用的参数和显示图形的指定设备等，Quartz 绘制图形均要绘制到图形上下文中。

Quartz 通过改变图形上下文中存储的状态参数来决定最终绘制出来的图形，上下文中有一个保存图形状态的栈，当某一个状态需要在以后使用时，可以调用 CGContextSaveGState 方法将当前上下文中的状态拷贝并推入栈中进行保存，而后改变当前上下文中的状态进行其他绘制，需要再次使用保存的状态时，调用 CGContextRestoreGState 方法，会将栈首的状态推出，替换当前上下文中的状态。

Quartz 绘制图形时，其默认的坐标系是左下角为坐标系原点，向上为 Y 坐标轴正方向，向右为 X 坐标轴正方向，但因为 iOS 中使用的坐标系是左上角为坐标系原点，向下、向右为 X、Y 轴正方向，所以，在获取图形上下文时，Quartz 坐标系也改为与 iOS 的坐标系一致。

## 创建图形上下文

在 iOS 中创建视图图形上下文，需要重写 UIView 类的 drawRect: 方法，该方法在视图显示或其内容需要更新时调用，在调用前，视图对象会自动配置绘制环境，其中会生成一个图形上下文，使用 UIGraphicsGetCurrentContext 方法即可获取这个上下文。

类似于在 iOS 中获取图形上下文，在 Mac OS X 中获取图形上下文，需要重写 NSView 的方法 drawRect: ，在该方法中获取上下文
CGContextRef myContext = [[NSGraphicsContext currentContext] graphicsPort];

创建 PDF 图形上下文时，使用 CGPDFContextCreate 、CGPDFContextCreateWithURL 方法，获取的 PDF 上下文，需要注意其使用的坐标系是 Quartz 的默认坐标系，如果在绘制 PDF 与 UIView 视图时使用相同的代码，那么就需要注意通过 CTM 改变其坐标系方向。

创建位图文件图形上下文，使用 CGBitmapContextCreate 方法，其得到的上下文坐标系是 Quartz 默认的坐标系，但是在 iOS 中，通常使用 UIGraphicsBeginImageContextWithOptions 方法获取上下文，该上下文已经过处理，其坐标系同 UIView 使用的坐标系一致。
通过位图上下文绘制得到的图片，可以再绘制到其他上下文中，从而进行输出。
在绘制位图时，若其分辨率低于人眼的分辨率，那么，图形边缘会出现锯齿形，所以可以调用 CGContextSetShouldAntialias 方法消除该情形。

## 路径

路径中包含一个或多个图形，或者多个子路径，而每个子路径可以是直线或曲线组成的简单图形，也可以是由许多线条组成的复杂图案。一个子路径可以是闭合的，也可以是非闭合的，对于直线、弧线、曲线，其是否闭合不是看它们的路径的起点和终点是否重合，而是这条子路径是否调用了 CGContextClosePath 方法，当然闭合的路径起始点与终点一定是重合的。

创建路径应注意以下几点：

* 开始创建路径应调用 CGContextBeginPath 方法
* 对于一个空的路径是没有当前点坐标的，所以在添加直线、曲线、弧线这种从当前点开始绘制的线条时，应先调用 CGContextMoveToPoint 方法
* 调用 CGContextClosePath 方法关闭当前子路径，再次添加线条，则开始了一个新路径
* 绘制弧线时，Quartz 会自动添加一条直线连接当前点与弧线的起点
* Quartz 向路径中添加椭圆、矩形时，其是作为一个单独的子路径进行添加的且是闭合的
* 创建的路径不会自动显示，需要调用 Quartz 中的方法进行渲染

路径一经渲染，其便会从图形上下文中清除，所以，如果需要重复使用路径，就需要保存生成的路径，Quartz 提供了 CGPathRef 和 CGMutablePathRef 两个类型，用于保存路径。所以在绘制路径的过程中，可以使用 CGPath 中的方法，其方法与 CGContext 中的方法达到相同的效果。

|CGContext 中的方法|CGPath 中的方法|
|:----:|:-----:|
|CGContextBeginPath|CGPathCreateMutable|
|CGContextMoveToPoint|CGPathMoveToPoint|
|CGContextAddLineToPoint|CGPathAddLineToPoint|
|CGContextAddCurveToPoint|CGPathAddCurveToPoint|
|CGContextAddEllipseInRect|CGPathAddEllipseInRect|
|CGContextAddArc|CGPathAddArc|
|CGContextAddRect|CGPathAddRect|
|CGContextClosePath|CGPathCloseSubpath|

当路径绘制好后，可以使用方法 CGContextAddPath 将路径添加到上下文中，这些路径在 Quartz 渲染显示前会一致保存在上下文中，下次再进行这些路径的绘制渲染时，仍然可以调用 CGContextAddPath 方法。

在渲染路径时，可以是描绘方式或者填充模式，在描绘路径时，应设置以下状态：

|设置方法|含义|
|:---:|:---:|
|CGContextSetLineWidth|设置线宽|
|CGContextSetLineJion|设置线的连接处的连接方式|
|CGContextSetLineCap|设置线的端点处的线帽类型|
|CGContextSetMiterLimit|设置斜接线的长度限制，如果两线以斜接方式连接，那么，若斜接长度除以线宽大于此处设置的值，那么两线改为切角连接|
|CGContextSetLineDash|若想使用虚线描绘路径，则使用该方法设置路径的虚线样式|
|CGContextSetStrokeColorSpace|设置描绘路径的颜色空间|
|CGContextSetStrokeColor、CGContextSetStrokeColorWithColor|设置描绘路径的颜色|
|CGContextSetPattern|设置描绘路径的样式|

根据需要设置好这些状态后，可以调用描线方法：

|方法|含义|
|:---:|:---:|
| CGContextStrokePath |描绘当前路径|
| CGContextStrokeRect |描绘指定的矩形|
| CGContextStrokeRectWithWidth |使用指定的线宽描绘指定的矩形|
| CGContextStrokeEllipseInRect |在指定的矩形中描绘椭圆|
| CGContextStrokeLineSegments |描绘多条直线|
| CGContextDrawPath |描绘路径，此处应该传递参数 kCGPathStroke |

在填充路径时，Quartz 会判断路径中的所有子路径，对于没有闭合的子路径，其会自动将当前点与起点相连接，构成闭合路径，而后进行填充。
对于简单的图形，如矩形、圆形等，这些很容易计算需要填充颜色的区域，但是对于重叠的路径，如同心圆，则有两个填充规则可供选择。

* 非零绕数规则，这个规则时默认规则，对于重叠区域的点，以该点为起点，画一条直线穿出所有相关的路径区域，从零开始计数，当有路径从左到右
穿过该条直线，则计数加一，若路径从右到左穿过直线，则计数减一，最终结果若为零，那么该点就不进行渲染，否则，就进行渲染。

* 奇偶规则，从待渲染的点画出一条直线，若路径穿过这条直线的条数为奇数，则渲染该点，否则，不渲染。

## 混合模式
在有背景的上下文中绘制，或者说当绘制的图形发生重叠时，上下两个图形该如何显示呢。可以通过调用 CGContextSetBlendMode 方法设置
渲染的模式，默认值是 kCGBlendModeNormal ，该值表明下面的图形被覆盖。模式的不同，是因为图形的透明度的使用不同，其遵循下面的公式：

`result = (alpha * foreground) + (1 - alpha) * background`

## 图形变换
Quartz 2D 绘制模型定义了两个坐标系，一个用户坐标系，一个设备坐标系，前者由用户使用，后者由设备使用，当打印或者显示图形时，
Quartz 会自动将用户空间的坐标映射到设备空间中，不需要额外的编程。

CTM（current transformatoin matrix）当前变换矩阵，可以通过改变 CTM 来改变绘制的图形，另外，可以构建仿射变换矩阵，然后调用 CGContextConcatCTM 方法，用 CTM 乘以构建的仿射变换矩阵，从而变换图形。

|方法|含义|
|:---:|:---:|
| CGContextTranslateCTM |改变 CTM 以实现图形的平移|
| CGContextRotateCTM |改变 CTM 以达到图形的旋转|
| CGContextScaleCTM |改变 CTM 以达到图形的缩放|
| CGAffineTransformMakeTranslation |构建一个平移矩阵|
| CGAffineTransformTranslate |在提供的仿射矩阵上构建一个平移矩阵|
| CGAffineTransformMakeRotation |构建一个旋转矩阵|
| CGAffineTransformRotate |在提供的仿射矩阵上构建一个旋转矩阵|
| CGAffineTransformMakeScale |构建一个缩放矩阵|
| CGAffineTransformScale |在提供的仿射矩阵上构建一个缩放矩阵|

## 图样
图样（pattern）是在图形上下文中反复绘制一系列图形的操作。图样单元是的图样的基础，分为彩色图样单元（colored patterns）和
模板图样单元（stencil patterns）。两者的区别在于，彩色单元的的颜色是创建单元的一部分，而模板单元在创建时是不包括颜色的，
其颜色是在渲染时确定的。

使用图样描绘或者填充图形，同使用颜色类似，要先设置图样，调用 CGContextSetFillPattern 方法，在调用之前需要先定义一个
图样变量 CGPatternRef ，使用 CGPatternCreate 方法创建一个图样类型的变量，其中一个关键参数是 CGPatternCallbacks 
，这个参数提供了创建图样单元的回调方法。

调用 CGContextSetShadow、CGContextSetShadowWithColor 方法，设置图形的阴影。

## 颜色梯度
当一种颜色到另一种颜色过渡时，会有一个渐变的过程，使用梯度来描述这种过程，并且可以设置这种渐变的情形。梯度分为轴向梯度与径向梯度。

* 轴向梯度，也叫线性梯度，从一个端点到另一个端点，这条线段上的垂线的所有的点的颜色值均相同。
* 径向梯度，对于同一个圆心，相同半径上的点的颜色值一致，即圆上的点的颜色值均相同。

Quartz 提供了两种类型 CGGradient 与 CGShading 用于描述梯度，用于绘制图形。前者 Quartz 会根据使用者提供的位置及颜色计算
每个点的梯度颜色值，而后者使用者需要提供自己的回调函数用于计算每个点的颜色梯度值。

使用 CGGradient 变量，先调用 CGGradientCreateWithColors、CGGradientCreateWithColorComponents 方法，
创建 CGGradient 变量描述梯度，然后使用 CGContextDrawLinearGradient、CGContextDrawRadialGradient 绘制轴向、径向梯度。

使用 CGShading 变量，先调用 CGShadingCreateAxial、CGShadingCreateRadial 方法，创建描述轴向、径向梯度颜色的变量，
而后调用 CGContextDrawShading 方法进行绘制。

## 透明图层
透明图层（transparency layer），由多个图形构成的组合图形，其会被当作一个图形进行其他的操作。创建透明图层很简单，主要是开始与结束标志，
如下：

1. 调用 CGContextBeginTransparencyLayer 方法，表示开始透明图层的绘制
2. 调用 CGContext 中的方法进行图形的绘制
3. 调用 CGContextEndTransparencyLayer 方法，表示结束透明图层的绘制

这两个标志之间绘制出的图形会被当作一个图形进行操作。
