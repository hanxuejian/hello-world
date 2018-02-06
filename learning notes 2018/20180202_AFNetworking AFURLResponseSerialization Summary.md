## AFURLResponseSerialization
### 响应报文解析器
在 AFNetworking 网络框架中，为了方便处理网络返回的响应报文，特抽象出来一个响应报文解析器，其相关的类都在 AFURLResponseSerialization.h 文件中。相较于网络请求报文构造器，解析器要简单的多，其关键为抽象类 **AFHTTPResponseSerializer** 以及其遵循的 **[AFURLResponseSerialization](#AFURLResponseSerialization)** 协议。

### AFHTTPResponseSerializer
AFHTTPResponseSerializer 会对响应报文做一些基本的处理，所以自定义处理 HTTP 响应报文时，应扩展其子类以保证基本的报文处理得以进行，不过，该框架中提供的子类解析器已经满足了大部分需要。

在 AFHTTPResponseSerializer 类中定义了两个重要的属性和一个判断响应报文是否有效的方法。

```
@property (nonatomic, copy, nullable) NSIndexSet *acceptableStatusCodes;
@property (nonatomic, copy, nullable) NSSet <NSString *> *acceptableContentTypes;
```

* **acceptableStatusCodes** 合法的报文状态码集合
* **acceptableContentTypes** 合法的报文体数据类型集合

上述两个属性会在下面的方法中被用来判断响应报文是否是有效报文，当然，如果这两个属性为 nil ，那么便不会使用其进行判断。

```
- (BOOL)validateResponse:(nullable NSHTTPURLResponse *)response
                    data:(nullable NSData *)data
                   error:(NSError * _Nullable __autoreleasing *)error;
```
调用上面的方法，判断 response 的 **MIMEType** 属性值是否在 acceptableContentTypes 集合中，response 的 **statusCode** 属性值是否在 acceptableStatusCodes 范围内，并且 data 是否存在，如果校验不通过，相关的错误信息会保存在 error 中并返回 NO 。

在创建解析器时，可以调用类方法 **serializer** ，在该方法中，会初始化 acceptableStatusCodes 属性集合的范围为 200～300 ，而 acceptableContentTypes 会被置为 nil 。

### AFURLResponseSerialization <a name = "AFURLResponseSerialization"></a>
该协议只提供了一个方法，用来解析响应报文中的数据，最后的返回值为解析后的数据。在自定义 AFHTTPResponseSerializer 的子类时，应该重写该协议方法，因为 AFHTTPResponseSerializer 类中并未对与报文相关的 data 数据进行额外的处理，而是直接返回了。

```
- (nullable id)responseObjectForResponse:(nullable NSURLResponse *)response
                           data:(nullable NSData *)data
                          error:(NSError * _Nullable __autoreleasing *)error NS_SWIFT_NOTHROW;
```

### AFJSONResponseSerializer
AFJSONResponseSerializer 类重写了父类 AFHTTPResponseSerializer 中的实例创建方法和初始化方法，并提供了下面的类方法用于创建解析 JSON 数据的实例对象。

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

在 AFURLResponseSerialization 协议的方法中，使用接收到的数据创建了一个 XML 数据解析器 **NSXMLParser** 并返回，进一步的解析则由用户负责。

### AFXMLDocumentResponseSerializer
AFXMLDocumentResponseSerializer 与 AFXMLParserResponseSerializer 类似，有相同的报文类型集合，但是其重写的解析方法最后返回的是 **NSXMLDocument** 对象。

> 该解析器只适用于 Mac OS X 系统中

### AFPropertyListResponseSerializer
AFPropertyListResponseSerializer 可以用来解析类型为 **application/x-plist** 的返回报文，在重写 AFURLResponseSerialization 中的方法时，会创建并返回一个 **NSPropertyListSerialization** 类实例对象。

### AFImageResponseSerializer
AFImageResponseSerializer 用来解析请求到的图片数据，其默认支持的图片格式如下：

- `image/tiff`
- `image/jpeg`
- `image/gif`
- `image/png`
- `image/ico`
- `image/x-icon`
- `image/bmp`
- `image/x-bmp`
- `image/x-xbitmap`
- `image/x-win-bitmap`

在该子类中，声明了 **imageScale** 、**automaticallyInflatesResponseImage** 两个属性，前者指定图片的缩放值，默认为设备屏幕的缩放值。后者指明是否调用函数 **AFInflatedImageFromResponseWithDataAtScale** 对请求的图片的透明度信息进行填充，默认为 YES ，即进行填充。

在 AFInflatedImageFromResponseWithDataAtScale 函数中，只会对类型为 PNG 和 JPEG 类型的图片进行处理，并且图片如果是 JPEG 类型且其颜色空间为 **kCGColorSpaceModelCMYK** 类型，也不会进行透明度信息的填充。

另外，获取的图片，其宽和高都要小于 1024 且通道信息的位数不能大于 8 。之后，如果设备所支持的颜色空间模型为 **kCGColorSpaceModelRGB** 则可以对图片的透明度信息进行处理，分为下面两种情况：

* 图片的 **kCGBitmapAlphaInfoMask** 值为 **kCGImageAlphaNone** 即图片没有透明度信息，那么透明度信息设置为 **kCGImageAlphaNoneSkipFirst**
* 图片的 **kCGBitmapAlphaInfoMask** 值不是 **kCGImageAlphaNoneSkipFirst** 、**kCGImageAlphaNoneSkipLast** 时，设置为 **kCGImageAlphaPremultipliedFirst**

> 这两个属性不适用于 Mac OS X 系统中。

### AFCompoundResponseSerializer
组合解析器，使用该类可以将多个解析器组合到一个解析器中，用于多种类型数据的解析，对于无法确定返回的数据类型的情况很方便，其实现的方式主要是在重写的协议方法中遍历 **responseSerializers** 属性中的所有解析器进行数据解析，一旦解析成功，则返回解析结果，否则继续使用下一个解析器。

这些解析器可以是自定义的，但是必需遵循 AFURLResponseSerialization 协议，当然，可能遍历结束后，数据仍然无法解析，参见下面的源码。

```
- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    for (id <AFURLResponseSerialization> serializer in self.responseSerializers) {
        if (![serializer isKindOfClass:[AFHTTPResponseSerializer class]]) {
            continue;
        }

        NSError *serializerError = nil;
        id responseObject = [serializer responseObjectForResponse:response data:data error:&serializerError];
        if (responseObject) {
            if (error) {
                *error = AFErrorWithUnderlyingError(serializerError, *error);
            }

            return responseObject;
        }
    }

    return [super responseObjectForResponse:response data:data error:error];
}
```

要注意的是，创建该类时，不能使用父类声明的 serializer 方法，而是要使用该类自己声明的类方法。

```
+ (instancetype)compoundSerializerWithResponseSerializers:(NSArray <id<AFURLResponseSerialization>> *)responseSerializers;
```


