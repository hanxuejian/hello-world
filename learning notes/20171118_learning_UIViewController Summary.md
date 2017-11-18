# UIViewController
## 概述
UIViewController 分为两类，一种是内容控制器，用来管理应用中各个独立的内容模块；另一种是容器控制器，其收集其他控制器的信息，以不同的方式显示这些控制器的内容。

UIViewController 的一个重要角色，就是管理着一个视图层级结构，其与一个根视图相关联，而其他需要显示的内容视图都在这个根视图中。内容控制器自己管理所有的视图，通过 outlet 可以使控制器存储其与视图的关联关系，那么当视图加载时，控制器中的 outlet 对象便会自动连接到实际的视图对象。

容器控制器与内容控制器不同，其除了管理自己的视图外，还管理着其他子控制器的根视图，其根据设计改变这些根视图的大小和位置，但是这些根视图的子视图的管理者仍是相应的内容控制器。常见的容器控制器有 UINavigationController、UISplitViewController、UIPageViewController、UITabBarController 等。

## 显示视图控制器
要在一个已经存在的视图控制器上显示一个新的视图控制器，有两种方法，如果这个已经存在的控制器是容器控制器，那么，可以将待显示的视图控制器作为子控制器加入其中。

另外一种，就是直接使用 UIViewController 中的方法显示新的视图控制器。在显示时，这两个控制器构成了一种相互关系，这种关系直到被显示的控制器消失后才会解除。在 UIViewController 中可以通过下面的两个属性来访问显示控制器或被显示的控制器。

```
//该控制器显示的控制器
@property(nullable, nonatomic,readonly) UIViewController *presentedViewController;
//显示该控制器的控制器
@property(nullable, nonatomic,readonly) UIViewController *presentingViewController;
```

在显示之前可以做一些设置来决定显示控制器的样式或方式，如下：

```
//设置被显示的控制器的显示类型
@property(nonatomic,assign) UIModalPresentationStyle modalPresentationStyle;
```
* **UIModalPresentationFullScreen、UIModalPresentationOverFullScreen** 这两个类型表示全屏覆盖，只是使用第一个值时，当控制器显示后，被遮盖的控制器会移除，而第二个不会，所以若显示的控制器视图有透明的部分，应使用第二个值。另外，在使用这个类型时，要求显示控制器的视图本身要是全屏的，若不是，系统会搜索视图结构，使用全屏的视图控制器，或者使用根控制器。
* **UIModalPresentationPageSheet** 页面类型
* **UIModalPresentationFormSheet** 表单类型
* **UIModalPresentationPopover** 将控制器视图显示在一个弹出的视图中
* **UIModalPresentationCurrentContext、UIModalPresentationOverCurrentContext** 这个类型表示覆盖控制器，而只有 definesPresentationContext 属性值为 YES 的控制器才可以被覆盖。另外，可以设置待覆盖的控制器的属性 providesPresentationContextTransitionStyle 值为 YES ，那么显示控制器的方式则由待覆盖的控制器的属性 modalTransitionStyle 决定。
* **UIModalPresentationCustom** 使用自定义的显示方式
* **UIModalPresentationNone** 未定义

```
//设置被显示的控制器的进场方式
@property(nonatomic,assign) UIModalTransitionStyle modalTransitionStyle;
```
* **UIModalTransitionStyleCoverVertical** 垂直进出
* **UIModalTransitionStyleFlipHorizontal** 水平翻转进出
* **UIModalTransitionStyleCrossDissolve** 十字形淡入淡出
* **UIModalTransitionStylePartialCurl** 翻页进出

## 自定义显示视图控制器
在显示控制器时，如果系统提供的方法和样式不满足需求，可以自定义自己的显示方法及样式。要使用自定义方法显示控制器，那么将待显示的控制器的 **modalPresentationStyle** 属性值设置为 **UIModalPresentationCustom** ，并且给属性 **transitioningDelegate** 赋值，这是个遵循 **UIViewControllerTransitioningDelegate** 协议的对象。实现这个协议中的方法，那么在显示控制器时，UIKit 框架会通过 **transitioningDelegate** 调用协议中的方法获取动画对象、交互对象、显示控制器，使用这 3 个对象来实现控制器的自定义显示。

* **Animator objects** 这个动画对象遵循 **UIViewControllerAnimatedTransitioning** 协议，实现协议中的方法来定义控制器的显示及消失的动画。如果不提供这个动画对象，那么显示控制器时，将使用 **modalTransitionStyle** 属性的值，注意这个动画过程是不可交互的。
 
	```
	//返回动画的持续时间
	- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext;
	//定义动画
	- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext;
	```

* **Interactive animator objects** 交互式动画对象，这个对象遵循 **UIViewControllerInteractiveTransitioning** 协议，生成该对象的简单方法是定义一个 **UIPercentDrivenInteractiveTransition** 的子类。在这个子类中可以定义交互事件，控制动画的时序。

* **Presentation controller** 显示控制器时，可以使用框架中的样式，也可以自定义自己的样式。

	使用自己的样式，就要为自己提供的 **transitioningDelegate** 实现 **UIViewControllerTransitioningDelegate** 协议中的
	
	```
	- (nullable UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented 
			presentingViewController:(nullable UIViewController *)presenting 
			sourceViewController:(UIViewController *)source NS_AVAILABLE_IOS(8_0);
	```
	方法。在这个方法中返回一个 UIPresentationController 的自定义子类，通过在该子类中复写父类的方法，以供 UIKit 框架调用，从而实现自定义的样式显示。

### 自定义显示控制器的流程
当调用 UIViewController 中的方法 

```
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated: (BOOL)flag 
		completion:(void (^ __nullable)(void))completion;
```
来显示控制器时，如果待显示的控制器 viewControllerToPresent 的属性 transitioningDelegate 有有效值时，UIKit 框架使用自定义的动画对象来显示控制器。框架调用 transitioningDelegate 的 

```
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
		presentingController:(UIViewController *)presenting 
		sourceController:(UIViewController *)source;
```
方法，获取到有效的动画对象后，进行以下步骤：

1. 调用 transitioningDelegate 的方法 
	
	```
	- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator;
	```
	来确定该动画是否是可交互的，如果该方法返回 nil ，那么动画则是不可交互的。

2. 调用获取的动画对象的方法 **`- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext;`** 得到动画的持续时间。

3. 对于不可交互的动画，调用动画对象的 
	**```- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext;```**
	的方法开始动画。如果是可交互的动画，那么调用可交互动画的
	**`- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext;`**
	方法来设置交互事件并开始动画。

4. 动画结束，控制器成功显示后，调用显示上下文对象的方法 **`- (void)completeTransition:(BOOL)didComplete;`** 表示显示控制器动画过程结束，这样框架便会调用 

	```
	- (void)presentViewController:(UIViewController *)viewControllerToPresent 
			animated: (BOOL)flag 
			completion:(void (^ __nullable)(void))completion;
	``` 
	中的 completion 块，并且调用动画对象的 **`- (void)animationEnded:(BOOL)transitionCompleted;`** 方法。

移除显示的控制器时，过程同上述过程类似，只是获取动画对象或交互动画对象时，调用的是 **`- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed;`** 和 **`- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator;`** 方法。

### 转场上下文对象
在进行显示控制器之前，UIKit 框架会创建一个转场上下文对象，用于保存显示动画的信息。这个对象遵循 **UIViewControllerContextTransitioning** 协议，通过协议中的方法，可以获取该对象保存的显示控制器、待显示的控制器、动画是否可交互等信息。在实现动画对象遵循的协议方法时，会传递遵循 **UIViewControllerContextTransitioning** 协议的具体对象，所以我们自己不必去创建遵循该协议的对象，而只是调用该协议的方法，从而获取需要的信息即可。主要的属性及方法如下

```
//转场相关视图所在的父视图
@property(nonatomic, readonly) UIView *containerView;

//是否能够创建动画，在动画对象的协议方法中，应访问该属性来确定是否定义动画
@property(nonatomic, readonly, getter=isAnimated) BOOL animated;

//控制器的转场是否是可交互
@property(nonatomic, readonly, getter=isInteractive) BOOL interactive;

//转场是否被取消
@property(nonatomic, readonly) BOOL transitionWasCancelled;

//转场的类型
@property(nonatomic, readonly) UIModalPresentationStyle presentationStyle;

/*对于可交互的动画，需要进行适当的操作*/
- (void)updateInteractiveTransition:(CGFloat)percentComplete;
- (void)finishInteractiveTransition;
- (void)cancelInteractiveTransition;
- (void)pauseInteractiveTransition NS_AVAILABLE_IOS(10_0);

//动画结束后调用，告诉框架动画结束
- (void)completeTransition:(BOOL)didComplete;

/*通过相关参数获取相应的控制器
UITransitionContextToViewControllerKey 待显示的控制器
UITransitionContextFromViewControllerKey 待移除的控制器
*／
- (nullable __kindof UIViewController *)viewControllerForKey:(UITransitionContextViewControllerKey)key;

/*通过相关参数获取相应的控制器的视图，如果返回 nil 表示动画对象不应操作该视图
UITransitionContextFromViewKey 待移除的控制视图
UITransitionContextToViewKey 待显示的控制器视图
*／
- (nullable __kindof UIView *)viewForKey:(UITransitionContextViewKey)key NS_AVAILABLE_IOS(8_0);

//获取控制器动画开始之前的位置
- (CGRect)initialFrameForViewController:(UIViewController *)vc;

//获取控制器动画结束之后的位置
- (CGRect)finalFrameForViewController:(UIViewController *)vc;

```

### 转场协调对象
当控制器发生转场时，若其本身视图内的子视图有动画效果需求，或者当屏幕旋转，控制器相应的旋转而其子视图中有动画需求时，可以用 UIViewController 的属性 **transitionCoordinator** 来协调系统动画与自定义动画。

```
@property(nonatomic, readonly) id<UIViewControllerTransitionCoordinator> transitionCoordinator;
```
这个对象遵循 **UIViewControllerTransitionCoordinator** 协议，并且该对象是当控制器转场时框架生成的，并且其也只在转场动作结束前有效，所以我们只需要适当使用该对象实现的协议方法即可，不必自己创建该对象。所以利用该协议方法注册的动画效果是控制器视图动画的一种补充，其执行时间同控制器动画执行时间一致。其相关的方法如下：

```
//注册动画
- (BOOL)animateAlongsideTransition:(void (^ __nullable)(id <UIViewControllerTransitionCoordinatorContext>context))animation
                        completion:(void (^ __nullable)(id <UIViewControllerTransitionCoordinatorContext>context))completion;

//注册动画，只是发生动画的视图不在转场的控制器视图中
- (BOOL)animateAlongsideTransitionInView:(nullable UIView *)view
                               animation:(void (^ __nullable)(id <UIViewControllerTransitionCoordinatorContext>context))animation
                              completion:(void (^ __nullable)(id <UIViewControllerTransitionCoordinatorContext>context))completion;

//给可交互的转场动画添加额外的处理
- (void)notifyWhenInteractionChangesUsingBlock: (void (^)(id <UIViewControllerTransitionCoordinatorContext>context))handler NS_AVAILABLE_IOS(10_0);
```
在调用上面的方法时，系统提供了一个遵循 **UIViewControllerTransitionCoordinatorContext** 协议的对像，这个对象包含了控制器转场的的相关信息，通过协议中的方法可以获取这些信息，这些信息与遵循 **UIViewControllerContextTransitioning** 协议的对象所包含的信息类似。