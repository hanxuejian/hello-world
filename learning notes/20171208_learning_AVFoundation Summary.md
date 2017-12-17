# AVFoundation 小结
## 概述
AVFoundation 是 Objective-C 中创建及编辑视听媒体文件的几个框架之一，其提供了检查、创建、编辑或重新编码媒体文件的接口，也使得从设备获取的视频实时数据可操纵。但是，通常情况，简单的播放或者录像，直接使用 AVKit 框架或者 UIImagePickerController 类即可。另外，值得注意的是，在 AVFoundation 框架中使用的基本数据结构，如时间相关的或描述媒体数据的数据结构都声明在 CoreMedia 框架中。

1. AVFoundation 框架包含视频相关的接口以及音频相关的接口，与音频相关的类有 AVAudioPlayer、AVAudioRecorder、AVAudioSession。

2. AVFoundation 框架中最基本的类是 **AVAsset** ，它是一个或者多个媒体数据的集合，描述的是整个集合的属性，如标题、时长、大小等，并且没有特定的数据格式。集合的每一个媒体数据都是统一的数据类型，称之为 **track**。简单的情况是一种数据是音频数据，一种是视频数据，而较复杂的情况是一种数据交织着音频和视频数据，并且 AVAsset 是可能有元数据的。

	另外，需要明白的是在 AVFoundation 中，初始化了 asset 及 track 后，并不意味着资源已经可用，因为若资源本身并不携带自身信息时，那么系统需要自己计算相关信息，这个过程会阻塞线程，所以应该使用异步方式进行获取资源信息后的操作。

3. AVFoundation 提供了丰富的方法来管理视听资源的播放，为了支持这些方法，它将描述 asset 的状态与 asset 本身分离，这就使得在同一个时刻，以不同的方式播放同一个 asset 中的不同的媒体数据变得可能。对于 asset 的状态是由 **player** 管理的，而 asset 中的 track 的状态是由 **player tracker** 管理的。使用这两个状态管理对象，可以实现诸如设置 asset 中视频部分的大小、设置音频的混合参数及与视频的合成或者将 asset 中的某些媒体数据置为不可用。

	另外，还可以通过 player 将输出定位到 Core Animation 层中，或通过播放队列设置 player 集合的播放顺序。

4. AVFoundation 提供了多种方法来创建 asset ，可以简单的重编码已经存在的 asset ，这个过程可以使用 **export session** 或者使用 **asset reader** 和 **asset writer** 。

5. 若要生成视频的缩略图，可以使用 asset 初始化一个 **AVAssetImageGenerator** 实例对象，它会使用默认可用的视频 tracks 来生成图片。

6. AVFoundation 中可以使用 **compositions** 将多个媒体数据（video/audio tracks）合成为一个 asset ，这个过程中，可以添加或移除 tracks ，调整它们的顺序，或者设置音频的音量和变化坡度，视频容量等属性。这些媒体数据的集合保存在内存中，直到使用 export session 将它导出到本地文件中。另外，还可以使用 asset writer 创建 asset 。

7. 使用 **capture session** 协调从设备（如相机、麦克风）输入的数据和输出目标（如视频文件）。可以为 session 设置多个输入和输出，即使它正在工作，还可以通过它停止数据的流动。另外，还可以使用 **preview layer** 将相机记录的影像实时展示给用户。

8. 在 AVFoundation 中的回调处理并不保证回调任务在某个特定的线程或队列中执行，其遵循两个原则，UI 相关的操作在主线程中执行，其他回调需要为其指定调用的队列。

## 基本类
### AVAsset
创建 AVAsset 或其子类 AVURLAsset 时，需要提供资源的位置，方法如下：

```
NSURL *url = <#视听资源的 URL ，可以是本地文件地址，也可以是网页媒体链接#>;
AVURLAsset *anAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
```
上述方法的第二个参数是创建对象时的选择项，其中可能包含的选择项如下：

* AVURLAssetPreferPreciseDurationAndTimingKey 是否需要资源的准确时长，及访问资源各个准确的时间点
* AVURLAssetReferenceRestrictionsKey 链接其他资源的约束
* AVURLAssetHTTPCookiesKey 添加资源能够访问的 HTTP cookies
* AVURLAssetAllowsCellularAccessKey 是否能够使用蜂窝网络

创建并初始化一个 AVAsset 实例对象后，并不意味着该对象的所有属性都可以获取使用了，因为其中的一些属性需要额外的计算才能够得到，那么当获取这些属性时，可能会阻塞当前线程，所以需要异步获取这些属性。

AVAsset 与 AVAssetTrack 都遵循 **AVAsynchronousKeyValueLoading** 协议，这个协议中有以下两个方法：

```
//获取指定属性的状态
- (AVKeyValueStatus)statusOfValueForKey:(NSString *)key error:(NSError * _Nullable * _Nullable)outError;

//异步加载指定的属性集合
- (void)loadValuesAsynchronouslyForKeys:(NSArray<NSString *> *)keys completionHandler:(nullable void (^)(void))handler;
```
通常，我们使用上述第二个方法异步加载想要的属性，而后在加载完成的回调 block 中使用第一个方法判断属性是否加载成功，然后访问想要的属性，执行自己的操作，如下代码：

```
NSURL *url = <#资源路径#>;
AVURLAsset *anAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
NSArray *keys = @[@"duration",@"tracks"];
 
[asset loadValuesAsynchronouslyForKeys:keys completionHandler:^() {
 
    NSError *error = nil;
    AVKeyValueStatus tracksStatus = [asset statusOfValueForKey:@"tracks" error:&error];
    //根据相应的属性状态进行对应的处理
    switch (tracksStatus) {
        case AVKeyValueStatusUnknown:
				//TODO
	        break;
        case AVKeyValueStatusLoading:
				//TODO
	        break;
        case AVKeyValueStatusLoaded:
				//TODO
            break;
        case AVKeyValueStatusFailed:
				//TODO
            break;
        case AVKeyValueStatusCancelled:
				//TODO
            break;
   }
}];
```

### AVAssetImageGenerator
使用 AVAssetImageGenerator 生成视频资源的缩略图，使用 AVAsset 对象创建 AVAssetImageGenerator 对象，可以使用类方法或实例方法，如下：

```
+ (instancetype)assetImageGeneratorWithAsset:(AVAsset *)asset;
- (instancetype)initWithAsset:(AVAsset *)asset NS_DESIGNATED_INITIALIZER;
```
当然，在此之前，最好调用 AVAsset 中的方法 `- (NSArray<AVAssetTrack *> *)tracksWithMediaCharacteristic:(NSString *)mediaCharacteristic;` 来判断 asset 中是否有可视媒体数据。如果有，那么再创建 AVAssetImageGenerator 对象，而后再调用下面的方法，来获取一张或多张图片。

```
//获取一张图片，requestedTime 指定要获取视频中哪个时刻的图片，actualTime 返回图片实际是视频的哪个时刻，outError 返回错误信息
- (nullable CGImageRef)copyCGImageAtTime:(CMTime)requestedTime actualTime:(nullable CMTime *)actualTime error:(NSError * _Nullable * _Nullable)outError CF_RETURNS_RETAINED;

//获取多张图片，每一次图片生成后，都会调用一次 handler
- (void)generateCGImagesAsynchronouslyForTimes:(NSArray<NSValue *> *)requestedTimes completionHandler:(AVAssetImageGeneratorCompletionHandler)handler;

//上述 handler 的类型如下，回调中的参数有图片的请求时刻和实际时刻，图片，状态（成功、失败、取消），错误信息
typedef void (^AVAssetImageGeneratorCompletionHandler)(CMTime requestedTime, CGImageRef _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error);
```

### AVAssetExportSession
使用 AVAssetExportSession 类对视频进行裁剪及转码，即将一个 AVAsset 类实例修改后保存为另一个 AVAsset 类实例，最后保存到文件中。

在修改资源之前，为避免不兼容带来的错误，可以先调用下面的方法，检查预设置是否合理。

```
//获取与 asset 兼容的预设置
+ (NSArray<NSString *> *)exportPresetsCompatibleWithAsset:(AVAsset *)asset;

//判断提供的预设置和输出的文件类型是否与 asset 相兼容
+ (void)determineCompatibilityOfExportPreset:(NSString *)presetName withAsset:(AVAsset *)asset outputFileType:(nullable NSString *)outputFileType completionHandler:(void (^)(BOOL compatible))handler NS_AVAILABLE(10_9, 6_0);
```
除了设置文件类型外，还可以设置文件的大小、时长、范围等属性，一切准备就绪后，调用方法：

```
- (void)exportAsynchronouslyWithCompletionHandler:(void (^)(void))handler;
```
进行文件的导出，导出结束后，会调用 handler 回调，在回调中应该检查 AVAssetExportSession 的 status 属性查看导出是否成功，若指定的文件保存地址在沙盒外，或在导出的过程中有电话打入都会导致文件保存失败，如下例程：

```
- (void)exportVideo:(NSURL *)url {
    AVAsset *anAsset = [AVAsset assetWithURL:url];
    
    [AVAssetExportSession determineCompatibilityOfExportPreset:AVAssetExportPresetHighestQuality
                                                     withAsset:anAsset
                                                outputFileType:AVFileTypeMPEG4
                                             completionHandler:^(BOOL compatible) {
        if (compatible){
            AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:anAsset
                                                                                   presetName:AVAssetExportPresetHighestQuality];
            
            exportSession.outputFileType = AVFileTypeMPEG4;
            
            CMTime start = CMTimeMakeWithSeconds(1.0, 600);
            CMTime duration = CMTimeMakeWithSeconds(3.0, 600);
            CMTimeRange range = CMTimeRangeMake(start, duration);
            exportSession.timeRange = range;
            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                
                switch ([exportSession status]) {
                    case AVAssetExportSessionStatusCompleted:
                        NSLog(@"completed");
                        break;
                    case AVAssetExportSessionStatusFailed:
                        NSLog(@"failed");
                        break;
                    case AVAssetExportSessionStatusCancelled:
                        NSLog(@"canceled");
                        break;
                    default:
                        break;
                }
            }];
        }
    }];
}
```

## 媒体资源播放
使用一个 **AVPlayer** 类实例可以管理一个 asset 资源，但是它的属性 **currentItem** 才是 asset 的实际管理者。currentItem 是 **AVPlayerItem** 类的实例，而它的属性 **tracks** 包含着的 **AVPlayerItemTracker** 实例对应着 asset 中的各个 track 。

那么，为了控制 asset 的播放，可以使用 **AVPlayer** 类，在播放的过程中，可以使用 **AVPlayerItem** 实例管理整个 asset 的状态，使用 **AVPlayerItemTracker** 对象管理 asset 中每个 track 的状态。另外，还可以使用 **AVPlayerLayer** 类来显示播放的内容。

所以，在创建 AVPlayer 实例对象时，除了可以直接传递资源文件的路径进行创建外，还可以传递 AVPlayerItem 的实例对象，如下方法：

```
+ (instancetype)playerWithURL:(NSURL *)URL;
+ (instancetype)playerWithPlayerItem:(nullable AVPlayerItem *)item;
- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)initWithPlayerItem:(nullable AVPlayerItem *)item;
```
创建后，并不是可以直接使用，还要对它的状态进行检查，只有 status 的值为 **AVPlayerStatusReadyToPlay** 时，才能进行播放，所以这里需要使用 KVO 模式对该状态进行监控，以决定何时可以进行播放。

若要管理多个资源的播放，则应使用 AVPlayer 的子类 **AVQueuePlayer** ，这个子类拥有的多个 AVPlayerItem 同各个资源相对应。

### 不同类型的 asset
对于播放不同类型的资源，需要进行的准备工作有所不同，这主要取决于资源的来源。资源数据可能来自本地设备上文件的读取，也可能来自网络上数据流。

对于本地文件，可以使用文件地址创建 AVAsset 对象，而后使用该对象创建 AVPlayerItem 对象，最后将这个 item 对象与 AVPlayer 对象相关联。之后，便是等待 status 的状态变为 AVPlayerStatusReadyToPlay ，便可以进行播放了。

对于网络数据的播放，不能使用地址创建 AVAsset 对象了，而是直接创建 AVPlayerItem 对象，将其同 AVPlayer 对象相关联，当 status 状态变为 AVPlayerStatusReadyToPlay 后，AVAsset 和 AVAssetTrack 对象将由 item 对象创建。

### 播放控制
通过调用 player 的 **play** 、**pause** 、**setRate:** 方法，可以控制 item 的播放，这些方法都会改变 player 的属性 **rate** 的值，该值为 1 表示 item 按正常速率播放，为 0 表示 item 暂停播放，0～1 表示低速播放，大于 1 表示高速播放，小于 0 表示从后向前播放。

item 的属性 **timeControlStatus** 的值表示当前 item 的状态，有下面 3 个值：

* AVPlayerTimeControlStatusPaused 暂停
* AVPlayerTimeControlStatusPlaying 播放
* AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate 等待按指定速率播放状态，该状态是当 rate 的值设置为非 0 值时，而 item 因某些原因还无法播放的情况，而无法播放的原因，可依通过 item 的 **reasonForWaitingToPlay** 属性值查看。

item 的属性 **actionAtItemEnd** 的值表示当前 item 播放结束后的动作，有下面 3 个值：

* AVPlayerActionAtItemEndAdvance	只适用于 AVQueuePlayer 类，表示播放队列中的下一个 item
* AVPlayerActionAtItemEndPause 表示暂停
* AVPlayerActionAtItemEndNone 表示无操作，当前 item 的 **currentTime** 属性值仍然按 rate 的值改变

item 的 **currentTime** 属性值表示当前 item 的播放时间，可以调用下面的方法指定 item 从何处进行播放。

```
//第二个方法能够进行更准确的跳转，但是需要进行额外的计算
- (void)seekToDate:(NSDate *)date;
- (void)seekToTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter;

//这两个方法传入了一个回调，当一个时间跳转请求被新的请求或其他操作打断时，回调也会被执行但是此时 finished 参数值为 NO
- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler NS_AVAILABLE(10_7, 5_0);
- (void)seekToTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter completionHandler:(void (^)(BOOL finished))completionHandler NS_AVAILABLE(10_7, 5_0);
```

使用 **AVQueuePlayer** 管理多个 item 的播放，仍然可以通过调用 **play** 开始依次播放 item，调用 **advanceToNextItem** 方法播放下一个 item ，还可以通过下面的方法添加或移除 item 。

```
- (BOOL)canInsertItem:(AVPlayerItem *)item afterItem:(nullable AVPlayerItem *)afterItem;
- (void)insertItem:(AVPlayerItem *)item afterItem:(nullable AVPlayerItem *)afterItem;
- (void)removeItem:(AVPlayerItem *)item;
- (void)removeAllItems;
```

可以使用下面的方法监听播放时间的变化，需要强引用这两个方法返回的监听者。

```
- (id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(nullable dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block;
- (id)addBoundaryTimeObserverForTimes:(NSArray<NSValue *> *)times queue:(nullable dispatch_queue_t)queue usingBlock:(void (^)(void))block;
```
用上面的方法每注册一个监听者，就需要对应的使用下面的方法进行注销，并且在注销之前，要确保没有 block 被执行。

```
- (void)removeTimeObserver:(id)observer;
```

当 item 播放结束后，再次调用 player 的方法 play 不会使 item 重新播放，要实现重播，可以注册一个 **AVPlayerItemDidPlayToEndTimeNotification** 通知，当接收到这个通知时，可以调 **seekToTime:** 方法，传入 **kCMTimeZero** 参数，将 player 的播放时间重置。

## 媒体资源编辑基本类
AVFoundation 框架中提供了丰富的接口用于视听资源的编辑，其中的关键是 **composition** ，它将不同的 asset 相结合并形成一个新的 asset 。使用 **AVMutableComposition** 类可以增删 asset 来将指定的 asset 集合到一起。除此之外，若想将集合到一起的视听资源以自定义的方式进行播放，需要使用 **AVMutableAudioMix** 和 **AVMutableVideoComposition** 类对其中的资源进行协调管理。最终要使用 **AVAssetExportSession** 类将编辑的内容保存到文件中。

### AVComposition
同 AVAsset 拥有多个 AVAssetTrack 一样，作为子类的 AVComposition 也拥有多个 **AVCompositionTrack** ，而 AVCompositionTrack 是 AVAssetTrack 的子类。所以，AVComposition 实例对象是多个 track 的集合，真正描述媒体属性的是 AVCompositionTrack 实例对象。而 AVCompositionTrack 又是媒体数据片段的集合，这些数据片段由 **AVCompositionTrackSegment** 类进行描述。

该类的相关属性和方法如下：

```
//获取 composition 中包含的 tracks
@property (nonatomic, readonly) NSArray<AVCompositionTrack *> *tracks;

//获取 composition 中可视媒体资源播放时在屏幕上显示的大小
@property (nonatomic, readonly) CGSize naturalSize;

//获取 composition 生成 asset 时的指定配置
@property (nonatomic, readonly, copy) NSDictionary<NSString *, id> *URLAssetInitializationOptions NS_AVAILABLE(10_11, 9_0);

//根据不同的参数，获取 composition 中的 track
- (nullable AVCompositionTrack *)trackWithTrackID:(CMPersistentTrackID)trackID;
- (NSArray<AVCompositionTrack *> *)tracksWithMediaType:(NSString *)mediaType;
- (NSArray<AVCompositionTrack *> *)tracksWithMediaCharacteristic:(NSString *)mediaCharacteristic;
```
值得注意的是 AVComposition 类中并没有提供初始化方法，一般我们使用它的子类 AVMutableComposition ，进行各种操作后，再生成 AVComposition 实例以供查询，如下例程：

```
AVMutableComposition *mutableComposition = [AVMutableComposition composition];

//进行添加资源等操作
<#····#>

//使用可变的 composition 生成一个不可变的 composition 以供使用
AVComposition *composition = [myMutableComposition copy];
AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:composition];
```

### AVMutableComposition
**AVMutableComposition** 是 AVComposition 的子类，其包含的 tracks 则是 AVCompositionTrack 的子类 **AVMutableCompositionTrack** 。

AVMutableComposition 中提供了两个类方法用来获取一个空的 AVMutableComposition 实例对象。

```
+ (instancetype)composition;
+ (instancetype)compositionWithURLAssetInitializationOptions:(nullable NSDictionary<NSString *, id> *)URLAssetInitializationOptions NS_AVAILABLE(10_11, 9_0);
```
对整个 composition 中的 tracks 的修改方法如下：

```
//将指定时间段的 asset 中的所有的 tracks 添加到 composition 中 startTime 处
//该方法可能会在 composition 中添加新的 track 以便 asset 中 timeRange 范围中的所有 tracks 都添加到 composition 中
- (BOOL)insertTimeRange:(CMTimeRange)timeRange ofAsset:(AVAsset *)asset atTime:(CMTime)startTime error:(NSError * _Nullable * _Nullable)outError;

//向 composition 中的所有 tracks 添加空的时间范围
- (void)insertEmptyTimeRange:(CMTimeRange)timeRange;

//从 composition 的所有 tracks 中删除一段时间，该操作不会删除 track ，而是会删除与该时间段相交的 track segment
- (void)removeTimeRange:(CMTimeRange)timeRange;

//改变 composition 中的所有的 tracks 的指定时间范围的时长，该操作会改变 asset 的播放速度
- (void)scaleTimeRange:(CMTimeRange)timeRange toDuration:(CMTime)duration;
```
从 composition 中获取 track 或向其中添加／移除 track 方法如下：

```
//向 composition 中添加一个空的 track ，并且指定媒体资源类型及 trackID 属性值
//若提供的参数 preferredTrackID 无效或为 kCMPersistentTrackID_Invalid ，那么唯一的 trackID 会自动生成
- (AVMutableCompositionTrack *)addMutableTrackWithMediaType:(NSString *)mediaType preferredTrackID:(CMPersistentTrackID)preferredTrackID;

//从 composition 中删除一个指定的 track
- (void)removeTrack:(AVCompositionTrack *)track;

//获取一个与 asset track 相兼容的 composition track 
//为了更好的性能，composition track 的数量应保持最小，这个数量与必需并行播放的媒体数据段数量以及媒体数据的类型相关
//对于能够线性执行且类型相同的媒体数据应使用同一个 composition track ，即使这些数据来自不同的 asset
- (nullable AVMutableCompositionTrack *)mutableTrackCompatibleWithTrack:(AVAssetTrack *)track;
```
AVMutableComposition 中也提供了过滤 AVMutableCompositionTrack 的接口

```
- (nullable AVMutableCompositionTrack *)trackWithTrackID:(CMPersistentTrackID)trackID;
- (NSArray<AVMutableCompositionTrack *> *)tracksWithMediaType:(NSString *)mediaType;
- (NSArray<AVMutableCompositionTrack *> *)tracksWithMediaCharacteristic:(NSString *)mediaCharacteristic;
```

### AVCompositionTrack
AVCompositionTrack 类同其父类 **AVAssetTrack** 一样是媒体资源的管理者，它实际是媒体资源数据的集合，它的属性 **segments** 是 **AVCompositionTrackSegment** 类的实例对象集合，每个对象描述一个媒体数据片段。类 AVCompositionTrack 并不常用，通常使用的是它的子类 **AVMutableCompositionTrack** 。

### AVMutableCompositionTrack
AVMutableCompositionTrack 中提供的属性如下：

```
//没有外部数值指定时，媒体1秒钟时间的粒度
@property (nonatomic) CMTimeScale naturalTimeScale;

//当前 track 相关联的语言编码
@property (nonatomic, copy, nullable) NSString *languageCode;

//当前 track 相关联的额外语言编码
@property (nonatomic, copy, nullable) NSString *extendedLanguageTag;

//对于可显示的媒体数据应优先选择的仿射变换设置，默认值为 CGAffineTransformIdentity
@property (nonatomic) CGAffineTransform preferredTransform;

//应优先选择的音量，默认值为 1
@property (nonatomic) float preferredVolume;

//当前track 所包含的所有的媒体数据片段，对于这些片段，它们构成了 track 的完整时间线，
//所以他们的时间线不可以重叠，并且第一个数据片段的时间从 kCMTimeZero 开始，依次往后的时间必须连续不间断、不重叠
@property (nonatomic, copy, null_resettable) NSArray<AVCompositionTrackSegment *> *segments;
```
当我们获取了一个 AVMutableCompositionTrack 实例对象后，便可以通过以下方法对其进行添加或移除数据片段

```
//将已存在的资源文件指定时间范围的媒体数据插入到当前 composition 的指定时间处
//如果 startTime 为 kCMTimeInvalid 值，那么数据被添加到 composition 的最后
- (BOOL)insertTimeRange:(CMTimeRange)timeRange ofTrack:(AVAssetTrack *)track atTime:(CMTime)startTime error:(NSError * _Nullable * _Nullable)outError;

//这个方法与上述方法类似，只是可以批量操作，但是注意提供的时间范围不能重叠
- (BOOL)insertTimeRanges:(NSArray<NSValue *> *)timeRanges ofTracks:(NSArray<AVAssetTrack *> *)tracks atTime:(CMTime)startTime error:(NSError * _Nullable * _Nullable)outError NS_AVAILABLE(10_8, 5_0);

//插入一个没有媒体数据的时间段，当这个范围之前的媒体资源播放结束后，不会立刻播放之后的媒体数据，而是会静默一段时间
- (void)insertEmptyTimeRange:(CMTimeRange)timeRange;

//移除一段时间范围的媒体数据，该方法不会导致该 track 从 composition 中移除，只是移除与时间范围相交的数据片段
- (void)removeTimeRange:(CMTimeRange)timeRange;

//改变某个时间范围内的时间的时长，实质是改变了媒体数据的播放速率
//其速率是原时长与现时长的比值，总之，媒体数据是要按时长播放的
- (void)scaleTimeRange:(CMTimeRange)timeRange toDuration:(CMTime)duration;

//判断数据片段的时间线是否重叠
- (BOOL)validateTrackSegments:(NSArray<AVCompositionTrackSegment *> *)trackSegments error:(NSError * _Nullable * _Nullable)outError;
```

### AVAssetTrackSegment
媒体资源 AVAsset 中的集合 AVAssetTrack 管理着单条时间线上的媒体数据片段，而每个数据片段则由 **AVAssetTrackSegment** 类进行描述。

AVAssetTrackSegment 有两个属性

* timeMapping 描述的是数据片段在整个媒体文件中所处的时间范围

	```
	timeMapping 是一个结构体，拥有两个成员，对于编辑中的媒体数据片段，它们分别表示数据在源文件中的位置和目标文件中的位置
	typedef struct 
	{
		CMTimeRange source; 
		CMTimeRange target; 
	} CMTimeMapping;
	```
* empty 描述该数据片段是否为空，如果为空，其 timeMapping.source.start 为 **kCMTimeInvalid**

### AVCompositionTrackSegment
在编辑媒体文件时，在描述数据时，使用的是 AVAssetTrackSegment 的子类 **AVCompositionTrackSegment** ，她的主要属性和方法如下：

```
//判断数据片段是否为空，若为空 timeMapping.target 可为有效值，其他为未定义值
@property (nonatomic, readonly, getter=isEmpty) BOOL empty;

//片段数据所处的文件的地址
@property (nonatomic, readonly, nullable) NSURL *sourceURL;

//片段数据所处文件的描述 asset track 的 ID
@property (nonatomic, readonly) CMPersistentTrackID sourceTrackID;

//创建对象，提供了数据片段所在的文件、文件的描述 asset track 的 ID 、源文件中的数据时间范围、目标文件中所处的时间范围
//sourceTimeRange 与 targetTimeRange 的时间长度如果不一致，那么播放的速率会改变
+ (instancetype)compositionTrackSegmentWithURL:(NSURL *)URL trackID:(CMPersistentTrackID)trackID sourceTimeRange:(CMTimeRange)sourceTimeRange targetTimeRange:(CMTimeRange)targetTimeRange;
- (instancetype)initWithURL:(NSURL *)URL trackID:(CMPersistentTrackID)trackID sourceTimeRange:(CMTimeRange)sourceTimeRange targetTimeRange:(CMTimeRange)targetTimeRange NS_DESIGNATED_INITIALIZER;

//创建仅有时间范围而无实际媒体数据的实例
+ (instancetype)compositionTrackSegmentWithTimeRange:(CMTimeRange)timeRange;
- (instancetype)initWithTimeRange:(CMTimeRange)timeRange NS_DESIGNATED_INITIALIZER; 
```

## 音频的自定义播放
要在媒体资源播放的过程中实现音频的自定义播放，需要用 **AVMutableAudioMix** 对不同的音频进行编辑。这个类的实例对象的属性 **inputParameters** 是音量描述对象的集合，每个对象都是对一个 audio track 的音量变化的描述，如下示例：

```
AVMutableAudioMix *mutableAudioMix = [AVMutableAudioMix audioMix];

AVMutableAudioMixInputParameters *mixParameters1 = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionAudioTrack1];
[mixParameters1 setVolumeRampFromStartVolume:1.f toEndVolume:0.f timeRange:CMTimeRangeMake(kCMTimeZero, mutableComposition.duration/2)];
[mixParameters1 setVolumeRampFromStartVolume:0.f toEndVolume:1.f timeRange:CMTimeRangeMake(mutableComposition.duration/2, mutableComposition.duration)];

AVMutableAudioMixInputParameters *mixParameters2 = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionAudioTrack2];
[mixParameters2 setVolumeRampFromStartVolume:1.f toEndVolume:0.f timeRange:CMTimeRangeMake(kCMTimeZero, mutableComposition.duration)];

mutableAudioMix.inputParameters = @[mixParameters1, mixParameters2];
```

### AVAudioMix
该类中有一个属性 **inputParameters** ，它是 **AVAudioMixInputParameters** 实例对象的集合，每个实例都是对音频播放方式的描述。可见，AVAudioMix 并不直接改变音频播放的方式，其只是存储了音频播放的方式。

### AVMutableAudioMix
AVMutableAudioMix 是 AVAudioMix 的子类，它的方法 **audioMix** 返回一个 inputParameters 属性为空的实例。

### AVAudioMixInputParameters
这个类是音量变化的描述类，它同一个音频的 track 相关联，并设置音量随时间变化的算法，其获取音量变化的方法如下：

```
//获取的音量变化范围 timeRange 应包含指定的时刻 time 否则最终返回 NO
//startVolume 获取音量开始变化时的初始音量
//endVolume 获取音量变化结束时的音量
//timeRang 是实际音量变化的范围，它应该包含指定的 time
- (BOOL)getVolumeRampForTime:(CMTime)time startVolume:(nullable float *)startVolume endVolume:(nullable float *)endVolume timeRange:(nullable CMTimeRange *)timeRange;
```

### AVMutableAudioMixInputParameters
AVMutableAudioMixInputParameters 是 AVAudioMixInputParameters 的子类，它提供了直接设置某个时刻或时间段的音量的方法。

```
//根据提供的 track 创建一个实例，此时的音量描述数据为空
+ (instancetype)audioMixInputParametersWithTrack:(nullable AVAssetTrack *)track;

//创建一个实例，此时的音量变化描述是空的，且 trackID 为 kCMPersistentTrackID_Invalid
+ (instancetype)audioMixInputParameters;

//设置某个时间范围内的初始音量及结束音量
- (void)setVolumeRampFromStartVolume:(float)startVolume toEndVolume:(float)endVolume timeRange:(CMTimeRange)timeRange;

//设置某个时刻的音量
- (void)setVolume:(float)volume atTime:(CMTime)time;
```

## 视频的自定义播放
同音频的自定义播放一样，要实现视频的自定义播放，仅仅将视频资源集合到一起是不够的，需要使用 **AVMutableVideoComposition** 类来定义不同的视频资源在不同的时间范围内的播放方式。

### AVVideoComposition
AVVideoComposition 是 AVMutableVideoComposition 的父类，它的主要属性和方法如下：

```
//该类的构造类，提供自定义的构造类时，提供的类要遵守 AVVideoCompositing 协议
@property (nonatomic, readonly, nullable) Class<AVVideoCompositing> customVideoCompositorClass NS_AVAILABLE(10_9, 7_0);

//视频每一帧的刷新时间
@property (nonatomic, readonly) CMTime frameDuration;

//视频显示时的大小范围
@property (nonatomic, readonly) CGSize renderSize;

//视频显示范围大小的缩放比例（仅仅对 iOS 有效）
@property (nonatomic, readonly) float renderScale;

//描述视频集合中具体视频播放方式信息的集合，其是遵循 AVVideoCompositionInstruction 协议的类实例对象
//这些视频播放信息构成一个完整的时间线，不能重叠，不能间断，并且在数组中的顺序即为相应视频的播放顺序
@property (nonatomic, readonly, copy) NSArray<id <AVVideoCompositionInstruction>> *instructions;

//用于组合视频帧与动态图层的 Core Animation 的工具对象，可以为 nil 
@property (nonatomic, readonly, retain, nullable) AVVideoCompositionCoreAnimationTool *animationTool;

//直接使用一个 asset 创建一个实例，创建的实例的各个属性会根据 asset 中的所有的 video tracks 的属性进行计算并适配，所以在调用该方法之前，确保 asset 中的属性已经加载
//返回的实例对象的属性 instructions 中的对象会对应每个 asset 中的 track 中属性要求
//返回的实例对象的属性 frameDuration 的值是 asset 中 所有 track 的 nominalFrameRate 属性值最大的，如果这些值都为 0 ，默认为 30fps
//返回的实例对象的属性 renderSize 的值是 asset 的 naturalSize 属性值，如果 asset 是 AVComposition 类的实例。否则，renderSize 的值将包含每个 track 的 naturalSize 属性值
+ (AVVideoComposition *)videoCompositionWithPropertiesOfAsset:(AVAsset *)asset NS_AVAILABLE(10_9, 6_0);

//这三个属性设置了渲染帧时的颜色空间、矩阵、颜色转换函数，可能的值都在 AVVideoSetting.h 文件中定义
@property (nonatomic, readonly, nullable) NSString *colorPrimaries NS_AVAILABLE(10_12, 10_0);
@property (nonatomic, readonly, nullable) NSString *colorYCbCrMatrix NS_AVAILABLE(10_12, 10_0);
@property (nonatomic, readonly, nullable) NSString *colorTransferFunction NS_AVAILABLE(10_12, 10_0);

//该方法返回一个实例，它指定的 block 会对 asset 中每一个有效的 track 的每一帧进行渲染得到 CIImage 实例对象
//在 block 中进行每一帧的渲染，成功后应调用 request 的方法 finishWithImage:context: 并将得到的 CIImage 对象作为参数
//若是渲染失败，则应调用 finishWithError: 方法并传递错误信息

+ (AVVideoComposition *)videoCompositionWithAsset:(AVAsset *)asset
			 applyingCIFiltersWithHandler:(void (^)(AVAsynchronousCIImageFilteringRequest *request))applier NS_AVAILABLE(10_11, 9_0);
```

### AVMutableVideoComposition
AVMutableVideoComposition 是 AVVideoComposition 的可变子类，它继承父类的属性可以改变，并且新增了下面的创建方法。

```
//这个方法创建的实例对象的属性的值都是 nil 或 0，但是它的属性都是可以进行修改的
+ (AVMutableVideoComposition *)videoComposition;
```

### AVVideoCompositionInstruction
在上述的两个类中，真正包含有视频播放方式信息的是 instructions 属性，这个集合中的对象都遵循 AVVideoCompositionInstruction 协议，若不使用自定义的类，那么可以使用 AVFoundation 框架中的 **AVVideoCompositionInstruction** 类。

该类的相关属性如下：

```
//表示该 instruction 生效的时间范围
@property (nonatomic, readonly) CMTimeRange timeRange;

//指定当前时间段的 composition 的背景色
//如果没有指定，那么使用默认的黑色
//如果渲染的像素没有透明度通道，那么这个颜色也会忽略透明度
@property (nonatomic, readonly, retain, nullable) __attribute__((NSObject)) CGColorRef backgroundColor;

//AVVideoCompositionLayerInstruction 类实例对象的集合，描述各个视频资源帧的层级及组合关系
//按这个数组的顺序，第一个显示在第一层，第二个在第一层下面显示，以此类推
@property (nonatomic, readonly, copy) NSArray<AVVideoCompositionLayerInstruction *> *layerInstructions;

//表明该时间段的视频帧是否需要后期处理
//若为 NO，后期图层的处理将跳过该时间段，这样能够提高效率
//为 YES 则按默认操作处理（参考 AVVideoCompositionCoreAnimationTool 类）
@property (nonatomic, readonly) BOOL enablePostProcessing;

//当前 instruction 中需要进行帧组合的所有的 track ID 的集合，由属性 layerInstructions 计算得到
@property (nonatomic, readonly) NSArray<NSValue *> *requiredSourceTrackIDs NS_AVAILABLE(10_9, 7_0);

//如果当前的 instruction 在该时间段内的视频帧组合后，实质得到的是某个源视频的帧，那么就返回这个视频资源的 ID
@property (nonatomic, readonly) CMPersistentTrackID passthroughTrackID NS_AVAILABLE(10_9, 7_0); 
```

### AVMutableVideoCompositionInstruction
AVMutableVideoCompositionInstruction 是 AVVideoCompositionInstruction 的子类，其继承的父类的属性可进行修改，并且提供了创建属性值为 nil 或无效的实例的方法。

```
+ (instancetype)videoCompositionInstruction;
```

### AVVideoCompositionLayerInstruction
AVVideoCompositionLayerInstruction 是对给定的视频资源的不同播放方式进行描述的类，通过下面的方法，可以获取仿射变化、透明度变化、裁剪区域变化的梯度信息。

```
//获取包含指定时间的仿射变化梯度信息
//startTransform、endTransform 用来接收变化过程的起始值与结束值
//timeRange 用来接收变化的持续时间范围
//返回值表示指定的时间 time 是否在变化时间 timeRange 内
- (BOOL)getTransformRampForTime:(CMTime)time startTransform:(nullable CGAffineTransform *)startTransform endTransform:(nullable CGAffineTransform *)endTransform timeRange:(nullable CMTimeRange *)timeRange;

//获取包含指定时间的透明度变化梯度信息
//startOpacity、endOpacity 用来接收透明度变化过程的起始值与结束值
//timeRange 用来接收变化的持续时间范围
//返回值表示指定的时间 time 是否在变化时间 timeRange 内
- (BOOL)getOpacityRampForTime:(CMTime)time startOpacity:(nullable float *)startOpacity endOpacity:(nullable float *)endOpacity timeRange:(nullable CMTimeRange *)timeRange;

//获取包含指定时间的裁剪区域的变化梯度信息
//startCropRectangle、endCropRectangle 用来接收变化过程的起始值与结束值
//timeRange 用来接收变化的持续时间范围
//返回值表示指定的时间 time 是否在变化时间 timeRange 内
- (BOOL)getCropRectangleRampForTime:(CMTime)time startCropRectangle:(nullable CGRect *)startCropRectangle endCropRectangle:(nullable CGRect *)endCropRectangle timeRange:(nullable CMTimeRange *)timeRange NS_AVAILABLE(10_9, 7_0);
```

### AVMutableVideoCompositionLayerInstruction
AVMutableVideoCompositionLayerInstruction 是 AVVideoCompositionLayerInstruction 的子类，它可以改变 composition 中的 track 资源播放时的仿射变化、裁剪区域、透明度等信息。

相比于父类，该子类还提供了创建实例的方法：

```
//这两个方法的区别在于，前者返回的实例对象的属性 trackID 的值是 track 的 trackID 值
//而第二个方法的返回的实例对象的属性 trackID 的值为 kCMPersistentTrackID_Invalid
+ (instancetype)videoCompositionLayerInstructionWithAssetTrack:(AVAssetTrack *)track;
+ (instancetype)videoCompositionLayerInstruction;
```
该类的属性表示 instruction 所作用的 track 的 ID

```
@property (nonatomic, assign) CMPersistentTrackID trackID;
```
设置了 trackID 后，通过下面的方法，进行剃度信息的设置：

```
//设置视频中帧的仿射变化信息
//指定了变化的时间范围、起始值和结束值，其中坐标系的原点为左上角，向下向右为正方向
- (void)setTransformRampFromStartTransform:(CGAffineTransform)startTransform toEndTransform:(CGAffineTransform)endTransform timeRange:(CMTimeRange)timeRange;

//设置 instruction 的 timeRange 范围内指定时间的仿射变换，该值会一直保持，直到被再次设置
- (void)setTransform:(CGAffineTransform)transform atTime:(CMTime)time;

//设置透明度的梯度信息，提供的透明度初始值和结束值应在0～1之间
//变化的过程是线形的
- (void)setOpacityRampFromStartOpacity:(float)startOpacity toEndOpacity:(float)endOpacity timeRange:(CMTimeRange)timeRange;

//设置指定时间的透明度，该透明度会一直持续到下一个值被设置
- (void)setOpacity:(float)opacity atTime:(CMTime)time;

//设置裁剪矩形的变化信息
- (void)setCropRectangleRampFromStartCropRectangle:(CGRect)startCropRectangle toEndCropRectangle:(CGRect)endCropRectangle timeRange:(CMTimeRange)timeRange NS_AVAILABLE(10_9, 7_0);

//设置指定时间的裁剪矩形
- (void)setCropRectangle:(CGRect)cropRectangle atTime:(CMTime)time NS_AVAILABLE(10_9, 7_0);
```

### AVVideoCompositionCoreAnimationTool
在自定义视频播放时，可能需要添加水印、标题或者其他的动画效果，需要使用该类。该类通常用来协调离线视频中图层与动画图层的组合（如使用 AVAssetExportSession 和 AVAssetReader 、AVAssetReader 类导出视频文件或读取视频文件时），而若是在线实时的视频播放，应使用 AVSynchronizedLayer 类来同步视频的播放与动画的效果。

在使用该类时，注意动画在整个视频的时间线上均可以被修改，所以，动画的开始时间应该设置为 **AVCoreAnimationBeginTimeAtZero** ，这个值其实比 0 大，属性值 **removedOnCompletion** 应该置为 NO，以防当动画执行结束后被移除，并且不应使用与任何的 UIView 相关联的图层。

作为视频组合的后期处理工具类，主要方法如下：

```
//向视频组合中添加一个动画图层，这个图层不能在任何图层树中
//提供的参数 trackID 应由方法 [AVAsset unusedTrackID] 得到，它不与任何视频资源的 trackID 相关
//AVVideoCompositionInstruction 的属性 layerInstructions 包含的 AVVideoCompositionLayerInstruction 实例对象中应该有
//该 trackID 一致的 AVVideoCompositionLayerInstruction 实例对象，并且为性能考虑，不应使用该对象设置 transform 的变化
//在 iOS 中，CALayer 作为 UIView 的背景图层，其内容的是否能够翻转，由方法 contentsAreFlipped 决定（如果所有的图层包括子图层，该方法返回的值为 YES 的个数为奇数个，表示可以图层中内容可以垂直翻转）
//所以这里的 layer 若用来设置 UIView 的 layer 属性，或作为其中的子图层，其属性值 geometryFlipped 应设置为 YES ，这样则能够保持是否能够翻转的结果一致
+ (instancetype)videoCompositionCoreAnimationToolWithAdditionalLayer:(CALayer *)layer asTrackID:(CMPersistentTrackID)trackID;

//将放在图层 videoLayer 中的组合视频帧同动画图层 animationLayer 中的内容一起进行渲染，得到最终的视频帧
//通常，videoLayer 是 animationLayer 的子图层，而 animationLayer 则不在任何图层树中
+ (instancetype)videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:(CALayer *)videoLayer inLayer:(CALayer *)animationLayer;

//复制 videoLayers 中的每一个图层，与 animationLayer一起渲染得到最中的帧
////通常，videoLayers 中的图层都在 animationLayer 的图层树中，而 animationLayer 则不属于任何图层树
+ (instancetype)videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayers:(NSArray<CALayer *> *)videoLayers inLayer:(CALayer *)animationLayer NS_AVAILABLE(10_9, 7_0);
```

### AVVideoCompositionValidationHandling
当我们经过编辑后得到一个视频资源 asset ，并且为该资源设置了自定义播放信息 video composition ，需要验证对于这个 asset 而言，video composition 是否有效，可以调用 AVVideoComposition 的校验方法。

```
/*
@param asset 
设置第一个参数的校验内容，设置 nil 忽略这些校验
1. 该方法可以校验 AVVideoComposition 的属性 instructions 是否符合要求
2. 校验 instructions 中的每个 AVVideoCompositionInstruction 对象的 layerInstructions 属性中的
每一个 AVVideoCompositionLayerInstruction 对象 trackID 值是否对应 asset 中 track 的 ID 
或 AVVideoComposition 的 animationTool 实例
3. 校验时间 asset 的时长是否与 instructions 中的时间范围相悖

@param timeRange 
设置第二个参数的校验内容
1. 校验 instructions 的所有的时间范围是否在提供的 timeRange 的范围内，
若要忽略该校验，可以传参数 CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity)

@param validationDelegate 
设置遵循 AVVideoCompositionValidationHandling 协议的代理类，用来处理校验过程中的报错，可以为 nil 
*/
- (BOOL)isValidForAsset:(nullable AVAsset *)asset timeRange:(CMTimeRange)timeRange validationDelegate:(nullable id<AVVideoCompositionValidationHandling>)validationDelegate NS_AVAILABLE(10_8, 5_0);
```
设置的代理对象要遵循协议 **AVVideoCompositionValidationHandling** ，该对象在实现下面的协议方法时，若修改了传递的 composition 参数，上面的校验方法则会抛出异常。

该协议提供了以下回调方法，所有方法的返回值用来确定是否继续进行校验以获取更多的错误。

```
//报告 videoComposition 中有无效的值
- (BOOL)videoComposition:(AVVideoComposition *)videoComposition shouldContinueValidatingAfterFindingInvalidValueForKey:(NSString *)key NS_AVAILABLE(10_8, 5_0);

//报告 videoComposition 中有时间段没有相对应的 instruction
- (BOOL)videoComposition:(AVVideoComposition *)videoComposition shouldContinueValidatingAfterFindingEmptyTimeRange:(CMTimeRange)timeRange NS_AVAILABLE(10_8, 5_0);

//报告 videoComposition 中的 instructions 中 timeRange 无效的实例对象
//可能是 timeRange 本身为 CMTIMERANGE_IS_INVALID 
//或者是该时间段同上一个的 instruction 的 timeRange 重叠
//也可能是其开始时间比上一个的 instruction 的 timeRange 的开始时间要早
- (BOOL)videoComposition:(AVVideoComposition *)videoComposition shouldContinueValidatingAfterFindingInvalidTimeRangeInInstruction:(id<AVVideoCompositionInstruction>)videoCompositionInstruction NS_AVAILABLE(10_8, 5_0);

//报告 videoComposition 中的 layer instruction 同调用校验方法时指定的 asset 中 track 的 trackID 不一致
//也不与 composition 使用的 animationTool 的trackID 一致
- (BOOL)videoComposition:(AVVideoComposition *)videoComposition shouldContinueValidatingAfterFindingInvalidTrackIDInInstruction:(id<AVVideoCompositionInstruction>)videoCompositionInstruction layerInstruction:(AVVideoCompositionLayerInstruction *)layerInstruction asset:(AVAsset *)asset NS_AVAILABLE(10_8, 5_0);

```

### 例程
下面的例子给出了将两个视频资源和一个音频资源编辑组合为一个资源文件的步骤。

1. 要组合多个视听资源，需要先创建一个 **AVMutableComposition** 实例对象，用来组合资源。
2. 然后向 composition 中添加 **AVMutableCompositionTrack** 实例对象，为性能考虑，对于非同时播放且相同类型的资源，应使用一个 AVMutableCompositionTrack 实例对象，所以这里添加一个视频类型的 composition track 和一个音频类型的 composition track 即可。

	```
	AVMutableComposition *mutableComposition = [AVMutableComposition composition];
	
	AVMutableCompositionTrack *videoCompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	
	AVMutableCompositionTrack *audioCompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	```
	
3. 获得了拥有 composition track 的 composition 后，下一步就是将具体的视听资源添加到组合中。

	```
	AVURLAsset *firstVideoAsset = [AVURLAsset URLAssetWithURL:firstVideoUrl options:nil];
	AVURLAsset *secondVideoAsset = [AVURLAsset URLAssetWithURL:secondVideoUrl options:nil];
	AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:audioUrl options:nil];
	
	//获取视听资源中的第一个 asset track
	AVAssetTrack *firstVideoAssetTrack = [[firstVideoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
	AVAssetTrack *secondVideoAssetTrack = [[secondVideoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
	AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
	
	//第一个视频插入的时间点是 kCMTimeZero
	[videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstVideoAssetTrack.timeRange.duration) ofTrack:firstVideoAssetTrack atTime:kCMTimeZero error:nil];
	
	//第二个视频插入的时间点是第一个视频结束的时间
	[videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondVideoAssetTrack.timeRange.duration) ofTrack:secondVideoAssetTrack atTime:firstVideoAssetTrack.timeRange.duration error:nil];
	
	//音频的持续时间是两个视频时间的总和
	CMTime videoTotalDuration = CMTimeAdd(firstVideoAssetTrack.timeRange.duration, secondVideoAssetTrack.timeRange.duration);
	[audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoTotalDuration) ofTrack: atTime:kCMTimeZero error:nil];
	
	```
	
4. 检查视频的镜头是否是横向模式，组合时，video track 总是被认为是横向模式，如果待组合的 video track 是纵向模式，那么最终的视频显示将不符合预想，而且无法将横向模式和纵向模式的的视频组合到一起。
	
	```
	//判断第一个视频的模式
	BOOL isFirstVideoPortrait = NO;
	CGAffineTransform firstTransform = firstVideoAssetTrack.preferredTransform;
	if (firstTransform.a == 0 && firstTransform.d == 0 && (firstTransform.b == 1.0 || firstTransform.b == -1.0) && (firstTransform.c == 1.0 || firstTransform.c == -1.0)) {
	    isFirstVideoPortrait = YES;
	}
	
	//判断第二个视频的模式
	BOOL isSecondVideoPortrait = NO;
	CGAffineTransform secondTransform = secondVideoAssetTrack.preferredTransform;
	if (secondTransform.a == 0 && secondTransform.d == 0 && (secondTransform.b == 1.0 || secondTransform.b == -1.0) && (secondTransform.c == 1.0 || secondTransform.c == -1.0)) {
	    isSecondVideoPortrait = YES;
	}
	
	//判断两个视频的模式是否一致
	if ((isFirstVideoAssetPortrait && !isSecondVideoAssetPortrait) || (!isFirstVideoAssetPortrait && isSecondVideoAssetPortrait)) {
	    UIAlertView *incompatibleVideoOrientationAlert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Cannot combine a video shot in portrait mode with a video shot in landscape mode." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
	    [incompatibleVideoOrientationAlert show];
	    return;
	}
	```
	
5. 当每个视频的方向是兼容的，那么可以对每个视频的图层进行必要的调整。
	
	```
	AVMutableVideoCompositionInstruction *firstVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
	firstVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstVideoAssetTrack.timeRange.duration);
	
	AVMutableVideoCompositionInstruction * secondVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
	secondVideoCompositionInstruction.timeRange = CMTimeRangeMake(firstVideoAssetTrack.timeRange.duration, secondVideoAssetTrack.timeRange.duration);
	
	AVMutableVideoCompositionLayerInstruction *firstVideoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
	[firstVideoLayerInstruction setTransform:firstTransform atTime:kCMTimeZero];
	
	AVMutableVideoCompositionLayerInstruction *secondVideoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
	[secondVideoLayerInstruction setTransform:secondTransform atTime:firstVideoAssetTrack.timeRange.duration];
	
	firstVideoCompositionInstruction.layerInstructions = @[firstVideoLayerInstruction];
	secondVideoCompositionInstruction.layerInstructions = @[secondVideoLayerInstruction];
	
	AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
	mutableVideoComposition.instructions = @[firstVideoCompositionInstruction, secondVideoCompositionInstruction];
	```
	
6. 检查视频方向的兼容性之后，需要调整视频组合渲染区域的大小，设置视频帧的刷新频率，以兼容每一个视频的播放。

	```
	//获取视频的原播放区域
	CGSize naturalSizeFirst, naturalSizeSecond;
	if (isFirstVideoAssetPortrait) {
	    naturalSizeFirst = CGSizeMake(firstVideoAssetTrack.naturalSize.height, firstVideoAssetTrack.naturalSize.width);
	    naturalSizeSecond = CGSizeMake(secondVideoAssetTrack.naturalSize.height, secondVideoAssetTrack.naturalSize.width);
	} else {
	    naturalSizeFirst = firstVideoAssetTrack.naturalSize;
	    naturalSizeSecond = secondVideoAssetTrack.naturalSize;
	}
	
	//设置的渲染区域要能包含两个视频的播放区域
	float renderWidth, renderHeight;
	if (naturalSizeFirst.width > naturalSizeSecond.width) {
	    renderWidth = naturalSizeFirst.width;
	} else {
	    renderWidth = naturalSizeSecond.width;
	}
	if (naturalSizeFirst.height > naturalSizeSecond.height) {
	    renderHeight = naturalSizeFirst.height;
	} else {
	    renderHeight = naturalSizeSecond.height;
	}
	mutableVideoComposition.renderSize = CGSizeMake(renderWidth, renderHeight);
	
	//设置帧每一秒刷新30次
	mutableVideoComposition.frameDuration = CMTimeMake(1,30);
	```

7. 最后将组合的视听资源导出到一个单独的文件中并保存到资源库。

	```
	static NSDateFormatter *kDateFormatter;
	if (!kDateFormatter) {
	    kDateFormatter = [[NSDateFormatter alloc] init];
	    kDateFormatter.dateStyle = NSDateFormatterMediumStyle;
	    kDateFormatter.timeStyle = NSDateFormatterShortStyle;
	}
	
	AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mutableComposition presetName:AVAssetExportPresetHighestQuality];
	
	exporter.outputURL = [[[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:@YES error:nil] URLByAppendingPathComponent:[kDateFormatter stringFromDate:[NSDate date]]] URLByAppendingPathExtension:CFBridgingRelease(UTTypeCopyPreferredTagWithClass((CFStringRef)AVFileTypeQuickTimeMovie, kUTTagClassFilenameExtension))];
	
	exporter.outputFileType = AVFileTypeQuickTimeMovie;
	exporter.shouldOptimizeForNetworkUse = YES;
	exporter.videoComposition = mutableVideoComposition;
	
	//异步导出
	[exporter exportAsynchronouslyWithCompletionHandler:^{
	    dispatch_async(dispatch_get_main_queue(), ^{
	        if (exporter.status == AVAssetExportSessionStatusCompleted) {
		         //保存文件到媒体库
	            ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];            
	            if ([assetsLibrary videoAtPathIsCompatibleWithSavedPhotosAlbum:exporter.outputURL]) {
	                [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:exporter.outputURL completionBlock:NULL];
	            }
	        }
	    });
	}];
	```

## 媒体资源捕获
通过麦克风、摄像机等设备，可以捕获外界的声音和影像。要处理设备捕获的数据，需要使用 **AVCaptureDevice** 类描述设备，使用 **AVCaptureInput** 配置数据从设备的输入，使用 **AVCaptureOutput** 类管理数据到文件的写入，而数据的输入到写出，需要使用 **AVCaptureSession** 类进行协调。此外，可以使用 **AVCaptureVideoPreviewLayer** 类显示相机正在拍摄的画面。

一个设备可以有多个输入，使用 **AVCaptureInputPort** 类描述这些输入，用 **AVCaptureConnection** 类描述具体类型的输入与输出的关系，可以实现更精细的数据处理。

### AVCaptureSession
AVCaptureSession 是捕获视听数据的核心类，它协调数据的输入和输出。创建一个 AVCaptureSession 类的对象时，可以指定最终得到的视听数据的质量，当然这个质量与设备也有关系，通常在设置之前，可以调用方法判断 session 是否支持要设置的质量。

AVCaptureSession 类实例可设置的数据质量有 AVCaptureSessionPresetHigh 、AVCaptureSessionPresetMedium 、AVCaptureSessionPresetLow 、AVCaptureSessionPreset320x240 等。在进行设置之前，可以调用 AVCaptureSession 中的方法进行校验。

```
- (BOOL)canSetSessionPreset:(NSString*)preset;
```
设置好对象后，可调用下面的方法，添加、移除输入、输出。

```
- (BOOL)canAddInput:(AVCaptureInput *)input;
- (void)addInput:(AVCaptureInput *)input;
- (void)removeInput:(AVCaptureInput *)input;

- (BOOL)canAddOutput:(AVCaptureOutput *)output;
- (void)addOutput:(AVCaptureOutput *)output;
- (void)removeOutput:(AVCaptureOutput *)output;

- (void)addInputWithNoConnections:(AVCaptureInput *)input NS_AVAILABLE(10_7, 8_0);
- (void)addOutputWithNoConnections:(AVCaptureOutput *)output NS_AVAILABLE(10_7, 8_0);

- (BOOL)canAddConnection:(AVCaptureConnection *)connection NS_AVAILABLE(10_7, 8_0);
- (void)addConnection:(AVCaptureConnection *)connection NS_AVAILABLE(10_7, 8_0);
- (void)removeConnection:(AVCaptureConnection *)connection NS_AVAILABLE(10_7, 8_0);
```
开始执行 session 或者结束执行，调用下面的方法。

```
- (void)startRunning;
- (void)stopRunning;
```

对于正在执行中的 session ，要对其进行改变，所作出的改变，应放在下面两个方法之间。

```
- (void)beginConfiguration;
- (void)commitConfiguration;
```
AVCaptureSession 开始执行、结束执行、执行过程中出错或被打断时，都会发出通知，通过注册下面的通知，可以获取我们感兴趣的信息。

* AVCaptureSessionRuntimeErrorNotification 通过 AVCaptureSessionErrorKey 可以获取出错的原因
* AVCaptureSessionDidStartRunningNotification 开始 session
* AVCaptureSessionDidStopRunningNotification 结束 session
* AVCaptureSessionWasInterruptedNotification 通过 AVCaptureSessionInterruptionReasonKey 可以获取被打断的原因
* AVCaptureSessionInterruptionEndedNotification 打断结束，session 重新开始

### AVCaptureDevice
AVCaptureDevice 是用来描述设备属性的类，要捕获视听数据，需要获取相应的设备，使用该类获取有效的设备资源。这个设备资源列表是随时变动的，其在变动时，会发送 **AVCaptureDeviceWasConnectedNotification** 或 **AVCaptureDeviceWasDisconnectedNotification** 通知，以告知有设备连接或断开。

在获取设备之前，要先确定要获取的设备的类型 **AVCaptureDeviceType** ，设备的位置 **AVCaptureDevicePosition** ，也可以通过要获取的媒体数据类型进行设备的选择。

获取设备后，可以保存它的唯一标识、模型标识、名称等信息，以待下次用来获取设备。

```
+ (NSArray *)devices;
+ (NSArray *)devicesWithMediaType:(NSString *)mediaType;
+ (AVCaptureDevice *)defaultDeviceWithMediaType:(NSString *)mediaType;
+ (AVCaptureDevice *)deviceWithUniqueID:(NSString *)deviceUniqueID;

@property(nonatomic, readonly) NSString *uniqueID;
@property(nonatomic, readonly) NSString *modelID;
@property(nonatomic, readonly) NSString *localizedName;

//校验获得的设备能否提供相应的媒体数据类型
- (BOOL)hasMediaType:(NSString *)mediaType;

//校验获得的设备能否支持相应的配置
- (BOOL)supportsAVCaptureSessionPreset:(NSString *)preset;
```
获取一个设备后，可以通过修改它的属性来满足自己的需要。

* flashMode 闪光灯的模式（AVCaptureFlashModeOff 、AVCaptureFlashModeOn 、AVCaptureFlashModeAuto）
* torchMode 手电筒的模式（AVCaptureTorchModeOff 、AVCaptureTorchModeOn 、AVCaptureTorchModeAuto）
* torchLevel 手电筒的亮度（0～1）
* focusMode 聚焦模式（AVCaptureFocusModeLocked 、AVCaptureFocusModeAutoFocus 、AVCaptureFocusModeContinuousAutoFocus）
* exposureMode 曝光模式（AVCaptureExposureModeLocked 、AVCaptureExposureModeAutoExpose 、AVCaptureExposureModeContinuousAutoExposure 、AVCaptureExposureModeCustom）
* whiteBalanceMode 白平衡模式（AVCaptureWhiteBalanceModeLocked 、AVCaptureWhiteBalanceModeAutoWhiteBalance 、AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance）

在修改这些属性时，应先判断当前设备是否支持要设置的属性值，并且所有的属性修改都要放在下面两个方法之间，以保证属性能够被正确设置。

```
- (BOOL)lockForConfiguration:(NSError **)outError;
- (void)unlockForConfiguration;
```
在调用硬件设备之前，应先判断应用是否拥有相应的权限，其权限分为以下几种：

* AVAuthorizationStatusNotDetermined 未定义
* AVAuthorizationStatusRestricted 无权限（因某些原因，系统拒绝权限）
* AVAuthorizationStatusDenied 无权限（用户拒绝）
* AVAuthorizationStatusAuthorized 有权限

```
//校验权限
+ (AVAuthorizationStatus)authorizationStatusForMediaType:(NSString *)mediaType NS_AVAILABLE_IOS(7_0);

//请求权限，handler 处理会在任意线程中执行，所以需要在主线程中执行的处理由用户负责指定
+ (void)requestAccessForMediaType:(NSString *)mediaType completionHandler:(void (^)(BOOL granted))handler NS_AVAILABLE_IOS(7_0);
```

### AVCaptureDeviceInput
AVCaptureDeviceInput 是 AVCaptureInput 的子类，使用一个 AVCaptureDevice 类实例创建该类的实例，其管理设备的输入。

在创建了实例对象后，将其添加到 session 中。

```
NSError *error;
AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
if (input && [session canAddInput:input]) {
	[captureSession addInput:captureDeviceInput];
}
```

### AVCaptureOutput
AVCaptureOutput 是一个抽象类，通常使用的是它的子类。

* AVCaptureMovieFileOutput 用来生成一个影视文件
* AVCaptureVideoDataOutput 用来处理输入的视频的帧
* AVCaptureAudioDataOutput 用来处理音频数据
* AVCaptureStillImageOutput 用来获取图片

在创建了具体的子类后，将它添加到 session 中。

```
AVCaptureMovieFileOutput *movieOutput = [[AVCaptureMovieFileOutput alloc] init];
if ([session canAddOutput:movieOutput]) {
    [session addOutput:movieOutput];
}
```

### AVCaptureFileOutput
AVCaptureFileOutput 是 AVCaptureOutput 的子类，是 AVCaptureMovieFileOutput 、AVCaptureAudioFileOutput 的父类。这个类中定义了文件输出时的地址、时长、容量等属性。

```
//当前记录的数据的文件的地址
@property(nonatomic, readonly) NSURL *outputFileURL;

//开始文件的记录，指定文件的地址，以及记录过程中或结束时要通知的代理对象
//指定的 outputFileURL 必需是有效的且没有文件占用
- (void)startRecordingToOutputFileURL:(NSURL*)outputFileURL recordingDelegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate;

//该方法可以停止数据向文件中写入
//如果要停止一个文件的写入转而指定另一个文件的写入，不应调用该方法，只需直接调用上面的方法
//当因该方法的调用、出错、或写入文件的变更导致当前文件开始停止写入时，最后传入的缓存数据仍会在后台被写入
//无论何时，要使用文件，都需要等指定的代理对象被告知文件的写入已经结束之后进行
- (void)stopRecording;

//判断当前是否有数据被写入文件
@property(nonatomic, readonly, getter=isRecording) BOOL recording;

//表示到目前为止，当前文件已经记录了多长时间
@property(nonatomic, readonly) CMTime recordedDuration;

//表示到目前为止，当前文件已经记录了多少个字节
@property(nonatomic, readonly) int64_t recordedFileSize;	
/**
下面三个值对文件的记录进行了限制，若果达到限制，则会在回调方法 captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error: 中传递相应的错误
*/
//表示当前文件能够记录的最长时间，kCMTimeInvalid 表示无时间限制
@property(nonatomic) CMTime maxRecordedDuration;

//表示当前文件能够记录的最大字节数，0 表示无大小限制
@property(nonatomic) int64_t maxRecordedFileSize;

//表示记录当前文件时需要保留的最小字节数
@property(nonatomic) int64_t minFreeDiskSpaceLimit;

//在 Mac OS X 系统下，通过指定遵循 AVCaptureFileOutputDelegate 协议的代理对象，来实现缓存数据的精确记录
@property(nonatomic, assign) id<AVCaptureFileOutputDelegate> delegate NS_AVAILABLE(10_7, NA);

/**
在 Mac OS X 系统下，这个属性和方法可以判断记录是否停止，以及控制数据向文件中的停止写入和重新开始写入
*/
@property(nonatomic, readonly, getter=isRecordingPaused) BOOL recordingPaused NS_AVAILABLE(10_7, NA);
- (void)pauseRecording NS_AVAILABLE(10_7, NA);
- (void)resumeRecording NS_AVAILABLE(10_7, NA);
```

### AVCaptureFileOutputRecordingDelegate
AVCaptureFileOutputRecordingDelegate 是文件记录过程中需要用到的协议，它通常的作用是告知代理对象文件记录结束了。

```
//这个代理方法是遵循该协议的代理对象必须要实现的方法
//每一个文件记录请求，最终都会调用这个方法，即使没有数据成功写入文件
//当 error 返回时，文件也可能成功保存了，应检查 error 中的 AVErrorRecordingSuccessfullyFinishedKey 信息，查看具体错误
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error;

//当数据写入文件后调用，如果数据写入失败，该方法可能不会被调用
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections;

/**
在 Mac OS X 系统下，当文件的记录被暂停或重新开始，会调用下面的方法，如果记录被终止，不会调用下面的方法
*/
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didPauseRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections NS_AVAILABLE(10_7, NA);
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didResumeRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections NS_AVAILABLE(10_7, NA);

//在 Mac OS X 系统下，当记录将被停止，无论是主动的还是被动的，都会调用下面的方法
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput willFinishRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections error:(NSError *)error NS_AVAILABLE(10_7, NA);
```

### AVCaptureFileOutputDelegate
AVCaptureFileOutputDelegate 这个协议只用于 Mac OS X 系统下，它给了客户端精准操控数据的机会。

```
/**
在 Mac OS X 10.8 系统之前，实现代理方法 captureOutput:didOutputSampleBuffer:fromConnection:
后便可以在该方法中实现数据记录的准确开始或结束，而要实现在任一一个画面帧处开始或停止数据的记录，要对每收到的
帧数据进行预先处理，这个过程消耗电能、产生热量、占用 CPU 资源，所以在 Mac OS X 10.8 及其之后的系统，提供了
下面的代理方法，来确定客户端需不需要随时进行记录的开始或停止。
如果这个方法返回 NO ，对数据记录的设置将在开启记录之后进行。
*/
- (BOOL)captureOutputShouldProvideSampleAccurateRecordingStart:(AVCaptureOutput *)captureOutput NS_AVAILABLE(10_8, NA);

/**
如果上面的方法返回了 YES ，那么客户端便可以使用下面的方法对每一个视频帧数据或音频数据进行操作
为了提高性能，缓存池中的缓存变量的内存通常会被复用，如果长时间使用缓存变量，那么新的缓存数据无法复制到
相应的内存中便会被废弃，所以若需要长时间使用缓存数据 sampleBuffer ，应复制一份，使其本身能够被系统复用
*/
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection NS_AVAILABLE(10_7, NA);
```

### AVCaptureMovieFileOutput
AVCaptureMovieFileOutput 是 AVCaptureFileOutput 的子类，它实现了在 AVCaptureFileOutput 中声明的视频数据记录方法，并且可以设置数据的格式、写入元数据、编码方式等属性。

```
//如果视频数据按片段写入，该值指定片段的时长，默认值是 10 秒
//该值为 kCMTimeInvalid 表示不使用片段对视频进行记录，这样视频只能一次写入，不能被打断
//改变该值不影响当前正在写入的片段时长
@property(nonatomic) CMTime movieFragmentInterval;

//向文件中添加的 AVMetadataItem 类元数据
@property(nonatomic, copy) NSArray *metadata;

//获取记录 connection 中数据时，使用的设置
- (NSDictionary *)outputSettingsForConnection:(AVCaptureConnection *)connection NS_AVAILABLE(10_7, 10_0);

//设置记录 connection 中数据时，使用的设置 AVVideoSettings.h
//outputSettings 为空，表示在将 connection 中的数据写入文件之前，其格式不做改变
//outputSettings 为 nil 时，其数据格式将由 session preset 决定
- (void)setOutputSettings:(NSDictionary *)outputSettings forConnection:(AVCaptureConnection *)connection NS_AVAILABLE(10_7, 10_0);

//在 iOS 系统下，获取有效的编码格式，作为 AVVideoCodecKey 的值，使用上面的方法进行设置
@property(nonatomic, readonly) NSArray *availableVideoCodecTypes NS_AVAILABLE_IOS(10_0);

//设置文件记录过程中，是否创建一个元数据对 connection 的 videoOrientation 和 videoMirrored 属性变化进行跟踪记录
//connection 的属性 mediaType 的值必需是 AVMediaTypeVideo 
//该值的设置只在记录开始之前有效，开始记录之后改变该值无效果
- (void)setRecordsVideoOrientationAndMirroringChanges:(BOOL)doRecordChanges asMetadataTrackForConnection:(AVCaptureConnection *)connection NS_AVAILABLE_IOS(9_0);

//判断该类实例对象是否会在记录的过程中创建一个 timed metadata track 记录 connection 的 videoOrientation 和 videoMirrored 属性变化情况
- (BOOL)recordsVideoOrientationAndMirroringChangesAsMetadataTrackForConnection:(AVCaptureConnection *)connection NS_AVAILABLE_IOS(9_0);
```

### AVCaptureAudioFileOutput
AVCaptureAudioFileOutput 是 AVCaptureFileOutput 的子类，该类用于将媒体数据记录为一个音频文件。

```
//返回该类支持的音频文件类型
+ (NSArray *)availableOutputFileTypes;

//开始记录音频文件
- (void)startRecordingToOutputFileURL:(NSURL*)outputFileURL outputFileType:(NSString *)fileType recordingDelegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate;

//要写入音频文件中的元数据 AVMetadataItem 集合
@property(nonatomic, copy) NSArray *metadata; 

//写入的音频文件的设置 AVAudioSettings.h
@property(nonatomic, copy) NSDictionary *audioSettings;

```

### AVCaptureVideoDataOutput
AVCaptureVideoDataOutput 是 AVCaptureOutput 的子类，该类可以用来处理捕获的每一个视频帧数据。创建一个该类的实例对象后，要调用下面的方法设置一个代理对象，及调用代理对象所实现的协议方法的队列。

```
- (void)setSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)sampleBufferDelegate queue:(dispatch_queue_t)sampleBufferCallbackQueue;
```
指定的队列 sampleBufferCallbackQueue 必需是串行队列以保证传递的帧是按记录时间先后传递的。

```
//设置输出的视频要进行怎样的格式处理
//设置为空（[NSDictionary dictionary]）表示不改变输入时的视频格式
//设置为 nil 表示未压缩格式
@property(nonatomic, copy) NSDictionary *videoSettings;

//获取 kCVPixelBufferPixelFormatTypeKey 的有效值
@property(nonatomic, readonly) NSArray *availableVideoCVPixelFormatTypes NS_AVAILABLE(10_7, 5_0);

//获取 AVVideoCodecKey 的有效值
@property(nonatomic, readonly) NSArray *availableVideoCodecTypes NS_AVAILABLE(10_7, 5_0);

//表示当回调队列阻塞时，是否立刻丢弃新接收的帧数据
@property(nonatomic) BOOL alwaysDiscardsLateVideoFrames;
```

### AVCaptureVideoDataOutputSampleBufferDelegate
该协议用来处理接收的每一个帧数据，或者提示客户端有帧数据被丢弃。

```
//接收到一个帧数据时，在指定的串行队列中调用该方法，携带帧数据并包含有其他帧信息
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;

//丢弃一个帧数据时，在指定的串行队列中调用该方法，sampleBuffer 只携带帧信息，具体帧数据并未携带
- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection NS_AVAILABLE(10_7, 6_0);
```

### AVCaptureVideoPreviewLayer
AVCaptureVideoPreviewLayer 是 CALayer 的子类，使用该类可以实现捕获视频的显示。使用一个 session 创建一个该类对象，而后将该类对象插入到图层树中，从而显示捕获的视频。

```
//创建方法
+ (instancetype)layerWithSession:(AVCaptureSession *)session;
- (instancetype)initWithSession:(AVCaptureSession *)session;
```

修改 AVCaptureVideoPreviewLayer 的属性 **videoGravity** 值，可以选择显示捕获视频时的界面大小变化方式，它有以下可选值：

* AVLayerVideoGravityResize 默认值，直接铺满屏幕，及时画面变形
* AVLayerVideoGravityResizeAspect 保持画面的横纵比，不铺满屏幕，多余的空间显示黑色
* AVLayerVideoGravityResizeAspectFill 保持画面的横纵比，铺满屏幕，多余的画面进行裁剪

### AVCaptureAudioDataOutput
AVCaptureAudioDataOutput 是 AVCaptureOutput 的子类，该类可以处理接收到的音频数据。同 AVCaptureVideoDataOutput 类似，该类也提供了一个方法，用于设置代理对象，以及调用代理对象实现的协议方法时的队列。

```
- (void)setSampleBufferDelegate:(id<AVCaptureAudioDataOutputSampleBufferDelegate>)sampleBufferDelegate queue:(dispatch_queue_t)sampleBufferCallbackQueue;
```

### AVCaptureAudioDataOutputSampleBufferDelegate
该协议提供了一个方法，用来实现对音频数据的接收处理。

```
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;
```

> 对于每个设备，其支持播放或捕获的媒体资源都不相同，通过 **AVCaptureDeviceFormat** 类可以获取相关信息。

## 视听资源读写
对媒体数据资源进行简单的转码或裁剪，使用 AVAssetExportSession 类便足够了，但是更深层次的修改媒体资源，便需要用到 **AVAssetReader** 类和 **AVAssetWriter** 类。

AVAssetReader 只能与一个资源 asset 相关联，且不能用来读取实时数据，在开始读取数据之前，需要为 reader 添加 **AVAssetReaderOutput** 的实例对象。这个实例对象描述的是待读取的数据资源来源类型，通常使用 **AVAssetReaderAudioMixOutput** 、**AVAssetReaderTrackOutput** 、**AVAssetReaderVideoCompositionOutput** 三种子类。

AVAssetWriter 可以将来自多个数据源的数据以指定的格式写入到一个指定的文件中，且其只能对应一个文件。在写文件之前，需要用每一个 **AVAssetWriterInput** 类实例对象来描述相应的数据源。每一个 AVAssetWriterInput 实例对象接收的数据都应是 CMSampleBufferRef 类型的变量。如果使用 **AVAssetWriterInputPixelBufferAdaptor** 类也可以直接将 **CVPixelBufferRef** 类型的变量数据添加到 writer input 中。

AVAssetReader 与 AVAssetWriter 结合起来使用，便可以对读取的数据进行相应的编辑修改，而后写入到一个文件中并保存。

### AVAssetReader
使用该类读取媒体资源，其提供的初始化方法与一个 asset 相关联。

```
//对于提供的参数 asset ，如果是可被修改的，那么在开始读取操作后，对其进行了修改，之后的读取操作都是无效的
+ (nullable instancetype)assetReaderWithAsset:(AVAsset *)asset error:(NSError * _Nullable * _Nullable)outError;
- (nullable instancetype)initWithAsset:(AVAsset *)asset error:(NSError * _Nullable * _Nullable)outError NS_DESIGNATED_INITIALIZER;

//当前读取操作的状态，可取值有 AVAssetReaderStatusUnknown 、AVAssetReaderStatusReading 、
AVAssetReaderStatusCompleted 、AVAssetReaderStatusFailed 、AVAssetReaderStatusCancelled
@property (readonly) AVAssetReaderStatus status;
//当 status 的值为 AVAssetReaderStatusFailed 时，描述错误信息
@property (readonly, nullable) NSError *error;


//限制可读取的资源的时间范围
@property (nonatomic) CMTimeRange timeRange;

//判断能否添加该数据源
- (BOOL)canAddOutput:(AVAssetReaderOutput *)output;
//添加数据源
- (void)addOutput:(AVAssetReaderOutput *)output;

//开始读取
- (BOOL)startReading;
//结束读取
- (void)cancelReading;
```

### AVAssetReaderOutput
AVAssetReaderOutput 是用来描述待读取的数据的抽象类，读取资源时，应创建该类的对象，并添加到相应的 AVAssetReader 实例对象中去。

```
//获取的媒体数据的类型
@property (nonatomic, readonly) NSString *mediaType;

//是否拷贝缓存中的数据到客户端，默认 YES ，客户端可以随意修改数据，但是为优化性能，通常设为 NO
@property (nonatomic) BOOL alwaysCopiesSampleData NS_AVAILABLE(10_8, 5_0);

//同步获取下一个缓存数据，使用返回的数据结束后，应使用 CFRelease 函数将其释放
//当错误或没有数据可读取时，返回 NULL ，返回空后，应检查相关联的 reader 的状态
- (nullable CMSampleBufferRef)copyNextSampleBuffer CF_RETURNS_RETAINED;

//是否支持重新设置数据的读取时间范围，即能否修改 reader 的 timeRange 属性
@property (nonatomic) BOOL supportsRandomAccess NS_AVAILABLE(10_10, 8_0);
//设置重新读取的时间范围，这个时间范围集合中的每一个时间范围的开始时间必需是增长的且各个时间范围不能重叠
//应在 reader 调用 copyNextSampleBuffer 方法返回 NULL 之后才可调用
- (void)resetForReadingTimeRanges:(NSArray<NSValue *> *)timeRanges NS_AVAILABLE(10_10, 8_0);
//该方法调用后，上面的方法即不可再调用，同时 reader 的状态也不会被阻止变为 AVAssetReaderStatusCompleted 了
- (void)markConfigurationAsFinal NS_AVAILABLE(10_10, 8_0);
```

### AVAssetReaderTrackOutput
AVAssetReaderTrackOutput 是 AVAssetReaderOutput 的子类，它用来描述待读取的数据来自 asset track ，在读取前，还可以对数据的格式进行修改。

```
//初始化方法，参数中指定了 track 和 媒体的格式
//指定的 track 应在 reader 的 asset 中
+ (instancetype)assetReaderTrackOutputWithTrack:(AVAssetTrack *)track outputSettings:(nullable NSDictionary<NSString *, id> *)outputSettings;
- (instancetype)initWithTrack:(AVAssetTrack *)track outputSettings:(nullable NSDictionary<NSString *, id> *)outputSettings NS_DESIGNATED_INITIALIZER;

//指定音频处理时的算法
@property (nonatomic, copy) NSString *audioTimePitchAlgorithm NS_AVAILABLE(10_9, 7_0);
```

### AVAssetReaderAudioMixOutput
AVAssetReaderAudioMixOutput 是 AVAssetReaderOutput 的子类，它用来描述待读取的数据来自音频组合数据。创建该类实例对象提供的参数 audioTracks 集合中的每一个 asset track 都属于相应的 reader 中的 asset 实例对象，且类型为 AVMediaTypeAudio 。
参数 audioSettings 给出了音频数据的格式设置。

```
+ (instancetype)assetReaderAudioMixOutputWithAudioTracks:(NSArray<AVAssetTrack *> *)audioTracks audioSettings:(nullable NSDictionary<NSString *, id> *)audioSettings;
- (instancetype)initWithAudioTracks:(NSArray<AVAssetTrack *> *)audioTracks audioSettings:(nullable NSDictionary<NSString *, id> *)audioSettings NS_DESIGNATED_INITIALIZER;
```

此外，该类的 audioMix 属性，描述了从多个 track 中读取的音频的音量变化情况。

```
@property (nonatomic, copy, nullable) AVAudioMix *audioMix;
```

### AVAssetReaderVideoCompositionOutput
AVAssetReaderVideoCompositionOutput 是 AVAssetReaderOutput 的子类，该类用来表示要读取的类是组合的视频数据。
同 AVAssetReaderAudioMixOutput 类似，该类也提供了两个创建实例的方法，需要提供的参数的 videoTracks 集合中每一个 track 都是
与 reader 相关联的 asset 中的 track 。

```
+ (instancetype)assetReaderVideoCompositionOutputWithVideoTracks:(NSArray<AVAssetTrack *> *)videoTracks videoSettings:(nullable NSDictionary<NSString *, id> *)videoSettings;
- (instancetype)initWithVideoTracks:(NSArray<AVAssetTrack *> *)videoTracks videoSettings:(nullable NSDictionary<NSString *, id> *)videoSettings NS_DESIGNATED_INITIALIZER;
```
该类的属性 videoComposition 同样描述了每个 track 的帧的显示方式。

```
@property (nonatomic, copy, nullable) AVVideoComposition *videoComposition;
```

> 使用 AVOutputSettingsAssistant 类可以获取简单的编码设置