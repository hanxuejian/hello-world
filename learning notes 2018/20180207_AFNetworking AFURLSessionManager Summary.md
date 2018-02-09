## AFURLSessionManager
如果说 [AFURLRequestSerialization](http://blog.csdn.net/u011374318/article/details/79256016) 是对网络请求的前期准备，而 [AFURLResponseSerialization](http://blog.csdn.net/u011374318/article/details/79274781) 是对网络请求结束后，对返回数据的后续处理的话，那么所缺少的便是两者之间的网络请求过程了。要开启一个网络请求过程，便需要创建一个 **NSURLSessionTask** 网络请求任务，而前提是需要先创建一个 **NSURLSession** 实例对象，所以 **AFURLSessionManager** 自然便是用来创建和管理 NSURLSession 会话对象的管理器了。

AFURLSessionManager 还有一个 AFHTTPSessionManager 子类，用于构造 HTTP 会话请求管理对象。

AFURLSessionManager 还遵循下面几个协议：

- `<NSURLSessionTaskDelegate>`
- `<NSURLSessionDataDelegate>`
- `<NSURLSessionDownloadDelegate>`
- `<NSURLSessionDelegate>`

在 AFURLSessionManager 中实现这些协议中声明的方法，用来处理网络请求过程中诸如暂停、取消、数据保存、更新进度条等操作。

### AFURLSessionManager 中的属性

|属性|类型|含义|
|:---:|:---:|----|
|session|NSURLSession|会话管理器管理的会话|
|operationQueue|NSOperationQueue|用于执行代理回调方法的队列|
|responseSerializer|id <AFURLResponseSerialization>|返回数据的解析器，默认是 AFJSONResponseSerializer 解析器|
|securityPolicy|AFSecurityPolicy|建立安全会话时，使用的安全策略|
|reachabilityManager|AFNetworkReachabilityManager|网络状态管理器|
|tasks|`NSArray <NSURLSessionTask *>`|当前会话所关联的所有任务，包含数据请求、下载、上传任务|
|dataTasks|`NSArray <NSURLSessionDataTask *>`|当前会话所关联的数据请求任务|
|uploadTasks|`NSArray <NSURLSessionUploadTask *>`|当前会话所关联的上传任务|
|downloadTasks|`NSArray <NSURLSessionDownloadTask *>`|当前会话所关联的下载任务|
|completionQueue|`dispatch_queue_t`|指定 completionBlock 执行时的队列，默认 NULL ，使用主队列|
|completionGroup|`dispatch_group_t`|指定 completionBlock 相关联的组，默认 NULL ，将创建一个私有的组|
|attemptsToRecreateUploadTasksForBackgroundSessions|BOOL|指明当创建后台上传任务失败时，是否重新尝试创建，默认值为 NO|

下面为该类的内部属性

|属性|类型|含义|
|:---:|:---:|----|
|sessionConfiguration|NSURLSessionConfiguration|当前会话管理器用于创建会话的配置|
|mutableTaskDelegatesKeyedByTaskIdentifier|NSMutableDictionary|用于保存当前会话创建的任务与任务的代理对象的对应关系|
|taskDescriptionForSessionTasks|NSString|用于描述当前会话创建的任务（其实就是当前会话管理器的地址）|
|lock|NSLock|锁，操作 mutableTaskDelegatesKeyedByTaskIdentifier 时使用|

下面是一些回调代码块

1. NSURLSessionDelegate 协议中方法使用的回调代码块

	```
	//会话失效时的回调代码块
	@property (readwrite, nonatomic, copy) AFURLSessionDidBecomeInvalidBlock sessionDidBecomeInvalid;
	
	//连接服务器，接收到认证请求时，该回调代码块可以返回指定的认证选项
	@property (readwrite, nonatomic, copy) AFURLSessionDidReceiveAuthenticationChallengeBlock sessionDidReceiveAuthenticationChallenge;
	```

2. NSURLSessionTaskDelegate 协议中方法使用的回调代码块

	```
	//任务需要流传递数据给服务端时，该代码块可以返回一个输入流
	@property (readwrite, nonatomic, copy) AFURLSessionTaskNeedNewBodyStreamBlock taskNeedNewBodyStream;
	
	//接收到重定向反馈时，该代码块可以指定重定向的链接
	@property (readwrite, nonatomic, copy) AFURLSessionTaskWillPerformHTTPRedirectionBlock taskWillPerformHTTPRedirection;
	
	//当数据任务被要求进行证书加密时，该代码块可以指定相关选择项，如使用证书、默认处理、取消请求
	@property (readwrite, nonatomic, copy) AFURLSessionTaskDidReceiveAuthenticationChallengeBlock taskDidReceiveAuthenticationChallenge;
	
	//当数据上传时，该代码回调可以用来获取本次上传的字节数、已经上传的字节数、该任务需要上传的总字节数
	@property (readwrite, nonatomic, copy) AFURLSessionTaskDidSendBodyDataBlock taskDidSendBodyData;
	
	//当任务结束时，该代码回调会被执行，可以获取错误信息，如果有的话
	@property (readwrite, nonatomic, copy) AFURLSessionTaskDidCompleteBlock taskDidComplete;
	```

3. NSURLSessionDataDelegate 协议中方法使用的回调代码块

	```
	//当数据任务接收到服务器响应时，该回调可以选择取消或允许等选项
	@property (readwrite, nonatomic, copy) AFURLSessionDataTaskDidReceiveResponseBlock dataTaskDidReceiveResponse;
	
	//当数据任务将转变为数据下载任务时，该回调可以进行一些处理，回调参数中包含了原任务，和将要转变为的目标任务
	@property (readwrite, nonatomic, copy) AFURLSessionDataTaskDidBecomeDownloadTaskBlock dataTaskDidBecomeDownloadTask;
	
	//当接收到服务端数据时，该回调被执行
	@property (readwrite, nonatomic, copy) AFURLSessionDataTaskDidReceiveDataBlock dataTaskDidReceiveData;
	
	//将要缓存响应报文时，可以对返回的响应报文进行一些处理，回调参数中包含了 NSCachedURLResponse 的实例对象，也是即将返回的实例
	@property (readwrite, nonatomic, copy) AFURLSessionDataTaskWillCacheResponseBlock dataTaskWillCacheResponse;
	
	//当应用进入后台时创建的后台会话的相关任务均执行完毕时，该回调在主队列中被执行
	/**
	这里需要注意在 UIApplication 的下述方法中重新创建会话对象，注意使用 identifier 参数
	- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler NS_AVAILABLE_IOS(7_0);
	*/
	@property (readwrite, nonatomic, copy) AFURLSessionDidFinishEventsForBackgroundURLSessionBlock didFinishEventsForBackgroundURLSession;
	```

4. NSURLSessionDownloadDelegate 协议中方法使用的回调代码块

	```
	//当下载任务结束时，该回调代码块可以指定下载的缓存数据移动到的目标地址
	@property (readwrite, nonatomic, copy) AFURLSessionDownloadTaskDidFinishDownloadingBlock downloadTaskDidFinishDownloading;
	
	//在数据下载的过程中，该回调会被调用，其参数包含有本次下载的数据字节数、已经下载的字节数、该任务需要下载的总字节数
	@property (readwrite, nonatomic, copy) AFURLSessionDownloadTaskDidWriteDataBlock downloadTaskDidWriteData;
	
	//当下载任务再次启动时，该回调执行，回调参数包含有文件的字节偏移量和整个文件的字节长度
	@property (readwrite, nonatomic, copy) AFURLSessionDownloadTaskDidResumeBlock downloadTaskDidResume;
	```

这些回调代码块都是在 AFURLSessionManager 实现的代理方法中调用的，所以其都是在自定义队列中执行的（除了 didFinishEventsForBackgroundURLSession）所以，如果有需要在主队列中执行的回调，那么需要在创建代码时注意指定主队列。

这些代码块属性都是内部属性，每一个都声明了相应的赋值方法。

### AFURLSessionManager 中的方法

1. 初始化实例对象方法
	
	```
	- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;
	```
	在该方法中，如果入参 configuration 为 nil ，则调用 NSURLSessionConfiguration 的 defaultSessionConfiguration 方法创建一个作为会话配置，并使用该配置创建一个会话对象，并设置会话对象的代理为该会话管理器，创建代理方法的执行队列。
	
	另外，还初始化了安全策略、锁、返回数据解析器（JSON 数据解析器）等属性。

2. 取消会话 session 对象
	
	```
	- (void)invalidateSessionCancelingTasks:(BOOL)cancelPendingTasks;
	```
	如果参数 cancelPendingTasks 为 YES ，那么直接取消会话，其相关联的任务和回调代码等都释放；如果为 NO ，则允许会话中的任务执行完毕后，再取消会话，会话一经取消将无法重启。

3. 创建数据任务

	```
	- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
	                               uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgressBlock
	                             downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgressBlock
	                            completionHandler:(nullable void (^)(NSURLResponse *response, id _Nullable responseObject,  NSError * _Nullable error))completionHandler {
	
	    __block NSURLSessionDataTask *dataTask = nil;
	    url_session_manager_create_task_safely(^{
	        dataTask = [self.session dataTaskWithRequest:request];
	    });
	
	    [self addDelegateForDataTask:dataTask uploadProgress:uploadProgressBlock downloadProgress:downloadProgressBlock completionHandler:completionHandler];
	
	    return dataTask;
	}
	```
	
	这里在使用会话对象 session 和入参 request 创建任务时，如果 **NSFoundationVersionNumber** 的值小于 **`NSFoundationVersionNumber_iOS_8_0`** 那么 dataTask 的创建会放在 **`af_url_session_manager_creation_queue`** 串行队列中同步执行，否则就由当前线程执行。接着，会调用下面的方法：
	
	```
	- (void)addDelegateForDataTask:(NSURLSessionDataTask *)dataTask
	                uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgressBlock
	              downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgressBlock
	             completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
	{
	    AFURLSessionManagerTaskDelegate *delegate = [[AFURLSessionManagerTaskDelegate alloc] initWithTask:dataTask];
	    delegate.manager = self;
	    delegate.completionHandler = completionHandler;
	
	    dataTask.taskDescription = self.taskDescriptionForSessionTasks;
	    [self setDelegate:delegate forTask:dataTask];
	
	    delegate.uploadProgressBlock = uploadProgressBlock;
	    delegate.downloadProgressBlock = downloadProgressBlock;
	}
	```
	在这个方法中，会创建一个 AFURLSessionManagerTaskDelegate 对象，设置其相关联的管理器、任务描述（会话地址）、结束回调、上传回调、下载回调等属性，并且使用当前任务的 **taskIdentifier** 标识（通常从 1 开始，并在生成该任务的会话中是唯一的）同该 AFURLSessionManagerTaskDelegate 对象作为一个映射关系保存在会话 session 的 **mutableTaskDelegatesKeyedByTaskIdentifier** 字典中。
	
	 除此之外，还会将当前会话注册为监听者，监听 task 任务发出的 **AFNSURLSessionTaskDidResumeNotification** 和 **AFNSURLSessionTaskDidSuspendNotification** 通知。当接收到该通知后，分别执行 **taskDidResume:** 和 **taskDidSuspend:** 方法，在这两个方法中又发出了 **AFNetworkingTaskDidResumeNotification** 和 **AFNetworkingTaskDidSuspendNotification** 通知。

4. 创建数据任务，不指定上传和下载回调代码块

	```
	- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
	                            completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
	{
	    return [self dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:completionHandler];
	}
	```
	这个方法其实是调用了上一个方法，只是参数 uploadProgressBlock 和 downloadProgressBlock 传 nil 。

5. 创建文件上传任务

	```
	- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
	                                         fromFile:(NSURL *)fileURL
	                                         progress:(void (^)(NSProgress *uploadProgress)) uploadProgressBlock
	                                completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
	{
	    __block NSURLSessionUploadTask *uploadTask = nil;
	    url_session_manager_create_task_safely(^{
	        uploadTask = [self.session uploadTaskWithRequest:request fromFile:fileURL];
	    });
	
	    // uploadTask may be nil on iOS7 because uploadTaskWithRequest:fromFile: may return nil despite being documented as nonnull (https://devforums.apple.com/message/926113#926113)
	    if (!uploadTask && self.attemptsToRecreateUploadTasksForBackgroundSessions && self.session.configuration.identifier) {
	        for (NSUInteger attempts = 0; !uploadTask && attempts < AFMaximumNumberOfAttemptsToRecreateBackgroundSessionUploadTask; attempts++) {
	            uploadTask = [self.session uploadTaskWithRequest:request fromFile:fileURL];
	        }
	    }
	
	    [self addDelegateForUploadTask:uploadTask progress:uploadProgressBlock completionHandler:completionHandler];
	
	    return uploadTask;
	}
	```
	在该方法中，如果后台会话对象创建文件上传任务失败时，会根据条件尝试重新创建，当然 **AFMaximumNumberOfAttemptsToRecreateBackgroundSessionUploadTask** 为 3 ，所以只能尝试 3 次。如果任务创建成功，则进而为任务创建一个 AFURLSessionManagerTaskDelegate 对象，作为任务的代理。
	
	请求报文的请求体数据即为根据参数 fileURL 获取的文件数据。

6. 创建数据上传任务

	```
	- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
	                                         fromData:(NSData *)bodyData
	                                         progress:(void (^)(NSProgress *uploadProgress)) uploadProgressBlock
	                                completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
	{
	    __block NSURLSessionUploadTask *uploadTask = nil;
	    url_session_manager_create_task_safely(^{
	        uploadTask = [self.session uploadTaskWithRequest:request fromData:bodyData];
	    });
	
	    [self addDelegateForUploadTask:uploadTask progress:uploadProgressBlock completionHandler:completionHandler];
	
	    return uploadTask;
	}
	```
	该方法上传数据，与上传文件类似，但待上传的数据直接由参数 bodyData 给出。

7. 创建上传流任务

	```
	- (NSURLSessionUploadTask *)uploadTaskWithStreamedRequest:(NSURLRequest *)request
	                                                 progress:(void (^)(NSProgress *uploadProgress)) uploadProgressBlock
	                                        completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
	{
	    __block NSURLSessionUploadTask *uploadTask = nil;
	    url_session_manager_create_task_safely(^{
	        uploadTask = [self.session uploadTaskWithStreamedRequest:request];
	    });
	
	    [self addDelegateForUploadTask:uploadTask progress:uploadProgressBlock completionHandler:completionHandler];
	
	    return uploadTask;
	}
	```
	这里直接使用指定的请求报文头创建一个流任务，然后将任务与代理对象的关系保存到映射表中。

8. 创建下载任务

	```
	- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
	                                             progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
	                                          destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
	                                    completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
	{
	    __block NSURLSessionDownloadTask *downloadTask = nil;
	    url_session_manager_create_task_safely(^{
	        downloadTask = [self.session downloadTaskWithRequest:request];
	    });
	
	    [self addDelegateForDownloadTask:downloadTask progress:downloadProgressBlock destination:destination completionHandler:completionHandler];
	
	    return downloadTask;
	}
	```
	
	* request 创建任务时使用的请求报文头信息
	* downloadProgressBlock 下载进度更新时调用的代码块，这个代码会在会话队列中调用，所以如果更新视图，需要自己在任务代码中指定主队列
	* destination 任务下载结束后，该参数可以返回指定的文件保存地址，缓存数据被移动到该地址，targetPath 为下载的数据缓存地址
	* completionHandler 下载任务结束后的回调
	
	在该方法中，使用 request 创建一个下载任务后，调用下面的方法：
	
	```
	- (void)addDelegateForDownloadTask:(NSURLSessionDownloadTask *)downloadTask
	                          progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
	                       destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
	                 completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
	{
	    AFURLSessionManagerTaskDelegate *delegate = [[AFURLSessionManagerTaskDelegate alloc] initWithTask:downloadTask];
	    delegate.manager = self;
	    delegate.completionHandler = completionHandler;
	
	    if (destination) {
	        delegate.downloadTaskDidFinishDownloading = ^NSURL * (NSURLSession * __unused session, NSURLSessionDownloadTask *task, NSURL *location) {
	            return destination(location, task.response);
	        };
	    }
	
	    downloadTask.taskDescription = self.taskDescriptionForSessionTasks;
	
	    [self setDelegate:delegate forTask:downloadTask];
	
	    delegate.downloadProgressBlock = downloadProgressBlock;
	}
	```
	与上面创建任务代理对象的方法类似，只是这里多出来一个为 **downloadTaskDidFinishDownloading** 赋值的步骤，这个代码块会在下载数据结束时用于获取数据的保存地址。

9. 创建重用数据的下任务

	```
	- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData
	                                                progress:(NSProgress * __autoreleasing *)progress
	                                             destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
	                                       completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
	{
	    __block NSURLSessionDownloadTask *downloadTask = nil;
	    dispatch_sync(url_session_manager_creation_queue(), ^{
	        downloadTask = [self.session downloadTaskWithResumeData:resumeData];
	    });
	
	    [self addDelegateForDownloadTask:downloadTask progress:progress destination:destination completionHandler:completionHandler];
	
	    return downloadTask;
	}
	```
	使用已经下载的部分数据 **resumeData** 创建一个下载任务，继续进行下载。

10. 获取任务的数据上传进度

	`- (nullable NSProgress *)uploadProgressForTask:(NSURLSessionTask *)task;`

11. 获取任务的数据下载进度

	`- (nullable NSProgress *)downloadProgressForTask:(NSURLSessionTask *)task;`

	该方法和上一个方法，都会调用下面的方法获取任务的代理对象，进而获取相应的进度信息。

	```
	- (AFURLSessionManagerTaskDelegate *)delegateForTask:(NSURLSessionTask *)task {
	    NSParameterAssert(task);
	
	    AFURLSessionManagerTaskDelegate *delegate = nil;
	    [self.lock lock];
	    delegate = self.mutableTaskDelegatesKeyedByTaskIdentifier[@(task.taskIdentifier)];
	    [self.lock unlock];
	
	    return delegate;
	}
	```

### AFURLSessionManager 中实现的代理方法
AFURLSessionManager 遵循 **NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate** 协议，以处理网络请求过程中的数据。

有些代理方法中所做的任务，完全由 AFURLSessionManager 的代码块属性决定。如果这些属性并没有设置，那么相应的代理方法就没必要响应。所以 AFURLSessionManager 中重写了 **respondsToSelector:** 过滤了一些不必响应的代理方法。

```
- (BOOL)respondsToSelector:(SEL)selector {
    if (selector == @selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)) {
        return self.taskWillPerformHTTPRedirection != nil;
    } else if (selector == @selector(URLSession:dataTask:didReceiveResponse:completionHandler:)) {
        return self.dataTaskDidReceiveResponse != nil;
    } else if (selector == @selector(URLSession:dataTask:willCacheResponse:completionHandler:)) {
        return self.dataTaskWillCacheResponse != nil;
    } else if (selector == @selector(URLSessionDidFinishEventsForBackgroundURLSession:)) {
        return self.didFinishEventsForBackgroundURLSession != nil;
    }

    return [[self class] instancesRespondToSelector:selector];
}
```

#### NSURLSessionDelegate

```
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    if (self.sessionDidBecomeInvalid) {
        self.sessionDidBecomeInvalid(session, error);
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:AFURLSessionDidInvalidateNotification object:session];
}
```
会话将要失效时，在这个方法中调用 sessionDidBecomeInvalid 回调，并发送一个 **AFURLSessionDidInvalidateNotification** 通知。

当会话连接，接收到服务端的加密要求时，执行下面的代理方法。

```
- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
	//首先选择默认的处理方式
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    
    //用于保存服务端返回的证书
    __block NSURLCredential *credential = nil;

    if (self.sessionDidReceiveAuthenticationChallenge) {
        //返回自己的处理方式
        disposition = self.sessionDidReceiveAuthenticationChallenge(session, challenge, &credential);
    } else {
        
        //如果对保护空间的验证方式不是 NSURLAuthenticationMethodServerTrust 则选择 NSURLSessionAuthChallengePerformDefaultHandling 处理方式
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            
            //如果校验返回的证书不通过，那么选择 NSURLSessionAuthChallengeCancelAuthenticationChallenge ，即取消会话
            if ([self.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                if (credential) {
                    disposition = NSURLSessionAuthChallengeUseCredential;
                } else {
                    disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                }
            } else {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
    }

    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}
```

当应用进入后台，方法 `-application:handleEventsForBackgroundURLSession:completionHandler:` 执行，根据 identifier 入参创建适用于后台的会话对象，当所有与会话相关联的任务均已执行后，会话代理会接收到 **URLSessionDidFinishEventsForBackgroundURLSession:** 消息，从而进行一些回调操作。

```
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    if (self.didFinishEventsForBackgroundURLSession) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.didFinishEventsForBackgroundURLSession(session);
        });
    }
}
```

#### NSURLSessionTaskDelegate
该方法进行重定向，完全是执行了属性 taskWillPerformHTTPRedirection 设置的代码块任务。

```
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler
```

该方法

```
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler;
```

同上述 NSURLSessionDelegate 协议中实现的下述方法类似。

```
- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler;
```

其他方法参见如下源码：

```
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler
{
    NSInputStream *inputStream = nil;

    if (self.taskNeedNewBodyStream) {
        inputStream = self.taskNeedNewBodyStream(session, task);
    } else if (task.originalRequest.HTTPBodyStream && [task.originalRequest.HTTPBodyStream conformsToProtocol:@protocol(NSCopying)]) {
        inputStream = [task.originalRequest.HTTPBodyStream copy];
    }

    if (completionHandler) {
        completionHandler(inputStream);
    }
}
```

```
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{

    int64_t totalUnitCount = totalBytesExpectedToSend;
    if(totalUnitCount == NSURLSessionTransferSizeUnknown) {
        NSString *contentLength = [task.originalRequest valueForHTTPHeaderField:@"Content-Length"];
        if(contentLength) {
            totalUnitCount = (int64_t) [contentLength longLongValue];
        }
    }
    
    AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:task];
    
    if (delegate) {
        [delegate URLSession:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
    }

    if (self.taskDidSendBodyData) {
        self.taskDidSendBodyData(session, task, bytesSent, totalBytesSent, totalUnitCount);
    }
}
```

```
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:task];

    // delegate may be nil when completing a task in the background
    if (delegate) {
        [delegate URLSession:session task:task didCompleteWithError:error];

        [self removeDelegateForTask:task];
    }

    if (self.taskDidComplete) {
        self.taskDidComplete(session, task, error);
    }
}
```

#### NSURLSessionDataDelegate

```
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:dataTask];
    if (delegate) {
        [self removeDelegateForTask:dataTask];
        [self setDelegate:delegate forTask:downloadTask];
    }

    if (self.dataTaskDidBecomeDownloadTask) {
        self.dataTaskDidBecomeDownloadTask(session, dataTask, downloadTask);
    }
}
```
这个方法中，会先获取原任务的代理，并将这个代理设置为新任务的代理，其他协议方法不再赘述（[参见源码](https://github.com/AFNetworking/AFNetworking/blob/master/AFNetworking/AFURLSessionManager.m)）。


#### NSURLSessionDownloadDelegate
当下载任务结束后，调用该代理方法。

```
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    //获取与任务相对应的代理对象
    AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:downloadTask];
    
    //如果设置了回调任务，先执行回调任务
    if (self.downloadTaskDidFinishDownloading) {
        
        //获取下载数据要保存的地址        
        NSURL *fileURL = self.downloadTaskDidFinishDownloading(session, downloadTask, location);
        if (fileURL) {
            delegate.downloadFileURL = fileURL;
            NSError *error = nil;
            
            //移动下载的数据到指定地址
            if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:fileURL error:&error]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:AFURLSessionDownloadTaskDidFailToMoveFileNotification object:downloadTask userInfo:error.userInfo];
            }

            return;
        }
    }

    if (delegate) {
        [delegate URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
    }
}
```
从上面的代码可知，如果会话管理器的 downloadTaskDidFinishDownloading 的代码块返回了地址，那么便不会去执行任务本身所对应的代理方法了，并且如果移动文件失败便会推送一个 **AFURLSessionDownloadTaskDidFailToMoveFileNotification** 通知。

下面两个协议方法中，都是先执行任务所关联的代理对象的方法，再执行会话对象设置的 **downloadTaskDidWriteData** 或 **downloadTaskDidResume** 任务。

```
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes;
```

> 从这些代理方法中可知，设置 AFURLSessionManager 会话实例对象的代码块任务属性，那么这些回调任务对于每一个网络请求任务都是有效的，所以针对于单个特殊的任务回调操作，便不能放在会话管理器的属性中，而是要放在与任务相关联的 AFURLSessionManagerTaskDelegate 代理对象中。

> 实际使用 AFURLSessionManager 的方法创建网络请求任务时，传递的回调任务，都是在与任务相关联的代理对象的方法中执行的。
 

## AFURLSessionManagerTaskDelegate
AFURLSessionManagerTaskDelegate 是个内部类，完全用于会话管理器内部，创建网络任务时，会相应的为该任务创建一个该对象作为其代理对象，其遵循 **NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate** 协议，实现的协议方法，在会话管理器实现的相应协议方法中被调用。

### AFURLSessionManagerTaskDelegate 中的属性

|属性|类型|含义|
|:---:|:---:|---|
|manager|AFURLSessionManager|与该代理对象相关联的会话管理器|
|mutableData|NSMutableData|用于保存在 NSURLSessionDataDelegate 协议方法中接收到的数据|
|uploadProgress|NSProgress|上传进度|
|downloadProgress|NSProgress|下载进度|
|downloadFileURL|NSURL|下载文件的存储路径|

```
//下载结束时，用于获取数据保存路径，其返回值会赋给 downloadFileURL
@property (nonatomic, copy) AFURLSessionDownloadTaskDidFinishDownloadingBlock downloadTaskDidFinishDownloading;

//uploadProgress.fractionCompleted 变化时的回调任务
@property (nonatomic, copy) AFURLSessionTaskProgressBlock uploadProgressBlock;

//downloadProgress.fractionCompleted 变化时的回调任务
@property (nonatomic, copy) AFURLSessionTaskProgressBlock downloadProgressBlock;

//任务结束时的回调，如果 manager.completionQueue 值为 NULL 则，该任务在主队列中执行
@property (nonatomic, copy) AFURLSessionTaskCompletionHandler completionHandler;
```

### AFURLSessionManagerTaskDelegate 中的方法

```
- (instancetype)initWithTask:(NSURLSessionTask *)task {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _mutableData = [NSMutableData data];
    _uploadProgress = [[NSProgress alloc] initWithParent:nil userInfo:nil];
    _downloadProgress = [[NSProgress alloc] initWithParent:nil userInfo:nil];
    
    __weak __typeof__(task) weakTask = task;
    for (NSProgress *progress in @[ _uploadProgress, _downloadProgress ])
    {
        progress.totalUnitCount = NSURLSessionTransferSizeUnknown;
        progress.cancellable = YES;
        progress.cancellationHandler = ^{
            [weakTask cancel];
        };
        progress.pausable = YES;
        progress.pausingHandler = ^{
            [weakTask suspend];
        };
        if ([progress respondsToSelector:@selector(setResumingHandler:)]) {
            progress.resumingHandler = ^{
                [weakTask resume];
            };
        }
        [progress addObserver:self
                   forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
    }
    return self;
}
```
在这个初始化方法中，主要为上传和下载进度进行了取消、暂停、重启的设置，并为它们的 **fractionCompleted** 属性值注册了监听者，即当前代理对象。

下面是 KVO 模式的监听响应方法，执行了相应的回调任务。

```
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
   if ([object isEqual:self.downloadProgress]) {
        if (self.downloadProgressBlock) {
            self.downloadProgressBlock(object);
        }
    }
    else if ([object isEqual:self.uploadProgress]) {
        if (self.uploadProgressBlock) {
            self.uploadProgressBlock(object);
        }
    }
}
```

### AFURLSessionManagerTaskDelegate 中实现的代理方法
#### NSURLSessionDataDelegate
在实现该协议的方法中，主要是修改了上传和下载进度以及保存接收的数据。

```
- (void)URLSession:(__unused NSURLSession *)session
          dataTask:(__unused NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    self.downloadProgress.totalUnitCount = dataTask.countOfBytesExpectedToReceive;
    self.downloadProgress.completedUnitCount = dataTask.countOfBytesReceived;

    [self.mutableData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    
    self.uploadProgress.totalUnitCount = task.countOfBytesExpectedToSend;
    self.uploadProgress.completedUnitCount = task.countOfBytesSent;
}
```

#### NSURLSessionDownloadDelegate

文件下载的过程中，下面的代理方法可能不止一次被调用，而其主要任务也是修改下载进度。

```
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    self.downloadProgress.totalUnitCount = totalBytesExpectedToWrite;
    self.downloadProgress.completedUnitCount = totalBytesWritten;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes{
    
    self.downloadProgress.totalUnitCount = expectedTotalBytes;
    self.downloadProgress.completedUnitCount = fileOffset;
}
```

在这个方法中，首先将 downloadFileURL 属性置为 nil ，并且 downloadTaskDidFinishDownloading 代码块必需要返回数据的保存地址，而后才能将文件从缓存空间移动到指定的位置，如果移动出错，也会推送 **AFURLSessionDownloadTaskDidFailToMoveFileNotification** 通知。

```
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    self.downloadFileURL = nil;

    if (self.downloadTaskDidFinishDownloading) {
        self.downloadFileURL = self.downloadTaskDidFinishDownloading(session, downloadTask, location);
        if (self.downloadFileURL) {
            NSError *fileManagerError = nil;

            if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:self.downloadFileURL error:&fileManagerError]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:AFURLSessionDownloadTaskDidFailToMoveFileNotification object:downloadTask userInfo:fileManagerError.userInfo];
            }
        }
    }
}
```

需要注意的是，如果 manager 管理器的 downloadTaskDidFinishDownloading 任务代码块能够返回保存地址，那么上述方法便不会被调用，所以对于多个文件同时下载，并且都需要更新下载进度或其他操作时，注意应将 downloadTaskDidFinishDownloading 设置为 nil 。

#### NSURLSessionTaskDelegate
该类只实现了 NSURLSessionTaskDelegate 协议中的一个方法（排除继承的协议中的方法），首先构造 userInfo 用于回传信息，字典中的信息如下：

|键名称|值含义|
|:---:|---|
|AFNetworkingTaskDidCompleteResponseSerializerKey|会话管理器 manager 的解析器 responseSerializer |
|AFNetworkingTaskDidCompleteAssetPathKey|文件地址|
AFNetworkingTaskDidCompleteResponseDataKey|数据|
AFNetworkingTaskDidCompleteErrorKey|下载任务过程中的报错信息|
AFNetworkingTaskDidCompleteSerializedResponseKey|解析器的解析结果，如果是下载任务，则为文件保存地址|
AFNetworkingTaskDidCompleteErrorKey|解析器解析数据过程中的报错信息|

当任务是因发生错误而结束时，直接调用 completionHandler 回调。

当任务正常结束时，那么会话管理器 manager 的解析器 responseSerializer 便会调用解析方法对接收的报文数据进行解析，并返回解析结果。而后，将该解析结果传给 completionHandler 回调任务。

另外，调用 completionHandler 回调之后，还会在主线程中推送了一个 AFNetworkingTaskDidCompleteNotification 通知，其携带 userInfo 信息。

参见下面的源码：

```
- (void)URLSession:(__unused NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    __strong AFURLSessionManager *manager = self.manager;

    __block id responseObject = nil;

    __block NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[AFNetworkingTaskDidCompleteResponseSerializerKey] = manager.responseSerializer;

    //Performance Improvement from #2672
    NSData *data = nil;
    if (self.mutableData) {
        data = [self.mutableData copy];
        //We no longer need the reference, so nil it out to gain back some memory.
        self.mutableData = nil;
    }

    if (self.downloadFileURL) {
        userInfo[AFNetworkingTaskDidCompleteAssetPathKey] = self.downloadFileURL;
    } else if (data) {
        userInfo[AFNetworkingTaskDidCompleteResponseDataKey] = data;
    }

    if (error) {
        userInfo[AFNetworkingTaskDidCompleteErrorKey] = error;

        dispatch_group_async(manager.completionGroup ?: url_session_manager_completion_group(), manager.completionQueue ?: dispatch_get_main_queue(), ^{
            if (self.completionHandler) {
                self.completionHandler(task.response, responseObject, error);
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingTaskDidCompleteNotification object:task userInfo:userInfo];
            });
        });
    } else {
        dispatch_async(url_session_manager_processing_queue(), ^{
            NSError *serializationError = nil;
            responseObject = [manager.responseSerializer responseObjectForResponse:task.response data:data error:&serializationError];

            if (self.downloadFileURL) {
                responseObject = self.downloadFileURL;
            }

            if (responseObject) {
                userInfo[AFNetworkingTaskDidCompleteSerializedResponseKey] = responseObject;
            }

            if (serializationError) {
                userInfo[AFNetworkingTaskDidCompleteErrorKey] = serializationError;
            }

            dispatch_group_async(manager.completionGroup ?: url_session_manager_completion_group(), manager.completionQueue ?: dispatch_get_main_queue(), ^{
                if (self.completionHandler) {
                    self.completionHandler(task.response, responseObject, serializationError);
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingTaskDidCompleteNotification object:task userInfo:userInfo];
                });
            });
        });
    }
}
```

----

##### 类型定义参考

```
typedef void (^AFURLSessionDidBecomeInvalidBlock)(NSURLSession *session, NSError *error);
typedef NSURLSessionAuthChallengeDisposition (^AFURLSessionDidReceiveAuthenticationChallengeBlock)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential);

typedef NSURLRequest * (^AFURLSessionTaskWillPerformHTTPRedirectionBlock)(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request);
typedef NSURLSessionAuthChallengeDisposition (^AFURLSessionTaskDidReceiveAuthenticationChallengeBlock)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential);
typedef void (^AFURLSessionDidFinishEventsForBackgroundURLSessionBlock)(NSURLSession *session);

typedef NSInputStream * (^AFURLSessionTaskNeedNewBodyStreamBlock)(NSURLSession *session, NSURLSessionTask *task);
typedef void (^AFURLSessionTaskDidSendBodyDataBlock)(NSURLSession *session, NSURLSessionTask *task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend);
typedef void (^AFURLSessionTaskDidCompleteBlock)(NSURLSession *session, NSURLSessionTask *task, NSError *error);

typedef NSURLSessionResponseDisposition (^AFURLSessionDataTaskDidReceiveResponseBlock)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response);
typedef void (^AFURLSessionDataTaskDidBecomeDownloadTaskBlock)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLSessionDownloadTask *downloadTask);
typedef void (^AFURLSessionDataTaskDidReceiveDataBlock)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data);
typedef NSCachedURLResponse * (^AFURLSessionDataTaskWillCacheResponseBlock)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSCachedURLResponse *proposedResponse);

typedef NSURL * (^AFURLSessionDownloadTaskDidFinishDownloadingBlock)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location);
typedef void (^AFURLSessionDownloadTaskDidWriteDataBlock)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);
typedef void (^AFURLSessionDownloadTaskDidResumeBlock)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t fileOffset, int64_t expectedTotalBytes);
typedef void (^AFURLSessionTaskProgressBlock)(NSProgress *);

typedef void (^AFURLSessionTaskCompletionHandler)(NSURLResponse *response, id responseObject, NSError *error);
```

