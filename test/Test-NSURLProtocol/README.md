## NSURLProtocol
NSURLProtocol 是一个抽象类，使用这个类可以处理网络请求，在使用时，要创建一个子类，并实现下面的方法。

`+ (BOOL)canInitWithRequest:(NSURLRequest *)request;`

这个方法的返回值确定该类是否可以处理传入的网络请求，这里，我们可以根据需要，选择出需要处理的网络请求。

`+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request;`

在这个方法中，可以对传入的请求报文 request 进行修改，比如添加一些公共的数据等。

`+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b;`

判断两个请求的相关缓存是否等同。

`- (void)startLoading;`

这个方法被调用时，NSURLProtocol 类应该开启网络请求任务。

`- (void)stopLoading;`

实现这个类来结束网络请求任务。

### 方法
要想自定义的 NSURLProtocol 子类生效，需要调用下面的方法进行注册。注册成功后，每当网络加载系统加载网络请求时，都会对所有注册的子类进行验证，当某一个子类的 `canInitWithRequest:` 方法返回 YES 后，便不会调用其他类的该方法进行判断了。

`+ (BOOL)registerClass:(Class)protocolClass;`

不需要时，还可以使用 `+ (void)unregisterClass:(Class)protocolClass;` 对相关类进行注销。

另外，还可以使用下面的方法对请求信息字段进行查询或修改。

```
+ (nullable id)propertyForKey:(NSString *)key inRequest:(NSURLRequest *)request;
+ (void)setProperty:(id)value forKey:(NSString *)key inRequest:(NSMutableURLRequest *)request;
+ (void)removePropertyForKey:(NSString *)key inRequest:(NSMutableURLRequest *)request;
```

我们不应创建 NSURLProtocol 子类的实例对象，只要进行注册即可，具体的创建由系统进行。在重写的子类方法中，可以使用其属性 client 调用 **NSURLProtocolClient** 协议中的方法进行诸如重定向、创建或使用缓存、加载数据、结束请求等操作。

### 例程
除了对指定的请求进行处理外，还可以截断相关请求。例如，实现 UIWebView 的 HTML 页面与类之间的数据交互。

先自定义一个 NSURLProtocol 的子类 **InputURLProtocol** 类，如下：

```
@implementation InputURLProtocol

+ (void)load
{
    [NSURLProtocol registerClass:self];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([request.URL.scheme isEqualToString:@"customprotocol"]) {
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    NSURL *url = self.request.URL;
        
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示" message:[url relativeString] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
    
    //响应请求，不然会话持续到超时才会释放
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] init];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocolDidFinishLoading:self];
}
- (void)stopLoading
{
    
}
@end
```
在这个类中，我们只处理网络协议名为 **customprotocol** 的请求，这是一个自定义的网络协议，不能在公网上传播。

iOS 系统中支持的网络协议头有：`ftp://` `http://` `https://` `file:///` `data://`

然后，编写一个 HTML 页面，如下：

```
<!DOCTYPE html>
<html>

    <head>
        
        <meta charset="UTF-8">
            
        <script type='text/javascript'>
            
            this.saveValue = function() {
                
                var content = document.getElementById("content").value;

                handle = new XMLHttpRequest();
                handle.open('POST', 'customprotocol://' + content, false);
                
                handle.setRequestHeader('value', content);
                return handle.send(null);
            };
            
        </script>

    </head>
    
    <body>
    
        <a>this is a test page.</a>
    
        <br>
    
        <input type="text" size="30" id="content">
        
        <input type="submit" value="提示" onclick="saveValue()">
        
        
    </body>

</html>
```
网页中只有一个输入框和一个提示按钮，当点击按钮时，会发送一个 customprotocol 网络请求，这个请求会被 InputURLProtocol 类截获，此时便可以获取网页传递而来的数据了。
当然这是一个十分简单的例子，不过，如果与后台的交互过程中，涉及到网页数据的处理和修改及保存，可以参考这种方式。

另外，值得注意的是自定义的网络协议名称是不区分大小写的，所以在判断过程中要忽略其大小写。而且，协议名不宜有分隔符号，如使用 `custom_protocol` ，系统便会自动添加 **applewebdata://** 协议头（奇怪的是 `custom-protocol` 却正常）。

[参见源码](https://github.com/hanxuejian/hello-world/tree/master/test/Test-NSURLProtocol)