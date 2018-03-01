# JavaScriptCore
从 iOS 7 开始，苹果引入了 JavaScriptCore 框架，用于原生代码同 JavaScript 脚本之间的数据交互，方便了原生和网页功能的混合开发。

要实现 JavaScript 中的方法与原生方法之间的相互调用，关键在于 JSContext 类以及 JSExport 协议。

## JSContext
JSContext 是 JavaScript 的执行环境，所有的 JavaScript 函数执行都发生在该上下文中，所有的 JavaScript 值都与之相关联。

该类的关键是下面四个类方法，这几个类方法的调用都应该是由 JavaScript 的函数调用引起的。

* `+ (JSContext *)currentContext;` 获取当前执行上下文，如果没有，返回 nil 。
* `+ (JSValue *)currentCallee;` 获取当前执行的 JavaScript 函数。
* `+ (JSValue *)currentThis;` 获取当前执行方法的 this 
* `+ (NSArray *)currentArguments;` 获取传递给当前回调方法的参数

## JSValue
JSValue 描述的是 JavaScript 中的值，这个值始终关联着一个 JSContext 对象，或者说这个值总是来源于某一个上下文。
OC 方法与 JavaScript 函数间的交互涉及到变量类型的转换，JSValue 便是用来处理这种转换的，下表是它们变量间的对应关系：

| Objective-C type  |   JavaScript type|
|:----:|:----:|
nil|undefined
NSNull|null
NSString|string
NSNumber|number, boolean
NSDictionary|Object object
NSArray|Array object
NSDate|Date object
NSBlock|Function object 
id|Wrapper object
Class|Constructor object

在该类中除了类型转换的方法外，还提供了三个方法用于实现 JavaScript 函数的调用。

* `- (JSValue *)callWithArguments:(NSArray *)arguments;` 

	将 JSValue 本身当作一个 JavaScript 函数，并执行该 JavaScript 函数。

* `- (JSValue *)constructWithArguments:(NSArray *)arguments;`
	
	调用 JavaScript 中的构造器方法，创建一个新的变量并返回。

* `- (JSValue *)invokeMethod:(NSString *)method withArguments:(NSArray *)arguments;`
	
	访问该变量的名为 method 的成员变量，并且将该成员变量当作一个函数进行调用，且返回该函数的调用结果。

## JSExport
当获取了 JSContext 对象后，可以直接绑定变量或 block 代码块到该上下文中，这样，在 JavaScript 中就可以使用这些绑定的变量或者调用这些代码块。但是，这样做并不符合面向对象的思想，并且代码也不好维护。所以，该框架给出了 JSExport 协议，这个协议并没有什么需要实现的方法，而是我们自定义一个继承该协议的子协议。

在自定义的子协议中，声明需要的属性和方法。而后，创建一个遵循该子协议的类，那么将该自定义类的实例绑定到 JSContext 上下文中时，框架便会将子协议中的变量和方法导入到 JavaScript 中，但是该类中其他不在子协议中的属性和方法并不能被 JavaScript 访问。

## 例程
自定义一个 CustomJSExport 协议，和一个遵循该协议的 CustomSave 类，如下：

```
@protocol CustomJSExport <JSExport>

@property (strong, nonatomic) NSString *name;

- (void)saveValue;

@end

@interface CustomSave : NSObject  <CustomJSExport>

@property (strong, nonatomic) NSString *name;

@end
```

实现协议中的方法如下：

```
- (void)saveValue {
    
    NSLog(@"currentArguments %@",[JSContext currentArguments]);
    
    JSValue *currentThis = [JSContext currentThis];
    NSLog(@"currentThis %@",currentThis);
    
    JSValue *currentCallee = [JSContext currentCallee];
    NSLog(@"currentCallee %@",currentCallee);
    
    [[JSContext currentContext][@"clear"] callWithArguments:nil];
}
```

创建一个包含 UIWebView 的控制器，并实现 UIWebViewDelegate 中的如下方法：

```
#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView {

	 //这个属性路径：UIWebBrowserView => WebView => WebFrame => JSContext
    JSContext *context = [webView valueForKeyPath: @"documentView.webView.mainFrame.javaScriptContext"];    
    
    context[@"saveValue"] = ^(){
        
        NSLog(@"currentArguments %@",[JSContext currentArguments]);

        JSContext *currentContext = [JSContext currentContext];

       [currentContext[@"show"] callWithArguments:nil];

    };
    
    
    CustomSave *save = [[CustomSave alloc]init];
    save.name = @"Martin";
    
    context[@"CustomSave"] = save;
    
    context[@"age"] = @"20";
    
}
```

启动应用时，让 UIWebView 加载下面的 HTML 文件：

```
<!DOCTYPE html>
<html>

    <head>
        
        <meta charset="UTF-8">

    </head>
    
    <body>
    
        <a>this is a test page.</a>
    
        <br>
    
        <input type="text" size="30" id="content">
        
        <input type="submit" value="show" onclick="saveValue('test1','test2')">
            
        <input type="submit" value="clear" onclick="CustomSave.saveValue('hello','world')">        
        
    </body>
    
    <script type='text/javascript'>
        
        function show() {
            var content = "His name is " + CustomSave.name + " and age is " + this.age;            
            document.getElementById('content').value = content;            
        }
    
        function clear() {            
            document.getElementById('content').value = '';            
        }
    </script>
    
</html>
```
在上面的 HTML 文件中的 CustomSave 变量就是在 webViewDidFinishLoad: 方法中创建的 CustomSave 类实例。并且，对于 JavaScript 中调用 OC 中的方法，其参数并没有严格的限制。

这是一个简单的例子，用于说明原生代码同 JavaScript 代码间的交互，感兴趣的可以[下载工程](https://github.com/hanxuejian/hello-world/tree/master/test/Test-JavaScriptCore)，自己尝试一下。
