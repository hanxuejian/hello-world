## AFSecurityPolicy
在 AFNetworking 框架中，可以使用 AFSecurityPolicy 类来设置 SSL 安全连接时的校验策略。在客户端应用中添加遵循 X.509 标准的数字证书，
并在与服务器建立安全连接时校验服务器传递的安全信息，这种方式可以有效避免中间人攻击等风险。

AFSecurityPolicy 的校验选项 AFSSLPinningMode 有三种：

* **AFSSLPinningModeNone** 在与服务器建立安全连接时，并不会使用应用中已有的证书（也可能本就没有）对服务器传递的信息进行校验，此为默认选项
* **AFSSLPinningModePublicKey** 使用应用中已有的公钥对服务器传递的信息进行校验
* **AFSSLPinningModeCertificate** 使用应用中已有的数字证书对服务器传递的信息进行校验

### 属性

|属性名称|属性类型|属性含义|
|:---:|:---:|----|
| SSLPinningMode | AFSSLPinningMode |校验策略|
|pinnedCertificates|`NSSet <NSData *>`|本地证书|
|pinnedPublicKeys|NSSet|本地证书所包含的公钥|
|allowInvalidCertificates|BOOL|是否信任证书是无效或过期的服务器，默认值为 NO|
|validatesDomainName| BOOL |是否校验证书中 CN 字段中的域名，默认值为 YES|

### 方法
1. 创建默认的安全策略

	`+ (instancetype)defaultPolicy;`
	
	在这个方法中，将 SSLPinningMode 的值设置为 AFSSLPinningModeNone 。

2. 创建指定校验模式的安全策略

	```
	+ (instancetype)policyWithPinningMode:(AFSSLPinningMode)pinningMode {
	    return [self policyWithPinningMode:pinningMode withPinnedCertificates:[self defaultPinnedCertificates]];
	}
	```
	这个类的方法，实际是调用了下面的方法返回一个策略，只是其所提供参数，表示的是默认当前类名包下的所有证书，
	如果没有名为 AFSecurityPolicy 的包，那么则没有本地证书以供校验时使用。

3. 创建指定校验模式和证书的安全策略

	```
	+ (instancetype)policyWithPinningMode:(AFSSLPinningMode)pinningMode withPinnedCertificates:(NSSet *)pinnedCertificates;
	```
	这个方法，完全由调用者自己提供校验选项和证书数据。

4. 获取指定包中的证书数据

	`+ (NSSet <NSData *> *)certificatesInBundle:(NSBundle *)bundle;`
	该方法可以很方便的获取指定包 bundle 中的证书数据，结合上一个方法，则创建安全策略实例对象十分方便。

5. 校验服务器传递的安全信息

	`- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forDomain:(nullable NSString *)domain;`
	这个方法会根据当前策略来判断接收的服务器的安全信息是否有效，域名参数 domain 如果未传递，则不对其进行校验。如果要校验自签名证书的域名，那么本地应包含该证书并且校验策略不能是 AFSSLPinningModeNone 选项。
	
	```
	NSMutableArray *policies = [NSMutableArray array];
	if (self.validatesDomainName) {
	    [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
	} else {
	    [policies addObject:(__bridge_transfer id)SecPolicyCreateBasicX509()];
	}
	
	SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);
	```
	从上面的源代码可知，如果不对域名进行校验，便会创建 X.509 标准的默认校验策略，而后，将策略与服务器传递的安全信息 serverTrust 相关联。
	
	接着执行下面的代码：
	
	```
	if (self.SSLPinningMode == AFSSLPinningModeNone) {
	    return self.allowInvalidCertificates || AFServerTrustIsValid(serverTrust);
	} else if (!AFServerTrustIsValid(serverTrust) && !self.allowInvalidCertificates) {
	    return NO;
	}
	```
	这里有点绕，如果策略选项为 AFSSLPinningModeNone ，那么分了两种情况，一种是，若 allowInvalidCertificates 属性值为 YES ，
	即客户端信任无效或过期的证书（可能是自签名证书），那么，客户端则认为服务器是可信的。
	另一种，则是调用 AFServerTrustIsValid 函数校验服务器传递的安全信息 serverTrust 是否是有效的。
	
	如果策略选项不是 AFSSLPinningModeNone 并且 AFServerTrustIsValid 校验未通过，而客户端也不信任无效或过期的证书，那么则认为所连接的服务器不可信。
	
	再接着往下校验，则是对 AFSSLPinningModeCertificate 和 AFSSLPinningModePublicKey 选项的分别处理，前者比较的是安全信息中的证书和本地的证书是否相同，
	而后者则是对证书中的公钥进行比较。
	
	在 AFSSLPinningModeCertificate 选项下，先调用 SecCertificateCreateWithData 函数将 pinnedCertificates 属性中的所有的本地证书数据转化为证书变量，
	而后使用 SecTrustSetAnchorCertificates 函数将这些变量设置为校验服务器安全信息 serverTrust 的锚证书。
	
	当确定 serverTrust 信息本身是有效的后，再调用 AFCertificateTrustChainForServerTrust 函数获取其所包含的所有证书 serverCertificates ，这个证书数组，第一个为子证书，最后一个可能是根证书（当然也可能不是），这样，再判断本地的所有证书 pinnedCertificates 中是否包含了 serverCertificates 中的一个证书。判断过程是从数组最后一个元素开始的，即从父证书开始判断。只要包含一个证书，那么就认为所连接的服务器是可以信任的。
	
	在 AFSSLPinningModePublicKey 选项下，先调用 AFPublicKeyTrustChainForServerTrust 函数获取 serverTrust 中所含证书的所有公钥，而后，遍历这些公钥，如果有一个公钥在 pinnedPublicKeys 属性中的所有公钥中，那么就认为服务器是可信的。
	
	具体的源代码如下：
	
	```
	- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
	                  forDomain:(NSString *)domain
	{
	    if (domain && self.allowInvalidCertificates && self.validatesDomainName && (self.SSLPinningMode == AFSSLPinningModeNone || [self.pinnedCertificates count] == 0)) {
	        // https://developer.apple.com/library/mac/documentation/NetworkingInternet/Conceptual/NetworkingTopics/Articles/OverridingSSLChainValidationCorrectly.html
	        //  According to the docs, you should only trust your provided certs for evaluation.
	        //  Pinned certificates are added to the trust. Without pinned certificates,
	        //  there is nothing to evaluate against.
	        //
	        //  From Apple Docs:
	        //          "Do not implicitly trust self-signed certificates as anchors (kSecTrustOptionImplicitAnchors).
	        //           Instead, add your own (self-signed) CA certificate to the list of trusted anchors."
	        NSLog(@"In order to validate a domain name for self signed certificates, you MUST use pinning.");
	        return NO;
	    }
	
	    NSMutableArray *policies = [NSMutableArray array];
	    if (self.validatesDomainName) {
	        [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
	    } else {
	        [policies addObject:(__bridge_transfer id)SecPolicyCreateBasicX509()];
	    }
	
	    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);
	
	    if (self.SSLPinningMode == AFSSLPinningModeNone) {
	        return self.allowInvalidCertificates || AFServerTrustIsValid(serverTrust);
	    } else if (!AFServerTrustIsValid(serverTrust) && !self.allowInvalidCertificates) {
	        return NO;
	    }
	
	    switch (self.SSLPinningMode) {
	        case AFSSLPinningModeNone:
	        default:
	            return NO;
	        case AFSSLPinningModeCertificate: {
	            NSMutableArray *pinnedCertificates = [NSMutableArray array];
	            for (NSData *certificateData in self.pinnedCertificates) {
	                [pinnedCertificates addObject:(__bridge_transfer id)SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificateData)];
	            }
	            SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)pinnedCertificates);
	
	            if (!AFServerTrustIsValid(serverTrust)) {
	                return NO;
	            }
	
	            // obtain the chain after being validated, which *should* contain the pinned certificate in the last position (if it's the Root CA)
	            NSArray *serverCertificates = AFCertificateTrustChainForServerTrust(serverTrust);
	            
	            for (NSData *trustChainCertificate in [serverCertificates reverseObjectEnumerator]) {
	                if ([self.pinnedCertificates containsObject:trustChainCertificate]) {
	                    return YES;
	                }
	            }
	            
	            return NO;
	        }
	        case AFSSLPinningModePublicKey: {
	            NSUInteger trustedPublicKeyCount = 0;
	            NSArray *publicKeys = AFPublicKeyTrustChainForServerTrust(serverTrust);
	
	            for (id trustChainPublicKey in publicKeys) {
	                for (id pinnedPublicKey in self.pinnedPublicKeys) {
	                    if (AFSecKeyIsEqualToKey((__bridge SecKeyRef)trustChainPublicKey, (__bridge SecKeyRef)pinnedPublicKey)) {
	                        trustedPublicKeyCount += 1;
	                    }
	                }
	            }
	            return trustedPublicKeyCount > 0;
	        }
	    }
	    
	    return NO;
	}
	```

### Security 框架
在对服务器传递的安全信息进行校验时，要获取安全信息中证书的证书或者公钥，主要使用的就是 Security 框架中的变量及其相关接口，
涉及到的变量类型有 SecTrustRef 、SecCertificateRef 、SecPolicyRef 、SecTrustResultType 等。

#### SecCertificateRef
这个变量用来描述遵循 X.509 标准格式的证书数据，使用下面的方法可以将 DER 编码的数据转换为该变量，当然反过来也能获取证书数据。

```
__nullable SecCertificateRef SecCertificateCreateWithData(CFAllocatorRef __nullable allocator, 
	CFDataRef data) __OSX_AVAILABLE_STARTING(__MAC_10_6, __IPHONE_2_0);

CFDataRef SecCertificateCopyData(SecCertificateRef certificate) 
	__OSX_AVAILABLE_STARTING(__MAC_10_6, __IPHONE_2_0);
```

#### SecPolicyRef
安全信息校验策略，在对 SecTrustRef 变量信息进行校验时会用到这个策略。

通常，我们调用下面的方法创建一个默认的策略，该策略针对于 X.509 标准。

`SecPolicyRef SecPolicyCreateBasicX509(void) __OSX_AVAILABLE_STARTING(__MAC_10_6, __IPHONE_2_0);`

当然，也可以使用下面的方法，表明是对 SSL 连接中证书的校验，并且可以指定主机名，表示子证书中的主机名要与其一致。

`SecPolicyRef SecPolicyCreateSSL(Boolean server, CFStringRef __nullable hostname) __OSX_AVAILABLE_STARTING(__MAC_10_6, __IPHONE_2_0);`

> 该接口中还预定义了一些字符串常量，可以用来获取或设置策略中的一些属性。

#### SecTrustRef
这个信息是安全信息的描述，该信息可以由证书信息和策略信息创建，如下：

```
OSStatus SecTrustCreateWithCertificates(CFTypeRef certificates,
    CFTypeRef __nullable policies, SecTrustRef * __nonnull CF_RETURNS_RETAINED trust)
    __OSX_AVAILABLE_STARTING(__MAC_10_3, __IPHONE_2_0);
```
这个方法便是提供了一个证书 SecCertificateRef 变量和策略 SecPolicyRef 变量，由 trust 指针接收创建的 SecTrustRef 变量。

拥有一个 SecTrustRef 变量，最自然的操作就是验证它是否有效，如连接服务器时，接收到服务器的校验请求，所以，下面的方法最为常用。

```
OSStatus SecTrustEvaluate(SecTrustRef trust, SecTrustResultType * __nullable result)
    __OSX_AVAILABLE_STARTING(__MAC_10_3, __IPHONE_2_0);
```
但是这个校验操作是同步的，所以要注意其应该在子线程中调用，否则可能会阻塞主线程。不过，接口里也提供了异步校验操作函数，并且可以指定校验结束后的回调操作。

```
OSStatus SecTrustEvaluateAsync(SecTrustRef trust,
    dispatch_queue_t __nullable queue, SecTrustCallback result)
    __OSX_AVAILABLE_STARTING(__MAC_10_7, __IPHONE_7_0);
```

回调 SecTrustCallback 的类型定义如下：

`typedef void (^SecTrustCallback)(SecTrustRef trustRef, SecTrustResultType trustResult);`

校验后，会由 SecTrustResultType 类型的变量描述校验的结果，它可能的结果如下：

* **kSecTrustResultInvalid** 通常表示校验尚未开始
* **kSecTrustResultProceed** 表示可以执行，即校验通过
* **kSecTrustResultConfirm** 表示后续执行需要用户确认，该字段在 OS X 10.9 和 iOS 7 之后就废弃了
* **kSecTrustResultDeny** 表示用户拒绝信任相关安全信息
* **kSecTrustResultUnspecified** 表示默认信任，但用户并没有明确表示信任
* **kSecTrustResultRecoverableTrustFailure** 表示校验失败，但是用户可以强制校验通过
* **kSecTrustResultFatalTrustFailure** 表示校验失败，且用户不能强制修改校验结果进行信任
* **kSecTrustResultOtherError** 表示并不是校验信息时所产生的错误

> 在 AFNetworking 框架的安全策略中，获取的服务器安全信息校验状态为 kSecTrustResultUnspecified 或 kSecTrustResultProceed 则认为其可信。

除了校验信息是否可信外，还可以调用函数 SecTrustCopyPublicKey 获取公钥信息，调用 SecTrustGetCertificateCount 函数获取证书数量，调用 SecTrustGetCertificateAtIndex 获取具体证书信息等等。


 