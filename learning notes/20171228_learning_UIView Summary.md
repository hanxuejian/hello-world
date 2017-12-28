## UIView
当 UIView 中的内容被渲染后，渲染的结果会被保存，当 UIView 发生大小或旋转等几何变化时，其内容并不会重新绘制，而是根据 UIVIew 的属性 **contentMode** 值进行相应的变化。但是如果该值为 **UIViewContentModeRedraw** 时，系统不会去复用缓存的渲染结果，而是调用下面的方法去渲染新的内容，并缓存渲染结果。

```
- (void)drawRect:(CGRect)rect;
```
当然，如果需要在特定的时机重新渲染 UIView 中的内容，可以调用下面的方法来告知系统，那么在下一个循环来到时，内容便会被重新渲染。

```
- (void)setNeedsDisplay;
- (void)setNeedsDisplayInRect:(CGRect)rect;
```
不过，应该尽量避免内容的重新绘制，尤其对于框架中封装的标准控件视图，不应该进行重绘。

当 contentMode 值设置为 **UIViewContentModeScaleToFill** 、**UIViewContentModeScaleAspectFit** 或 **UIViewContentModeScaleAspectFill** 时，UIView 中的内容可能会被拉伸变形，通过设置属性 **contentStretch** 的值来限定能够被拉伸变形的区域。

在 UIKit 框架中，设备屏幕的几何坐标是以左上角为原点，向右为 x 轴正方向，向下为 y 轴正方向。另外，每个 UIView 都有自己的坐标系，所以对于绘制图形或者对图形做几何变换时，需要明确究竟是哪个坐标系在起作用。

在 UIView 中，属性 **frame** 、**bounds** 和 **center** 是相关的，改变其中的一个会影响其他的属性值。frame 记录了 UIView 的大小和其在父视图中的位置坐标，bounds 则记录了 UIView 本身的原点坐标和大小，center 保存的是 UIView 的中心点在父视图中的位置，注意这个坐标是相对于父视图坐标系的。

在绘制视图时，如果子视图超出了父视图，可以通过设置父视图的属性 **clipsToBounds** 为 YES 来裁剪掉子视图超出父视图的部分，如果使用默认值 NO ，那么超出的部分也会渲染出来，但是，不管哪种情况，超出的视图并不能响应点击等事件。

在绘制 UIView 的过程中，使用仿射变换的方式，可以快速的实现 UIView 的几何变换。在 `drawRect:` 中使用 **CGContextGetCTM**  函数或者通过 UIView 的 **transform** 属性都可以获取 **current transformation matrix (CTM)**，通过修改 CTM 的值来实现当前图形的几何变换。几何变换总是相对于其父视图的坐标系的，而视图中的内容是相对于本身的坐标系的，所以改变的 CTM 的值时，会影响子视图的几何位置，但这只是渲染时看到的效果发生了变化，其子视图的内容相对于本身坐标系的坐标并没有受到影响。

UIView 或者 UIWindow 中都提供了坐标转换的方法，来实现不同坐标在不同坐标系之间的转换。需要注意的是，如果视图本身发生了旋转，那么在转换视图中的矩形坐标到其他坐标系时，返回的结果所表示的矩形并不一定与原视图中的矩形大小一致。如一个父视图拥有一个旋转了45度的子视图，子视图中有一个矩形，将这个子视图中的矩形的坐标转换到父视图中时，返回的矩形其实是待转换矩形的外接矩形。

> 当 transform 的属性值不是 **CGAffineTransformIdentity** 时，frame 的值是没有意义的，需要使用 bounds 和 center 的值来确定视图的位置。

在 iOS 中，使用点的概念来计量坐标系中的位置或者屏幕的宽高，这个计量并不会因为设备的不同而改变，且1个点并不是始终对应一个像素点。

|设备|宽高（单位：点）|
|:---:|:---:|
|iPhone 和 iPod touch 的 4 英寸的 Retina 显示屏|`320*568`|
|iPhone 和 iPod touch|`320*480`|
|iPad|768*1024|

这种使用点的概念来进行坐标计算的方式被定义为用户坐标空间（**user coordinate space**），但是就设备而言，所有的坐标最终需要转换为像素点才能对应到屏幕上，这个坐标系称为设备坐标系（**device coordinate space**），不过这个转换的过程通常由系统自动进行。

为了提高性能，保证界面流畅，应注意下面几点：

* 要注意并不是所有的 UIView 都要有对应的 UIViewController 控制器进行管理
* 应尽可能的避免视图的重新渲染
* 能够使用框架提供的标准视图控件组合而成的视图组件，就应避免进行绘制自定义的视图
* 对于不透明的视图，应设置 UIView 的属性 **opaque** 为 YES ，系统便不会对该视图的后面进行绘制
* 如果是对所有区域进行绘制，那么应设置 **clearsContextBeforeDrawing** 为 NO 避免在调用 **drawRect** 之前对要绘制的区域进行刷新
* 在频繁调整视图时（如滚动视图）应调整绘制视图的质量或方式以保证视图能够流畅滚动或变化
* 对于框架中提供的视图控件，不应该向其中添加子视图，这样容易导致错误

每个 UIView 都有一个图层管理视图内容的显示和动画。这个图层的默认类是 **CALayer** 但是通过重写 UIView 的 **layerClass** 方法可以指定新的类。

UIView 的一些属性支持动画效果，但是只是直接修改这些属性值并不会有动画效果。要想属性值修改时，实现动画效果，应将修改属性的代码放在 block 中，UIView 提供了下面几个方法来实现属性值修改时，有动画效果。

```
+ (void)animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^ __nullable)(BOOL finished))completion NS_AVAILABLE_IOS(4_0);

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^ __nullable)(BOOL finished))completion NS_AVAILABLE_IOS(4_0);

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations NS_AVAILABLE_IOS(4_0);
```
上面的方法只适用于 iOS 4 及其之后的系统，如果是在 iOS 3.2 及其之前的系统，则需要将属性的变动和动画的设置放在下面两个方法之间。

```
+ (void)beginAnimations:(nullable NSString *)animationID context:(nullable void *)context;
+ (void)commitAnimations;
```
要实现动画开始之前或结束之后执行某些操作，可以在上面的两个方法之间调用下面的方法设置代理和执行方法。

```
//设置代理
+ (void)setAnimationDelegate:(nullable id)delegate;     

//指定的方法应类似 -animationWillStart:(NSString *)animationID context:(void *)context
+ (void)setAnimationWillStartSelector:(nullable SEL)selector;

//指定的方法应类似 -animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
+ (void)setAnimationDidStopSelector:(nullable SEL)selector; 
```

## UIWindow
UIWindow 是 UIView 的子类，该类描述的是所有视图的容器，所以一个应用中至少要有一个 UIWindow 类实例，并且在整个运行过程中强引用。它可与控制器协作实现屏幕的旋转，可以传递触摸事件，这里要注意的是 UIWindow 本身不包含内容，所有可见的内容都在其包含的 UIView 视图中，所以如果 UIWindow 并不是全屏的，而 UIView 又超出了 UIWindow 的范围，那么 UIView 的触摸事件可能并不会被响应。

在创建工程时，Xcode 生成的模版会指定 UIWindow 但是通过在 Info.plist 文件中设置 **NSMainNibFile** 值可以指定加载 UIWindow 时的资源文件。另外，还可以直接用代码创建 UIWindow 实例，在指定其大小时，通常使用屏幕的大小，而不必在意状态栏，因为状态栏始终是浮在 UIWindow 之上的。

如果要监听 UIWindow 的出现和隐藏，可以注册通知 **UIWindowDidBecomeVisibleNotification** 和 **UIWindowDidBecomeHiddenNotification** ，当应用中的 UIWindow 出现或隐藏时，相应的通知就会发出，但是应用进入后台，并不会发出该通知，相对于应用，UIWindow 被认为仍是显示的。

UIWindow 中的触摸等事件会发送给该 UIWindow 中的视图进行响应，但是一些诸如键盘弹出等未绑定到具体 UIWindow 的事件，都会由当前 **key window** 接收。通过注册 **UIWindowDidBecomeKeyNotification** 和 **UIWindowDidResignKeyNotification** 来追踪 key window 。

一般设备只有一个屏幕关联一个 UIWindow 用来显示内容，但是如果有外部屏幕连入设备，应创建新的 UIWindow 类实例在外部屏幕上显示内容。注册屏幕连接（**UIScreenDidConnectNotification**）的通知后，可以监听屏幕的接入，如果接到了该通知，可以使用 UIScreen 的 **screens** 属性获取所有的屏幕（返回的数组中第一个元素总是设备内屏幕），将指定的屏幕赋给 UIWindow 的属性 **screen** 之后便可以向 UIWindow 中添加视图来显示内容了。另外，需要注册屏幕断开连接（**UIScreenDidDisconnectNotification**）的通知，当收到该通知后，应释放与之相关联的 UIWindow 实例对象。在屏幕上显示内容之前，可以通过 UIScreen 的 **availableModes** 属性获取屏幕支持的显示模式，模式中保存着屏幕的大小和横纵像素比。遍历获取的所有模式，选择自己需要的模式。