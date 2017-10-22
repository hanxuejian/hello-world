# 导航控制器小结
## UINavigationController
导航控制器 UINavigationController 是 UIViewController 的子类，但它是用来管理一系列 UIViewController 实例对象的类。在使用方法 **`- (instancetype)initWithRootViewController:(UIViewController *)rootViewController;`** 初始化时，需要提供一个控制器对象作为根控制器，相应的这个控制器的视图就是导航控制器的根视图。

导航控制器在管理视图控制器时，类似于栈，先压入栈中的控制器后弹出栈，而栈顶的控制器便是当前设备显示的控制器，这里注意模态显示的视图控制器并不在栈中。下面是常见的压入及弹出视图控制器的方法：

```
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (nullable UIViewController *)popViewControllerAnimated:(BOOL)animated;
- (nullable NSArray<__kindof UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (nullable NSArray<__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated;
```

除了上面的方法外，可以直接对栈进行操作，使用方法 **`- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated`** 可以直接改变栈中的控制器，提供的数组中，第一个元素是根控制器，最后一个元素是要显示的控制器，如果在使用该方法时，animation 是 YES ，那么其动画效果分为下面3种：

	* 如果要显示的控制器本就是原来栈中的元素，且位于栈顶，那么没有动画效果
	* 如果要显示的控制器本就是原来栈中的元素，但不位于栈顶，那么显示弹出的动画效果
	* 如果要显示的控制器不在原来栈中，，那么显示推入的动画效果

## UINavigationBar
**`@property(nonatomic,readonly) UINavigationBar *navigationBar;`**

对于导航控制器而言，导航栏尤显重要，大致分为两种类型，UIBarStyleDefault 白底黑字、UIBarStyleBlack 黑底白字。它有点类似于导航控制器，只不过其管理的是一系列 UINavigationItem 实例对象。但是在导航控制器中，它是由导航控制器管理，我们可以通过 UINavigationBar 的一些方法和属性改变其一些外观，但是对于它的大小、透明度及视图层级结构不应修改。

## UINavigationItem
导航栏中管理的 UINavigationItem 实例对象，其实对应着导航控制器中每个视图控制器的 UINavigationItem 实例对象。

```
@interface UIViewController (UINavigationControllerItem)
@property(nonatomic,readonly,strong) UINavigationItem *navigationItem;
@property(nullable, nonatomic,readonly,strong) UINavigationController *navigationController;
@end
```
从这个分类中可以看出，当视图控制器被推入栈中后，那么控制器的属性 **navigationController** 便指向了导航控制器。而属性 **navigationItem** 则指向了当前导航栏显示的内容。

UINavigationItem 对象中包含了标题、标题视图、返回按钮等内容，除此之外，还可以通过下面的方法添加其他按钮。

```
@property(nullable,nonatomic,copy) NSArray<UIBarButtonItem *> *leftBarButtonItems NS_AVAILABLE_IOS(5_0);
@property(nullable,nonatomic,copy) NSArray<UIBarButtonItem *> *rightBarButtonItems NS_AVAILABLE_IOS(5_0);
- (void)setLeftBarButtonItems:(nullable NSArray<UIBarButtonItem *> *)items animated:(BOOL)animated NS_AVAILABLE_IOS(5_0);
- (void)setRightBarButtonItems:(nullable NSArray<UIBarButtonItem *> *)items animated:(BOOL)animated NS_AVAILABLE_IOS(5_0);

@property(nonatomic) BOOL leftItemsSupplementBackButton NS_AVAILABLE_IOS(5_0) __TVOS_PROHIBITED;

@property(nullable, nonatomic,strong) UIBarButtonItem *leftBarButtonItem;
@property(nullable, nonatomic,strong) UIBarButtonItem *rightBarButtonItem;
- (void)setLeftBarButtonItem:(nullable UIBarButtonItem *)item animated:(BOOL)animated;
- (void)setRightBarButtonItem:(nullable UIBarButtonItem *)item animated:(BOOL)animated;
```
在使用上面的方法添加左侧按钮或者右侧按钮时，不应混用，在添加左侧按钮时，若不想返回按钮被替代，可将 **leftItemsSupplementBackButton** 属性设置为 YES。

## UIToolbar
**`@property(null_resettable,nonatomic,readonly) UIToolbar *toolbar NS_AVAILABLE_IOS(3_0) __TVOS_PROHIBITED;`**

toolbar 是导航栏中的一个属性，其指向导航控制器管理的一个工具栏，但是这个工具栏中的具体内容，则是由导航控制器中的每个视图控制器决定的。

```
@interface UIViewController (UINavigationControllerContextualToolbarItems)

@property (nullable, nonatomic, strong) NSArray<__kindof UIBarButtonItem *> *toolbarItems NS_AVAILABLE_IOS(3_0) __TVOS_PROHIBITED;
- (void)setToolbarItems:(nullable NSArray<UIBarButtonItem *> *)toolbarItems animated:(BOOL)animated NS_AVAILABLE_IOS(3_0) __TVOS_PROHIBITED;

@end
```
由上可知，通过 UIViewController 分类中的方法可以设置导航控制器工具栏中的具体按钮。这个按钮是 UIBarButtonItem 对象实例，而不是 UIButton。并且，UIBarButtonItem 同 UITabBarItem 一样都是 UIBarItem 的子类，UIBarItem 的子类是 NSObject，即它们都不是 UIView 的子类。