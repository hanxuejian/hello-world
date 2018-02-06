# MVVM 在 iOS 中的应用
MVVM（Model View ViewModel）是基于 MVC（Model View Controller）和 MVP（Model View Presenter）发展起来的一种新的软件设计框架，并且其包含有 WPF 的特性。

> WPF（Windows Presentation Foundation）是微软在 .NET Framework 3.0 开始推出的基于 Windows 的用户界面框架。

随着客户需求的日益繁杂，以及越来越重要的用户体验，都促使着视图设计工作与业务处理工作的分离。当两者分离后，视图的变化不再影响数据模型，而数据模型的变化也不影响视图，只要两者暴露出来的接口能够相互对应。在 ViewModel 中，根据两者对应的接口，将视图和数据相互绑定，以达到视图和数据的同步变化。

### MVC
在 iOS 应用开发中，常用的框架设计模式为 MVC 模式（参见下图），控制器负责协调数据模型与视图之间的交互，除此之外，控制器还需要处理如场景转换、内存警告、键盘弹出等系统事件以及其他用户自定义的事件，所有的这些都放在控制器中，如 UITableview 的代理通常是控制器，而其中的 UITableviewCell 一般也设置控制器作为其代理，这些都造成了控制器中的代码臃肿，不利于程序的维护和扩展。

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2018/pic-20180205-01.png)

### MVVM
MVVM 框架的关键在于将视图和数据模型之间的交互从其他事物剥离出来，单独作为一个模块。在 iOS 中，即将有关视图的变换从控制器中分离出来，这样，不仅避免了控制器代码量的过度膨胀，而且利于视图逻辑的修改。另外，可以预见的是，这种将视图与数据模型的绑定、变更操作统一到 ViewModel 中的设计方式，可以提高视图和数据模型的复用率。

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2018/pic-20180205-02.png)

### MVVM 实例
这里给出一个 MVVM 架构设计的实例，目录结构如下图所示：

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2018/pic-20180206-01.png)

在这个例子中，自定义了一个 UIView 的子视图 PersonInfoView 用来保存并显示人员信息，与该视图相关的操作都封装在了 ViewModel 类中，其中包含数据的保存和读取。而这种方式，给控制器 ViewController 带来的影响是非常明显的，如下，其代码十分精简。

```
#import "ViewController.h"
#import "ViewModel.h"

@interface ViewController ()

@property (strong, nonatomic) ViewModel *viewModel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.viewModel = [[ViewModel alloc]init];
    [self.view addSubview:self.viewModel.personView];
}

@end
```

数据模型在 Model 文件夹下，自定义视图在 View 文件夹下，视图模型在 ViewModel 文件夹下，合理的项目结构有利于项目的理解和维护。

需要注意的是，这只是一个简单的例子，使用 MVVM 架构并不比 MVC 架构方便多少，在实际工程应用中，需要根据实际情况来选择合适的架构。

该例子的效果图如下，感兴趣的可以[参考源码](https://github.com/hanxuejian/hello-world/tree/master/test/Test-MVVM)。

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2018/pic-20180206-02.png)

##### 参考：

[http://blog.devtang.com/2015/11/02/mvc-and-mvvm/](http://blog.devtang.com/2015/11/02/mvc-and-mvvm/)

[http://blog.csdn.net/u013406800/article/details/53410766](http://blog.csdn.net/u013406800/article/details/53410766)