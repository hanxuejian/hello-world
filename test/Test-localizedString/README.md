## 国际化学习

国际化也称作本地化，为了使不同国家和地区的用户能够有良好的体验，需要对自己所开发的应用进行不同语言的适配。

iOS中的`NSBundle.h`中提供了本地化的实现方法：

`- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName NS_FORMAT_ARGUMENT(1);`

* key 查找的字符串的唯一标识
* value 查找的字符串的默认值
* tableName 查找的文件名，传入的文件名参数不应包含后缀名 strings，若为nil或空，则默认查找文件`Localizable.strings`

|key|value|return|
|---|-----|------|
|nil|nil|空串|
|nil|非 nil|value|
|未找到|nil 或 空串|key|
|未找到|非 nil 且 非空串|value|

***
一般可以直接使用`NSBundle.h`中定义的宏

```
#define NSLocalizedString(key, comment) [[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil]
#define NSLocalizedStringFromTable(key, tbl, comment) [[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:(tbl)]
#define NSLocalizedStringFromTableInBundle(key, tbl, bundle, comment) [bundle localizedStringForKey:(key) value:@"" table:(tbl)]
#define NSLocalizedStringWithDefaultValue(key, tbl, bundle, val, comment) [bundle localizedStringForKey:(key) value:(val) table:(tbl)]
```

* **NSLocalizedString(key, comment)**
* **NSLocalizedStringFromTable(key, tbl, comment)**
	
	使用这两个宏时，都是使用与系统语言相同的语言资源包，但前者是使用默认的字符串文件`Localizable.strings`，而后者使用传入的文件进行查找。

* **NSLocalizedStringFromTableInBundle(key, tbl, bundle, comment)**
* **NSLocalizedStringWithDefaultValue(key, tbl, bundle, val, comment)**
	使用这两个宏，可以指定资源包，即可以加载自己想要显示的语言的资源，从而实现应用内语言的切换。
	在实现应用内语言切换，需要监听用户切换语言的动作，当用户切换语言时，发送通知，加载相应语言的资源包，再去刷新界面，显示正确的语言。
	

