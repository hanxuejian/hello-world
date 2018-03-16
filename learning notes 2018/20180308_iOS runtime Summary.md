# 运行时小结
Objective-C 作为一门动态语言，不同于静态语言，其类及方法都是在运行时才确定的，所以调用类中未声明和实现的方法，编译过程并不会报错，
在运行时，在向指定的类中添加属性或方法，这种方式使得 OC 编程更加灵活和方便。

在苹果提供的 SDK 中的 usr/include/objc 路径下给出了纯 C 的接口，以实现运行时的一些操作。

## 结构体
在该接口中，定义了一些结构体来表示 OC 类或 OC 类的实例或变量等。

结构体 **`objc_class`** 描述了 OC 类，其所包含的信息如下所示，但是在 objc 2.0 中，该结构体中除 isa 的成员变量外都无法访问了，当然，isa 也是将要被废弃的。

```
struct object_class{
    Class isa OBJC_ISA_AVAILABILITY;
#if !__OBJC2__
     Class super_class                        OBJC2_UNAVAILABLE;  // 父类
     const char *name                         OBJC2_UNAVAILABLE;  // 类名
     long version                             OBJC2_UNAVAILABLE;  // 类的版本信息，默认为0
     long info                                OBJC2_UNAVAILABLE;  // 类信息，供运行时使用的一些位标识
     long instance_size                       OBJC2_UNAVAILABLE;  // 该类的实例变量大小
     struct objc_ivar_list *ivars             OBJC2_UNAVAILABLE;  // 该类的成员变量链表
     struct objc_method_list *methodLists     OBJC2_UNAVAILABLE;  // 方法定义的链表
     struct objc_cache *cache                 OBJC2_UNAVAILABLE;  // 方法缓存
     struct objc_protocol_list *protocols     OBJC2_UNAVAILABLE;  // 协议链表
#endif
}OBJC2_UNAVAILABLE;
```

由 **`typedef struct objc_class *Class;`** 可知，Class 是一个指向描述类的结构体的指针。

下面这个结构体 objc_object 描述具体类的实例对象，其包含一个 isa 成员变量，该变量指向该对象所属的类。

```
struct objc_object {
    Class isa  OBJC_ISA_AVAILABILITY;
};
```
由 **`typedef struct objc_object *id;`** 可知，id 是一个指向描述具体类实例对象结构体的指针。

由 **`typedef struct objc_selector *SEL;`** 可知，SEL 是一个指向描述方法选择器的结构体的指针。

IMP 是一个指向方法具体实现地址的指针。

```
#if !OBJC_OLD_DISPATCH_PROTOTYPES
typedef void (*IMP)(void /* id, SEL, ... */ ); 
#else
typedef id (*IMP)(id, SEL, ...); 
#endif
```

描述方法的结构体

```
struct objc_method {
    SEL method_name                                          OBJC2_UNAVAILABLE;
    char *method_types                                       OBJC2_UNAVAILABLE;
    IMP method_imp                                           OBJC2_UNAVAILABLE;
}                                                            OBJC2_UNAVAILABLE;

typedef struct objc_method *Method;
```

描述类的成员变量的结构体

```
struct objc_ivar {
    char *ivar_name                                          OBJC2_UNAVAILABLE;
    char *ivar_type                                          OBJC2_UNAVAILABLE;
    int ivar_offset                                          OBJC2_UNAVAILABLE;
#ifdef __LP64__
    int space                                                OBJC2_UNAVAILABLE;
#endif
}                                                            OBJC2_UNAVAILABLE;

typedef struct objc_ivar *Ivar;
```

描述类的分类的结构体

```
struct objc_category {
    char *category_name                                      OBJC2_UNAVAILABLE;
    char *class_name                                         OBJC2_UNAVAILABLE;
    struct objc_method_list *instance_methods                OBJC2_UNAVAILABLE;
    struct objc_method_list *class_methods                   OBJC2_UNAVAILABLE;
    struct objc_protocol_list *protocols                     OBJC2_UNAVAILABLE;
}                                                            OBJC2_UNAVAILABLE;

typedef struct objc_category *Category;
```

由 `typedef struct objc_property *objc_property_t;` 可知 `objc_property_t` 是一个指向描述类属性的结构体的指针。


由下面的定义可知，objc_object 也会用来描述类所遵循的协议。

```
#ifdef __OBJC__
@class Protocol;
#else
typedef struct objc_object Protocol;
#endif
```

描述方法的结构体

```
struct objc_method_description {
	SEL name;               //方法选择器
	char *types;            //方法返回类型及参数类型的编码字符集合
};
```

描述属性所含特性的结构体

```
typedef struct {
    const char *name;           //属性特性名称
    const char *value;          //属性特性值，通常为空
} objc_property_attribute_t;
```

## 常见函数
### 实例对象相关函数
1. 获取 OC 实例对象所属的类 

	`OBJC_EXPORT Class object_getClass(id obj) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);`

2. 设置 OC 实例对象所属的类

	`OBJC_EXPORT Class object_setClass(id obj, Class cls) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);`
    
3. 获取实例对象指定变量的值    

	```
	OBJC_EXPORT id object_getIvar(id obj, Ivar ivar) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	
	//不能用于 ARC 下，变量名由字符串指定
	OBJC_EXPORT Ivar object_getInstanceVariable(id obj, const char *name, void **outValue)
	    OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0)
	    OBJC_ARC_UNAVAILABLE;
	```

4. 设置实例对象指定变量的值

	```
	//使用已有的内存管理方式（如 strong、weak），否则默认使用 unsafe_unretained
	OBJC_EXPORT void object_setIvar(id obj, Ivar ivar, id value) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	
	//使用已有的内存管理方式（如 strong、weak），否则默认使用 strong
	OBJC_EXPORT void object_setIvarWithStrongDefault(id obj, Ivar ivar, id value) 
	    OBJC_AVAILABLE(10.12, 10.0, 10.0, 3.0);
	
	//不能用于 ARC 下，变量名由字符串指定
	//使用已有的内存管理方式（如 strong、weak），否则默认使用 unsafe_unretained
	OBJC_EXPORT Ivar object_setInstanceVariable(id obj, const char *name, void *value)
	    OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0)
	    OBJC_ARC_UNAVAILABLE;
	
	//不能用于 ARC 下，变量名由字符串指定
	//使用已有的内存管理方式（如 strong、weak），否则默认使用 strong
	OBJC_EXPORT Ivar object_setInstanceVariableWithStrongDefault(id obj, const char *name, void *value)
	    OBJC_AVAILABLE(10.12, 10.0, 10.0, 3.0)
	    OBJC_ARC_UNAVAILABLE;
	```

### 类相关函数
5. 获取指定类名的类定义

	`OBJC_EXPORT Class objc_getClass(const char *name) OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0);`

6. 获取指定个数的类定义

	```
	//buffer 为返回的类定义的指针
	//bufferCount 表示最多返回类定义的个数，传 NULL 表示都返回，但是返回的类定义所占内存不能超出 buffer 申请的内存
	//返回值表示已经注册的类定义的个数
	OBJC_EXPORT int objc_getClassList(Class *buffer, int bufferCount) 
			OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0);
	
	//例程如下
	Class *class = malloc(sizeof(Class)*10);    
	int total =  objc_getClassList(class,10);
	for(int i=0;i<10;i++){
	    char * name = object_getClassName(class++);
	    NSLog(@"%i => %s",i,name);
	}
	```

7. 获取所有注册的类定义

	```
	OBJC_EXPORT Class *objc_copyClassList(unsigned int *outCount) 
			OBJC_AVAILABLE(10.7, 3.1, 9.0, 1.0);
	```

1. 获取类的名称

	`OBJC_EXPORT const char *class_getName(Class cls) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);`

1. 获取指定类的实例对象所占内存的字节数

	`OBJC_EXPORT size_t class_getInstanceSize(Class cls) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);`

1. 获取指定类的实例对象的成员变量，包含父类中的变量

	```
	OBJC_EXPORT Ivar class_getInstanceVariable(Class cls, const char *name) 
				OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0);
	```

1. 获取指定类的实例对象的成员变量，不包含继承父类的成员变量

	```
	OBJC_EXPORT Ivar *class_copyIvarList(Class cls, unsigned int *outCount) 
				OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	
	//例程
	unsigned int total;    
	Ivar *ivarList = class_copyIvarList([instance class],&total);    
	for (int i =0; i<total; i++,ivarList++) {    
		NSString *value = object_getIvar(gl, *ivarList);
		NSLog(@"%i %s : %@",i,ivar_getName(*ivarList),value);
	}
	```

1. 获取指定类的实例方法，包含父类中的方法

	`OBJC_EXPORT Method class_getClassMethod(Class cls, SEL name) OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0);`

1. 获取指定类的类方法，包含父类中的方法

	`OBJC_EXPORT Method class_getClassMethod(Class cls, SEL name) OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0);`

1. 获取指定类的实例方法的具体实现

	```
	OBJC_EXPORT IMP class_getMethodImplementation(Class cls, SEL name) 
			OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

1. 返回指定类是否的实例方法，不包含从父类继承的方法

	```
	OBJC_EXPORT Method *class_copyMethodList(Class cls, unsigned int *outCount)
				 OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

1. 返回指定类所遵循的协议

	```
	OBJC_EXPORT Protocol * __unsafe_unretained *class_copyProtocolList(Class cls, 
						unsigned int *outCount)   OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

1. 获取指定类的指定名称的属性

	```
	OBJC_EXPORT objc_property_t class_getProperty(Class cls, const char *name)
			 OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

1. 获取指定类的属性列表

	```
	OBJC_EXPORT objc_property_t *class_copyPropertyList(Class cls, unsigned int *outCount) 							OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

	例程如下：

	```
    unsigned int outCount;
    objc_property_t *properties = class_copyPropertyList([gl class],&outCount);
    for (int i = 0;i<outCount;i++,properties++) {
        NSLog(@"%i property_name : %s , property_attr : %s",
        		i,property_getName(*properties),property_getAttributes(*properties));
        
        unsigned int n;
        objc_property_attribute_t *att = property_copyAttributeList(*properties,&n);
        for (int j=0;j<n;j++,att++){
            NSLog(@"attr_name : %s , attr_value : %s",att->name,att->value);
        }
    }    
	```

	结果如下：

	```
	TestView[31775:1321424] 0 property_name : view , property_attr : T@"GLKView",&,N
	TestView[31775:1321424] attr_name : T , attr_value : @"GLKView"
	TestView[31775:1321424] attr_name : & , attr_value : 
	TestView[31775:1321424] attr_name : N , attr_value : 
	TestView[31775:1321424] 1 property_name : context , property_attr : T@"EAGLContext",&,N,V_context
	TestView[31775:1321424] attr_name : T , attr_value : @"EAGLContext"
	TestView[31775:1321424] attr_name : & , attr_value : 
	TestView[31775:1321424] attr_name : N , attr_value : 
	TestView[31775:1321424] attr_name : V , attr_value : _context
	TestView[31775:1321424] 2 property_name : test , property_attr : T@"NSString",&,N,V_test
	TestView[31775:1321424] attr_name : T , attr_value : @"NSString"
	TestView[31775:1321424] attr_name : & , attr_value : 
	TestView[31775:1321424] attr_name : N , attr_value : 
	TestView[31775:1321424] attr_name : V , attr_value : _test
	TestView[31775:1321424] 3 property_name : hash , property_attr : TQ,R
	TestView[31775:1321424] attr_name : T , attr_value : Q
	TestView[31775:1321424] attr_name : R , attr_value : 
	TestView[31775:1321424] 4 property_name : superclass , property_attr : T#,R
	TestView[31775:1321424] attr_name : T , attr_value : #
	TestView[31775:1321424] attr_name : R , attr_value : 
	TestView[31775:1321424] 5 property_name : description , property_attr : T@"NSString",R,C
	TestView[31775:1321424] attr_name : T , attr_value : @"NSString"
	TestView[31775:1321424] attr_name : R , attr_value : 
	TestView[31775:1321424] attr_name : C , attr_value : 
	TestView[31775:1321424] 6 property_name : debugDescription , property_attr : T@"NSString",R,C
	TestView[31775:1321424] attr_name : T , attr_value : @"NSString"
	TestView[31775:1321424] attr_name : R , attr_value : 
	TestView[31775:1321424] attr_name : C , attr_value : 
	```
	属性字符编码的详细含义，参见[OC Runtime 及消息转发机制](http://blog.csdn.net/u011374318/article/details/70210196)

1. 向指定类中添加方法，可以覆盖父类中的方法，但是不能覆盖当前类中已有的方法

	```
	OBJC_EXPORT BOOL class_addMethod(Class cls, SEL name, 
				IMP imp, const char *types) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

1. 替换或添加指定类指定方法的实现

	```
	OBJC_EXPORT IMP class_replaceMethod(Class cls, SEL name, IMP imp,const char *types)
				OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

1. 向指定的类中添加成员变量，该操作只能在类注册之前有效

	```
	OBJC_EXPORT BOOL class_addIvar(Class cls, const char *name,
						 size_t size, uint8_t alignment,
						  const char *types) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

1. 向指定类中添加遵循的协议

	```
	OBJC_EXPORT BOOL class_addProtocol(Class cls, Protocol *protocol) 
				OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

1. 向指定的类中添加属性
 
	```
	OBJC_EXPORT BOOL class_addProperty(Class cls, const char *name,
	  			const objc_property_attribute_t *attributes, 
	  			unsigned int attributeCount) OBJC_AVAILABLE(10.7, 4.3, 9.0, 1.0);
	```

1. 替换指定类中的属性

	```
	OBJC_EXPORT void class_replaceProperty(Class cls, const char *name, 
			const objc_property_attribute_t *attributes, 
			unsigned int attributeCount) OBJC_AVAILABLE(10.7, 4.3, 9.0, 1.0);
	```

1. 创建指定类的实例，申请额外的内存可以用来存储类定义之外的成员变量

	```
	OBJC_EXPORT id class_createInstance(Class cls, size_t extraBytes) 
			OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0) OBJC_ARC_UNAVAILABLE;
	```

1. 创建指定类的实例，并指定实例在的内存中的地址

	```
	OBJC_EXPORT id objc_constructInstance(Class cls, void *bytes)
				 OBJC_AVAILABLE(10.6, 3.0, 9.0, 1.0) OBJC_ARC_UNAVAILABLE;
	```

1. 销毁指定的类实例对象

	```
	OBJC_EXPORT void *objc_destructInstance(id obj)
			 OBJC_AVAILABLE(10.6, 3.0, 9.0, 1.0) OBJC_ARC_UNAVAILABLE;
	```

1. 创建指定类的子类或根类

	```
	OBJC_EXPORT Class objc_allocateClassPair(Class superclass, 
								const char *name, size_t extraBytes)
								 OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

1. 注册创建并添加方法、变量、属性后的类

	`OBJC_EXPORT void objc_registerClassPair(Class cls) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);`

1. 销毁创建的类及其相关联的元类

	`OBJC_EXPORT void objc_disposeClassPair(Class cls) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);`

### 方法相关函数
1. 获取方法的选择器

	`OBJC_EXPORT SEL method_getName(Method m) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);`

2. 获取方法的实现地址

	`OBJC_EXPORT IMP method_getImplementation(Method m) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);`

3. 获取方法返回值及参数的类型编码

	`OBJC_EXPORT const char *method_getTypeEncoding(Method m) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);`

4. 获取方法的描述

	```
	OBJC_EXPORT struct objc_method_description *method_getDescription(Method m) 
						OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

	例程如下：
	
	```
    GLVC *gl = [[GLVC alloc]init];
        
    unsigned int outCount;
    
    Method *methodList = class_copyMethodList(gl.class, &outCount);
    for (int i=0;i<outCount;i++,methodList++){
        NSLog(@"%i SEL : %@ , typeEncode : %s",i,
        		NSStringFromSelector(method_getName(*methodList)),method_getTypeEncoding(*methodList));
        struct objc_method_description *des = method_getDescription(*methodList);
        NSLog(@"%i des_name : %@ , des_type : %s",i,NSStringFromSelector(des->name),des->types);
    }
	```
	
	打印结果如下：
	
	```
	TestView[32820:1401554] 0 SEL : setTest: , typeEncode : v24@0:8@16
	TestView[32820:1401554] 0 des_name : setTest: , des_type : v24@0:8@16
	TestView[32820:1401554] 1 SEL : test , typeEncode : @16@0:8
	TestView[32820:1401554] 1 des_name : test , des_type : @16@0:8
	TestView[32820:1401554] 2 SEL : click , typeEncode : v16@0:8
	TestView[32820:1401554] 2 des_name : click , des_type : v16@0:8
	TestView[32820:1401554] 3 SEL : glkView:drawInRect: , typeEncode : v56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24
	TestView[32820:1401554] 3 des_name : glkView:drawInRect: , des_type : v56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24
	TestView[32820:1401554] 4 SEL : .cxx_destruct , typeEncode : v16@0:8
	TestView[32820:1401554] 4 des_name : .cxx_destruct , des_type : v16@0:8
	TestView[32820:1401554] 5 SEL : loadView , typeEncode : v16@0:8
	TestView[32820:1401554] 5 des_name : loadView , des_type : v16@0:8
	TestView[32820:1401554] 6 SEL : init , typeEncode : @16@0:8
	TestView[32820:1401554] 6 des_name : init , des_type : @16@0:8
	TestView[32820:1401554] 7 SEL : setContext: , typeEncode : v24@0:8@16
	TestView[32820:1401554] 7 des_name : setContext: , des_type : v24@0:8@16
	TestView[32820:1401554] 8 SEL : context , typeEncode : @16@0:8
	TestView[32820:1401554] 8 des_name : context , des_type : @16@0:8
	```

5. 设置方法的实现地址

	```
	OBJC_EXPORT IMP method_setImplementation(Method m, IMP imp) 
			OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

6. 交换两个方法的实现地址

	```
	OBJC_EXPORT void method_exchangeImplementations(Method m1, Method m2)
			 OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

### 变量相关函数
1. 获取变量名称

	`OBJC_EXPORT const char *ivar_getName(Ivar v) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);`

2. 获取变量类型

	`OBJC_EXPORT const char *ivar_getTypeEncoding(Ivar v) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);`

例程如下：

```
GLVC *gl = [[GLVC alloc]init];
gl.test = @"this is a test";

unsigned int total;
Ivar *ivarList = class_copyIvarList([gl class],&total);
for (int i =0; i<total; i++,ivarList++) {
    const char * name = ivar_getName(*ivarList);
    const char * type = ivar_getTypeEncoding(*ivarList);
    NSString *value = object_getIvar(gl,*ivarList);
    
    NSLog(@"%i name : %s , type : %s , value : %@",i,name,type,value);
}
```

打印结果如下：

```
TestView[32894:1413751] 0 name : testV , type : @"NSString" , value : (null)
TestView[32894:1413751] 1 name : _context , type : @"EAGLContext" , value : (null)
TestView[32894:1413751] 2 name : _test , type : @"NSString" , value : this is a test
```

### 属性相关函数
1. 获取属性名称

	```
	OBJC_EXPORT const char *property_getName(objc_property_t property)
				 OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

2. 获取属性类型及特性的编码字符串，该字符串通常以 'T' 和属性类型开始，中间是各种特性，最后以 'V'和属性对应成员变量名称结束（如 T@"NSString",&,N,V_test）

	```
	OBJC_EXPORT const char *property_getAttributes(objc_property_t property)
				 OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

3. 获取描述属性的编码数组

	```
	OBJC_EXPORT objc_property_attribute_t *property_copyAttributeList(objc_property_t property,
		 unsigned int *outCount) OBJC_AVAILABLE(10.7, 4.3, 9.0, 1.0);
	```

### 协议相关函数
1. 获取指定名称的协议

	`OBJC_EXPORT Protocol *objc_getProtocol(const char *name)OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);`

1. 获取当前运行时中的协议列表

	```
	OBJC_EXPORT Protocol * __unsafe_unretained *objc_copyProtocolList(unsigned int *outCount) 
					OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

1. 获取指定协议的名称

	`OBJC_EXPORT const char *protocol_getName(Protocol *p) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);`

1. 返回指定协议中的方法的描述结构体

	```
	OBJC_EXPORT struct objc_method_description protocol_getMethodDescription(Protocol *p, 
							SEL aSel, BOOL isRequiredMethod, BOOL isInstanceMethod) 
							OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

1. 返回指定协议中的方法列表

	```
	OBJC_EXPORT struct objc_method_description *protocol_copyMethodDescriptionList(Protocol *p, 
						BOOL isRequiredMethod, BOOL isInstanceMethod,
   						unsigned int *outCount) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

1. 获取协议中声明的属性

	```
	OBJC_EXPORT objc_property_t protocol_getProperty(Protocol *proto, 
				const char *name, BOOL isRequiredProperty, 
				BOOL isInstanceProperty) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

1. 获取指定协议中指定是否为必需实现、是否为实例的属性列表

	```
	OBJC_EXPORT objc_property_t *protocol_copyPropertyList2(Protocol *proto, 
				unsigned int *outCount, BOOL isRequiredProperty, 
				BOOL isInstanceProperty) OBJC_AVAILABLE(10.12, 10.0, 10.0, 3.0);
	```

1. 获取指定协议中为必需实现且为实例中的属性列表，同上一个方法中后两个参数为 YES 的时候

	```
	OBJC_EXPORT objc_property_t *protocol_copyPropertyList(Protocol *proto,
			 unsigned int *outCount) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

1. 获取指定协议所遵循的协议列表

	```
	OBJC_EXPORT Protocol * __unsafe_unretained *protocol_copyProtocolList(Protocol *proto,
					unsigned int *outCount) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

1. 创建指定名称的协议

	```
	OBJC_EXPORT Protocol *objc_allocateProtocol(const char *name)
				 OBJC_AVAILABLE(10.7, 4.3, 9.0, 1.0);
	```

1. 注册一个新的协议，注册后便不可修改

	`OBJC_EXPORT void objc_registerProtocol(Protocol *proto) OBJC_AVAILABLE(10.7, 4.3, 9.0, 1.0);`

1. 向创建但未注册的协议中添加方法

	```
	OBJC_EXPORT void protocol_addMethodDescription(Protocol *proto, 
				SEL name, const char *types, BOOL isRequiredMethod,
				 BOOL isInstanceMethod) OBJC_AVAILABLE(10.7, 4.3, 9.0, 1.0);
	```

1. 向创建但未注册的协议中添加父协议，父协议必须是已经注册的

	```
	OBJC_EXPORT void protocol_addProtocol(Protocol *proto, Protocol *addition)
			 OBJC_AVAILABLE(10.7, 4.3, 9.0, 1.0);
	```

1. 向创建但未注册的协议中添加属性

	```
	OBJC_EXPORT void protocol_addProperty(Protocol *proto, const char *name, 
							const objc_property_attribute_t *attributes,
							 unsigned int attributeCount,BOOL isRequiredProperty,
							  BOOL isInstanceProperty) OBJC_AVAILABLE(10.7, 4.3, 9.0, 1.0);
	```

### 库相关函数
1. 获取加载的所有框架和库文件

	```
	OBJC_EXPORT const char **objc_copyImageNames(unsigned int *outCount)
			 OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

1. 获取指定类所属的动态库名称

	`OBJC_EXPORT const char *class_getImageName(Class cls) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);`

1. 获取指定库中的所有类名

	```
	OBJC_EXPORT const char **objc_copyClassNamesForImage(const char *image,
			 unsigned int *outCount) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);
	```

例程如下：

```
unsigned int total;
    
const char **libs = objc_copyImageNames(&total);
for(int i=0;i<3;i++,libs++){
   NSLog(@"%i %s",i,*libs);
}
    
const char *lib = class_getImageName(UIView.class);
NSLog(@"%s",lib);
    
const char **classes = objc_copyClassNamesForImage(lib, &total);
for(int i=0;i<3;i++,classes++){
    NSLog(@"%i %s",i,*classes);
}
```
打印结果如下：

```
TestView[33382:1512380] 0 /Applications/Xcode 8.0.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/lib/system/introspection/libdispatch.dylib
TestView[33382:1512380] 1 /Applications/Xcode 8.0.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/lib/system/libxpc.dylib
TestView[33382:1512380] 2 /Applications/Xcode 8.0.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/lib/system/libsystem_trace.dylib
TestView[33382:1512380] /Applications/Xcode 8.0.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/UIKit.framework/UIKit
TestView[33382:1512380] 0 _UIPreviewPresentationPlatterView
TestView[33382:1512380] 1 UIKeyboardUISettings
TestView[33382:1512380] 2 _UIPickerViewTopFrame
```

### 选择器相关函数
1. 获取指定选择器的名称

	`OBJC_EXPORT const char *sel_getName(SEL sel) OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0);`

2. 注册指定名称的选择器

	```
	//同下面的方法相同，但是在 OS X 10.0 之前，该函数只是检查选择器是否存在，如果不存在就返回 NULL
	OBJC_EXPORT SEL sel_getUid(const char *str) OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0);
	OBJC_EXPORT SEL sel_registerName(const char *str) OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0);
	```

3. 判断两个选择器是否相同，与 '==' 效果相同

	`OBJC_EXPORT BOOL sel_isEqual(SEL lhs, SEL rhs) OBJC_AVAILABLE(10.5, 2.0, 9.0, 1.0);`

### 关联相关函数

```
//设置指定对象的关联对象，value 为 nil 表示清除已存在的关联对象
OBJC_EXPORT void objc_setAssociatedObject(id object, const void *key, 
				id value, objc_AssociationPolicy policy)
    				OBJC_AVAILABLE(10.6, 3.1, 9.0, 1.0);

//获取指定对象的关联对象
OBJC_EXPORT id objc_getAssociatedObject(id object, const void *key)
    OBJC_AVAILABLE(10.6, 3.1, 9.0, 1.0);

//移除指定类的所有关联对象，不应调用该函数，而是使用 objc_setAssociatedObject 函数，
//通过设置 value 参数为 nil 来移除相应的关联对象
OBJC_EXPORT void objc_removeAssociatedObjects(id object)
    OBJC_AVAILABLE(10.6, 3.1, 9.0, 1.0);
```

objc_AssociationPolicy 的值表示关联对象的引用特性，其可选值如下：

```
typedef OBJC_ENUM(uintptr_t, objc_AssociationPolicy) {
    OBJC_ASSOCIATION_ASSIGN = 0,           //assgin
    OBJC_ASSOCIATION_RETAIN_NONATOMIC = 1, //retain nonatomic
    OBJC_ASSOCIATION_COPY_NONATOMIC = 3,   //copy nonatomic
    OBJC_ASSOCIATION_RETAIN = 01401,       //retain atomic
    OBJC_ASSOCIATION_COPY = 01403          //copy atomic
};
```

