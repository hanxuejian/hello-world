Objective-C 运行时学习
===
### 简介
Objective-C 语言会尽可能的将事情从编译及链接推迟到运行时才决定，其总是动态的决定事物。这意味着该语言不仅仅需要编译器也需要运行时系统来执行编译的代码，其对于 Objective-C 就如一种操作系统。

虽然不了解运行时系统，并不影响我们编写应用程序，但是学习该知识，我们可以知道 Objective-C 程序是如何与运行时系统进行交互的，并且在程序运行时，定义增加新类，发送消息给其他类对象，或获取类对象的信息。

### 运行时版本
运行时在不同的平台上有不同的版本，现在分为新旧两个版本，新版本是在 Objective-C 2.0 引入的，其相较于旧版本的运行时系统增加了一些新的特性，其中值得注意的是，在旧版本中，改变类中的实例变量后，需要重新编译继承该类的子类，而新版本的运行时系统则不需要重新编译，并且，新版本的运行时可以根据声明的类属性合成实例变量。

`iPhone 应用和 OS X v10.5 及其之后的64位平台上的应用程序均使用新版本的运行时，其他32位的平台使用的是旧版本的运行时。`

### 运行时交互
Objective-C 程序与运行时系统交互，通常通过三种方法：Objective-C 源码，NSObject 中定义的方法，运行时方法。

1. Objective-C 源码

	当我们在编写源码时，运行时系统自动运行，编译源码时，其从源码中提取实例变量，方法等信息生成数据结构及动态方法。其中最主要的动态方法是消息发送，该方法是源码中消息发送代码所产生。

2. NSObject 方法

	作为 Cocoa 中几乎所有类的父类 NSObject ，其所定义的方法被其他类继承，这些被继承的方法实现了一些必要的操作，被所有子类继承，但是也有些方法，并未进行任何操作，只是为了提供给子类重写。还有一些方法只是简单的向运行时系统查询信息，如 `isKindOfClass:` `isMemberOfClass:` `conformsToProtocol:`等方法，而这些方法与运行时的交互，为类对象检查自身信息提供了途径。

3. 运行时方法
	
	直接使用 `SDK` 中路径 `/usr/include/objc` 下的的数据结构及方法，使用纯 C 语言同运行时系统交互，可以进行与编译器编译 Objective-C 源码时一样的操作，并且可以开发更多开发工具，并且一些方法也是 Objective-C 中常用的。

### 运行时方法 objc_msgSend
在 Objective-C 中，消息表达式 `[receiver message]` 直到运行时，massage 才会绑定到实现方法上，该方法会转化为一个消息函数 `objc_msgSend(receiver,selector)` 这两个参数分别是消息接收对象 receiver 与 方法 message 相应的方法选择器 selector。当然，如果有参数，可以使用函数 `objc_msgSend(receiver, selector, arg1, arg2, ...)` ,该函数会找到并调用实现方法，而后将方法返回的值作为自己的返回值返回。

消息传递的关键在于编译器为每一个类和对象生成的结构，其包含两个基本要素：

* 指向父类的指针
* 消息分发表，这个表保存着方法选择器以及该选择器表示的方法的实现地址

当一个类对象创建时，分配内存并初始化变量，其第一个变量就是指向该对象的类的结构，变量名为 `isa` ,通过该变量，该对象就可以访问其所对应的类，及其继承的父类。如下图所示：

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2017/pic-20170413-01.png)

当消息发送给类对象后，objc_msgSend 根据对象的 isa 指针找到类结构，并搜索消息转发表中的 selector 方法选择器，若未找到，则继续搜索父类的转发表，直到根类 NSObject ，一旦找到相匹配的 selector ，则 objc_msgSend 将调用 selector 在表中所对应的方法，并将对象的数据结构传给该方法。

这个找寻消息的实现方法的过程是在运行时进行的，或者用面向对象编程的术语说，就是方法与消息的动态绑定。

为了提升消息发送过程的速度，运行系统会分别缓存每个类的 selector 与 方法地址的值，且包含该类继承的方法，当方法第一调用，其会加入该缓存，而消息转发时，也会先查找该缓存，时间足够长时，基本所有的消息转发均可在缓存中找到相应的实现方法，并且这个缓存会自动增加以适应不断加入的缓存数据。

当 objc_msgSend 函数找到相应方法的实现时，除了将消息中的参数传递给该方法外，还传递了另外两个隐式参数

* 接收消息的对象 receiver
* 方法的选择器 selector

之所以称其为隐式参数，是因为这两个参数并不在源代码的方法声明的参数列表中，而是编译器在编译时自己插入的，但在方法的实现代码中，还是可以用关键字 `self` 与 `_cmd` 获取对象本身及方法选择器的。

另外，若是能够获取方法的实现地址，便可以绕过消息与方法的动态绑定，可以使用 `NSObject` 中的方法 `methodForSelector` 获取 selector 所对应的方法实现地址。如下例程：

```
void (*setter)(id, SEL, BOOL);
int i;
 
setter = (void (*)(id, SEL, BOOL))[target methodForSelector:@selector(setFilled:)];
for ( i = 0 ; i < 1000 ; i++ ) {
    setter(targetList[i], @selector(setFilled:), YES);
}

```

这里需要注意的是，使用 `methodForSelector` 获取的方法需要进行类型转换，返回类型及参数均需要转换。转换时，前两个参数是必须的，也是固定的，分别为：消息接收者与方法选择器，而其后的参数的个数是任意的，这取决于你所要调用的方法，其返回类型也是一样。

这种绕过消息传送机制的做法比直接使用消息传送要节约时间，但也仅仅在一个方法不断反复调用时才有意义，如上面的例程那样，并且方法 `methodForSelector` 是运行时系统所提供的特性，而不是 Objective-C 语言本身的特性。

### 动态绑定方法与消息转发机制
从上面的叙述可知，当一个类对象接收一个消息时，他先后查询自己及父类的方法表直到根类，而如若仍然没有找到相应的方法来执行，那么程序就会崩溃报错么？其实不然，运行时系统提供了一种机制，给予了其第二次机会来处理消息，可分以下三步：

1. 使用运行时函数 `class_addMethod(Class cls, SEL name, IMP imp, const char *types)` 添加新的方法
	
	在 NSObject 类中有两个方法
		+ (BOOL)resolveClassMethod:(SEL)sel __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_2_0);
		+ (BOOL)resolveInstanceMethod:(SEL)sel __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_2_0);
	
	我们可以重写这两个方法，当重写该方法的类无法处理某个消息时，便会调用这两个方法中的一个，第一个方法是类方法未找到时的处理方法，后者是在实例方法未找到时调用。
	
	```
	+ (BOOL)resolveInstanceMethod:(SEL)sel {
	    IMP testMethod1 = [self instanceMethodForSelector:@selector(testMethod1)];
	    class_addMethod([self class] ,sel, testMethod1, "v@:");
	    return YES;
	}

	- (void)testMethod1 {
	    NSLog(@"%@",NSStringFromSelector(_cmd));
	}
	```
	动态函数 **BOOL class_addMethod(Class cls, SEL name, IMP imp, const char \*types);** 中有4个参数：                                 
		
	* cls   ，添加方法到指定的类中
	* name  ，添加的方法的名称	
	* imp   ，实现该方法的地址
	* types ，[描述方法的返回类型及参数类型的字符数组](#encode)

	可见，这种动态绑定的方法，可以推迟方法与实现代码的关联。而当该处理方法未实现或者无效时，消息转入第二步。
	
2. 将消息转发给其他类对象 
	
	使用 NSObject 中的方法 `- (id)forwardingTargetForSelector:(SEL)aSelector;`
	
	这个方法可以将消息转发给其他类对象，如果判断某对象可以响应该消息，则返回该对象，然后由该对象执行相关方法。
	
	```
	- (id)forwardingTargetForSelector:(SEL)aSelector {
	    if ([self.object respondsToSelector:aSelector]) {
	        return self.object;
	    }
	    return [super forwardingTargetForSelector:aSelector];
	}
	```
	如果该步骤仍然无法处理消息，则转入第三步
	
3. 消息转发
	
	当前步骤也是消息转发，与上一步只能转发给指定的一个对象不同，该方法可以转发给多个对象，重写 NSObject 的如下方法：
	
	
	```
	- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
	
	    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
	    if (!signature){
	    	signature = [NSMethodSignature signatureWithObjCTypes:"v@:"];
	    }
	    return signature;
	}

	- (void)forwardInvocation:(NSInvocation *)anInvocation {	    
	    if ([self.object1 respondsToSelector:anInvocation.selector]) {
	        
	        [anInvocation invokeWithTarget:self.object1];
	    }
	    if ([self.object2 respondsToSelector:anInvocation.selector]) {
	        
	        [anInvocation invokeWithTarget:self.object2];
	    }
	}
	
	```
	
	在该步骤中，运行时系统会先调用方法 `methodSignatureForSelector:` ，该方法生成一个 `NSMethodSignature` 对象，该对象包含有 `aSelector` 的返回类型及参数的字符描述数组，得到非空的 `NSMethodSignature` 对象后，使用该对象生成 `NSInvocation` 对象，这个对象封装了消息的接收者及方法信息，并传递给方法 `forwardInvocation:` ，而后根据情况选择响应消息的对象。

最终，若仍然没有类对象处理消息，那么，系统会调用 NSObject 中的方法 `- (void)doesNotRecognizeSelector:(SEL)aSelector;` 抛出错误，当然，可以重写这个方法，不抛出异常，但最后不要这样做。

### 类型编码[](id:encode)
为了支持运行时系统，编译器将方法的返回类型及参数类型编码成一个字符串并将其与方法选择器相关联，为了方便其使用，编译器提供了命令 `@encode(type)` 可以直接传入类型参数，得到编码结果，一般，能够被 `sizeof(type)` 的参数都可以作为编码的参数。

|编码后的结果|待编码的类型|
|:---:|:----:|
|c|char|
|i|int|
|s|short|
|l|long|
|q|long long|
|C|unsigned char|
|I|unsigned int|
|S|unsigned short|
|L|unsigned long|
|Q|unsigned long long|
|f|float|
|d|double|
|B|C++ bool 或 C99 _Bool|
|v|void|
|*|char *|
|@|id 或 静态类型|
|#|Class|
|:|SEL|
|[array type]|数组|
|{name=type···}|结构体|
|(name=type···)|内联体|
|b**num**|指定位数的比特位|
|^**type**|指向某个类型的指针|
|?|未知类型|

如下面几个例子

```
//数组：包含12个指向浮点类型的指针
[12^f]

//结构体
typedef struct example {
    id   anObject;
    char *aString;
    int  anInt;
} Example;

其相关的编码结果如下：
@encode(Example) 与 @encode(struct example)有相同结果 {example=@*i}

@encode(Example *) 与 @encode(struct example *)有相同结果 ^{example=@*i}

@encode(Example **) 编码结果为 ^^{example}

而对于类的编码类似于 {className=#} ，如 
@encode(NSObject) => {NSObject=#}
@encode(NSString) => {NSString=#}

```
另外，对于在协议中声明方法时，使用的关键字也有对应的编码值，尽管 @encode() 命令不会返回编码值。

|编码后的结果|待编码的关键字|
|:---:|:----:|
|r|const|
|n|in|
|N|inout|
|o|out|
|O|bycopy|
|R|byref|
|V|oneway|

### 属性类型声明
在使用运行时函数时，可以动态获取类的属性声明或修改器属性声明，这里也会如上面的类型编码一样，使用 @encode() 命令。属性特性的编码如下表：

|编码结果|属性特性含义|
|:----:|:-----:|
|R|readonly|
|C|copy|
|&|retain|
|N|nonatomic|
|G<methodName>|自定义获取属性值的方法，如 GisFirstPosition|
|S<methodName>|自定义设置属性值的方法，如 SsetPosition|
|D|@dynamic|
|W|__weak|
|P|该属性用于垃圾回收|
|t<encoding>|指定该类型使用旧版本的编码类型|

使用运行时方法获取属性特性编码的字符串有特定格式，其以大写字母 `T` 开始，其后跟随编码类型（多个类型用逗号分隔），最后以 大写字母 `V` 跟随变量名结束。如以下例子：

```
enum FooManChu { FOO, MAN, CHU };

struct YorkshireTeaStruct { int pot; char lady; };

typedef struct YorkshireTeaStruct YorkshireTeaStructType;

union MoneyUnion { float alone; double down; };
```

|属性声明|编码后得到的描述字符串|
|:----:|:----:|
|@property char charDefault;|Tc,VcharDefault|
|@property long longDefault;|Tl,VlongDefault|
|@property signed signedDefault;|Ti,VsignedDefault|
|@property unsigned unsignedDefault;|TI,VunsignedDefault|
|@property enum FooManChu enumDefault;|Ti,VenumDefault|
|@property struct YorkshireTeaStruct structDefault;|T{YorkshireTeaStruct="pot"i"lady"c},VstructDefault|
|@property YorkshireTeaStructType typedefDefault;|T{YorkshireTeaStruct="pot"i"lady"c},VtypedefDefault|
|@property union MoneyUnion unionDefault;|T(MoneyUnion="alone"f"down"d),VunionDefault|
|@property int (\*functionPointerDefault)(char \*);|T^?,VfunctionPointerDefault|
|@property int intSynthEquals;<br>In the implementation block:<br>**@synthesize intSynthEquals=_intSynthEquals;**|Ti,V_intSynthEquals|
|@property(getter=isIntReadOnlyGetter, readonly) int intReadonlyGetter;|Ti,R,GisIntReadOnlyGetter|
|@property(readwrite) int intReadwrite;|Ti,VintReadwrite|
|@property(nonatomic, readonly, copy) id idReadonlyCopyNonatomic;|T@,R,C,VidReadonlyCopyNonatomic|
|@property(nonatomic, readonly, retain) id idReadonlyRetainNonatomic;|T@,R,&,VidReadonlyRetainNonatomic|

详细列表请见官方文档[Property Attribute Description Examples](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW5)


