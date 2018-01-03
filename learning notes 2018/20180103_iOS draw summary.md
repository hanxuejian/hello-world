# iOS 绘图小结
使用 iOS 中框架提供的绘图接口可以实现自定义视图的绘制，还可实现位图、PDF 文档内容的绘制。iOS 中支持绘图的原生框架有 **UIKit** 、**CoreGraphics** 、**QuartzCore** 。UIKit 框架中的 UIView 及其一些子类声明了一些绘制图形的方法，CoreGraphics 框架则提供了更多底层的方法支持图形的绘制，而 QuartzCore 中的 CoreAnimation 则提供了实现图形动画效果的方法。

使用 UIKit 框架绘制视图时，所有的绘制代码应放在 UIView 的 **drawRect:** 方法中，在调用这个方法进行绘制之前，系统会自动准备图形上下文，这个图形上下文保存着进行绘制时的属性，如线宽、颜色等信息。在 `drawRect:` 方法中获取这个图形上下文，进行必要的设置即可进行绘制视图。

在进行绘制时，图形上下文的绘制操作总是相对于坐标系的，这个坐标系可能与当前的 UIView 的坐标系一致（即使这个 UIView 发生了旋转），但是可以通过修改当前图形上下文中的当前变换矩阵（current transformation matrix）来修改该坐标系相对于当前 UIView 的位置，需要注意改变图形上下文的变换矩阵时，所有的变换都是相对于坐标系原点的，不像 UIView 默认相对于中心点。另外，要明白绘制时的坐标、长度等计量都是按照点的概念来计量的，要区别于最终设备上的像素计量方式。

## 基本概念
对于自定义的 UIView 子类，需要重写 `drawRect:` 方法来实现图形的绘制。每当视图第一次显示在屏幕上或者在其他时机需要重新绘制时，系统就会调用 `drawRect:` 方法。

触发 `drawRect:` 方法的情况有下面几种：

* 有视图移除或显示时影响了当前视图的显示
* 视图属性 hidden 被置为 NO 后重新设置为 YES 
* 视图中内容滚动出屏幕后再次滚回屏幕内
* 明确调用方法 setNeedsDisplay 或 setNeedsDisplayInRect: 

### 坐标系
在 `drawRect:` 方法中获取的图形上下文是经过系统处理的，它的默认坐标系同当前的 UIView 的坐标系是重合的，但是应该知晓的是对于图形上下文，其有三个坐标系的概念。

* 绘图坐标系，这个坐标系是面向开发者的，所有的绘制命令都是对于该坐标系而言的。
* 视图坐标系，这个坐标系描述的是绘图坐标系中的点在 UIView 视图中的位置。
* 设备坐标系，这个坐标系描述的是绘图坐标系中的点最终在设备上的像素点的位置。

在 iOS 中，坐标系通常分为两种，一种坐标系原点在左上角（ULO），向右为 x 轴正方向，向下为 y 轴正方向；一种坐标系原点在左下角（LLO），向右为 x 轴正方向，向上为 y 轴正方向。一般在 UIKit 框架和 CoreAnimation 框架中使用的默认坐标系都是 ULO 形式的，而在 CoreGraphics 框架中使用的坐标系都是 LLO 形式的。

在 `drawRect:` 中使用 **UIGraphicsGetCurrentContext** 函数获取的图形上下文的默认坐标系经过了系统处理，其坐标系是与当前视图坐标系是重合的，即使当前视图发生了旋转等变换。

### 像素
为了保证不同的设备上绘制的内容保持一致，在 iOS 中使用了逻辑坐标空间，用**点**的概念来描述绘制图形时的位置和大小，而一个点表示几个像素则根据设备而定，并且将点具体以像素显示在设备上的过程由系统负责。

对于普通的显示屏，一个点对应一个像素点，但是在高清显示屏上则不然，一个点可能对应两个像素点或三个像素点。在 UIView 中属性 **contentScaleFactor** 描述了点和像素的关系，在 iOS 4 之前，默认该值为 1 。

> 在 PDF 的绘图上下文中，CoreGraphics 定义一个点表示 1／72 英寸。

在 iOS 系统中，为了防止在高分辨率屏幕上显示正常的图形在低分辨率的屏幕上显示时出现齿状，系统会自动的拉伸图形使其占满像素点。当在低分辨率屏幕上绘制宽为一个点的竖直黑线时，如果这个直线的宽刚好占满一个像素，则正常显示，但是如果该线开始位置并不是一个像素的起始位置，那么线会被拉伸占满两个像素，同时颜色也会失真，而在高分辨率屏幕上则不会出现这种情况，当然如果旋转这个直线处于不平行于坐标轴的位置，也不会出现该情况，因为此时系统并没有使用防锯齿技术，也不应该使用。

### 图形上下文
不管是向视图或 PDF 文件中绘制内容，还是直接绘制生成图片，都需要用到**图形上下文** 。当前生效的图形上下文保存着绘制的信息，如画笔的颜色、线条的粗细、绘制的位置等。在 UIKit 框架中，提供了简单的函数用来进行图形的绘制，其中获取的图形上下文的坐标系是 ULO 形式的，如下函数：

```
UIKIT_EXTERN CGContextRef UIGraphicsGetCurrentContext(void);

UIKIT_EXTERN void UIGraphicsBeginImageContext(CGSize size);

UIKIT_EXTERN void UIGraphicsBeginPDFPage(void)
```
当然，在 CoreGraphics 框架中，也提供了创建图形上下文的函数，但是创建图形上下文的坐标系是 LLO 形式的，所以要使用该上下文对视图进行绘制，应该调整它的坐标系。需要注意的是，当坐标系发生翻转后，相对该坐标系绘制的图形的方向也要做相应的变化。在进行旋转或绘制弧线时，提供的弧度的正负与当前坐标系的方向，决定了旋转的方向和弧线的方向。弧度值为正值，方向为弧度的正方向，否则为弧度的负方向。弧度的正方向为 x 轴正方向指向 y 轴正方向的距离最短的方向。对于 ULO 坐标系，顺时针为正方向，而 LLO 坐标系，逆时针为正方向。

### 动画
CoreAnimation 框架提供了创建动画的接口，它并不提供绘制的方法，而是一种将其他技术绘制出来的图形动态化的框架。该框架的主要概念便是图层，它类似于视图，但实际上封装了几何信息、时间线、可见内容属性等信息。通常，有下面三种方法来修改图层中的内容。

* 直接为图层的 contents 属性赋值
* 为图层设置代理对象，实现代理方法提供要显示的内容
* 自定义图层，重写绘制方法

使用 **CAAnimation** 类或其子类来定义一个动画，使用 **CATransaction** 类将定义的多个动画合成一个动画单元。

在 drawRect: 方法或图层的代理方法 drawLayer:inContext: 中使用图层显示内容时，系统会自动调整点与像素之间的关系，即图层的属性 **contentsScale** 。当图层与一个视图相关联时，该值同视图的 **contentScaleFactor** 值相等，并且变化一致。而对于没有相关联的图层的 contentsScale 的值默认为 1 。当默认值为 1 时，将内容渲染到高分辨率屏幕上，内容会根据图层的属性 **contentsGravity** 的值来决定是否放大，默认值 **kCAGravityResize** 是填满显示范围。若不想放大，可以将 contentsScale 的值改为 2 ，但是如果提供的要渲染的内容是低分辨率的，那么在高分辨率的屏幕上显示的内容要比预想的要小。

## 曲线绘制
**UIBezierPath** 是 Objective-C 中的类，它是对 CoreGraphics 框架中线条绘制相关接口的封装。该类提供了绘制直线、矩形、圆形、椭圆、曲线和抛物线等线条的绘制方法。

绘制线条时，基本都需要明确绘制的起始位置，使用类方法 **bezierPath** 创建一个 UIBezierPath 实例对象。调用方法 **moveToPoint:** 指定绘制的起始点，而后调用下面的方法添加想要的线条。

```
//添加直线
- (void)addLineToPoint:(CGPoint)point;

//添加曲线
- (void)addCurveToPoint:(CGPoint)endPoint controlPoint1:(CGPoint)controlPoint1 controlPoint2:(CGPoint)controlPoint2;

//添加抛物线
- (void)addQuadCurveToPoint:(CGPoint)endPoint controlPoint:(CGPoint)controlPoint;
```
添加弧线时，使用下面的方法，如果已经有确定的起始点，系统会自动将起始点与弧线的起始点相连接。

```
//添加弧线
- (void)addArcWithCenter:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle clockwise:(BOOL)clockwise NS_AVAILABLE_IOS(4_0);
```
如下面的示例，最终的图形是两段直线和一段弧线。

```
- (void)drawRect:(CGRect)rect {
    UIBezierPath *path = [UIBezierPath bezierPath];    
    [path moveToPoint:CGPointMake(20, 30)];
    path.lineWidth = 2;    
    [[UIColor redColor]set];
    [path addLineToPoint:CGPointMake(50, 60)];    
    [path addArcWithCenter:CGPointMake(100, 100) radius:50 startAngle:0 endAngle:M_PI_2 clockwise:YES];    
    [path stroke];
}
```
另外，UIBezierPath 中提供了方法来检验指定的点是否落在关闭的曲线上，或在关闭的曲线内部。对于没有调用 **closePath** 方法进行关闭的曲线，调用下面的方法，始终返回 NO 。

```
- (BOOL)containsPoint:(CGPoint)point;
```

## 图像绘制
如果需要将图片绘制到视图中去，可以调用 UIImage 中的方法。这些方法会自动处理坐标系不同带来的影响，而使用 **CGContextDrawImage** 函数，则需要自己进行坐标系的调整。

在 UIKit 框架中，除了使用 UIImage 中的方法将图片绘制到视图中外，还可以使用下面的函数获取图形上下文进行图片的绘制，而后生成一个图片。

```
//开始绘制图片的图形上下文，只指定了绘制的范围大小（单位：点）
UIKIT_EXTERN void     UIGraphicsBeginImageContext(CGSize size);

//开始绘制图片的图形上下文，指定了绘制的范围大小、是否不透明、点与像素的关系
//size 指定绘制的范围大小（单位：点）
//opaque 对于含有透明度通道的图片，传 NO ，如果图片没有透明的区域，应设置为 YES
//scale 表示点与像素的关系，同 size 一起决定了最终的图片所包含的像素点的个数
UIKIT_EXTERN void     UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale) NS_AVAILABLE_IOS(4_0);

//根据当前上下文中的内容创建一个图片
UIKIT_EXTERN UIImage* __nullable UIGraphicsGetImageFromCurrentImageContext(void);

//结束图形上下文
UIKIT_EXTERN void     UIGraphicsEndImageContext(void);
```

如下面的示例，绘制一段弧线，并将其以 PNG 的格式保存到沙盒中。

```
- (void)createPic {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(300, 300), NO, [[UIScreen mainScreen]scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddArc(context, 100, 100, 100, 0, M_PI_2, 0);
    CGContextSetFontSize(context, 2);
    [[UIColor redColor]set];
    CGContextStrokePath(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *data = UIImagePNGRepresentation(image);
    NSString *filePath = [NSString stringWithFormat:@"%@/pic.png",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];
    BOOL success = [data writeToFile:filePath atomically:YES];
    NSLog(@"%@",[NSNumber numberWithBool:success]);
}
```

除了使用 UIKit 框架中的函数外，还可以使用 CoreGraphics 框架中的 **CGBitmapContextCreate** 函数来创建一个绘制图片的图形上下文。

```
/**
data 指定绘制的内容在内存中存储位置，传 NULL 则系统自动分配内容空间
width 绘制的图片的宽度（单位：像素）
height 绘制的图片的高度（单位：像素）
bitsPerComponent 一个像素中的每个颜色通道所占的位数
bytesPerRow 每行所占的字节数，如果 data 为 NULL ，该值可传 0 系统将自动计算位图每行所占的字节数
space 颜色空间
bitmapInfo 透明度通道信息
*/
CG_EXTERN CGContextRef __nullable CGBitmapContextCreate(void * __nullable data,
    size_t width, size_t height, size_t bitsPerComponent, size_t bytesPerRow,
    CGColorSpaceRef cg_nullable space, uint32_t bitmapInfo)
    CG_AVAILABLE_STARTING(__MAC_10_0, __IPHONE_2_0);
```
创建得到上下文后，可以进行需要的绘制，最后使用 **CGBitmapContextCreateImage** 函数获取一个 CGImageRef 变量。

## PDF 文档绘制
同绘制图片类似，UIKit 框架中也提供了绘制 PDF 文档的函数，通过提供的函数可以获取一个绘制 PDF 文档的图形上下文。

```
//绘制的目标最终保存到文件中
/**
path 文件的存储路径，会覆盖已经存在的文件内容
bounds 每一个 PDF 页的默认大小，如果传 CGRectZero ，则系统默认 612*792 （单位：点）
documentInfo 设置 PDF 文档额外的信息
*/
UIKIT_EXTERN BOOL UIGraphicsBeginPDFContextToFile(NSString *path, CGRect bounds, NSDictionary * __nullable documentInfo) NS_AVAILABLE_IOS(3_2);

//绘制的目标保存在内存中
UIKIT_EXTERN void UIGraphicsBeginPDFContextToData(NSMutableData *data, CGRect bounds, NSDictionary * __nullable documentInfo) NS_AVAILABLE_IOS(3_2);
```
创建得到了绘制 PDF 文档的图形上下文后，并不可以立刻进行绘制，而是需要调用下面的方法开始一个 PDF 页，每添加一个 PDF 页都要调用下面的方法。

```
//使用默认的大小创建页
UIKIT_EXTERN void UIGraphicsBeginPDFPage(void) NS_AVAILABLE_IOS(3_2);

//可以指定页的大小和其他信息
UIKIT_EXTERN void UIGraphicsBeginPDFPageWithInfo(CGRect bounds, NSDictionary * __nullable pageInfo) NS_AVAILABLE_IOS(3_2);
```

在每一页上的绘制操作同在视图上进行绘制操作类似，除了绘制内容外，框架中还提供了绘制文档内部链接和外部网络链接的函数。

```
//设置外部网络链接
UIKIT_EXTERN void UIGraphicsSetPDFContextURLForRect(NSURL *url, CGRect rect) NS_AVAILABLE_IOS(3_2);

//设置文档内部链接锚点
UIKIT_EXTERN void UIGraphicsAddPDFContextDestinationAtPoint(NSString *name, CGPoint point) NS_AVAILABLE_IOS(3_2);

//设置文档内部链接
UIKIT_EXTERN void UIGraphicsSetPDFContextDestinationForRect(NSString *name, CGRect rect) NS_AVAILABLE_IOS(3_2);
```

所有绘制结束后，需要调用下面的方法结束绘制，那么 PDF 文档就会保存到指定路径下或存储到指定内存中。

```
UIKIT_EXTERN void UIGraphicsEndPDFContext(void) NS_AVAILABLE_IOS(3_2);
```

## 打印
在 UIKit 框架中提供了支持 AirPrint 的接口，使用该接口可以方便的实现内容的打印。对于简单的打印任务，可以直接使用 **UIActivityViewController** 控制器实现，但是如果要实现较为复杂的打印任务，则需要使用 **UIPrintInteractionController** 控制器。该类包含一个 **UIPrintInfo** 类实例，描述打印任务的信息，包含了一个 **UIPrintPaper** 类实例，描述打印时所用纸张的大小和打印内容的区域，还有一个遵循 **UIPrintInteractionControllerDelegate** 协议的代理对象，来配置更多的打印信息。

更主要的是 UIPrintInteractionController 可以更灵活的指定要打印的内容：

* **printingItem** 打印简单的图片或 PDF 文档，可直接将打印的内容赋给该属性
* **printingItems** 打印过个文件，可以使用该属性
* **printFormatter** 打印流数据如 HTML 数据，使用 **UIPrintFormatter** 的相关子类
* **printPageRenderer** 创建一个 **UIPrintPageRenderer** 的子类，自定义打印操作

上述四个提供打印内容的属性，同一个时间只有一个有效，赋值其中一个，系统会自动将其他三个置为 nil 。

创建打印任务的步骤如下：

1. 调用 **sharedPrintController** 方法获取一个 UIPrintInteractionController 共享实例对象。
2. 创建一个 UIPrintInfo 实例对象，设置打印任务的相关信息，赋值给 UIPrintInteractionController 的属性 printInfo ，如果省略该步骤，将使用默认值。
3. 创建一个遵循 **UIPrintInteractionControllerDelegate** 协议的对象，赋值给 UIPrintInteractionController 的 delegate 属性，可省略该步骤。
4. 设置打印的内容，四种方式只能选择一种，不同的内容提供方式决定不同的打印方式。

配置好打印的信息和内容后，根据设备的不同，调用下面的方法来显示打印界面。

```
//用于 iPhone 设备
- (BOOL)presentAnimated:(BOOL)animated completionHandler:(nullable UIPrintInteractionCompletionHandler)completion;

//用于 iPad 设备
- (BOOL)presentFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated completionHandler:(nullable UIPrintInteractionCompletionHandler)completion;
- (BOOL)presentFromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated completionHandler:(nullable UIPrintInteractionCompletionHandler)completion;
```
当然，在此之前应调用 **isPrintingAvailable** 方法来判断当前设备是否支持打印。

### 打印固定内容
如果只是打印图片或者 PDF 文档，那么只需要提供待打印内容的数据或者地址即可，将数据或地址赋给 UIPrintInteractionController 的属性 printingItem 或 printingItems 。在赋值之前，可以使用下面的方法进行校验，判断所提供的内容或地址是否有效。

```
+ (BOOL)canPrintURL:(NSURL *)url;
+ (BOOL)canPrintData:(NSData *)data;
```

### 设置打印的区域
通过设置 UIPrintInteractionController 的属性 printFormatter 来提供打印的内容时，可以决定打印的具体区域。使用 **UIPrintFormatter** 子类的实例对象为 printFormatter 赋值，该实例对象保存了绘制区域的信息。

* **maximumContentHeight** 打印区域的最大高度
* **maximumContentWidth** 打印区域的最大宽度
* **contentInsets** 打印区域的上、左、右边距，上边距只对第一页有效
* **startPage** 开始打印的页码，从 0 开始计算
* **pageCount** 通过上述设置，计算得到的页面总数

UIPrintFormatter 是一个抽象类，在框架中提供了具体的子类 **UIViewPrintFormatter** 、**UISimpleTextPrintFormatter** 、**UIMarkupTextPrintFormatter** 分别用来打印视图、纯文本和 HTML 文档。需要注意的是，并不是所有的视图都支持打印，目前只有 **UIWebView 、UITextView 、MKMapView** 支持打印，至于其他视图以及自定义视图的打印，应当设置 UIPrintInteractionController 的属性 printPageRenderer 来进行打印。

> 不应去自定义 UIPrintFormatter 的子类，其他打印需求应当通过设置 UIPrintInteractionController 的属性 printPageRenderer 来进行。

### 设置打印的页眉页脚
若需要在打印时设置页眉、页脚内容，则应自定义一个 **UIPrintPageRenderer** 子类，创建该子类实例对象后，将对象赋值给 UIPrintInteractionController 的 printPageRenderer 属性。

在自定义的子类中，重写下面的方法，达到控制打印内容的目的。

```
- (void)drawPrintFormatter:(UIPrintFormatter *)printFormatter forPageAtIndex:(NSInteger)pageIndex;
- (void)drawHeaderForPageAtIndex:(NSInteger)pageIndex  inRect:(CGRect)headerRect;
- (void)drawContentForPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)contentRect;
- (void)drawFooterForPageAtIndex:(NSInteger)pageIndex  inRect:(CGRect)footerRect;
```
使用下面的方法将 UIPrintFormatter 与 UIPrintPageRenderer 相关联，从而可以使用 UIPrintFormatter 来绘制具体的页面内容。

```
- (void)addPrintFormatter:(UIPrintFormatter *)formatter startingAtPageAtIndex:(NSInteger)pageIndex;
```

