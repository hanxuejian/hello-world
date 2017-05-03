# Objective-C 编程中的概念

## Cocoa 与 Cocoa Touch 中的基本概念
学习 Objective-C 编程时，了解其核心概念、设计模式及 Cocoa 与 Cocoa Touch 的机制，有助于我们应用程序的设计与开发。

## 类簇
类簇，有一个公有的抽象类，以及一些私有的子类。这种基于抽象工程设计模式的类的组织方法，简化了面向对象框架的对外架构，同时，并不会降低函数的丰富性。

例如 Cocoa Touch 中的 NSNumber 类就是一个抽象类，他可以用来保存 char int float double 等数据类型。这样，就可以就可以将基本数据类型用同一个类进行保存，读取等操作，而不是用许多单独的类。但是，注意 NSNumber 这个抽象类并不会声明实例变量去保存各个数据，这个动作是由具体的子类实现的。而为了更一步方便使用，子类通常设计为私有的，至于如何获取到正确地子类实例对象来处理数据，就是抽象超类的工作了。例如 NSNumber 就是实现了类方法以供使用者获取到相应地私有类的实例，尽管这个实例被赋值给 NSNumber 类变量。

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

若要创建得子类属于一个类簇，需要满足以下几点：

* 是类簇的抽象超类的子类
* 分配其自己的存储空间
* 重写其父类的所有初始化方法
* 重写其父类的原生方法

类簇的抽象超类仅仅作为类簇层级中的展示层，其并没有声明实例变量，所以当子类继承了超类的接口方法并重写时，必须声明自己需要的实例变量，当然，重要的是要重写直接访问这些变量的方法。这些需要重写的方法都叫做原生方法。

原生方法构成了接口的基础，在原生方法上还会衍生出一些源方法。如 NSArray 中，方法 lastObjcet 与 containsObject: 两个源方法可能是调用 count 与 objectAtIndex: 两个方法实现的，所以可知前面两个方法的实现是基于后两个原生方法的，这也说明了创建子类时，重写原生方法的必要性，这样可以使源方法正常执行。

## 类工厂方法
类工厂方法由类实现，他将分配内存与初始化一步解决，所以使用起来很简便，但是类方法返回的类实例并不属于接收者，并且接收者也不负责该实例的内存释放。

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
在程序中，当某个对象发生某一事件后，由其他对象代其执行一些操作，那么这个其他对象就是代理，或称为代理对象，其所属类为代理类。代理机制给了类对象在其他类发生某事，或状态改变时，进行相应操作或改变的机会。与代理相关的概念是协议，协议分为正式协议与非正式协议，由一个或多个方法声明组成。

* 非正式协议，就是在代理类中声明一个 NSObject 的分类，所有 NSObject 的子类都可以实现该分类中的方法，所以这个代理类只要实现自己感兴趣的方法即可
* 正式协议，使用关键字 protocol 进行声明，并且分为可选方法 optional 与 必须实现的方法 required ，当代理类遵循该协议时，必须实现 required 标识下声明的方法


