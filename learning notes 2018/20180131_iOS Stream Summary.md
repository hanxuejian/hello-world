# 流
流是二进制数据串在端与端之间的传输。在 Cocoa 中提供了 **NSStream** 、**NSInputStream** 、**NSOutputStream** 三个类来实现数据通过流的方式在文件、内存、网络之间的传输。

NSStream 是一个抽象类，它是 NSInputStream 和 NSOutputStream 类的父类。NSInputStream 是输入流，流中的数据可能来自本地文件，也可能来自网络资源，应用从输入流中读取到数据后，便可以进行必要的处理了。NSOutputStream 是输出流，将处理后的数据写入输出流中，而后数据传输到目标，这个目标可以是本地文件，也可以是网络上的某个地址。但是，这种较为底层的数据处理方式，如无必要，可以使用 NSURL 或 NSFileHandle 代替。

## NSStream
NSStream 类作为流的抽象类，定义了一些基本的方法和属性。在自定义 NSSteam 子类时，应重写其中的方法。

```
- (void)open;
- (void)close;
- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSRunLoopMode)mode;
- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSRunLoopMode)mode;
```
当流创建并开启后，会占用一些系统资源，所以流使用结束后，应主动关闭，关闭后的流不能再次开启，但是其相关属性仍可以访问。如果流被添加到运行循环中，关闭时应将其移出运行循环。

```
#if FOUNDATION_SWIFT_SDK_EPOCH_AT_LEAST(8)
- (nullable id)propertyForKey:(NSStreamPropertyKey)key;
- (BOOL)setProperty:(nullable id)property forKey:(NSStreamPropertyKey)key;
#else
- (nullable id)propertyForKey:(NSString *)key;
- (BOOL)setProperty:(nullable id)property forKey:(NSString *)key;
#endif
```
通过上面的方法，可以获取流相关的属性配置，可选的属性如下：

* NSStreamSocketSecurityLevelKey 套接字安全选项
* NSStreamSOCKSProxyConfigurationKey 套接字代理的配置信息
* NSStreamDataWrittenToMemoryStreamKey 获取输出流写入内存中的数据
* NSStreamFileCurrentOffsetKey 获取基于文件的流的数据偏移量
* NSStreamNetworkServiceType 指定流的用途

```
//流的状态
@property (readonly) NSStreamStatus streamStatus;

typedef NS_ENUM(NSUInteger, NSStreamStatus) {
    NSStreamStatusNotOpen = 0,
    NSStreamStatusOpening = 1,
    NSStreamStatusOpen = 2,
    NSStreamStatusReading = 3,
    NSStreamStatusWriting = 4,
    NSStreamStatusAtEnd = 5,
    NSStreamStatusClosed = 6,
    NSStreamStatusError = 7
};

```

流的代理可以不指定，如果不指定，那么流本身即为代理对象，应实现代理方法。

```
//流的代理
@property (nullable, assign) id <NSStreamDelegate> delegate;

//NSStreamDelegate 协议中的唯一的方法
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode;
```
这个代理方法可以用来处理流的相关事件，可能的事件如下：

* NSStreamEventNone 无事件发生
* NSStreamEventOpenCompleted 成功打开流 
* NSStreamEventHasBytesAvailable 流中有数据可读
* NSStreamEventHasSpaceAvailable 可以向流中写入数据
* NSStreamEventErrorOccurred 发生错误
* NSStreamEventEndEncountered 达到流末尾

> NSStream 流并不支持套接字连接，要实现远程客户端套接字交互，可以使用 CFStream 的相关接口。

## NSInputStream
创建 NSInputStream 实例对象时，应当指定数据源，数据源可以是文件、内存或网络资源。

NSInputStream 中的属性 hasBytesAvailable 值表示了当前输入流中是否有可以读取的数据，如果该属性值为 YES 那么可以调用流的方法进行读取。

```
//buffer 是提供的缓存地址
//len 是可以读取的数据的最大字节数
//返回实际读取的数据字节数
- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len;
```

## NSOutputStream
创建 NSOutputStream 实例对象时，应当指定数据输出的目标，该目标可以是内存、本地文件或网络地址。

NSOutputStream 的属性 hasSpaceAvailable 值如果为 YES ，则表示可以向流中写入数据。

```
//buffer 从指定的缓存中向流中写入数据
//len 可以写入的数据最大字节数
//返回实际向流中写入的数据字节数
- (NSInteger)write:(const uint8_t *)buffer maxLength:(NSUInteger)len;
```

> 如果输出流的目标为内存，那么可以使用 NSStreamDataWrittenToMemoryStreamKey 获取最终输出的数据。

## NSStreamDelegate
NSStreamDelegate 该协议只有一个方法，该方法用来处理与流相关的事件。

```
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode;
```
