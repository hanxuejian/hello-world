# [扩展配件编程话题](https://developer.apple.com/library/content/featuredarticles/ExternalAccessoryPT/Introduction/Introduction.html#//apple_ref/doc/uid/TP40009498-SW1)

## [介绍](https://developer.apple.com/library/content/featuredarticles/ExternalAccessoryPT/Introduction/Introduction.html#//apple_ref/doc/uid/TP40009498-SW1)

### 关于扩展配件
扩展配件框架([ExternalAccessory.framework](https://developer.apple.com/reference/externalaccessory))提供了连接到基于iOS设备的配件与iOS设备之间进行通信的方法。应用开发人员可以通过此方法将配件的特性集成到自己的应用中。

与扩展配件通讯，需要你同配件厂商通力合作，并理解其配件所提供的服务。而厂商必须精准的支持其硬件设备同iOS之间的通讯。作为支持的一部分，其配件必须支持至少一种命令行协议，该协议用于配件与其相配套的应用之间进行数据的传输，并且厂家可以自定义该协议，或者使用其他厂商支持的标准协议，而苹果公司并不注册或管理该协议。

要与厂商生产的配件相通讯，你必须知道该配件所支持的协议，为了避免冲突，协议名称应使用反向域名字符串，这就使得厂商能够定义出足够的协议名称以支持其生产的配件。

```
注：如果你想要成为一个 iPad、iPhone、iPod 的配件开发者，可以访问 http://developer.apple.com
```

#### 概述
与配件通讯，你需要从硬件厂商那里获取配件的必要信息，由此，你才可使用扩展配件框架中的类使配件与你的应用进行通讯。

##### 在工程中引用扩展配件框架
为了使用扩展配件框架的特性，你必须将 ExternalAccessory.framework 添加到你的工程中并将其链接到所有相关的目标中。而后，在所有相关的源文件顶部添加 #import <ExternalAccessory/ExternalAccessory.h> 以便其能够访问框架中的类及头文件。

##### 声明应用支持的协议
应用若要与配件通讯，必须在 Info.plist 文件中声明其所支持的协议。声明所支持的协议，系统才能在配件连接后加载该应用，如果设备上没有安装支持所连接的配件的应用，那么，系统会打开应用商店，并指出支持的应用。

在 Info.plist 文件中添加键值 UISupportedExternalAccessoryProtocols 以声明你的应用所支持的协议。该键值对应一个包含字符串的数组，存储你的应用所支持的所有协议，可以是无序且任意个数的。系统会使用该列表判断你的应用能否与配件通讯，而不会决定你的应用具体使用哪个协议通讯。至于使用的是哪个协议，当配件与应用开始通讯时，由你的代码选择合适的通讯协议。

获取更多应用中有关 Info.plist 文件的键值信息，查看 [Information Property List Key Reference](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Introduction/Introduction.html#//apple_ref/doc/uid/TP40009247)。

##### 与配件通讯
一个应用通过创建类 EASession 对象来管理与配件的通讯及交互，该类对象同系统底层合作传输或接收数据包。在应用中，数据的传输是通过 NSInputStream 和 NSOutputStream 对象进行的，这两个流对象都是在通讯连接开始时，由会话对象生成的。为了接收数据，需要自定义的代理类监听输入流，而发送数据，需要将数据包写入输出流，而接收与发送的数据包的格式由你与配件通讯时采用的协议决定。

相关文档：[连接配件](#ConnectingtoanAccessory)、[监控配件相关事件](#Monitoring Accessory-Related Events)

#### 参见
获取扩展配件框架类信息，请参考[External Accessory Framework Reference](https://developer.apple.com/reference/externalaccessory)

---
### [连接配件](id:ConnectingtoanAccessory)
配件在被系统连接及做好使用准备之前对扩展配件框架是不可见的，当配件可以使用时，你的应用会获取一个合适的配件对象，并使用配件支持的协议打开一个会话。

类 [EAAccessoryManager](https://developer.apple.com/reference/externalaccessory/eaaccessorymanager) 的共享对象为应用提供了与配件通讯的主入口点，该类提供了一个列表，包含所有已经连接的配件对象，你可以遍历这些对象找到一个你的应用支持的对象。配件类 [EAAccessory](https://developer.apple.com/reference/externalaccessory/eaaccessory) 对象中的大多信息（如名称、厂商、模式信息）只是用于显示，而为了你的应用能够连接配件，你需要查看配件的协议，并保证其中至少一个协议是你的应用所支持的。

```
注：存在多个配件对象支持一个相同的协议的可能，若这种情况发生，由你的应用程序代码决定使用哪个配件对象。
```
对于一个给定的配件对象指定的协议，同一时间，只允许启动一个会话。每个配件类 EAAccessory 对象的属性值 [protocolStrings](https://developer.apple.com/reference/externalaccessory/eaaccessory/1613877-protocolstrings?language=objc) 都包含着该配件所支持的所有协议。如果你企图使用一个正在使用中的协议创建一个会话，那么，扩展配件框架在打开新的会话之前会先关闭已经存在的会话。

列表 1 给出了一个检查已连接的配件对象列表，并选择第一个被应用支持的配件对象的方法，并为该配件对象协议生成一个会话，且配置号会话的输入输出流。当该方法返回了会话对象，则连接配件成功并开始传送并接收数据。

列表 1 为配件创建会话

```
- (EASession *)openSessionForProtocol:(NSString *)protocolString
{
    NSArray *accessories = [[EAAccessoryManager sharedAccessoryManager]
                                   connectedAccessories];
    EAAccessory *accessory = nil;
    EASession *session = nil;
 
    for (EAAccessory *obj in accessories)
    {
        if ([[obj protocolStrings] containsObject:protocolString])
        {
            accessory = obj;
            break;
        }
    }
 
    if (accessory)
    {
        session = [[EASession alloc] initWithAccessory:accessory
                                 forProtocol:protocolString];
        if (session)
        {
            [[session inputStream] setDelegate:self];
            [[session inputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                     forMode:NSDefaultRunLoopMode];
            [[session inputStream] open];
            [[session outputStream] setDelegate:self];
            [[session outputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                     forMode:NSDefaultRunLoopMode];
            [[session outputStream] open];
            [session autorelease];
        }
    }
 
    return session;
}
```
配置好输入输出流之后，最后一步是处理流相关的数据，列表 2 给出了流数据处理代码的代理方法的基本结构。该方法会响应配件的输入输出流的事件，当配件传送数据给应用时，事件发生，说明有数据待读取。同样，当配件准备接收数据是，事件也会表明该事实。（当然，在流可以写数据之前，应用不必一直等待事件的发生，可以调用流方法 [hasBytesAvailable](https://developer.apple.com/reference/foundation/inputstream/1409410-hasbytesavailable) 来判断配件是否仍然能够接收数据。）获取更多流信息及流相关事件，查看[Stream Programming Guide](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Streams/Streams.html#//apple_ref/doc/uid/10000188i)

列表 2 处理流事件

```
// Handle communications from the streams.
- (void)stream:(NSStream*)theStream handleEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent)
    {
        case NSStreamHasBytesAvailable:
            // Process the incoming stream data.
            break;
 
        case NSStreamEventHasSpaceAvailable:
            // Send the next queued command.
            break;
 
        default:
            break;
    }
 
}
```

### [监控配件相关事件](id:Monitoring Accessory-Related Events)
当硬件配件连接或断开连接时，扩展配件框架均能发送通知。但其并不会自动发送通知，这需要你的应用调用类 EAAccessoryManager 的方法 [registerForLocalNotifications](https://developer.apple.com/reference/externalaccessory/eaaccessorymanager/1613873-registerforlocalnotifications) 明确指出接收通知。当配件连接，通过认证，并准备与你的应用通讯，该框架会发送 [EAAccessoryDidConnectNotification](https://developer.apple.com/reference/foundation/nsnotification.name/1613827-eaaccessorydidconnect) 通知,当配件断开连接，其会发送[EAAccessoryDidDisconnectNotification](https://developer.apple.com/reference/foundation/nsnotification.name/1613901-eaaccessorydiddisconnect)通知。你可以使用通知中心注册接收这两个通知，并且这两个通知里包含有配件对象的信息。

除了通过通知中心接收通知外，同配件通讯的应用还可以通给类 EAAccessory 对象的代理对象赋值，以获取变更提醒。代理对象必须遵循[EAAccessoryDelegate](https://developer.apple.com/reference/externalaccessory/eaaccessorydelegate)代理协议，该协议包含一个可选的方法[accessoryDidDisconnect:](https://developer.apple.com/reference/externalaccessory/eaaccessorydelegate/1613858-accessorydiddisconnect)。你可以实现这个方法来接收配件断开连接的通知，而不必开始的时候设置通知监听。

如果你的应用被系统挂起了，而此时有配件通知到达，那么该通知被放进队列中，而当你的应用再次执行时（不管是在前台还是后台），在队列中的通知都将传送给你的应用。通知也会合并及过滤，从而尽可能消除无关的事件。例如，当你的应用在挂起过程中，如果配件连接了，紧接着又断开了连接，那么，你的应用最终不会接收到任何通知来提示有这种事件发生。

获取更多注册及接收通知的信息，查看 [Notification Programming Topics](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Notifications/Introduction/introNotifications.html#//apple_ref/doc/uid/10000043i)
