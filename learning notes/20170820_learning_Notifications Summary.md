# 推送通知小结
这里所说的推送通知与通知代理中的推送不同，前者是面向用户的，是用来告知用户一些事情，无论应用是否开启，而后者（NSNotification）是面向程序的，用于应用中线程间的通信。推送通知可以通过弹出弹框、弹出横幅、在应用程序图标上显示角标数字、发出声音来告知用户有推送消息，当然这些提示的方式需要在应用第一次安装时，得到用户的授权，用户也可以在设置里更改这些授权。推送通知分为本地推送与远程推送两种。
## 本地推送通知
本地推送通知不需要连接网络，常用来提醒用户完成一些任务，如生日提醒、会议、约会等。使用 **UILocalNotification** 类来创建本地推送通知对象，然后设置推送发出的时间，及要通知的消息。其相关属性如下：

```
//推送通知的触发时间
@property(nonatomic,copy) NSDate *fireDate;
//推送通知的具体内容
@property(nonatomic,copy) NSString *alertBody;
//锁屏界面显示的小标题（完整小标题：“滑动来” + alertAction）
@property(nonatomic,copy) NSString *alertAction;
//音效文件名，默认为 UILocalNotificationDefaultSoundName
@property(nonatomic,copy) NSString *soundName;
//应用程序图标的角标数字
@property(nonatomic) NSInteger applicationIconBadgeNumber;

```
设置完本地推送的相关属性后，需要将其加入系统工作列表中，这里需要调用 UIApplication 的分类 **UILocalNotifications** 中的方法，如下：

```
///立即发出本地通知
- (void)presentLocalNotificationNow:(UILocalNotification *)notification;

///将本地通知加入本地调度列表
- (void)scheduleLocalNotification:(UILocalNotification *)notification;

/**
删除本地通知，该方法是必须的，如果不取消本地通知，那么即使将整个应用删除，
该本地通知任务仍然存在，当再次安装相同ID的应用时，即使新安装的应用未注册本地通知任务，
系统仍会推送以前的推送通知任务（前提是该任务未过期）
*/
- (void)cancelLocalNotification:(UILocalNotification *)notification;
- (void)cancelAllLocalNotifications;

///获取本地有效的推送通知任务
@property(nullable,nonatomic,copy) NSArray<UILocalNotification *> *scheduledLocalNotifications
```
当本地推送通知发出时，有以下几种情况：

* 应用处于前台运行状态，那么应用会调用代理方法 **`- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification;`** ，不会有系统提示信息。
* 应用处于后台运行状态，根据系统设置进行消息的提示，此时点击推送的通知，应用会调用代理方法 **`- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification;`**。
* 应用处于未运行状态，根据系统设置进行消息的提示，此时点击推送的通知，应用会启动，调用方法 **`- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions; `** ，使用  **UIApplicationLaunchOptionsLocalNotificationKey** 从其参数 launchOptions 中取出通知对象。

## 远程推送通知
远程推送通知，需要连接网络，只要设备与网络相连，通过 APNs（Apple Push Notification Services）便可以将消息推送给用户，而不用管应用程序是否是开启状态。
一般在应用程序开启时，就调用远程推送的注册方法 `- (void)registerForRemoteNotificationTypes:(UIRemoteNotificationType)types;` ，若注册成功，会调用代理方法 `- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;` ，该方法返回的 **deviceToken** 应传给服务端，用于消息的推送。

当接收到远程推送通知时，有以下几种情况：

* 应用处于前台运行状态，那么应用会调用代理方法 **`- (void)application:(UIApplication *)application didReceiveRemoteNotification:(UILocalNotification *)notification;`** ，不会有系统提示信息。
* 应用处于后台运行状态，根据系统设置进行消息的提示，此时点击推送的通知，应用会调用代理方法 **`- (void)application:(UIApplication *)application didReceiveRemoteNotification:(UILocalNotification *)notification;`**。
* 应用处于未运行状态，根据系统设置进行消息的提示，此时点击推送的通知，应用会启动，调用方法 **`- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions; `** ，使用  **UIApplicationLaunchOptionsRemoteNotificationKey** 从其参数 launchOptions 中取出通知对象。

## 推送通知框架 UserNotifications
从 iOS 10 开始，苹果公司对推送通知功能进行了重构，将其单独作为一个框架，这意味着在移动互联网的发展过程中，推送功能的重要性不断在增强。

该框架中，**UNNotificationContent、UNMutableNotificationContent** 是用于描述推送通知的类，其中包含有标题、子标题、通知内容等推送通知的属性。

**UNNotificationTrigger** 类是一个抽象类，在使用时，不应该直接生成该类的实例，而是根据需要生成其子类。其有以下4个子类：

* **UNPushNotificationTrigger** - 该类的实例是由系统生成的，表明接收到了一个远程推送通知，在处理推送消息时，可从 **UNNotificationRequest** 类实例的 **trigger** 属性获得。
* **UNTimeIntervalNotificationTrigger** - 该类用于生成本地推送通知，可以设置相对当前时间后多少秒时发出通知，并且可以设置一次或重复多次。
* **UNCalendarNotificationTrigger** - 该类用于生成本地推送通知，但是其可以使用 **NSDateComponents** 类实例，设置具体的推送时间。
* **UNLocationNotificationTrigger** - 该类用于生成本地推送通知，其是用来提示用户设备进入或离开某一地理区域范围。

**UNLocationNotificationTrigger** 类用于封装通知的内容与推送触发的条件，对于本地推送通知，使用方法 `+ (instancetype)requestWithIdentifier:(NSString *)identifier content:(UNNotificationContent *)content trigger:(nullable UNNotificationTrigger *)trigger;` 生成一个该类实例，而后将该实例加入用户推送通知中心。若是远程推送通知，则可从 **UNNotification** 实例中的属性 **request** 获取该实例，从而获取推送的内容。

**UNUserNotificationCenter** 类是用户推送通知中心，用于管理推送通知。其相关方法如下：

```
///获取当前应用程序的通知中心
+ (UNUserNotificationCenter *)currentNotificationCenter;

///设置通知的提示方式
- (void)requestAuthorizationWithOptions:(UNAuthorizationOptions)options completionHandler:(void (^)(BOOL granted, NSError *__nullable error))completionHandler;

///获取应用程序在系统中推送通知的提示方式
- (void)getNotificationSettingsWithCompletionHandler:(void(^)(UNNotificationSettings *settings))completionHandler;

///添加本地推送通知
- (void)addNotificationRequest:(UNNotificationRequest *)request withCompletionHandler:(nullable void(^)(NSError *__nullable error))completionHandler;

///获取待推送的本地通知
- (void)getPendingNotificationRequestsWithCompletionHandler:(void(^)(NSArray<UNNotificationRequest *> *requests))completionHandler;

///移除待推送的本地通知
- (void)removePendingNotificationRequestsWithIdentifiers:(NSArray<NSString *> *)identifiers;
- (void)removeAllPendingNotificationRequests;
```

**UNUserNotificationCenterDelegate** 接收到推送通知的代理，有下面两个代理方法：

```
///当应用在前台运行并且接收到推送通知时，调用该方法
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0) __WATCHOS_AVAILABLE(3.0);

///当用户点击通知消息，进而应用进入前台运行或开启时，调用该方法
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler __IOS_AVAILABLE(10.0) __WATCHOS_AVAILABLE(3.0) __TVOS_PROHIBITED;
```