# Objective-C 编程中的概念

## Cocoa 与 Cocoa Touch 中的基本概念
学习 Objective-C 编程时，了解其核心概念、设计模式及 Cocoa 与 Cocoa Touch 的机制，有助于我们应用程序的设计与开发。

## 类簇
类簇，有一个公有的抽象类，以及一些私有的子类的集合。这种基于抽象工程设计模式的类的组织方法，简化了面向对象框架的对外架构，同时，并不会降低函数的丰富性。

例如 Cocoa Touch 中的 NSNumber 类就是一个抽象类，他可以用来保存 char ,int ,float ,double 等数据类型。这样，就可以使用同一个类对基本数据类型进行保存或读取等操作，而不是用许多单独的类。但是，注意 NSNumber 这个抽象类并不会声明实例变量去保存各个数据，保存数据是由具体的子类实现的。而为了进一步方便使用，子类通常设计为私有的，至于如何获取到正确地子类实例对象来处理数据，就是抽象超类的工作了。例如 NSNumber 就是实现了类方法以供使用者获取到相应地私有类的实例，尽管这个实例被赋值给 NSNumber 类型的变量。

```
NSNumber *aChar = [NSNumber numberWithChar:’a’];
NSNumber *anInt = [NSNumber numberWithInt:1];
NSNumber *aFloat = [NSNumber numberWithFloat:1.0];
NSNumber *aDouble = [NSNumber numberWithDouble:1.0];
```

上面的 NSNumber 类簇只有一个超类，而通常情况下，类簇拥有多个抽象公有类作为接口。如下：

|类簇|超类|
|----|----|
|NSData|NSData 、NSMutableData|
|NSArray|NSArray 、NSMutableArray|
|NSDictionary|NSDictionary 、NSMutableDictionary|
|NSString|NSString 、NSMutableString|

其他诸如此类情况的类簇也存在，而以上类簇很好地说明了类簇的协作方式。两个超类，一个类定义的实例内容不可修改，一个却是可以修改的。

### 在类簇中创建子类
类簇结构的易用性及扩展性使其得到普遍使用，使用少数公有类与多个私有类使得框架变得易学易用，但是类簇中的子类创建比普通的类的子类创建更复杂些。

如果类簇并没有提供程序所用到的功能，那么创建子类便是必要的了。例如，创建一个数组对象，而其存储方式是基于文件的，不像 NSArray 类簇是基于内存的，那么，此时就必须创建子类了，因为类的底层存储机制已经改变了。

另一种方法，在类簇中定义一个子类，在这个子类中声明一个类簇中的类的实例对象，如同截断了发送给实例对象的消息，进行必要的操作后，再将消息发送给实例对象。例如，定义一个 MyData 类继承于 NSData 类，类中包含一个 NSData 类簇中的 NSData 类实例对象 embeddedData，那么这个 MyData 类可以进行各种操作，而后将结果存储在 embeddedData 实例对象中。

所以，若改变了类的存储方式，就需要在类簇中创建子类，否则，新建一个组合类更简便一点。

若要创建的子类属于一个类簇，需要满足以下几点：

* 是类簇的抽象超类的子类
* 分配其自己的存储空间
* 重写其父类的所有初始化方法
* 重写其父类的原生方法

类簇的抽象超类仅仅作为类簇层级中的展示层，其并没有声明实例变量，所以当子类继承了超类的接口方法并重写时，必须声明自己需要的实例变量，当然，重要的是要重写直接访问这些变量的方法。这些需要重写的方法都叫做原生方法。

原生方法构成了接口的基础，在原生方法上还会衍生出一些源方法。如 NSArray 中，方法 lastObjcet 与 containsObject: 两个源方法可能是调用 count 与 objectAtIndex: 两个方法实现的，所以可知前面两个方法的实现是基于后两个原生方法的，这也说明了创建子类时，重写原生方法的必要性，这样可以使源方法正常执行。

## 类工厂方法
类工厂方法由类实现，他获取类实例对象的方法将分配内存与初始化一步解决，所以使用起来很简便，但是类方法返回的类实例并不属于接收者，并且接收者也不负责该实例的内存释放。

类工厂方法的声明形式诸如：+(type name)className...  ，如 NSDate 与 NSData 的类工厂方法

```
+ (id)dateWithTimeIntervalSinceNow:(NSTimeInterval)secs;
+ (id)dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)secs;
+ (id)dateWithTimeIntervalSince1970:(NSTimeInterval)secs;

+ (id)dataWithContentsOfFile:(NSString *)path;
+ (id)dataWithContentsOfURL:(NSURL *)url;
+ (id)dataWithContentsOfMappedFile:(NSString *)path;
```

当然，类工厂方法不仅仅是简便，其在将分配内存与初始化合并到一起之外，还可以根据不同的类改变初始化方法。例如，当从一个由 NSData ,NSDate ,NSString 等多个类对象编码得到的文件中初始化一个集合类对象时，类工厂方法在分配内存之前必须先读取文件，确定共有多少对象及分别是什么对象。

另外，类工厂方法也可以用于保证某个特殊的类只有一个单独的类实例对象，如下代码：

```
static AccountManager *DefaultManager = nil;
 
+ (AccountManager *)defaultManager {
    if (!DefaultManager) DefaultManager = [[self allocWithZone:NULL] init];
    return DefaultManager;
}
```

## 代理及数据源
在程序中，当某个对象发生某一事件后，由其他对象代其执行一些操作，那么这个其他对象就是代理，或称为代理对象，其所属类为代理类。代理机制给了类对象在其他类发生某事，或状态改变时，进行相应操作或改变的机会。与代理相关的概念是协议，协议分为正式协议与非正式协议，由一个或多个方法声明组成。数据源与代理类似，只是数据源控制的是数据。

* 非正式协议，就是在代理类中声明一个 NSObject 的分类，所有 NSObject 的子类都可以实现该分类中的方法，所以要遵循该非正式协议，代理类只要实现自己感兴趣的方法即可
* 正式协议，使用 @protocol 进行声明，并且分为可选方法 @optional 与 必须实现的方法 @required ，当代理类遵循该协议时，必须实现 @required 标识下声明的方法

在调用代理方法之前，最好先调用 respondsToSelector: 方法确定代理方法确实实现了，当然，这种预防措施只是对非正式协议及正式协议中的 @optional 修饰的方法必要。

## 自查性
对于面向对象语言及环境来说，自查是很强大的特性之一。在 Objective-C 中，自查性意味着可以在运行时获取对象继承层级，遵循的协议，能够响应的消息等信息。在编程中使用这个特性，可以减少诸如消息错误分发，类对象错误等同等类似错误，从而提高了程序的效率和健壮性。

类 NSObject 中声明了许多自查性的方法，如 isKindOfClass: , isMemberOfClass: , respondsToSelector: , conformsToProtocol: 等。

## 对象的分配
在分配对象时，首先从虚拟内存中分配足够的内存用于存储类对象，这个步骤需要计算类对象的实例变量的个数及大小。

除了分配内存外，分配步骤还完成了以下重要的步骤：

* 将对象的引用计数的值设为1
* 初始化对象的实例变量 isa ，使其指向由类定义所编译得到的用于运行时的类
* 将其他实例变量置为0，或与0等同的 NULL ，nil ，或0.0

分配结束后，得到的对象并不能使用，还需要进行初始化，设置一些其独有的特性才可使用。

## 对象的初始化
在使用对象之前，需要初始化对象的实例变量，设置变量的值，加载全局资源或者额外文件资源等。如果默认的全部置为0的初始化满足需要，也可不进行自定义的初始化。而若不实现初始化方法，Cocoa 框架会调用其父类的初始化方法。

初始化方法的方法名通常以 init 开始，实现初始化方法应遵循以下原则：

* 首先调用父类的初始化方法
* 检查父类初始化方法返回的对象，如果为 nil ，结束方法
* 初始化对象的变量，必要时使用 retain 或 copy 方式
* 初始化结束后，返回 self ，除非需要返回替代的对象或初始化出错

一个类可以有多个初始化方法，而创建子类时，应重写父类的初始化方法，使得无论使用哪个初始化方法，均能正确初始化类对象。

## 模型视图控制器
MVC（Model View Controller）是一种存在很久的设计模式，他更注重在应用的整体架构中的位置，并且融合了多种设计模式。在面向对象编程中使用 MVC 设计模式，提高了对象的复用率，增强了程序的扩展性。

MVC设计模式主要考虑三种对象：模型对象、视图对象和控制器对象。在设计程序时，我们将自定义的类分成前面所说的三种角色，并协调他们互相通信。

* 模型对象，封装数据及对数据的逻辑处理
* 视图对象，为用户展示数据，其随数据变化而变化
* 控制器对象，作为模型对象与视图对象交互的协调者

MVC 中的这三种角色，可以进行组合，形成不同的角色以关注不同的任务。如模型控制器，模型对象与控制器对象相组合，主要关注模型数据的各种操作并且主要与视图对象通信；视图控制器则由视图对象与控制器对象组成，主要负责视图的显示与模型的通信。

### Cocoa 中的控制器种类
在 Cocoa 中，控制器分为两种，一种中间控制器，一种协调控制器。

* 中间控制器

	中间控制器类继承 NSController 类，用于 Cocoa 中的绑定技术，协调数据在视图对象与模型对象之间的流转。但是，在 iOS 中并不支持这种类及绑定技术。
	
	通常，中间控制器类已经在IB库中定义好了，我们只需将需要的类其拖拽到工程中。然后，建立控制器属性与视图对象的属性的关联关系，再将控制器属性绑定到相应地模型对象的属性上。这样，当视图上的数据改变了，数据便会通过中间控制器自动保存到模型对象中，相反，当模型对象中的数据变动了，视图中显示的数据也会相应地改变。

* 协调控制器

	协调控制器，例如 NSWindowController 、 NSDocumentController 或 NSObject 的子类，可以协调应用的全部或部分功能，提供以下服务：
	
	* 响应代理消息、监听通知
	* 响应用户或系统动作消息
	* 管理所拥有的类对象的生命周期
	* 建立对象间的联系，执行其他任务
	
	协调控制器通常作为 nib 文件中对象的拥有者，这些对象包括了中间控制器、窗口对象、视图对象等，协调控制器负责管理他们。NSObject 的子类作为控制器时，融合了协调控制器及中间控制器的功能，为了促使数据传递，该类控制器为目标设置动作，使用代理，监听通知等模式。所以，这些控制器类的代码大多与应用的相关性较高，复用率较低。

### MVC 是多个设计模式的组合
MVC 有多个基础的设计模式组合而成，这些基础的设计模式分工协作，构成了 MVC 的特点。但是，传统的 MVC 设计模式与现在的 Cocoa MVC 设计模式也是有区别的，其不同在于控制器与视图在应用中扮演的角色不同。

传统的 MVC 模式由 Composite 、Strategy 、Observer 组成

* Composite ，视图集合
* Strategy ，用于处理视图的策略
* Observer ，监听者，通常是视图监听着数据模型

传统的 MVC 通常是用户查看操作视图，触发事件，然后控制器修改数据或刷新视图，或者当视图监听到数据发生改变，进行视图的刷新，如下图：

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2017/pic-20170502-01.png)

对于现行的 Cocoa MVC 模式，其与传统的 MVC 设计模式很相似，实际上，其完全可以基于上图的的结构进行设计，而采用绑定技术，视图监听数据模型的变化更加直接简便。但是，视图显示数据，数据模型封装数据，为了提高效率，会经常性的复用他们，所以在设计时，将两者分开，不让其直接发生交互，更有利于他们的复用。两者的区别可参见下图：

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2017/pic-20170502-02.png)

可见，控制器新增了 Mediator 模式与原有的 Strategy 模式共同协调数据在视图与数据模型之间传递，数据模型则通过控制器与视图传递数据，而视图则融合了由 target-action 机制实现的 Command 模式。

```
target-action 机制使得视图对象与用户的输入及选择能够进行交互，这个可以在协调控制器及中间控制器中实现，但是两者存在区别。
在将 nib 中的视图对象的动作连接到控制器中的方法时，协调控制器的方法选择器必须是确定的（变量个数及类型固定），
而绑定中间控制器的方法的参数的种类及个数可以是任意的。另外，前者可以看做代理能够在响应链中被检索，而后者不行。
```

因为一些现实因素，上图中的模式需要进行一些修改，尤其是在 Mediator 设计模式中。如中间控制器采用了该种模式，也提供了一些很好的特性。

在拥有良好 Cocoa MVC 设计的应用中，协调控制器经常含有中间控制器（从 nib 文件中解档而来），他们之间的关系如下图：

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2017/pic-20170502-03.png)

### MVC 应用的设计要点
* 能够使用 NSController 的子类作为中间控制类便没有必要使用 NSObject 的子类作为控制器
* 为提高类对象复用率，应避免让一个类对象承担 MVC 的多个角色
* 好的 MVC 应用设计应以类对象高复用率为目标
* 避免让视图对象之间监听数据模型的状态
* 尽量减少应用中类与类之间的依赖
* 若 Cocoa 中提供了解决问题的 MVC 结构，直接使用该架构

### Cocoa 中基于 MVC 的技术
在 Cocoa 中，有许多技术与架构是基于 MVC 设计模式的，所以在设计自己的应用时，采用 MVC 模式，有利于使用 Cocoa 中的各种机制及架构。

* Document architecture ，这个架构中，主要是 NSDocumentController 、NSWindowController 、NSDocument 类
* Bindings ，MVC 是 Cocoa 中绑定技术的核心，使用 NSController 的一些子类可以直接建立视图对象与模型对象的连接
* Application scriptability ，脚本命令通常是发送给模型对象或控制器对象，所以遵循 MVC 设计模式是必要的
* Core Data ，Core Data 框架管理并保存对象，其是绑定技术的应用，所以 MVC 模式是该框架的关键
* Undo ，在该框架中，模型对象担当关键角色，其 redo 及 undo 的操作，视图及控制器也会参与其中

## 对象模型
了解对象模型及键值编码（KVC ，Key Value Coding），对于使用 Cocoa bindings 和 Core Data 技术很有用处。在 Core Data 框架中，需要使用一种方法描述模型对象，使得该对象独立于视图与控制器，这种设计方式能够提高复用率。于是，Core Data 便引入了数据库中的**实体-关系模型**技术。这种技术可以方便的存取对象，而数据源可以是数据库、文件、网络服务器或者其他存储方式。所以，这种不依赖数据存储形式的方式可以很好地用于表示各种对象，及其之间的关系。

在**实体-关系模型**中，存储数据的对象叫做**实体（entity）**，组成实体的各个部分叫做**属性（attribute）**，实体与另一个实体间的关系叫做**关系（relationship）**，使用这三个概念可以表示任何复杂的对象，对 MVC 设计很有用。

* Entities ，实体就是模型对象，在 MVC 设计模式中，他封装特定的数据并提供一些方法
* Attributes ，属性描述了对象所包含的数据结构，其可以包含如 integer 、float 、double 的纯量，或者在 Cocoa 中的类，如 NSNumber 、NSData
* Relationships ，在对象中的属性并不一定都是 Attribute ，一些属性是其他类对象，那么就由 relationship 来表示两者间的关系

为了使模型、视图、控制器彼此相互独立，访问模型属性时，应独立于模型的实现，于是引入键-值的概念。

* Keys ，使用键指定模型的一个属性，使用该键获取相应地值
* Values ，值得类型与实体的属性的类型一致并且是 Objective-C 对象
* Key Paths ，键路径是由点与键相间组成的字符串，可以用来贯穿对象的属性，第一个键决定访问的属性，第二个键决定访问的属性的属性，以此类推

## 对象的可变性
在 Cocoa 中，出于某些考虑，将对象分为可变的与不可变的。如下面的可变类型：

```
NSMutableArray
NSMutableDictionary
NSMutableSet
NSMutableIndexSet
NSMutableCharacterSet
NSMutableData
NSMutableString
NSMutableAttributedString
NSMutableURLRequest
```
在编程过程中，可依据以下几点进行选择：

* 当创建的变量内容需要逐渐且频繁修改时，使用可变变量
* 诸如赋值等操作，应使用新的不可变变量替代原不可变得变量
* 根据返回的变量类型决定使用何种变量
* 若不确定，应使用不可变的变量

## 出口
**出口（Outlets）**是表示对象的属性是连接到其他对象的，而这个对象通常是由 IB 解档而来。使用 IBOutlet 来使 IB 识别其是一个出口属性，使用 weak 来防止强引用循环。

```
@interface AppController : NSObject
@property (weak) IBOutlet NSArray *keywords;
```

## 监察者模式
**监察者模式（Receptionist Pattern）**完成了事件的重定向，即当某件事发生在一个执行上下文时，转而由另一个执行上下文进行处理。这个设计模式融合了命令行（Command），消息（Memo）及代理（Proxy）等模式，事件由一个对象接收，但由另一个对象处理。

KVO 就是这种设计模式的一种实践。在 KVO 模式中，让监察者对象监察某一个对象的状态，调用方法 **addObserver:forKeyPath:options:** ，当该对象的状态发生变化，则监察者对象会执行固定的方法 **observeValueForKeyPath:ofObject:change:context:** ，所以监察者对象都要实现该方法，以便当监控的对象发生变化时，进行相应的处理。

```
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context;

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context;
```

## 目标-处理
代理、绑定、通知等技术对于程序中对象间的通讯很有用处，但是他们并不适用于所有情况。对于与用户交互的控件，接收硬件设备因用户操作而产生的事件，而后转换为相应的指令，但是这个事件仅仅给出了用户的动作，如点击鼠标或按钮，而不能提供更多信息来表明用户的意图。所以，在事件转换为指令的过程中，需要一种机制来表示用户的目的，这种机制就是**目标-处理（target-action）**。

* Target ，目标是动作处理消息的接收者，可以是任意类，通常接收控件发送来的消息
* Action ，处理动作是控件发送给目标的消息，从目标的角度看，就是目标为响应消息而实现的方法

## 免桥接
在 Core Foundation 框架与 Foundation 之间，一些变量类型可以相互转换，这种能力就叫做**免桥接（toll-free bridging）**。

如下面的代码，除了变量，内存的管理方法也可以混用

```
NSLocale *gbNSLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
CFLocaleRef gbCFLocale = (CFLocaleRef) gbNSLocale;
CFStringRef cfIdentifier = CFLocaleGetIdentifier (gbCFLocale);
NSLog(@"cfIdentifier: %@", (NSString *)cfIdentifier);
// logs: "cfIdentifier: en_GB"
CFRelease((CFLocaleRef) gbNSLocale);
//
CFLocaleRef myCFLocale = CFLocaleCopyCurrent();
NSLocale * myNSLocale = (NSLocale *) myCFLocale;
[myNSLocale autorelease];
NSString *nsIdentifier = [myNSLocale localeIdentifier];
CFShow((CFStringRef) [@"nsIdentifier: " stringByAppendingString:nsIdentifier]);
// logs identifier for current locale
```

但是，也不是所有的变量都是免桥接的，如下表中的变量：

|Foundation|Core Foundation|
|:----:|:-----:|
|NSRunLoop|CFRunLoopRef|
|NSBundle|CFBundleRef|
|NSDateFormatter|CFDateFormatterRef|