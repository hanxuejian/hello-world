# AFNetworking 框架小结
AFNetworking 是一款功能丰富，简单易用的网络框架。整个框架可以分为 4 个部分：请求报文构造器和响应报文解析器、会话管理器、网络环境管理器、安全选项。

> 该框架在 3.0 版本之后，取消了对 NSURLConnectionOperation 的支持。

## AFURLRequestSerialization
### 请求报文构造器
对于遵循 HTTP 协议的请求报文而言，其分为请求头和请求体。在网络交互的过程中，传递给服务器的参数可以放在请求头中的请求链接中，也可以放在请求体中。在该框架中的 **AFURLRequestSerialization.h** 文件中，声明了 3 个类来帮助我们构造需要的请求报文。

* AFHTTPRequestSerializer
* AFJSONRequestSerializer
* AFPropertyListRequestSerializer

这三个类都可以构造请求报文，但是 AFHTTPRequestSerializer 是其他两个类的父类，定义了一些基本属性和方法，并且遵循 **AFURLRequestSerialization** 协议。三个构造器类都对该协议中的方法进行了实现，并且在构造请求报文时，会用到一个遵循了 **AFMultipartFormData** 协议的类来构造请求体内容，这个协议是构造请求报文的关键。

该文件中声明了两个很方便的函数：

```
FOUNDATION_EXPORT NSString * AFPercentEscapedStringFromString(NSString *string);

FOUNDATION_EXPORT NSString * AFQueryStringFromParameters(NSDictionary *parameters);
```
AFPercentEscapedStringFromString 函数用来对传入的字符串进行百分比符合转译，因为在网络交互过程中并不能识别请求链接中的中文及其他特殊字符，所以在构造请求报文时，需要调用该函数对请求链接及其参数进行转译。

AFQueryStringFromParameters 函数用来获取待传输的参数，这些参数用 **&** 符号分隔，构成一个字符串。该函数的实现是调用了下面的函数：

```
FOUNDATION_EXPORT NSArray * AFQueryStringPairsFromDictionary(NSDictionary *dictionary);
FOUNDATION_EXPORT NSArray * AFQueryStringPairsFromKeyAndValue(NSString *key, id value);
```
在 AFQueryStringPairsFromKeyAndValue 函数中，将传递的参数构造为一个包含一个或多个 **AFQueryStringPair** 类实例对象的数组。

AFQueryStringPair 类包含两个属性，field 和 value ，相当于用户传入的参数键值对。而 AFQueryStringFromParameters 最终返回的字符串也是由该类的 URLEncodedStringValue 方法的返回值拼接而成。

### AFHTTPRequestSerializer
作为请求报文的构造器，其定义了一些基本属性，如缓存策略、超时时间、请求用途、蜂窝网络访问权限等，并且这些属性都注册了 KVO 监听，被监听的属性可以调用 AFHTTPRequestSerializerObservedKeyPaths 函数获取。当被监听的属性值发生变化时，便会将该属性加入集合 mutableObservedChangedKeyPaths 中。

AFHTTPRequestSerializer 类扩展中声明了下面几个属性：

```
//保存发生变化的类属性
@property (readwrite, nonatomic, strong) NSMutableSet *mutableObservedChangedKeyPaths;

//保存添加的头信息
@property (readwrite, nonatomic, strong) NSMutableDictionary *mutableHTTPRequestHeaders;

//并行队列，所有对 mutableHTTPRequestHeaders 的操作都放在该队列中
@property (readwrite, nonatomic, strong) dispatch_queue_t requestHeaderModificationQueue;

//请求参数的处理方式，默认 AFHTTPRequestQueryStringDefaultStyle ，即调用 AFQueryStringFromParameters 函数生成参数字符串
@property (readwrite, nonatomic, assign) AFHTTPRequestQueryStringSerializationStyle queryStringSerializationStyle;

//自定义请求参数的处理方式
@property (readwrite, nonatomic, copy) AFQueryStringSerializationBlock queryStringSerialization;

//queryStringSerialization 所属类型的定义，该 block 由用户提供，自定义处理参数的方式，然后拼接到请求链接尾部或放在请求体中
typedef NSString * (^AFQueryStringSerializationBlock)(NSURLRequest *request, id parameters, NSError *__autoreleasing *error);
```

对于传递的参数放在请求链接中，还是请求体中，与下面的集合相关，其中的元素有 GET 、HEAD 、DELETE 三个，如果构造请求报文时，指定的请求方式不是其中之一，那么，参数字符串会放在请求报文的请求体中。
```
@property (nonatomic, strong) NSSet <NSString *> *HTTPMethodsEncodingParametersInURI;
```

在 AFHTTPRequestSerializer 类中，提供了一个 **serializer** 类方法，用来创建构造器实例，在初始化方法中，默认编码方法为 NSUTF8StringEncoding ，初始化了变量，创建了处理请求头信息的并行队列（命名为 `requestHeaderModificationQueue`），并且设置了 **Accept-Language** 和 **User-Agent** 两个请求头信息。另外，使用 KVO 对一些属性添加了监听。

该类的实例方法：

```
//添加头部信息
- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(NSString *)field;

//从头部信息中获取指定键的值
- (nullable NSString *)valueForHTTPHeaderField:(NSString *)field;

//设置用户及密码信息，username 与 password 用分号连接，进行 base64 编码后，在拼接到 Basic 后，最后与 Authorization 构成键值对，放在头部信息中
- (void)setAuthorizationHeaderFieldWithUsername:(NSString *)username
                                       password:(NSString *)password;

//从头部信息中移除 Authorization 键及其对应的值
- (void)clearAuthorizationHeader;
```
上述的方法都是对属性 mutableHTTPRequestHeaders 的操作，并且操作都是在名为 `requestHeaderModificationQueue` 的队列 **requestHeaderModificationQueue** 中进行的。

下面的方法设置了请求参数的处理方式，或设置自定义的处理 block 代码。

```
//调用该方法时，会自动将自定义的处理代码 queryStringSerialization 置为 nil
- (void)setQueryStringSerializationWithStyle:(AFHTTPRequestQueryStringSerializationStyle)style;

- (void)setQueryStringSerializationWithBlock:(nullable NSString * (^)(NSURLRequest *request, id parameters, NSError * __autoreleasing *error))block;
```

在 iOS 系统中，描述请求报文的是 NSURLRequest 或 NSMutableURLRequest 类，所以创建并设置好请求报文构造器后，便可以调用相关的实例方法获取 NSURLRequest 类实例对象了。

1. 创建请求体不含表单数据的请求报文

	```
	- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
	                                 URLString:(NSString *)URLString
	                                parameters:(nullable id)parameters
	                                     error:(NSError * _Nullable __autoreleasing *)error;
	```
	
	* method 请求方式，可以是 GET POST HEAD DELETE 中的一种，如果是 GET HEAD DELETE 中的一种，那么请求参数会拼接在请求链接之后，否则则放置在请求体中。
	* URLString 请求链接，用来创建 NSURL 实例对象，进而创建 NSMutableURLRequest 实例对象。
	* parameters 请求参数
	* error 保存创建过程中产生的报错信息

	在该方法中，先创建 NSMutableURLRequest 对象实例，而后将构造器 mutableObservedChangedKeyPaths 属性中的监听到发生改变的值重新赋给 NSMutableURLRequest 实例，然后调用 AFURLRequestSerialization 协议中的方法来对 NSMutableURLRequest 实例对象进行其他的处理。
	
	```
	- (nullable NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(nullable id)parameters
                                        error:(NSError * _Nullable __autoreleasing *)error NS_SWIFT_NOTHROW;
	```
	
	* request 请求报文构造器传递而来的实例
	* parameters 用户提供的参数
	* error 保存错误信息的指针

	在该方法中，首先会获取构造器中保存的头部信息，即 mutableHTTPRequestHeaders 属性中的值，所以对于具有相同头信息的报文请求，可以使用同一个构造器创建。
	
	接着，处理用户提供的参数，如果提供了自定义的处理 block ，那么便由用户对参数的格式进行处理，得到处理后的字符串；否则使用默认的处理方式，即使用 **&** 符号将参数相拼接。
	
	最后，如果请求的方式在 HTTPMethodsEncodingParametersInURI 集合中，那么便将参数字符串拼接到请求链接后；否则，就将参数字符串放在请求体中并将头信息中的 **Content-Type** 默认为 **application/x-www-form-urlencoded**。
	
	参见下面的源码：
	
	```
	- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error
	{
	    NSParameterAssert(request);
	
	    NSMutableURLRequest *mutableRequest = [request mutableCopy];
	
	    [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
	        if (![request valueForHTTPHeaderField:field]) {
	            [mutableRequest setValue:value forHTTPHeaderField:field];
	        }
	    }];
	
	    NSString *query = nil;
	    if (parameters) {
	        if (self.queryStringSerialization) {
	            NSError *serializationError;
	            query = self.queryStringSerialization(request, parameters, &serializationError);
	
	            if (serializationError) {
	                if (error) {
	                    *error = serializationError;
	                }
	
	                return nil;
	            }
	        } else {
	            switch (self.queryStringSerializationStyle) {
	                case AFHTTPRequestQueryStringDefaultStyle:
	                    query = AFQueryStringFromParameters(parameters);
	                    break;
	            }
	        }
	    }
	
	    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
	        if (query && query.length > 0) {
	            mutableRequest.URL = [NSURL URLWithString:[[mutableRequest.URL absoluteString] stringByAppendingFormat:mutableRequest.URL.query ? @"&%@" : @"?%@", query]];
	        }
	    } else {
	        // #2864: an empty string is a valid x-www-form-urlencoded payload
	        if (!query) {
	            query = @"";
	        }
	        if (![mutableRequest valueForHTTPHeaderField:@"Content-Type"]) {
	            [mutableRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	        }
	        [mutableRequest setHTTPBody:[query dataUsingEncoding:self.stringEncoding]];
	    }
	
	    return mutableRequest;
	}
	```

2. 创建包含 `multipart/form-data` 结构请求体数据的请求报文

	```
	- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
	                                              URLString:(NSString *)URLString
	                                             parameters:(nullable NSDictionary <NSString *, id> *)parameters
	                              constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
	                                                  error:(NSError * _Nullable __autoreleasing *)error;
	```
	
	* method 请求方法，不能是 GET HEAD 或 nil
	* URLString 请求链接
	* parameters 请求参数
	* block 添加请求体数据的代码块，由用户使用块提供的 formData 变量调用 [AFMultipartFormData](#AFMultipartFormData) 协议中的方法提供数据
	* error 保存创建过程中产生的错误信息

	在该方法中，会先调用上面介绍的方法生成一个 NSMutableURLRequest 实例对象，但是在调用时，并不会将请求参数传递过去，因为这里的请求参数会最终放在请求体中。
	
	```
	NSMutableURLRequest *mutableRequest = [self requestWithMethod:method URLString:URLString parameters:nil error:error];
	```
	
	然后使用得到的 mutableRequest 创建一个遵循 AFMultipartFormData 协议的 AFStreamingMultipartFormData 实例对象。
	
	```
	__block AFStreamingMultipartFormData *formData = [[AFStreamingMultipartFormData alloc] initWithURLRequest:mutableRequest stringEncoding:NSUTF8StringEncoding];
	```
	
	使用 formData 对象，调用相应的方法，可以将请求参数放到请求体中，或使用代码块由用户将文件数据放置到请求体中。
	
	最后，设置 **Content-Type** 和 **Content-Length** 头信息。
	
	参考下面的源代码：
	
	```
	- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                              URLString:(NSString *)URLString
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                                                  error:(NSError *__autoreleasing *)error
	{
	    NSParameterAssert(method);
	    NSParameterAssert(![method isEqualToString:@"GET"] && ![method isEqualToString:@"HEAD"]);
	
	    NSMutableURLRequest *mutableRequest = [self requestWithMethod:method URLString:URLString parameters:nil error:error];
	
	    __block AFStreamingMultipartFormData *formData = [[AFStreamingMultipartFormData alloc] initWithURLRequest:mutableRequest stringEncoding:NSUTF8StringEncoding];
	
	    if (parameters) {
	        for (AFQueryStringPair *pair in AFQueryStringPairsFromDictionary(parameters)) {
	            NSData *data = nil;
	            if ([pair.value isKindOfClass:[NSData class]]) {
	                data = pair.value;
	            } else if ([pair.value isEqual:[NSNull null]]) {
	                data = [NSData data];
	            } else {
	                data = [[pair.value description] dataUsingEncoding:self.stringEncoding];
	            }
	
	            if (data) {
	                [formData appendPartWithFormData:data name:[pair.field description]];
	            }
	        }
	    }
	
	    if (block) {
	        block(formData);
	    }
	
	    return [formData requestByFinalizingMultipartFormData];
	}	
	```
	
3. 将输入流中的数据写入指定的文件中	
	
	```
	- (NSMutableURLRequest *)requestWithMultipartFormRequest:(NSURLRequest *)request
                             writingStreamContentsToFile:(NSURL *)fileURL
                                       completionHandler:(nullable void (^)(NSError * _Nullable error))handler;
	```
	
	* request 其 HTTPBodyStream 属性值不能为 nil
	* fileURL 指定写入文件的文件地址
	* handler 内容写入结束后的处理回调

	该方法中，先获取 request 中的输入流，而后用文件地址创建一个输出流，将两个流加入到当前运行循环中，而后打开。每当输入流由数据可读取并且输出流有空间可写入时，便对数据进行操作，最终数据处理完毕，关闭流，然后异步调用回调处理，最后返回 HTTPBodyStream 置为 nil 的 request 副本。
	
### AFStreamingMultipartFormData
AFStreamingMultipartFormData 遵循 AFMultipartFormData 协议，用来向报文体插入数据。其类扩展中声明了下面几个属性：

```
@property (readwrite, nonatomic, copy) NSMutableURLRequest *request;
@property (readwrite, nonatomic, assign) NSStringEncoding stringEncoding;
@property (readwrite, nonatomic, copy) NSString *boundary;
@property (readwrite, nonatomic, strong) AFMultipartBodyStream *bodyStream;
```

* request 请求报文 NSMutableURLRequest 类实例
* stringEncoding 编码格式
* boundary 分隔字符串，用来分隔报文体中不同的数据块
* bodyStream 自定义输入流，用来读取数据到报文体中

在 AFStreamingMultipartFormData 的初始化方法中，会初始化上述的属性。

```
- (instancetype)initWithURLRequest:(NSMutableURLRequest *)urlRequest
                    stringEncoding:(NSStringEncoding)encoding;
```

该类的关键是实现了 AFMultipartFormData 协议中的方法，使用户可以提供自己的数据到报文体中。

#### AFMultipartFormData <a name="AFMultipartFormData"></a>
下面两个方法类似，都是将指定的文件数据加入到报文体中，但是第一个方法会使用文件地址 fileURL 最后部分作为 fileName ，并且根据其后缀名生成相应的 MIME 类型。

##### 添加文件数据

```
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                        error:(NSError * _Nullable __autoreleasing *)error;

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                     fileName:(NSString *)fileName
                     mimeType:(NSString *)mimeType
                        error:(NSError * _Nullable __autoreleasing *)error;
```

* fileURL 文件路径
* name 与数据相关联的名称，用来区分不同的数据
* fileName 为数据提供的文件名
* mimeType 指定数据的 MIME 类型
* error 保存错误信息
* 如果添加数据成功，返回 YES ，否则返回 NO

参考上面两个方法的部分源码，如下，可知数据信息被封装到了 **[AFHTTPBodyPart](#AFHTTPBodyPart)** 类中，并添加到了自定义的输入流中。

```
NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:error];
if (!fileAttributes) {
    return NO;
}

NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
[mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
[mutableHeaders setValue:mimeType forKey:@"Content-Type"];

AFHTTPBodyPart *bodyPart = [[AFHTTPBodyPart alloc] init];
bodyPart.stringEncoding = self.stringEncoding;
bodyPart.headers = mutableHeaders;
bodyPart.boundary = self.boundary;
bodyPart.body = fileURL;
bodyPart.bodyContentLength = [fileAttributes[NSFileSize] unsignedLongLongValue];
[self.bodyStream appendHTTPBodyPart:bodyPart];
```

参见下面的源码可知，如果根据后缀名获取相关联的 MIME 类型失败时，则默认 MIME 类型为 **application/octet-stream** 。

```
static inline NSString * AFContentTypeForPathExtension(NSString *extension) {
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    } else {
        return contentType;
    }
}
```

##### 添加输入流数据
除了添加文件数据，还可以添加输入流。相较于上面的方法，需要提供输入流参数以及输入的数据字节数参数。并且，最终数据信息也封装为了一个 AFHTTPBodyPart 实例对象，然后添加到了自定义流中。

```
- (void)appendPartWithInputStream:(NSInputStream *)inputStream
                             name:(NSString *)name
                         fileName:(NSString *)fileName
                           length:(int64_t)length
                         mimeType:(NSString *)mimeType
{
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);

    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];

    AFHTTPBodyPart *bodyPart = [[AFHTTPBodyPart alloc] init];
    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = mutableHeaders;
    bodyPart.boundary = self.boundary;
    bodyPart.body = inputStream;

    bodyPart.bodyContentLength = (unsigned long long)length;

    [self.bodyStream appendHTTPBodyPart:bodyPart];
}
```

##### 添加二进制数据
下面两个方法类似，但是第二个方法不需要 fileName 和 mimeType 参数。

```
- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType;

- (void)appendPartWithFormData:(NSData *)data
                          name:(NSString *)name;
```

并且两者都会调用下面的方法，封装数据信息。

```
- (void)appendPartWithHeaders:(NSDictionary *)headers
                         body:(NSData *)body
{
    NSParameterAssert(body);

    AFHTTPBodyPart *bodyPart = [[AFHTTPBodyPart alloc] init];
    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = headers;
    bodyPart.boundary = self.boundary;
    bodyPart.bodyContentLength = [body length];
    bodyPart.body = body;

    [self.bodyStream appendHTTPBodyPart:bodyPart];
}
```

##### 设置数据包的大小以及读取数据的间隔时间

```
- (void)throttleBandwidthWithPacketSize:(NSUInteger)numberOfBytes
                                  delay:(NSTimeInterval)delay
{
    self.bodyStream.numberOfBytesInPacket = numberOfBytes;
    self.bodyStream.delay = delay;
}
```

##### 数据报文信息封装完毕
当所有的数据都组织到了报文体中后，调用下面的方法，该方法中将自定义输入流赋给 NSMutableURLRequest 的 **HTTPBodyStream** 属性。并且，设置报文的头部信息 **Content-Type** 和 **Content-Length** 。

```
- (NSMutableURLRequest *)requestByFinalizingMultipartFormData {
    if ([self.bodyStream isEmpty]) {
        return self.request;
    }

    [self.bodyStream setInitialAndFinalBoundaries];
    [self.request setHTTPBodyStream:self.bodyStream];

    [self.request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary] forHTTPHeaderField:@"Content-Type"];
    [self.request setValue:[NSString stringWithFormat:@"%llu", [self.bodyStream contentLength]] forHTTPHeaderField:@"Content-Length"];

    return self.request;
}
```

### AFHTTPBodyPart <a name = "AFHTTPBodyPart" ></a>
从 AFMultipartFormData 协议中诸多添加数据的方法中可知，其数据信息只是封装成了 AFHTTPBodyPart 实例对象，并保存在自定义流 **[AFMultipartBodyStream](#AFMultipartBodyStream)** 中。

AFHTTPBodyPart 类提供了下面几个属性，在封装数据信息时，应对它们进行初始化。

```
//编码格式
@property (nonatomic, assign) NSStringEncoding stringEncoding;

//头部信息，通常是 Content-Disposition 和 Content-Type
@property (nonatomic, strong) NSDictionary *headers;

//数据边界分隔字符串
@property (nonatomic, copy) NSString *boundary;

//数据体，可以是二进制数据、输入流、文件地址等
@property (nonatomic, strong) id body;

//数据体的字节数
@property (nonatomic, assign) unsigned long long bodyContentLength;

//数据体是否有首边界，即是否是第一个数据体
@property (nonatomic, assign) BOOL hasInitialBoundary;

//数据体是否有尾边界，即是否是最后一个数据体
@property (nonatomic, assign) BOOL hasFinalBoundary;

//用数据体 body 构造该输入流，将在数据写入报文体时使用
@property (nonatomic, strong) NSInputStream *inputStream;

//是否有可读数据
@property (readonly, nonatomic, assign, getter = hasBytesAvailable) BOOL bytesAvailable;

//写入报文体中的数据的字节数，包含前边界字符串、头部信息、数据体、后边界字符串
@property (readonly, nonatomic, assign) unsigned long long contentLength;
```

除了上述属性，AFHTTPBodyPart 类还定义了三个关键的成员变量，用于将数据写入到报文中。

* **`NSInputStream *_inputStream;`** 该变量同属性 inputStream 相对应
* **`unsigned long long _phaseReadOffset;`** 用来记录每个数据读取阶段读取的数据的偏移量
* **`AFHTTPBodyPartReadPhase _phase;`** 表示读取数据的 4 个阶段，可选值如下

	```
	typedef enum {
	    AFEncapsulationBoundaryPhase = 1, //数据体前边界值读取阶段
	    AFHeaderPhase                = 2, //数据体头部信息读取阶段
	    AFBodyPhase                  = 3, //数据体读取阶段
	    AFFinalBoundaryPhase         = 4, //数据体后边界值读取阶段
	} AFHTTPBodyPartReadPhase;
	```

该类提供了下面的方法对读取阶段进行修改，参见下面的源码可知，进入数据体读取阶段时，需要把自定义流加入主线程的运行循环中，并开启流，而离开此阶段时要关闭流（奇怪的是此处没有将流移除运行循环）。并且，每一次改变读取数据的阶段，都会将偏移量置为 0 。在该类初始化时，便调用了该方法，则 **`_phase`** 的初始值为 **AFEncapsulationBoundaryPhase** 表示前边界读取阶段。

```
- (BOOL)transitionToNextPhase {
    if (![[NSThread currentThread] isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self transitionToNextPhase];
        });
        return YES;
    }

    switch (_phase) {
        case AFEncapsulationBoundaryPhase:
            _phase = AFHeaderPhase;
            break;
        case AFHeaderPhase:
            [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            [self.inputStream open];
            _phase = AFBodyPhase;
            break;
        case AFBodyPhase:
            [self.inputStream close];
            _phase = AFFinalBoundaryPhase;
            break;
        case AFFinalBoundaryPhase:
        default:
            _phase = AFEncapsulationBoundaryPhase;
            break;
    }
    _phaseReadOffset = 0;

    return YES;
}
```

<a name="read_maxLength" ></a>
下面的方法为读取数据的关键方法，其根据 `_phase` 的值来判断读取数据的阶段，进行不同的读取操作。

* buffer 读取的数据将保存在该缓存中
* length 最大可读取的数据字节数
* 返回实际读取的字节数

```
- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)length
{
	//已经读取的字节数
    NSInteger totalNumberOfBytesRead = 0;

	//前边界读取
	//如果数据体是第一个数据体，那么则插入首分隔字符串，否则，就插入中间分隔字符串，后者比前者多了一个回车换行符 \r\n
    if (_phase == AFEncapsulationBoundaryPhase) {
        NSData *encapsulationBoundaryData = [([self hasInitialBoundary] ? AFMultipartFormInitialBoundary(self.boundary) : AFMultipartFormEncapsulationBoundary(self.boundary)) dataUsingEncoding:self.stringEncoding];
        totalNumberOfBytesRead += [self readData:encapsulationBoundaryData intoBuffer:&buffer[totalNumberOfBytesRead] maxLength:(length - (NSUInteger)totalNumberOfBytesRead)];
    }

	//头部信息读取
    if (_phase == AFHeaderPhase) {
        NSData *headersData = [[self stringForHeaders] dataUsingEncoding:self.stringEncoding];
        totalNumberOfBytesRead += [self readData:headersData intoBuffer:&buffer[totalNumberOfBytesRead] maxLength:(length - (NSUInteger)totalNumberOfBytesRead)];
    }

	//数据体读取
	//调用输入流进行数据读取，如果读到了流的末尾，那么进入下一个读取阶段
    if (_phase == AFBodyPhase) {
        NSInteger numberOfBytesRead = 0;

        numberOfBytesRead = [self.inputStream read:&buffer[totalNumberOfBytesRead] maxLength:(length - (NSUInteger)totalNumberOfBytesRead)];
        if (numberOfBytesRead == -1) {
            return -1;
        } else {
            totalNumberOfBytesRead += numberOfBytesRead;

            if ([self.inputStream streamStatus] >= NSStreamStatusAtEnd) {
                [self transitionToNextPhase];
            }
        }
    }

	//后边界读取
	//如果数据体是最后一个数据，那么插入后边界字符串，否则，插入空值
    if (_phase == AFFinalBoundaryPhase) {
        NSData *closingBoundaryData = ([self hasFinalBoundary] ? [AFMultipartFormFinalBoundary(self.boundary) dataUsingEncoding:self.stringEncoding] : [NSData data]);
        totalNumberOfBytesRead += [self readData:closingBoundaryData intoBuffer:&buffer[totalNumberOfBytesRead] maxLength:(length - (NSUInteger)totalNumberOfBytesRead)];
    }

	//最后返回读取到的所有数据的字节数
    return totalNumberOfBytesRead;
}
```

除了数据体用流直接进行读取外，其他的数据总是调用下面的方法进行写入。

```
- (NSInteger)readData:(NSData *)data
           intoBuffer:(uint8_t *)buffer
            maxLength:(NSUInteger)length
{
	//这里总是使用偏移量和可读取的最小长度构造读取范围
    NSRange range = NSMakeRange((NSUInteger)_phaseReadOffset, MIN([data length] - ((NSUInteger)_phaseReadOffset), length));
    [data getBytes:buffer range:range];

    _phaseReadOffset += range.length;

	//如果偏移量大于等于数据的长度，说明数据读取完毕，可以进入下一个阶段
    if (((NSUInteger)_phaseReadOffset) >= [data length]) {
        [self transitionToNextPhase];
    }

    return (NSInteger)range.length;
}
```

这里要知道的是，在拼接请求体的数据时，必需要遵循 HTTP 协议，下面的方法可以方便的获取不同数据体间的分隔字符串。

```
static NSString * AFCreateMultipartFormBoundary() {
    return [NSString stringWithFormat:@"Boundary+%08X%08X", arc4random(), arc4random()];
}

static NSString * const kAFMultipartFormCRLF = @"\r\n";

static inline NSString * AFMultipartFormInitialBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"--%@%@", boundary, kAFMultipartFormCRLF];
}

static inline NSString * AFMultipartFormEncapsulationBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"%@--%@%@", kAFMultipartFormCRLF, boundary, kAFMultipartFormCRLF];
}

static inline NSString * AFMultipartFormFinalBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"%@--%@--%@", kAFMultipartFormCRLF, boundary, kAFMultipartFormCRLF];
}
```

最终得到的请求体数据类似下面的格式：

```
--boundary+004563210AB32145
Content-Disposition: form-data; name="field1"

value1
--boundary+004563210AB32145
Content-Disposition: form-data; name="field2"

value2
--boundary+004563210AB32145
Content-Disposition: form-data; name="text"; filename="file.txt"

data1
--boundary+004563210AB32145
Content-Disposition: form-data; name="pic"; filename="icon.png"

data2
--boundary+004563210AB32145--
```

<a name = "AFMultipartBodyStream"></a>
### AFMultipartBodyStream 
在 AFNetWorking 框架中，定义了一个 NSInputStream 的子类来实现报文体数据的写入，其中声明了如下几个属性。

```
//每一次读取的报文体数据的最大字节数，默认为 NSIntegerMax
@property (nonatomic, assign) NSUInteger numberOfBytesInPacket;

//每一次读取数据的时间间隔，如果 delay 大于 0 ，那么读取数据的线程会在下一次读取前暂停
@property (nonatomic, assign) NSTimeInterval delay;

//使用该自定义流写入报文体中的数据的字节数，是 HTTPBodyParts 中元素的 contentLength 长度的和
@property (readonly, nonatomic, assign) unsigned long long contentLength;

//要写入的数据是否为空
@property (readonly, nonatomic, assign, getter = isEmpty) BOOL empty;

//编码格式
@property (readwrite, nonatomic, assign) NSStringEncoding stringEncoding;

//保存所有的数据信息，成员为 AFHTTPBodyPart 类型
@property (readwrite, nonatomic, strong) NSMutableArray *HTTPBodyParts;

//使用 HTTPBodyParts 生成的枚举器，在读取数据填充 buffer 时使用
@property (readwrite, nonatomic, strong) NSEnumerator *HTTPBodyPartEnumerator;

//当前操作的数据体，在遍历 HTTPBodyPartEnumerator 枚举器中的数据信息时使用
@property (readwrite, nonatomic, strong) AFHTTPBodyPart *currentHTTPBodyPart;

//存储报文体数据的缓存
@property (readwrite, nonatomic, strong) NSMutableData *buffer;

//这两个流貌似没啥用处……
@property (nonatomic, strong) NSInputStream *inputStream;
@property (readwrite, nonatomic, strong) NSOutputStream *outputStream;
```

创建一个自定义流后，使用下面的方法判断流中是否有数据信息，或向流中添加数据信息。

```
- (void)appendHTTPBodyPart:(AFHTTPBodyPart *)bodyPart {
    [self.HTTPBodyParts addObject:bodyPart];
}

- (BOOL)isEmpty {
    return [self.HTTPBodyParts count] == 0;
}
```

重写 NSStream 中的 **open** 方法，在该方法中设置数据体分隔标记并生成数据体枚举器。

```
- (void)open {
    if (self.streamStatus == NSStreamStatusOpen) {
        return;
    }

    self.streamStatus = NSStreamStatusOpen;

    [self setInitialAndFinalBoundaries];
    self.HTTPBodyPartEnumerator = [self.HTTPBodyParts objectEnumerator];
}

- (void)setInitialAndFinalBoundaries {
    if ([self.HTTPBodyParts count] > 0) {
        for (AFHTTPBodyPart *bodyPart in self.HTTPBodyParts) {
            bodyPart.hasInitialBoundary = NO;
            bodyPart.hasFinalBoundary = NO;
        }
		  
		 //将第一个元素设置为拥有首边界
        [[self.HTTPBodyParts firstObject] setHasInitialBoundary:YES];
		 //将最后一个元素设置为拥有尾边界
        [[self.HTTPBodyParts lastObject] setHasFinalBoundary:YES];
    }
}
```

重写 NSInputStream 中的 **read:maxLength** 方法，对所有的 AFHTTPBodyPart 元素进行遍历，调用其 [read:maxLength](#read_maxLength) 方法。

```
- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)length
{
    if ([self streamStatus] == NSStreamStatusClosed) {
        return 0;
    }

    NSInteger totalNumberOfBytesRead = 0;

	//如果读到的字节数小于准许读取的字节数中的最小值，则继续读取
    while ((NSUInteger)totalNumberOfBytesRead < MIN(length, self.numberOfBytesInPacket)) {
    
	    //如果当前数据体不存在，或者当前数据体没有可读取的数据，那么就处理下一个数据体
        if (!self.currentHTTPBodyPart || ![self.currentHTTPBodyPart hasBytesAvailable]) {
            if (!(self.currentHTTPBodyPart = [self.HTTPBodyPartEnumerator nextObject])) {
                break;
            }
        } else {
            NSUInteger maxLength = MIN(length, self.numberOfBytesInPacket) - (NSUInteger)totalNumberOfBytesRead;
            NSInteger numberOfBytesRead = [self.currentHTTPBodyPart read:&buffer[totalNumberOfBytesRead] maxLength:maxLength];
            if (numberOfBytesRead == -1) {
                self.streamError = self.currentHTTPBodyPart.inputStream.streamError;
                break;
            } else {
                totalNumberOfBytesRead += numberOfBytesRead;

                if (self.delay > 0.0f) {
                    [NSThread sleepForTimeInterval:self.delay];
                }
            }
        }
    }

    return totalNumberOfBytesRead;
}
```

### AFJSONRequestSerializer
AFJSONRequestSerializer 是 AFHTTPRequestSerializer 的子类，使用该构造器创建请求报文，用户提供的 JSON 参数会被放置在请求报文的请求体中。

该类重写了父类的 serializer 方法，也提供了类方法创建实例。

```
+ (instancetype)serializerWithWritingOptions:(NSJSONWritingOptions)writingOptions;
```

该类仍然使用父类中的初始化方法，只是重写了 AFURLRequestSerialization 协议中的方法，参见下面的部分源码。在该协议方法中，先对请求方法进行了校验，如果不符合要求，则直接调用父类的方法创建参数拼接于链接后的请求报文。如果通过校验，则将 JSON 对象参数转换为二进制数据放置到请求体中。

```
if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
	return [super requestBySerializingRequest:request withParameters:parameters error:error];
}
    
NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:self.writingOptions error:error];        
[mutableRequest setHTTPBody:jsonData];
```

> **`Content-Type`** 将默认设置为 **application/json**

### AFPropertyListRequestSerializer
AFPropertyListRequestSerializer 是 AFHTTPRequestSerializer 的子类，其重写了父类的 serializer 方法，也提供了类方法创建实例。

```
+ (instancetype)serializerWithFormat:(NSPropertyListFormat)format
                        writeOptions:(NSPropertyListWriteOptions)writeOptions;
```
同 AFJSONRequestSerializer 类似，其关键是重写的 AFURLRequestSerialization 协议方法，在该方法中，将属性列表数据转换为二进制放在请求体中。

```
- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(request);

    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
        return [super requestBySerializingRequest:request withParameters:parameters error:error];
    }

    NSMutableURLRequest *mutableRequest = [request mutableCopy];

    [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
        if (![request valueForHTTPHeaderField:field]) {
            [mutableRequest setValue:value forHTTPHeaderField:field];
        }
    }];

    if (parameters) {
        if (![mutableRequest valueForHTTPHeaderField:@"Content-Type"]) {
            [mutableRequest setValue:@"application/x-plist" forHTTPHeaderField:@"Content-Type"];
        }

        NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:parameters format:self.format options:self.writeOptions error:error];
        
        if (!plistData) {
            return nil;
        }
        
        [mutableRequest setHTTPBody:plistData];
    }

    return mutableRequest;
}
```

> 默认的属性格式为 `NSPropertyListXMLFormat_v1_0`