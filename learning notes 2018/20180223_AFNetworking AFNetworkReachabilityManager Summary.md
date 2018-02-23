## AFNetworkReachabilityManager
在 AFNetworking 框架中，提供了一个 AFNetworkReachabilityManager 类用来监控网络状态，其可能的状态如下：

* AFNetworkReachabilityStatusUnknown 未知状态（-1）
* AFNetworkReachabilityStatusNotReachable 不可达状态（0）
* AFNetworkReachabilityStatusReachableViaWWAN 蜂窝网络连通（1）
* AFNetworkReachabilityStatusReachableViaWiFi 无线网络连通（2）

通过 AFNetworkReachabilityManager 的属性 networkReachabilityStatus 可以获取当前网络的状态，这个属性值是上述状态之一。

还可以通过方法 **isReachable** 、**isReachableViaWWAN** 、**isReachableViaWiFi** 判断当前网络是否连通或是蜂窝数据连通还是无线网络连通。

AFNetworkReachabilityManager 中提供了多个创建实例的方法，常用的是 **sharedManager** 方法，这也是 AFURLSessionManager 类中获取网络状态监视器的方法。
该方法获取一个公用的实例对象，其实际上也是调用 **manager** 方法，创建一个监控默认套接字地址是否可达的监视器。

当然，还可以直接调用 **managerForAddress:** 或 **managerForDomain:** 方法来指点要监控的套接字地址或域名地址。

当获取到 AFNetworkReachabilityManager 实例对象后，根据需要可以使用下面的方法设置网络状态发生变化时的回调。

`- (void)setReachabilityStatusChangeBlock:(nullable void (^)(AFNetworkReachabilityStatus status))block;`

之后，调用实例方法 **startMonitoring** 便可以开启网络状态监控了，不需要时，可以调用方法 **stopMonitoring** 关闭监控。

每当网络发生变化时，除了调用设置的回调方法外，还会推送一个 **AFNetworkingReachabilityDidChangeNotification** 通知，该通知中的 userInfo 信息中的 **AFNetworkingReachabilityNotificationStatusItem** 包含网络状态信息。

### SCNetworkReachabilityRef
网络监控的实现，关键是 SCNetworkReachabilityRef 变量的创建及设置。该变量及其相关的接口可以用来决定当前系统的网络状态，并且可以在网络状态发生变化时，发送通知。

在该接口里也定义了一些常量来标记指定节点域名或地址的网络状态：

* **kSCNetworkReachabilityFlagsTransientConnection** 表示指定的节点或地址可以短暂连通，如 PPP
* **kSCNetworkReachabilityFlagsReachable** 表示当前网络配置可以连通到指定的节点或地址
* **kSCNetworkReachabilityFlagsConnectionRequired** 表示要使用当前网络配置连通到指定地址必需先建立连接，如拨号连接
* **kSCNetworkReachabilityFlagsConnectionOnTraffic** 同样需要先建立连接才能传输网络数据，但是每一次传输数据都会初始化连接
* **kSCNetworkReachabilityFlagsConnectionAutomatic** 等同于 kSCNetworkReachabilityFlagsConnectionOnTraffic
* **kSCNetworkReachabilityFlagsInterventionRequired** 该状态表示除了要先建立连接外，还要提供诸如用户名、密码等信息的网络环境
* **kSCNetworkReachabilityFlagsConnectionOnDemand** 该状态表示由 CFSocketStream 接口根据需要建立连接后可以连通到指定地址，其他接口并不会建立连接
* **kSCNetworkReachabilityFlagsIsLocalAddress** 表示指定的地址是本地系统的地址
* **kSCNetworkReachabilityFlagsIsDirect** 表示连通到指定地址的网络通信不会经过某个网关，而是直接通过本系统的某个接口
* **kSCNetworkReachabilityFlagsIsWWAN** 表示指定的网络地址可以通过 EDGE 、GPRS 或其他蜂窝数据连接到达（只用于 iOS 系统）

除了上述的状态概念外，还需要理解一个网络可达性上下文结构，如下：

```
typedef struct {
	CFIndex		version;
	void *		__nullable info;
	const void	* __nonnull (* __nullable retain)(const void *info);
	void		(* __nullable release)(const void *info);
	CFStringRef	__nonnull (* __nullable copyDescription)(const void *info);
} SCNetworkReachabilityContext;
```
在构造使用这个结构体时，version 设置为 0 ，info 是一个指向数据块的 C 指针，retain 是一个含有一个参数和一个返回值的函数，
该回调函数用来对 info 添加引用，与之对应，release 则是用来取消对 info 引用的回调函数，copyDescription 则可以返回对 info 的描述。

该接口里还对回调函数进行了定义：

```
typedef void (*SCNetworkReachabilityCallBack) (
	SCNetworkReachabilityRef target,			SCNetworkReachabilityFlags flags,
	void     *	__nullable	info
);
```
SCNetworkReachabilityCallBack 指向一个函数，该函数没有返回值，且包含三个参数，受监控的 target ，网络状态变化后的状态 flags ，
以及上下文中的 info 信息，这个信息就是 SCNetworkReachabilityContext 结构体中的 info 成员变量。

理解上面的定义后，现在再来看下面设置回调的函数，则十分简单了。

```
Boolean SCNetworkReachabilitySetCallback (
	SCNetworkReachabilityRef target,
	SCNetworkReachabilityCallBack __nullable callout,
	SCNetworkReachabilityContext * __nullable context
) __OSX_AVAILABLE_STARTING(__MAC_10_3,__IPHONE_2_0);
```
三个参数，即为 target 设置回调函数 callout ，同时 callout 关联着 context 上下文，其中可以保存 callout 要用的数据。

在设置回调函数之前，需要使用下面三个函数中的一个创建变量。

```
//指定一个网络地址
SCNetworkReachabilityRef __nullable SCNetworkReachabilityCreateWithAddress (
	CFAllocatorRef __nullable allocator,
	const struct sockaddr *address
) __OSX_AVAILABLE_STARTING(__MAC_10_3,__IPHONE_2_0);

//指定网络连接的本地地址和远程地址
SCNetworkReachabilityRef __nullable SCNetworkReachabilityCreateWithAddressPair (
	CFAllocatorRef __nullable allocator,
	const struct sockaddr * __nullable localAddress,
	const struct sockaddr * __nullable remoteAddress
) __OSX_AVAILABLE_STARTING(__MAC_10_3,__IPHONE_2_0);

//指定节点域名
SCNetworkReachabilityRef __nullable SCNetworkReachabilityCreateWithName (
	CFAllocatorRef __nullable allocator,
	const char *nodename
) __OSX_AVAILABLE_STARTING(__MAC_10_3,__IPHONE_2_0);
```

前两个方法中都使用下面的结构体保存网络地址：

```
struct sockaddr {
	__uint8_t	    sa_len;		/* 总长度 */
	sa_family_t	 sa_family;	/* 协议簇 */
	char		     sa_data[14];	/* 地址 */
};
```
上面这个结构体和下面的结构体可以通用

```
struct sockaddr_in {
	__uint8_t	    sin_len;
	sa_family_t	 sin_family;
	in_port_t	     sin_port;
	struct	in_addr  sin_addr;
	char		      sin_zero[8]; //为了兼容 sockaddr 结构体而保留的成员变量
};
```
这两个结构体都占有 16 Bytes 即 `sa_len` 和 `sin_len` 的值都是 16 。

创建并设置好 SCNetworkReachabilityRef 变量后，还需要将变量加入到运行循环中，取消监控时，对应的要将该变量移除运行循环。

```
Boolean SCNetworkReachabilityScheduleWithRunLoop (
	SCNetworkReachabilityRef target,
	CFRunLoopRef			runLoop,
	CFStringRef			runLoopMode
) __OSX_AVAILABLE_STARTING(__MAC_10_3,__IPHONE_2_0);

Boolean SCNetworkReachabilityUnscheduleFromRunLoop (
	SCNetworkReachabilityRef target,
	CFRunLoopRef			runLoop,
	CFStringRef			runLoopMode
) __OSX_AVAILABLE_STARTING(__MAC_10_3,__IPHONE_2_0);
```

另外，还可以使用下面的函数指定回调函数调用的队列：

```
Boolean SCNetworkReachabilitySetDispatchQueue (
	SCNetworkReachabilityRef target,
	dispatch_queue_t __nullable queue
) __OSX_AVAILABLE_STARTING(__MAC_10_6,__IPHONE_4_0);
```

使用下面的方法获取监控对象的网络状态：

```
Boolean SCNetworkReachabilityGetFlags (
	SCNetworkReachabilityRef	target,
	SCNetworkReachabilityFlags *flags
) __OSX_AVAILABLE_STARTING(__MAC_10_3,__IPHONE_2_0);
```

### startMonitoring
在获取了 AFNetworkReachabilityManager 监视器后，需要调用 startMonitoring 方法来开启监控。

在这个开启方法中，会对创建的 SCNetworkReachabilityRef 变量进行设置，不管这个变量是由域名或地址创建的。

参见下面的源代码：

```
- (void)startMonitoring {
    [self stopMonitoring];

    if (!self.networkReachability) {
        return;
    }
    
    //这里 callback 与 networkReachabilityStatusBlock 是相同类型的回调代码块
    //此处进行了包裹，是为了避免 networkReachabilityStatusBlock 为 nil 

    __weak __typeof(self)weakSelf = self;
    AFNetworkReachabilityStatusBlock callback = ^(AFNetworkReachabilityStatus status) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;

        strongSelf.networkReachabilityStatus = status;
        if (strongSelf.networkReachabilityStatusBlock) {
            strongSelf.networkReachabilityStatusBlock(status);
        }
    };

	 //构建上下文，包含回调代码块
    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, AFNetworkReachabilityRetainCallback, AFNetworkReachabilityReleaseCallback, NULL};
    
    //设置 AFNetworkReachabilityCallback 为回调函数
    //这个函数中，会对上面的 callback 进行调用，并推送 AFNetworkingReachabilityDidChangeNotification 通知
    SCNetworkReachabilitySetCallback(self.networkReachability, AFNetworkReachabilityCallback, &context);
    
    //加入运行循环
    SCNetworkReachabilityScheduleWithRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
    
        SCNetworkReachabilityFlags flags;
        
        //首先查询了一次网络状态
        if (SCNetworkReachabilityGetFlags(self.networkReachability, &flags)) {
            AFPostReachabilityStatusChange(flags, callback);
        }
    });
}
```