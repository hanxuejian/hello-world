# CMTime CMTimeRange CMTimeMapping
在使用 AVFoundation 框架处理多媒体资源时，通常会用到一些在 CoreMedia 框架中定义的结构体，
这里对其中描述时间的类型 CMTime 、CMTimeRange 、CMTimeMapping 进行简单的小结。

## CMTime
### 概述
CMTime 是一个结构体，其用来表示一个有理数，描述一个时刻或时段。在结构体中有4个成员，如下：

```
typedef struct
{
	CMTimeValue	value;
	CMTimeScale	timescale;
	CMTimeFlags	flags;
	CMTimeEpoch	epoch;
} CMTime;
```
该结构体类型的变量表示的时刻或时段的值为 value/timescale ，单位是秒。

* **timescale** 这个分母值的含义是将 1 秒钟分成了多少个单元
* **value** 这个分子值的含义是所表示的时刻或时段共计占用了多少个单元

那么 **1/timescale** 表示一个单元占用了多长时间，这个时间小于 1 秒，而 **value * (1/timescale)** 即表示整个结构体变量所表示的时间长度。

* **flags** 该标识可以表示当前变量表示的时刻或时段是否有效、是否是准确值等，可取的值如下：

	- **`kCMTimeFlags_Valid = 1UL<<0`** 该值必需设置，否则当前变量会被认为是无效的
	- **`kCMTimeFlags_HasBeenRounded = 1UL<<1`** 表示当前变量是约数并不是原始的精确值，或者是由其他非精确的值生成的
	- **`kCMTimeFlags_PositiveInfinity = 1UL<<2`** 表示当前变量为正无穷
	- **`kCMTimeFlags_NegativeInfinity = 1UL<<3`** 表示当前变量为负无穷
	- **`kCMTimeFlags_Indefinite = 1UL<<4`** 表示当前变量未定义
	- **`kCMTimeFlags_ImpliedValueFlagsMask = kCMTimeFlags_PositiveInfinity | kCMTimeFlags_NegativeInfinity | kCMTimeFlags_Indefinite`** 表示正负无穷或未定义

* **epoch** 可以用来区分两个表示相同时间的变量，如循环递增的时间，这个值可以区分不同循环内的相同的时间的变量。

### 常量
在 CoreMedia 框架中，提供了一些常量，用来表示特殊的 CMTime 值。

* **kCMTimeInvalid** 用来初始化无效的 CMTime 值，该变量的每个成员的值都是 0
* **kCMTimeZero** 用来表示时间为 0 ，该变量的成员值为 value=0，timescale=1，flags=kCMTimeFlags_Valid，epoch=0
* **kCMTimePositiveInfinity** 表示时间为正无穷，flags=5（即 kCMTimeFlags_Valid|kCMTimeFlags_PositiveInfinity），其他成员的值都是 0
* **kCMTimeNegativeInfinity** 表示时间为负无穷，flags=9（即 kCMTimeFlags_Valid|kCMTimeFlags_NegativeInfinity），其他成员的值都是 0
* **kCMTimeIndefinite** 表示时间未定义，flags=17（即 kCMTimeFlags_Valid|kCMTimeFlags_Indefinite），其他成员的值都是 0

要判断已知的变量是否等于上述的变量时，不可以使用 “==” 进行判断，而是要使用框架中提供的宏，在这些宏定义中，都是对变量的成员 flags 值进行了判断。

* **`CMTIME_IS_VALID(time)`** 判断已知的 CMTime 变量是否是有效的
* **`CMTIME_IS_INVALID(time)`** 判断已知的 CMTime 变量是否是无效的
* **`CMTIME_IS_POSITIVE_INFINITY(time)`** 判断已知的 CMTime 变量是否表示时间正无穷
* **`CMTIME_IS_NEGATIVE_INFINITY(time)`** 判断已知的 CMTime 变量是否表示时间负无穷
* **`CMTIME_IS_INDEFINITE(time)`** 判断已知的 CMTime 变量是否是未定义的
* **`CMTIME_IS_NUMERIC(time)`** 判断已知的 CMTime 变量是否是明确的时间，而不是正负无穷或未定义
* **`CMTIME_HAS_BEEN_ROUNDED(time)`** 判断已知的 CMTime 变量是否是约数

### 函数
1. **`CMTime CMTimeMake(int64_t value,int32_t timescale);`**
2. **`CMTime CMTimeMakeWithEpoch(int64_t value,int32_t timescale,int64_t epoch);`**

	上面两个是生成 CMTime 变量的常见函数，通过指定相应的成员变量的值来生成相应的变量。

3. **`CMTime CMTimeMakeWithSeconds(Float64 seconds,int32_t preferredTimescale)`**

	除了指定相应的成员变量来生成 CMTime 变量外，还可以通过指定时间和时间粒度来生成变量。返回的变量，其成员 epoch 被设置为 0 ，而 value 的值则是 seconds 与 preferredTimescale 的乘积，所以 value 的值可能会溢出。
	
	当发生溢出时，会将 preferredTimescale 的值自动减半，直到 value 的值不再溢出，或者 preferredTimescale 减到 1 ，如果减到 1 后，value 仍然溢出，则这个变量表示无穷大。
	
	由于提供的时间是浮点型，而计算得到的成员变量 value 是整型值，所以计算时，value 的值可能含有小数，如果有小数部分，便需要舍入。如此，使用成员变量再次计算得到的时间值与原来提供的时间值不相等，所以对于这种情况，返回值的成员变量 flags 中，kCMTimeFlags_HasBeenRounded 标识会被设置。

4. **`Float64 CMTimeGetSeconds(CMTime time);`**	
	使用该方法将 CMTime 类型的变量转化为时间值，如果变量本身表示的值无效或是正负无穷值，则返回 **NaN** 或 **+Inf** 、**-Inf** 。

5. **`CMTime CMTimeConvertScale(CMTime time,int32_t newTimescale,CMTimeRoundingMethod method);`**
				
	该方法可以修改已知的 CMTime 类型变量的 timescale 成员变量的值，计算 value 的值时可能需要舍入小数部分，所以调用函数时要指定舍入方法。
	
	CMTimeRoundingMethod 有以下可取值：
	
	- kCMTimeRoundingMethod_RoundHalfAwayFromZero = 1, 表示四舍五入
	- kCMTimeRoundingMethod_RoundTowardZero = 2, 始终舍弃小数部分
	- kCMTimeRoundingMethod_RoundAwayFromZero = 3, 始终进1
	- kCMTimeRoundingMethod_QuickTime = 4, 当时间粒度值变大，则应进1，反之，时间粒度值变小，舍弃小数部分，而当表示的时间是负的时，舍弃小数后，value 若为 0 ，应将其置为 -1
	- kCMTimeRoundingMethod_Default = kCMTimeRoundingMethod_RoundHalfAwayFromZero

	```
	//转换后 time2 的 value 为 1
	CMTime time1 = CMTimeMake(1, 4);
	CMTime tiem2 = CMTimeConvertScale(time, 2, kCMTimeRoundingMethod_RoundHalfAwayFromZero);
	
	//转换后 time2 的 value 为 0
	CMTime time1 = CMTimeMake(1, 5);
	CMTime tiem2 = CMTimeConvertScale(time, 2, kCMTimeRoundingMethod_RoundHalfAwayFromZero);
	
	//转换后 time2 的 value 为 0
	CMTime time1 = CMTimeMake(1, 5);
	CMTime tiem2 = CMTimeConvertScale(time, 2, kCMTimeRoundingMethod_QuickTime);
	
	//转换后 time2 的 value 为 -1
	CMTime time1 = CMTimeMake(-1, 5);
	CMTime tiem2 = CMTimeConvertScale(time, 2, kCMTimeRoundingMethod_QuickTime);
	```

6. **`CMTime CMTimeAdd(	CMTime addend1,CMTime addend2);`**
7. **`CMTime CMTimeSubtract(CMTime minuend,CMTime subtrahend);`**
	
	两个 CMTime 类型的变量之和或之差，得到的结果的 timescale 的值是两个变量的 timescale 的最小公倍数。如果这个公倍数大于 kCMTimeMaxTimescale 这个值，那么 timescale 就使用 kCMTimeMaxTimescale 这个值。在转换这个 timescale 的过程中，计算 value 的值时采用默认的舍入方法，如果 value 的值溢出，便减半 timescale 再进行计算，判断其是否溢出，若溢出，再次减半，直到其值为 1 ，如果仍然溢出，则返回的结果为无穷大。
						
8. **`CMTime CMTimeMultiply(CMTime time,int32_t multiplier);`**
9. **`CMTime CMTimeMultiplyByFloat64(CMTime time,Float64 multiplier);`**

	扩大已知的 time 的倍数，value 的值扩大 multiplier 倍，如果溢出，持续减半 timescale 的值，直到不再溢出或为 1 ，如果为 1  时仍然溢出，返回的值表示无穷大。

10. **`CMTime CMTimeMultiplyByRatio(CMTime time,int32_t multiplier,int32_t divisor)`**

	用已知的 time 的 value 值乘以 multiplier 再除以 divisor 得到新的 value 值，如果 value 的值发生溢出，那么 timescale 便会发生转变。
				
11. **`int32_t CMTimeCompare(CMTime time1,CMTime time2)`**

	两个时间比较，遵循的规则：**负无穷 < 具体时间 < 未定义 < 正无穷 < 无效时间**
	
	具体的两个时间比较大小时，其成员 epoch 也参与比较，epoch 较大的时间较大。
	
	- time1 > time2 ，返回值为 1
	- time1 < time2 ，返回值为 -1	
	- time1 = time2 ，返回值为 0
	
	框架中提供了一个宏 **CMTIME_COMPARE_INLINE(time1, comparator, time2)** ，通过提供比较运算符（>、>=、=、<、=<）comparator 来获取 time1 与 time2 的大小关系。
				
12. **`CMTime CMTimeMinimum(CMTime time1,CMTime time2)`**	
	返回 time1 与 time2 中较小的值

13. **`CMTime CMTimeMaximum(CMTime time1,CMTime time2)`**	
	返回 time1 与 time2 中较大的值
				
14. **`CMTime CMTimeAbsoluteValue(CMTime time)`**

	返回 time 的绝对值

15. **`CFDictionaryRef CM_NULLABLE CMTimeCopyAsDictionary(CMTime time,CFAllocatorRef CM_NULLABLE allocator)`**
16. **`CMTime CMTimeMakeFromDictionary(CFDictionaryRef CM_NULLABLE dict)`**

	上面两个方法，可以将 CMTime 类型的变量转化为 CFDictionaryRef 类型的变量，或者从已经转化的变量中生成一个 CMTime 类型的变量。在 CFDictionary 中，它应包含键值：**kCMTimeValueKey 、kCMTimeScaleKey 、kCMTimeEpochKey 、kCMTimeFlagsKey** 分别对应 CMTime 的各个成员变量。
	
17. **`CFStringRef CM_NULLABLE CMTimeCopyDescription(CFAllocatorRef CM_NULLABLE allocator,CMTime time)`**
18. **`void CMTimeShow(CMTime time)`**
	
	上面的两个方法，可以获取 CMTime 类型变量的字符串描述，或者直接将字符串描述打印出来。

## CMTimeRange
### 概述
CMTimeRange 是用来表示一个时间范围的结构体变量，它的两个成员变量都是 CMTime 类型的变量，分别表示时间范围的开始时刻和时间范围的持续时长，所以开始时刻与持续时长的和得到的时刻并不属于该类型表示的时间范围。

```
typedef struct
{
	CMTime			start;		
	CMTime			duration;
} CMTimeRange;

```

可以使用 **kCMTimeRangeZero 、kCMTimeRangeInvalid** 分别表示时间范围为 0 和无效的的 CMTimeRange 类型变量。

对于有效的 CMTimeRange 类型变量，它的两个 CMTime 成员变量都必须是有效的，并且 duration.epoch 必须是 0 ，duration.value 的值必须是非负的。可以直接使用框架中提供的宏定义，进行判断。

* **CMTIMERANGE_IS_VALID(range)** 当 start 、duration 是有效的，且 duration.epoch == 0 且 duration.value >= 0 时，返回 true
* **CMTIMERANGE_IS_INVALID(range)** 返回的真假值与上面的宏返回的值相反
* **CMTIMERANGE_IS_INDEFINITE(range)** 当 range 为有效值，且 range.start 和 range.duration 中至少有一个为未定义时，这个宏返回 true
* **CMTIMERANGE_IS_EMPTY(range)** 当 range 为有效值，且 range.duration 为 kCMTimeZero 时，这个宏返回 true

### 函数
1. **`CMTimeRange CMTimeRangeMake(CMTime start,CMTime duration)`**	
	创建一个表示时间范围的变量

2. **`CMTimeRange CMTimeRangeGetUnion(CMTimeRange range1,CMTimeRange range2)`**
		
	返回两个时间范围的最小并集
		
3. **`CMTimeRange CMTimeRangeGetIntersection(CMTimeRange range1,CMTimeRange range2)`**
								
	返回两个时间范围的最大交集
								
4. **`Boolean CMTimeRangeEqual(CMTimeRange range1,CMTimeRange range2)`**

	返回两个时间范围是否相等

5. **`Boolean CMTimeRangeContainsTime(CMTimeRange range,CMTime time)`**

	返回指定的时间范围内是否包含指定的时间				
6. **`Boolean CMTimeRangeContainsTimeRange(CMTimeRange range1,CMTimeRange range2)`**

	返回指定的时间范围 range1 是否包含 指定的时间范围 range2
								
7. **`CMTime CMTimeRangeGetEnd(CMTimeRange range)`**

	返回指定时间范围的结束时间，这个时间是不包含在时间范围内的，即 
	
	`CMTimeRangeContainsTime(range, CMTimeRangeGetEnd(range))` 的返回值总是 false 。

8. **`CMTime CMTimeMapTimeFromRangeToRange(CMTime t,CMTimeRange fromRange,CMTimeRange toRange )`**

	将指定的时间 t 根据时间范围 fromRange 和 toRange 进行转换，如果 t 是 fromRange 的开始或者结束时间，那么转换后，其就是 toRange 的开始或结束时间。如果 t 是其他时间，那么按照公式 
	`result = (t-fromRange.start)*(toRange.duration/fromRange.duration)+toRange.start`
	进行计算。
				 
9. **`CMTime CMTimeClampToRange(CMTime time,CMTimeRange range)`**

	返回的是指定的时间范围内 range 中距离指定时间 time 最近的时间。如果 time 的时间小于 range 的开始时间，那么返回的就是 range 的开始时间，如果 time 在 range 范围内，那么返回其本身，如果 time 是 range 的结束时间或结束时间之后，那么返回的都是 range 的结束时间（即使该结束时间不属于 range 表示的时间范围之内）。

10. **`CMTime CMTimeMapDurationFromRangeToRange(CMTime dur,CMTimeRange fromRange,CMTimeRange toRange )`**

	将指定的时间范围的持续时长根据时间范围 fromRange 和 toRange 进行转换，实际是对持续时长进行了缩小或放大，其计算公式为
	`result = dur*(toRange.duration/fromRange.duration)`
				 
11. **`CMTimeRange CMTimeRangeFromTimeToTime(CMTime start,CMTime end)`**	 
	根据指定的开始时间和结束时间构建一个表示时间范围的变量。

12. **`CFDictionaryRef CM_NULLABLE CMTimeRangeCopyAsDictionary(CMTimeRange range,CFAllocatorRef CM_NULLABLE  allocator)`**
13. **`CMTimeRange CMTimeRangeMakeFromDictionary(CFDictionaryRef CM_NONNULL dict)`**

	上面的方法实现了 CMTimeRange 类型变量与 CFDictionaryRef 变量的相互转换，CFDictionary 中的键 **kCMTimeRangeStartKey 、kCMTimeRangeDurationKey** 分别对应着 CMTimeRange 中的成员。
												
14. **`CFStringRef CM_NULLABLE CMTimeRangeCopyDescription(CFAllocatorRef CM_NULLABLE allocator,CMTimeRange range)`**
15. **`void CMTimeRangeShow(CMTimeRange range)`**

	上面的两个方法，可以获取 CMTimeRange 类型变量的字符串描述，或者直接将字符串描述打印出来。
	
## CMTimeMapping
### 概述
CMTimeMapping 是一个描述媒体资源时间线映射关系的结构体变量，其包含两个 CMTimeRange 类型的成员变量。

```
typedef struct 
{
	CMTimeRange source;
	CMTimeRange target;
} CMTimeMapping;
```
* source 表示的是源资源的时间线范围，包括开始的时刻和持续的时长，如果开始时间为 kCMTimeInvalid ，表示没有资源的编辑信息，即该变量为空。
* target 表示的是资源目标的时间线，包含开始时间和持续时长，如果 source 和 target 的 duration 不同，那么资源在播放时，速度为 **source.duration/target.duration** 以保证资源播放完整。
				
在框架中，使用 **kCMTimeMappingInvalid** 来表示无效的 CMTimeMapping 类型变量，可以使用 **`CMTIMEMAPPING_IS_VALID(mapping)`** 、**`CMTIMEMAPPING_IS_INVALID(mapping)`** 来判断变量 mapping 是否有效（mapping.target 有效即可），或者使用 **`CMTIMEMAPPING_IS_EMPTY(mapping)`** 来判断 mapping 是否为空（mapping 有效且 mapping.source.start 为 kCMTimeInvalid）
				
### 函数
1. **`CMTimeMapping CMTimeMappingMake(CMTimeRange source,CMTimeRange target)`**

	创建一个映射关系变量，提供的 source 和 target 的 epoch 的值必需为 0 ，否则将返回一个无效值。

2. **`CMTimeMapping CMTimeMappingMakeEmpty(CMTimeRange target)`**
				
	创建一个空的变量，提供的 target 的 epoch 必需时 0 ，否则将返回一个无效值。

3. **`CFDictionaryRef CM_NULLABLE CMTimeMappingCopyAsDictionary(CMTimeMapping mapping,CFAllocatorRef CM_NULLABLE allocator)`**
4. **`CMTimeMapping CMTimeMappingMakeFromDictionary(CFDictionaryRef CM_NONNULL dict)`**
			
	上面的方法实现了 CMTimeMapping 类型变量与 CFDictionaryRef 变量的相互转换，CFDictionary 中的键 **kCMTimeMappingSourceKey 、kCMTimeMappingTargetKey** 分别对应着 CMTimeMapping 中的成员。	
5. **`CFStringRef CM_NULLABLE CMTimeMappingCopyDescription(CFAllocatorRef CM_NULLABLE allocator,CMTimeMapping mapping)`**
6. **`void CMTimeMappingShow(CMTimeMapping mapping)`**

	上面的两个方法，可以获取 CMTimeMapping 类型变量的字符串描述，或者直接将字符串描述打印出来。