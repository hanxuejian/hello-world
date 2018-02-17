## AFHTTPSessionManager
在 AFNetworking 框架中创建网络请求任务时，除了使用 **AFURLSessionManager** 中的方法外，还可以直接使用其子类 **AFHTTPSessionManager** 创建 HTTP 请求任务。

在使用该类创建网络任务时，与使用父类 AFURLSessionManager 创建任务，需要提供 NSURLRequest 请求报文参数不同的是，AFHTTPSessionManager 的属性中有请求报文构造器，可以根据传入的参数构造 NSURLRequest 对象。

### AFHTTPSessionManager 的属性

* **`@property (readonly, nonatomic, strong, nullable) NSURL *baseURL;`** 

	在构造 NSURLRequest 对象时使用的路径，设置该路径后，之后创建任务时，传入的路径参数都会拼接到该路径后。

* **`@property (nonatomic, strong) AFHTTPRequestSerializer <AFURLRequestSerialization> * requestSerializer;`**
	
	构造请求报文的构造器，默认为 `AFHTTPRequestSerializer` 实例对象。

* **`@property (nonatomic, strong) AFHTTPResponseSerializer <AFURLResponseSerialization> * responseSerializer;`**

	返回报文解析器，默认为 `AFJSONResponseSerializer` 实例对象。

* **`@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;`**

	创建会话时，用来校验服务器的安全策略，如果对于非安全的连接使用了安全策略，则会抛出异常。

### AFHTTPSessionManager 的方法
1. 创建实例对象的类方法

	```
	+ (instancetype)manager {
		return [[[self class] alloc] initWithBaseURL:nil];
	}
	```
	该类方法创建一个 baseURL 属性为 nil 的实例对象。

2. 初始化方法

	```
	- (instancetype)init {
	    return [self initWithBaseURL:nil];
	}
	- (instancetype)initWithBaseURL:(NSURL *)url {
	    return [self initWithBaseURL:url sessionConfiguration:nil];
	}

	- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
		return [self initWithBaseURL:nil sessionConfiguration:configuration];
	}
	```
	上述的这些方法始终绕不过下面这个方法，要么只提供 baseURL 参数，要么只提供创建会话时使用的配置信息。
	
	```
	- (instancetype)initWithBaseURL:(NSURL *)url
	           sessionConfiguration:(NSURLSessionConfiguration *)configuration
	{
		self = [super initWithSessionConfiguration:configuration];
		if (!self) {
		    return nil;
		}
		
		//这里会判断参数 url 是否是以 “/” 符号结尾，如果不是，则调用方法使其符合预期
		if ([[url path] length] > 0 && ![[url absoluteString] hasSuffix:@"/"]) {
		    url = [url URLByAppendingPathComponent:@""];
		}
		
		self.baseURL = url;
		
		self.requestSerializer = [AFHTTPRequestSerializer serializer];
		self.responseSerializer = [AFJSONResponseSerializer serializer];
		
		return self;
	}
	```
	在这个方法中，还初始化了请求报文构造器和响应报文解析器。
	
3. 创建任务方法

	AFHTTPSessionManager 类中提供了创建任务的方法，其支持的请求方式为：GET、HEAD、POST、PUT、PATCH、DELETE，相关方法的名称都以这几个方式名称开始。
	
	创建任务的方法都很类似，主要是下面的方法，注意这个方法不能被外部调用。
	
	```
	
	- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
	                                       URLString:(NSString *)URLString
	                                      parameters:(id)parameters
	                                  uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgress
	                                downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgress
	                                         success:(void (^)(NSURLSessionDataTask *, id))success
	                                         failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
	{
	    NSError *serializationError = nil;
	    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:&serializationError];
	    if (serializationError) {
	        if (failure) {
	            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
	                failure(nil, serializationError);
	            });
	        }
	
	        return nil;
	    }
	
	    __block NSURLSessionDataTask *dataTask = nil;
	    dataTask = [self dataTaskWithRequest:request
	                          uploadProgress:uploadProgress
	                        downloadProgress:downloadProgress
	                       completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
	        if (error) {
	            if (failure) {
	                failure(dataTask, error);
	            }
	        } else {
	            if (success) {
	                success(dataTask, responseObject);
	            }
	        }
	    }];
	
	    return dataTask;
	}
	```
	在这个方法中先使用传入的请求方式、地址、参数和会话管理器的 requestSerializer 属性创建一个 NSMutableURLRequest 实例对象，然后调用下面的方法创建 NSURLSessionDataTask 任务。
	
	```
	- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
	                               uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgressBlock
	                             downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgressBlock
	                            completionHandler:(nullable void (^)(NSURLResponse *response, id _Nullable responseObject,  NSError * _Nullable error))completionHandler;
	```
	其实这个方法是在父类中声明和实现的，另外，还可以使用下面的方法，构造一个含有报文体数据的报文请求。
	
	```
	- (NSURLSessionDataTask *)POST:(NSString *)URLString
	                    parameters:(id)parameters
	     constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
	                      progress:(nullable void (^)(NSProgress * _Nonnull))uploadProgress
	                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
	                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
	{
	    NSError *serializationError = nil;
	    NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters constructingBodyWithBlock:block error:&serializationError];
	    if (serializationError) {
	        if (failure) {
	            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
	                failure(nil, serializationError);
	            });
	        }
	
	        return nil;
	    }
	
	    __block NSURLSessionDataTask *task = [self uploadTaskWithStreamedRequest:request progress:uploadProgress completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
	        if (error) {
	            if (failure) {
	                failure(task, error);
	            }
	        } else {
	            if (success) {
	                success(task, responseObject);
	            }
	        }
	    }];
	
	    [task resume];
	
	    return task;
	}
	```
	该方法也是先使用 requestSerializer 属性创建 NSMutableURLRequest 实例，而后调用父类中声明的方法创建一个任务。

