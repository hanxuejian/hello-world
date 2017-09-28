# iOS 时间表示小结
## NSDate
不同地区的时间表示方法不同，而 NSDate 只是保存一个绝对的时间点，通过计算与转化，其在不同地区、时区或历法下能够得到有意义的时间。NSDate 定义一个不可变的时间点，那么在定义时就需要一个参考时间，否则便无法进行定义。通常使用的参考时间是 2001.1.1 0:0:0 GMT，使用参考时间创建对象时，传递相对的秒数，负值表示在参考时间点之前，正值，则表示在参考点时间之后。常用方法如下：

```
// 返回当前系统时间
+ (instancetype)date;

// 以当前时间为参考时间，创建时间
+ (instancetype)dateWithTimeIntervalSinceNow:(NSTimeInterval)secs;

// 以 2001.1.1 0:0:0 为参考时间，创建时间
+ (instancetype)dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)ti;
```

## NSDateComponents 与 NSCalendar
1. NSDateComponents

	NSDateComponents 用来表示时间的每一个部分，使得创建时间更加灵活，其主要属性如下：
	
	* **`@property (nullable, copy) NSCalendar *calendar NS_AVAILABLE(10_7, 4_0);`**
	* **`@property (nullable, copy) NSTimeZone *timeZone NS_AVAILABLE(10_7, 4_0);`**
	* **`@property (nullable, readonly, copy) NSDate *date NS_AVAILABLE(10_7, 4_0);`**
	
		通过设置不同的历法、时区，可以得到相应的时间对象，但是其表示的某个时间瞬间总是不变的。
	
	* **`@property NSInteger era;`**
	* **`@property NSInteger year;`**
	* **`@property NSInteger month;`**
	* **`@property NSInteger day;`**
	* **`@property NSInteger hour;`**
	* **`@property NSInteger minute;`**
	* **`@property NSInteger second;`**
	* **`@property NSInteger nanosecond NS_AVAILABLE(10_7, 5_0);`**
	* **`@property NSInteger weekday;`**
	
		通过设置年月日、时分秒、纳秒、纪元类型、一周的第几天来确定一个时间点。

2. NSCalendar

	对于需要获取不同历法下的时间时，使用该类创建 NSDate 对象更加方便。其配合 NSDateComponents 类使用，能给更加灵活的创建时间对象。常用的方法如下：
	
	```
	// 根据历法的唯一标识创建一个历法对象
	+ (nullable NSCalendar *)calendarWithIdentifier:(NSCalendarIdentifier)calendarIdentifierConstant NS_AVAILABLE(10_9, 8_0);
	```
	```
	// 获取某个时间部分的最大最小范围，如阳历的月份，其最大范围为1～31，最小范围为1～28
	- (NSRange)minimumRangeOfUnit:(NSCalendarUnit)unit;
	- (NSRange)maximumRangeOfUnit:(NSCalendarUnit)unit;
	```
	```
	// 获取时间 date 中较小的时间部分在较大的时间部分的范围
	- (NSRange)rangeOfUnit:(NSCalendarUnit)smaller inUnit:(NSCalendarUnit)larger forDate:(NSDate *)date;
	
	例程：
	NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];   
	NSRange range = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:today];
	NSLog(@"%@",NSStringFromRange(range));
	
	输入：
	2017-09-28 17:25:16.286 test[2333:1059610] {1, 30}
	```
	```
	// 获取 date 中指定的时间部分的开始时间和持续的秒数
	- (BOOL)rangeOfUnit:(NSCalendarUnit)unit startDate:(NSDate * _Nullable * _Nullable)datep interval:(nullable NSTimeInterval *)tip forDate:(NSDate *)date NS_AVAILABLE(10_5, 2_0);
	
	例程：
	NSDate *start;
	NSTimeInterval extends;
	BOOL success = [calendar rangeOfUnit:NSWeekCalendarUnit startDate:&start interval: &extends forDate:today];
	NSLog(@"%@",start);
	NSLog(@"%f",extends);
	
	输出：
	2017-09-28 17:25:16.282 test[2333:1059610] 2017-09-23 16:00:00 +0000
	2017-09-28 17:25:16.283 test[2333:1059610] 604800.000000
	```
	
	```
	// 由自定义的时间各个部分创建时间对象
	- (nullable NSDate *)dateFromComponents:(NSDateComponents *)comps;
	
	// 将指定的时间对象分解为各个部分
	- (NSDateComponents *)components:(NSCalendarUnit)unitFlags fromDate:(NSDate *)date;
	
	// 向指定的时间添加新的时间部分
	- (nullable NSDate *)dateByAddingComponents:(NSDateComponents *)comps toDate:(NSDate *)date options:(NSCalendarOptions)opts;
	```

## NSTimeZone
地球分为24个时区，每一个瞬间，不同时区的时间是不同的，而 NSDate 用来记录一个瞬间的绝对时间点，其表示的总是该瞬间的 GMT 时间。

对于不同的时区，使用 NSTimeZone 进行描述，不同的时区由不同的时区名称进行区分，可以用创建指定名称的时区，使用时需要注意其如下属性：

* **`@property (class, readonly, copy) NSTimeZone *systemTimeZone;`**

	可以使用该属性获取系统使用的时区，需要注意的是第一次获取后，其会保存在缓存中，再次获取时，会读取缓存中的值，所以如果自己对系统时区进行了修改，或者存在其他修改系统时区的可能，应该调用方法 **`+ (void)resetSystemTimeZone;`**，以清空缓存的系统时区值。

* **`@property (class, copy) NSTimeZone *defaultTimeZone;`**

	获取应用默认使用的时区，这个值同系统时区一样，第一次读取后也会缓存在内存中，后续对默认时区进行了修改，再次读取默认时区，得到的仍然是第一次得到时区值。

* **`@property (class, readonly, copy) NSTimeZone *localTimeZone;`**

	获取实时的默认时区值，其总是读区最新的 defaultTimeZone 值。

不同的时区总是相对于 GMT 的时区进行表示的，对于早于 GMT 的时区，用正值表示其早于 GMT 几时几分，对于小于30秒的秒值进行省略，大于等于30秒的秒值按1分中记。相应的，对于晚于 GMT 的时间点，用负值进行记录。如下例程：

```
NSTimeZone *z1 = [NSTimeZone systemTimeZone];
NSLog(@"%@",z1);
NSTimeZone *z2 = [NSTimeZone defaultTimeZone];
NSLog(@"%@",z2);
NSTimeZone *z3 = [NSTimeZone localTimeZone];
NSLog(@"%@",z3);
NSTimeZone *z4 = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
NSLog(@"%@",z4);
    
NSTimeZone *z5 = [NSTimeZone timeZoneWithName:@"Pacific/Tahiti"];
NSLog(@"%@",z5);
    
NSTimeZone *z6 = [NSTimeZone timeZoneWithName:@"GMT"];
NSLog(@"%@",z6);
    
    
NSTimeZone *z7 = [NSTimeZone timeZoneForSecondsFromGMT:3629];
NSLog(@"%@",z7);
    
NSTimeZone *z8 = [NSTimeZone timeZoneForSecondsFromGMT:3630];
NSLog(@"%@",z8);

输入结果如下：
2017-09-27 19:59:31.214 test[8209:3254103] Asia/Shanghai (GMT+8) offset 28800
2017-09-27 19:59:31.215 test[8209:3254103] Asia/Shanghai (GMT+8) offset 28800
2017-09-27 19:59:31.215 test[8209:3254103] Local Time Zone (Asia/Shanghai (GMT+8) offset 28800)
2017-09-27 19:59:31.216 test[8209:3254103] Asia/Shanghai (GMT+8) offset 28800
2017-09-27 19:59:31.217 test[8209:3254103] Pacific/Tahiti (GMT-10) offset -36000
2017-09-27 19:59:31.217 test[8209:3254103] GMT (GMT) offset 0
2017-09-27 19:59:31.219 test[8209:3254103] GMT+0100 (GMT+1) offset 3600
2017-09-27 19:59:31.219 test[8209:3254103] GMT+0101 (GMT+1:01) offset 3660

```
NSTimeZone 中还提供了几个属性用来获取夏时令的一些信息，如下：

* isDaylightSavingTime 确定夏时令是否生效
* daylightSavingTimeOffset 确定当前的夏时令偏移几个小时
* nextDaylightSavingTimeTransition 获取下次夏时令变更时间

> 夏时制，夏时令（Daylight Saving Time：DST），又称“日光节约时制”和“夏令时间”，是一种为节约能源而人为规定地方时间的制度，在这一制度实行期间所采用的统一时间称为“夏令时间”。一般在天亮早的夏季人为将时间调快一小时，可以使人早起早睡，减少照明量，以充分利用光照资源，从而节约照明用电。

> CDT ,Central Daylight Time 美国中央时区
> 
> EST ,Eastern Standart Time 美国东部时区
> 
> EDT ,Eastern Daylight Time 美国东部时区（夏时令生效中）
> 
> GMT ,Greenwich Mean Time 格林尼治标准时间
> 
> PST ,Pacific Standard Time 太平洋标准时间
