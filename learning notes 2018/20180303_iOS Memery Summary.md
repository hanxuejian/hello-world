# iOS 内存管理
## 简介
内存主要分为 5 个部分：栈区、堆区、BSS 段、数据段、代码段。

**栈区：**存放局部变量的内存区域，当可执行程序在执行过程中创建局部变量时，系统会自动将变量压入栈区存储，当程序执行结束后，变量被弹出栈区，内存释放。该栈区的空间由系统控制分配，并且分配时，按内存地址从高到低进行分配。

**堆区：**程序执行过程中可动态分配的内存区域，该分配按内存地址从低到高进行，并且该内存的分配由程序发起，那么其释放也由程序负责。

**BSS 段：**Block Started by Symbol ，存放程序中未初始化的全局变量和静态变量的内存区域，该内存区域在程序执行前会被自动清空为 0 。

**数据段：**存放已经初始化的全局变量、静态变量以及字符串常量。

**代码段：**存放可执行程序。

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2018/pic-20180303-01.png)

## 管理方式
在 Objective-C 语言中，类实例对象的内存空间是动态分配的，所以 OC 的内存管理工作很重要，其管理方式可以分为下面三种：

* MRC（Manual Reference Counting），手动引用计数，即需要开发人员自己负责内存的申请和释放。
* ARC（Automatic Reference Counting），自动引用计数，由系统自动管理内存，于 iOS 4.1 之后推出。
* Garbage Collection ，垃圾回收机制，只用于 Mac OS X 系统。

对于每一个 OC 对象，都有一个存储空间（8 Bytes）来保存该对象的引用计数，对象的引用数值表示有多少个变量在引用该对象，那么就表示该对象所占据的堆区内存正在使用中，不能被释放。而若该值为 0 ，则表示该对象已经不需要了，那么该对象就会被销毁，其所占内存就会被系统收回堆区，以备他用。

一般 OC 类都是 NSObject 的子类，那么其都可以调用下面的方法对引用计数进行管理。

```
- (instancetype)retain OBJC_ARC_UNAVAILABLE;
- (oneway void)release OBJC_ARC_UNAVAILABLE;
- (instancetype)autorelease OBJC_ARC_UNAVAILABLE;
- (NSUInteger)retainCount OBJC_ARC_UNAVAILABLE;
```
调用 retain 方法，对象的引用计数值增 1 。

调用 release 方法，对象的引用计数值减 1 。

调用 autorelease 方法，将对象添加到位于栈顶的自动释放池中，该方法并不会改变对象的引用计数值。

调用 retainCount 方法返回对象的当前引用计数的值。

上述方法只能在 MRC 内存管理模式下调用，如果整个工程默认是 ARC 的内存管理模式，而有少数文件需要自己管理内存，那么可以在工程文件下，Build Phases 界面中的 Compile Sources 资源中指定文件的编译标识为 `-fno-objc-arc`，反之，设置为 `-f-objc-arc` 表示该文件使用 ARC 模式管理内存。

## 自动释放池
不管 MRC 还是 ARC 内存管理模式，都支持自动释放池，池中的对象会在池被销毁时，执行一次引用计数值减 1 的操作。

对于占用内存大并且循环次数多的操作，可以将该操作放在自己创建的自动释放池中，每一次释放池销毁，池中的对象也随之销毁，这样来减小内存的压力。

在 iOS 5 之前，使用 NSAutoreleasePool 类来创建缓存池，如下：

```
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];

//codes

[pool release];//Mac 下使用 [pool drain];
```

在 iOS 5 之后，使用关键字 autoreleasepool ，如下：

```
@autoreleasepool {
	//codes
}
```

> OC 类变量的使用实质是指针的使用，如果类的实例对象已经释放，仍然使用该变量对对象进行操作，那么程序便会报错，此时的对象即为**僵尸对象**，指针即为**野指针**，因为其指向了不可用的内存空间。

## 属性声明
在创建一个类时，需要使用 property 关键字声明类的属性，并且每一个属性都要有与之对应的类成员变量。

在 iOS 4.4 之前，有三种方式对属性进行声明。

1. 使用 property 关键字声明属性，定义一个成员变量，而后自己编写属性的读写方法，将属性同成员变量对应起来。

	```
	@interface Test : NSObject{
	    int _age;
	}
	@property(assign) int age;
	@end
	
	@implementation Test
	- (int)age {
	    return _age;
	}
	- (void)setAge:(int)age {
	    _age = age;
	}
	@end
	```

2. 声明一个属性后，使用 synthesize 关键字自动创建与属性同名的成员变量，且自动创建读写方法使两者对应。

	```
	@interface Test : NSObject
	@property(assign) int age;//对应成员变量 age
	@end
	
	@implementation Test
	@synthesize age;
	@end
	```

3. 声明一个属性后，使用 synthesize 关键字指定与属性关联的成员变量，那么将自动创建该成员变量（如果没有创建）并且生成读写方法。

	```
	@interface Test : NSObject
	@property(assign) int age;//对应成员变量 userAge
	@end
	
	@implementation Test
	@synthesize age = userAge;
	@end
	```

在 iOS 4.4 之后，单单使用 property 关键字声明属性，就会自动创建一个以下划线开始的属性名称的成员变量以及读写方法。

```
@interface Test : NSObject
@property(assign) int age;//对应成员变量 _age
@end
	
@implementation Test
@end
```

在声明属性时，其有默认的特性，也可以自己设置其特性。

|特性|可选值|含义|
|:---:|:----:|:---:|
|原子特性|atomic、nonatomic|属性是否是线程安全的，默认为 atomic 即属性读写时会被加锁以确保线程安全|
|读写特性|readwrite、readonly|是可读写的，还是只读的，默认为 readwrite ，可以生成读写方法，而设置为后者则只能创建读取方法|
|引用特性|assign/weak、retain/strong/copy|是否修改引用计数的值，默认值为 assign 表示不修改引用计数的值，weak 表示弱引用，但是只能修饰对象属性；后面三个选项值都只能修饰对象属性，且表示对象的引用计数增 1 ，但是 copy 表示复制一份所提供的对象|
