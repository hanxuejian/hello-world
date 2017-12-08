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

6. AVFoundation 中可以使用 **compositions** 将多个媒体数据（video/audio tracks）合成为一个 asset ，这个过程中，可以添加或移除 tracks ，调整它们的顺序，或者设置音频的音量和倾斜度，视频容量等属性。这些媒体数据的集合保存在内存中，直到使用 export session 将它导出到本地文件中。另外，还可以使用 asset writer 创建 asset 。

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
当然，在此之前，最好调用 AVAsset 中的方法 `- (NSArray<AVAssetTrack *> *)tracksWithMediaCharacteristic:(NSString *)mediaCharacteristic;` 来判断是否有可视媒体数据。如果有，那么再创建 AVAssetImageGenerator 对象，而后再调用下面的方法，来获取一张或多张图片。

```
//获取一张图片，requestedTime 指定要获取视频中哪个时刻的图片，actualTime 返回图片实际是视频的哪个时刻，outError 返回错误信息
- (nullable CGImageRef)copyCGImageAtTime:(CMTime)requestedTime actualTime:(nullable CMTime *)actualTime error:(NSError * _Nullable * _Nullable)outError CF_RETURNS_RETAINED;

//获取多张图片，每一次图片生成后，都会调用一次 handler
- (void)generateCGImagesAsynchronouslyForTimes:(NSArray<NSValue *> *)requestedTimes completionHandler:(AVAssetImageGeneratorCompletionHandler)handler;

//上述 handler 的类型如下，回调中的参数有图片的请求时刻和实际时刻，图片，状态（成功、失败、取消），错误信息
typedef void (^AVAssetImageGeneratorCompletionHandler)(CMTime requestedTime, CGImageRef _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error);
```

### AVAssetExportSession
使用 AVAssetExportSession 类对视频进行裁剪及转码，即将一个 AVAsset 类实例修改后保存为例一个 AVAsset 类实例，最后保存到文件中。

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

## Playback
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
对于播放不同类型的资源，需要进行的准备工作有所不同，这主要取决于资源的来源，可能资源是本地设备上的文件，也可能资源来自网络。

对于本地文件，可以使用文件地址创建 AVAsset 对象，而后使用该对象创建 AVPlayerItem 对象，最后将这个 item 对象于 AVPlayer 对象相关联。之后，便是等待 status 的状态变为 AVPlayerStatusReadyToPlay ，便可以进行播放了。

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

//这两个方法传入了一个回调，当一个时间跳转请求被新的请求或其他操作打断时，会调会被执行并且 finished 参数为 NO
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

当 item 播放结束后，再次调用 player 的方法 play 不会使 item 重新播放，要实现重播，可以注册一个 ** AVPlayerItemDidPlayToEndTimeNotification** 通知，当接收到这个通知时，可以调 **seekToTime:** 方法，传入 **kCMTimeZero** 参数，将 player 的播放时间重置。

## Editing
AVFoundation 框架中提供了丰富的接口用于视听资源的编辑，其中的关键是 **composition** ，它将不同的 asset 相结合并形成一个新的 asset 。使用 **AVMutableComposition** 类可以增删 asset 来将指定的 asset 集合到一起。除此之外，若想集合到一起的视听资源以自定义的方式进行播放，需要使用 **AVMutableAudioMix** 和 **AVMutableVideoComposition** 类对其中的资源进行协调管理。最终要使用 **AVAssetExportSession** 类将编辑的内容保存到文件中。

### AVComposition
同 AVAsset 拥有多个 AVAssetTrack 一样，作为子类的 AVComposition 也拥有多个 **AVCompositionTrack** ，而 AVCompositionTrack 是 AVAssetTrack 的子类。所以，AVComposition 实例对象是多个 track 的集合，真正描述媒体属性的是 AVCompositionTrack 实例对象。而 AVCompositionTrack 又是媒体数据片段的集合，这些数据片段由 **AVCompositionTrackSegment** 类进行描述。

该类的相关属性和方法如下：

```
//获取 composition 中包含的 tracks
@property (nonatomic, readonly) NSArray<AVCompositionTrack *> *tracks;

//获取 composition 可见部分的大小
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
····

//使用可变的 composition 生成一个不可变的 composition 以供使用
AVComposition *composition = [myMutableComposition copy];
AVPlayerItem *playerItemForSnapshottedComposition = [[AVPlayerItem alloc] initWithAsset:immutableSnapshotOfMyComposition];
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


