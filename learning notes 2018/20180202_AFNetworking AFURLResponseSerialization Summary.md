## AFURLResponseSerialization
### 响应报文解析器
在 AFNetworking 网络框架中，为了方便处理网络返回的响应报文，特抽象出来一个响应报文解析器，其相关的类都在 AFURLResponseSerialization.h 文件中。相较于网络请求报文构造器，解析器要简单的多，其关键为抽象类 **AFHTTPResponseSerializer** 以及其遵循的 **[AFURLResponseSerialization](#AFURLResponseSerialization)** 协议。

### AFHTTPResponseSerializer
AFURLRequestSerialization 会对响应报文做一些基本的处理，所以自定义处理 HTTP 响应报文时，应扩展其子类以保证基本的报文处理得以进行，但是通常，该框架中提供的子类解析器已经满足大部分需要了。

在 AFURLRequestSerialization 类中定义了两个重要的属性和一个判断响应报文是否有效的方法。

```
@property (nonatomic, copy, nullable) NSIndexSet *acceptableStatusCodes;
@property (nonatomic, copy, nullable) NSSet <NSString *> *acceptableContentTypes;
```

* acceptableStatusCodes 合法的报文状态码集合
* acceptableContentTypes 合法的报文体数据类型集合

上述两个属性会在下面的方法中被用来判断响应报文是否是有效报文，当然，如果这两个属性为 nil ，那么便不会使用其进行判断。

```
- (BOOL)validateResponse:(nullable NSHTTPURLResponse *)response
                    data:(nullable NSData *)data
                   error:(NSError * _Nullable __autoreleasing *)error;
```
调用上面的方法，判断 response 的 MIMEType 属性值是否在 acceptableContentTypes 集合中，response 的 statusCode 属性值是否在 acceptableStatusCodes 范围内，并且 data 是否存在，如果校验不通过，相关的错误信息会保存在 error 中并返回 NO 。

在创建解析器时，可以调用类方法 **serializer** ，在该方法中，会初始化 acceptableStatusCodes 属性集合的范围为 200～300 ，而 acceptableContentTypes 会被置为 nil 。

### AFURLResponseSerialization <a name = "AFURLResponseSerialization"></a>
该协议只提供了一个方法，用来解析响应报文中的数据，最后的返回值为解析后的数据。在自定义 AFHTTPResponseSerializer 的子类时，应该重新该协议方法，因为 AFHTTPResponseSerializer 类中并未对与报文相关的 data 数据进行额外的处理，而是直接返回了。

```
- (nullable id)responseObjectForResponse:(nullable NSURLResponse *)response
                           data:(nullable NSData *)data
                          error:(NSError * _Nullable __autoreleasing *)error NS_SWIFT_NOTHROW;
```

### AFJSONResponseSerializer
AFJSONResponseSerializer 类重写了父类 AFHTTPResponseSerializer 中的实例创建方法和初始化方法，并提供了下面的类方法用于创建指定 JSON 数据选项的实例对象。

```
+ (instancetype)serializerWithReadingOptions:(NSJSONReadingOptions)readingOptions;
```
并且可以通过设置 **removesKeysWithNullValues** 属性值为 YES 来过滤为 NULL 的数据。

在创建 JSON 数据的解析器时，其初始化方法，会将有效的报文类型集合设置为 **application/json** 、**text/json** 、**text/javascript** ，如下：

```
self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];
```
这样在校验报文数据时，就会过滤掉非 JSON 格式的返回报文，然后使用 NSJSONSerialization 解析 JSON 数据得到相应的对象，如果需要移除为 NULL 的值，则会接着调用下面的函数。

```
static id AFJSONObjectByRemovingKeysWithNullValues(id JSONObject, NSJSONReadingOptions readingOptions)
```

### AFXMLParserResponseSerializer
AFXMLParserResponseSerializer 同样是 AFHTTPResponseSerializer 的子类，只是其并未增加属性，只是重写了父类的方法。

在初始化方法中将 acceptableContentTypes 设置为 **application/xml** 和 **text/xml** 的集合。

在 AFURLResponseSerialization 协议中的方法中，使用返回的数据创建了一个 XML 数据解析器 **NSXMLParser** 并返回，进一步的解析则由用户负责。

### AFXMLDocumentResponseSerializer
AFXMLDocumentResponseSerializer 与 AFXMLParserResponseSerializer 类似，有相同的报文类型集合，但是其重写的解析方法最后返回的是 **NSXMLDocument** 对象。

> 该解析器只适用于 Mac OS X 系统中

### AFPropertyListResponseSerializer
AFPropertyListResponseSerializer 会可以用来解析类型为 **application/x-plist** 的返回报文，在解析时会使用 NSPropertyListSerialization 类。





