# OpenGL ES 小结
## 概述
> OpenGL ES （Open Graphics Library for Embedded Systems）是访问类似 iPhone 和 iPad 的现代嵌入式系统的 2D 和 3D 图形加速硬件的标准。
> 
> 把程序提供的几何数据转换为屏幕上的图像的过程叫做渲染。
>  
> GPU 控制的缓存是高效渲染的关键。容纳几何数据的缓存定义了要渲染的点、线段和三角形。
> 
> OpenGL ES 3D 的默认坐标系、顶点和矢量为几何数据的描述提供了数学基础。
> 
> 渲染的结果通常保存在帧缓存中。有两个特别的帧缓存，前帧缓存和后帧缓存，它们控制着屏幕像素的最终颜色。
> 
> OpenGL ES 的上下文保存了 OpenGL ES 的状态信息，包括用于提供渲染数据的缓存地址和用于接收渲染结果的缓存地址。 

OpenGL ES 是 OpenGL 的子集，它移除了 OpenGL 中冗余的函数，使其更易学也更容易在移动图形硬件中实现。OpenGL ES 是基于 C 语言的 API ，所以可以无缝移植到 Objective—C 中，然后通过创建上下文来接收命令和帧缓存。

在 iOS 中，使用 OpenGL ES 时，可以使用 GLKit 框架中的 GLKView 将 OpenGL ES 绘制的内容渲染到屏幕上，并且可以使用 GLKViewController 来管理 GLKView 视图。另外，还可以使用 CAEAGLLayer 图层将动画与视图相结合。但是，需要注意的是，当应用处于后台状态时，不能调用 OpenGL ES 中的函数，否则应用便会被终止，而且 OpenGL ES 中的上下文也不支持在同一时刻被不同的线程访问。

## 在 iOS 中使用 OpenGL ES
OpenGL ES 定义了跨平台的接口来使用 GPU 的硬件性能加速图形的渲染，其中由渲染上下文来执行渲染命令，帧缓存存储渲染结果，渲染目标显示帧缓存中结果。对应到 iOS 中，EAGLContext 是实现上下文的类，GLKView 和 CAEAGLLayer 则表示渲染目标来显示最终的渲染结果。

使用 OpenGL ES 之前，需要明确自己要使用哪个版本的 OpenGL ES 。目前最新的版本是 3.0 ，相较于 iOS 7.0 之前的 2.0 版本，添加了一些新的特性，使用了原本只在桌面系统中有效的技术，使得 GPU 的性能能够更好的发挥出来。

### EAGLContext
在 iOS 中，要想使用 OpenGL ES 中的函数必须要先创建一个 EAGLContext 实例对象，该对象表示绘制上下文。对于每一个线程都有一个上下文，可以调用 EAGLContext 的类方法设置或获取当前上下文。在同一个线程中切换不同的上下文时，需要注意应用应自己对上下文进行强引用以防止其被释放，并且在切换之前应调用 **glFlush** 函数将当前上下文提交的指令传到图形硬件中去。

使用下面的方法设置或获取当前上下文：

```
+ (BOOL)            setCurrentContext:(EAGLContext*) context;
+ (EAGLContext*)    currentContext;
```

对于不同的设备，其支持的 OpenGL ES 版本也不同，所以在创建上下文时，如果返回的值为 nil 那么表示设备不支持指定版本的 OpenGL ES 。

```
- (instancetype) initWithAPI:(EAGLRenderingAPI) api;
- (instancetype) initWithAPI:(EAGLRenderingAPI) api sharegroup:(EAGLSharegroup*) sharegroup NS_DESIGNATED_INITIALIZER;
```
创建上下文时需要指定 OpenGL ES 的版本，并且这里上下文的状态与上下文对象是分离的，其状态都保存在 **EAGLSharegroup** 实例对象中，该对象是透明的，不应该主动创建该类的实例。这种设计方式是为了节约系统资源，对于不同的上下文可能拥有相同的上下文状态，那么这种设计方式便十分便利。如，需要在子线程中加载数据，在主线程中进行渲染，那么当数据加载完成后，可以直接将子线程中上下文的状态绑定到主线程上下文中。

### GLKView
GLKView 类为 OpenGL ES 上下文提供了渲染结果的显示视图，在创建一个 GLKView 视图之后，需要将其与一个上下文相绑定。

```
- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)context;
```
同在 UIView 视图中绘制图形一样，可以通过继承 GLKView 类重写 drawRect: 方法来进行图形的绘制。另一种方式不用创建子类，直接设置 GLKView 的代理，实现协议 **GLKViewDelegate** 中的代理方法。

```
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect;
```

> 当重写 drawRect: 时，代理方法不会被执行。

### GLKViewController
使用 GLKViewController 类可以管理 GLKView 视图，两者通常配合使用。

设置该类的 **preferredFramesPerSecond** 属性值可以指定每秒钟刷新的帧数，但是实际帧的刷新频率可能并不与之相等。

设置该类的代理对象 delegate ，该代理需要实现 **GLKViewControllerDelegate** 协议。

```
//如果 GLKViewController 被继承，并且实现了 -(void)update 方法，那么该代理方法不会被调用。
- (void)glkViewControllerUpdate:(GLKViewController *)controller;

//当暂停状态发生改变时，调用该方法。
- (void)glkViewController:(GLKViewController *)controller willPause:(BOOL)pause;
```

## 渲染目标
帧缓存接收渲染命令，在应用中，配置不同帧缓存，实现不同的目的。

* 渲染离屏图像，与帧缓存相关联的所有配置都以渲染缓存的形式存在。

	1. 创建帧缓存并绑定
		 
		 ```
		 GLuint framebuffer;
		 glGenFramebuffers(1,&framebuffer);
		 glBindFramebuffer(GL_FRAMEBUFFER, framebuffer); 
		 ```

	2. 创建颜色渲染缓存并绑定
		
		```
		GLuint colorRenderbuffer;
		glGenRenderbuffers(1, &colorRenderbuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
		glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, width, height);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
		```

	3. 创建渲染深度并绑定

		```
		GLuint depthRenderbuffer;
		glGenRenderbuffers(1, &depthRenderbuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
		```
	
	4. 判断帧缓存配置是否完成

		```
		//配置状态改变时，需要重新判断
		GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER) ;
		if(status != GL_FRAMEBUFFER_COMPLETE) {
		    NSLog(@"failed to make complete framebuffer object %x", status);
		}
		```

	当渲染结束后，使用 **glReadPixels** 函数读取像素值，进行其他的处理。

* 渲染纹理

	1. 创建帧缓存并绑定（同上）
	2. 创建纹理缓存并绑定

		```
		GLuint texture;
		glGenTextures(1, &texture);
		glBindTexture(GL_TEXTURE_2D, texture);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8,  width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
		```

	3. 创建渲染深度并绑定（同上）
	4. 判断帧缓存配置是否完成（同上）

	可见，纹理渲染只是在离屏渲染操作中改变了颜色的设置

* 渲染动画图层
	
	要将 OpenGL ES 渲染缓存中的内容显示在设备上，需要通过 CAEAGLLayer 图层类。该类提供了一个共享的内存空间给渲染缓存，并且负责将渲染缓存中的内容插入到动画图层中。

	1. 创建 CAEAGLLayer 类的实例对象，并设置属性
		
		* **presentsWithTransaction** 设置图层刷新的方式，默认 false 则异步刷新到图层，设置为 true 则以标准的 CATransaction 机制将内容发送到屏幕进行显示。
		* **drawableProperties** 该属性是在协议 EAGLDrawable 中进行声明的，通过一个字典来改变渲染的像素的格式以及内容显示后是否仍然被引用，其可能的键值如下：
			* kEAGLDrawablePropertyRetainedBacking 对应的值为 NSNumber（boolean）
			* kEAGLDrawablePropertyColorFormat 可能的值为 kEAGLColorFormatRGBA8 、kEAGLColorFormatRGB565 、kEAGLColorFormatSRGBA8

	2. 创建一个 OpenGL ES 上下文，并设置为当前上下文
	3. 创建帧缓存
	4. 创建颜色渲染缓存，而后调用上下文的方法 renderbufferStorage:fromDrawable: 来为渲染缓存创建内存

		```
		GLuint colorRenderbuffer;
		glGenRenderbuffers(1, &colorRenderbuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
		[myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:myEAGLLayer];
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
		```	
		需要注意的是，当动画图层大小或属性发送改变时，渲染内存应重新分配，否则渲染结果可能会被缩放以覆盖整个图层。

	5. 获取实际的颜色渲染缓存的宽高

		```
		GLint width;
		GLint height;
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
		```
		对于不是明确指定的颜色缓存内存的大小，需要使用该方式获取实际的缓存大小，其他渲染缓存要与此保持大小一致。

	6. 创建渲染深度并绑定（同上）
	7. 判断帧缓存配置是否完成（同上）
	8. 将 CAEAGLLayer 图层插入到可见的动画图层中

## 绘制帧
当创建并配置好了一个帧缓存后，接下来的任务就是填满整个帧。首先要确认的是绘制帧的时机，一种是需要显示 OpenGL ES 的内容时，进行绘制，如同使用 GLKit 框架时，绘制总是在视图要显示时进行。另一种是与动画循环同步，使用 CADisplayLink 类实例对象可以实现绘制与屏幕刷新频率同步。

使用 UIScreen 的实例方法，获取一个与屏幕刷新频率一致的 CADisplayLink 实例对象。

```
- (nullable CADisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)sel NS_AVAILABLE_IOS(4_0);
```
而后调用 CADisplayLink 的实例方法，将指定的方法添加到当前循环中。

```
- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode;
```
另外，可以根据需要调整指定方法的调用频率，只要修改 CADisplayLink 的属性 **frameInterval** 或 **preferredFramesPerSecond** 值即可。但是，frameInterval（已废弃） 的值指的是刷新多少次才出发一次该方法，如设置该值为 5 ，那么对于 60Hz 的屏幕刷新频率而言，该方法调用频率为 12Hz 。preferredFramesPerSecond 则是直接表示指定方法每秒钟的调用次数，即帧的刷新频率。

1. 清空缓存

	在绘制每一帧之前，清空帧中一些不需要的信息，防止其被绘制到下一帧中，从而提高性能。
	
	```
	glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
	```

2. 准备需要的资源并提交到 GPU 后，执行绘制命令进行帧的绘制
3. 如果采用多重采样改善图片的质量，需要在其显示之前完成像素的处理
4. 当渲染的内容显示后，那么一些缓存数据就不需要了，为提高性能应进行舍弃

	```
	const GLenum discards[]  = {GL_DEPTH_ATTACHMENT};
	glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
	glDiscardFramebufferEXT(GL_FRAMEBUFFER,1,discards);
	```
	> glDiscardFramebufferEXT 函数适用于 OpenGL ES 1.1 和 2.0 版本，3.0 版本要使用 glInvalidateFramebuffer 函数。

5. 显示渲染的结果

	颜色渲染缓存持有最终的帧，所以将其绑定到当前上下文中并显示。
	
	```
	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER];
	```
	内容显示后，如果想要继续持有颜色渲染缓存中的内容，需要设置 CAEAGLLayer 的属性 drawableProperties 值，使其包含的 kEAGLDrawablePropertyRetainedBacking 的键所对应的值为真，并且绘制下一帧调用 glClear 函数时，不传 GL_COLOR_BUFFER_BIT 参数。

### 多重采样
多重采样是保证图片边界平滑的技术之一，其会消耗一些内存和处理时间，但这是提高图片质量的有效方式。

要实现多重采样，需要创建两个帧缓存。一个多重样本帧缓存，其包含了渲染内容所需的所有关联数据，如颜色缓存和深度缓存。另一个抽样帧缓存，只包含显示渲染结果所需要的数据，通常是颜色缓存，也可能是纹理缓存。

多重样本帧缓存所包含的所有的渲染缓存的大小同抽样帧缓存的大小一样，但是每一个渲染缓存都有一个额外的参数指定每一个像素所需要的样本数。

```
//创建样本帧缓存并绑定
glGenFramebuffers(1, &sampleFramebuffer);
glBindFramebuffer(GL_FRAMEBUFFER, sampleFramebuffer);

//创建样本颜色渲染缓存并绑定
glGenRenderbuffers(1, &sampleColorRenderbuffer);
glBindRenderbuffer(GL_RENDERBUFFER, sampleColorRenderbuffer);
//为颜色缓存生成内存空间
glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_RGBA8_OES, width, height);
glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, sampleColorRenderbuffer);

//创建样本深度渲染缓存
glGenRenderbuffers(1, &sampleDepthRenderbuffer);
glBindRenderbuffer(GL_RENDERBUFFER, sampleDepthRenderbuffer);
//为深度缓存生成内存空间
glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_DEPTH_COMPONENT16, width, height);
glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, sampleDepthRenderbuffer);
 
if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
```

创建样本帧缓存和抽样帧缓存后，绘制过程也要做一些变化。

1. 清空样本帧缓存

	```
	glBindFramebuffer(GL_FRAMEBUFFER, sampleFramebuffer);
	glViewport(0, 0, framebufferWidth, framebufferHeight);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	```

2. 将所有的绘制命令提交后，要将多个样本中的每一个像素汇合为一个样本，最后存储到抽样帧缓存中

	```
	glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, resolveFrameBuffer);
	glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, sampleFramebuffer);
	glResolveMultisampleFramebufferAPPLE();
	```

3. 要显示的内容保存在了抽样帧缓存中，所有样本帧缓存可以遗弃

	```
	const GLenum discards[]  = {GL_COLOR_ATTACHMENT0,GL_DEPTH_ATTACHMENT};
	glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE,2,discards);
	```

4. 最后显示抽样帧缓存中的颜色渲染缓存

	```
	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER];
	```

上述的函数都是属于 OpenGL ES 1.1 和 2.0 中的 GL_APPLE_framebuffer_multisample 部分的扩展函数，在 OpenGL ES 3.0 中，实现多重采样的函数并不一样。

### 其他特性
OpenGL ES 是跨平台的，但是在一些平台上的某些特性需要特殊考虑。在 iOS 系统中，需要注意多任务的正确处理、防止在后台调用 OpenGL ES 函数，并且要考虑设备的分辨率及其他特性。

iOS 为了前台应用程序能够流畅运行，禁止处在后台的程序调用图形硬件指令，除了终止尝试调用的应用外，其还会清除进入后台的应用提交的指令，所以应用进入后台前，应确保其提交的指令均执行完毕。如果并没有使用 GLKView 进行图形的绘制，那么应当在 applicationWillResignActive: 方法中，停止图形刷新的定时器。在 applicationDidEnterBackground: 方法中释放 OpenGL ES 使用的资源。调用 函数 glFinish 确保所有提交的指令均被执行，之前便不可以尝试图形硬件指令的调用。当应用将要重新回到前台时，在 applicationWillEnterForeground: 方法中重启定时器并重新创建资源。

当应用进入后时，对于一些易于重新生成的资源，如帧缓存，应当释放。而一些耗费大量时间才生成的资源，不应释放。

当屏幕发生转动时，绘制的图像也要做出相应的改变。如果使用了 GLKViewController 或 GLKView 则可以通过重写 viewWillLayoutSubviews 、viewDidLayoutSubviews 或 layoutSubviews 方法来调整图形的大小。

## 渲染流程设计
### 基本概念
OpenGL ES 的使用一般分为两种结构，一种是客户端-服务器结构，另一种是图形管线的概念。

在客户端-服务器结构中，OpenGL ES 框架被当作客户端，图形硬件被当作服务器，用户应用同客户端交互，将要渲染的资源，如纹理、顶点数据等，提供给客户端，客户端将这些数据转化为图形硬件可以处理的数据，然后传递给 GPU 进行处理。

图形管线将图形的绘制分为多个有序的步骤，从应用准备原始数据，到执行绘制命令发送顶点数据，然后处理顶点数据进行栅格化为片段，对每个片段进行颜色的计算和深度值的设置，最后将所有的片段集合成一页帧数据进行显示。这些步骤可以同步进行，但是下一个步骤的数据输入来自上一个步骤的输出，所以最低处理数据效率的步骤限制整个帧的生成效率，当进行性能优化时，应首先确定最低效率的步骤是哪一步及造成其效率低的原因。

* OpenGL ES 3.0

从 iOS 7 开始，可以使用 OpenGL ES 3.0 版本，该版本相较于以前的版本提供了一些新的特性。详细信息可以[参见官方网站](http://www.khronos.org/registry/gles/)。

在 3.0 版本中，可以同时渲染多个与帧缓存相关联的目标，即将片段着色器的计算结果输出到多个目标缓存中。

```
//为帧缓存关联多个颜色缓存目标
glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _colorTexture, 0);
glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, _positionTexture, 0);
glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT2, GL_TEXTURE_2D, _normalTexture, 0);
glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_TEXTURE_2D, _depthTexture, 0);
 
//渲染指定的关联目标
GLenum targets[] = {GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1, GL_COLOR_ATTACHMENT2};
glDrawBuffers(3, targets);
```	

* OpenGL ES 2.0

OpenGL ES 2.0 中通过可编程着色器来实现图形管线的可变性，适用于当前所有的 iOS 设备，并且在 OpenGL ES 3.0 中引入的特性可以通过 2.0 版本中的扩展函数实现，所以两者可以相互兼容。

* OpenGL ES 1.1

OpenGL ES 1.1 提供最基本的固定图形管线。

### 设计
要实现高性能的 OpenGL ES 应用，需要注意两点，一是注意图形管线各个步骤的并行使用，另一个是注意应用与图形硬件间的数据流动。

当应用加载时，第一步应初始化所需要的静态资源，将这些资源封装到 OpenGL ES 的对象中去，在整个或部分应用的生命周期中，这些资源保持不变。

另外，复杂指令和状态的改变也应用 OpenGL ES 对象替代，这样，便可以通过一个函数调用来使用这个对象。

创建或修改 OpenGL ES 对象很耗费资源，所以这种操作应尽可能的放在帧渲染的开始或结束时。

在渲染循环中，在 OpenGL ES 中的数据不应在传回应用中，因为从 GPU 中向 CPU 中传输数据很慢，并且当该数据在下面的帧渲染中仍然需要用到时，当前应用会阻塞直到所有提交的指令均已完成。

当绘图指令发出后，其并不一定会立刻执行，而是保存在指令缓存区中。但是 OpenGL ES 中的某些函数会将缓存区中的所有指令提交到图形硬件中执行，而有的函数除了提交所有的指令外，还会停止接收指令直到已提交的指令全部执行结束。

* glFlush 函数会提交指令缓存中的所有所有指令到图形硬件，但不会等待所有指令执行完毕。
* glFinish 、glReadPixels 函数不仅提交所有指令，而且会等待所有指令执行完毕。
* 当指令区满时，指令会提交到图形硬件中。

在桌面系统的 OpenGL 实现中，可以通过调用 glFlush 函数来实现 GPU 和 CPU 的平衡，但是在 iOS 系统中不可以这样操作，调用 glFlush 和 glFinish 函数一般只有下面两种情况：

	* 当应用进入后台时，需要提交所有指令，因为 iOS 系统禁止后台应用执行图形硬件指令。
	* 当需要在不同上下文间共享 OpenGL ES 对象时，需要确保所有指令被执行完毕，共享的资源渲染结束。

在使用 glGet*() 、glGetError() 请求 OpenGL ES 的状态时，总是要求已提交的绘制命令执行完毕，所以这种访问 OpenGL ES 状态的方式会使 CPU 锁定 GPU 降低处理性能，所以通常应拷贝一份 OpenGL ES 状态，直接访问拷贝的状态。

> 诸如 glCheckFramebufferStatus() 、glGetProgramInfoLog() 和 glValidateProgram() 等函数只在调试模式下有效，发布模式下应省略。

### 双缓存区
当使用 OpenGL ES 对象管理资源时，其不能够被 OpenGL ES 和应用同时使用，这就降低了 CPU 和 GPU 的并行性能。使用单缓冲区处理同一个资源时，CPU 总是要同步 GPU ，等待提交的命令执行完毕后，在进行后续的处理，这同样降低了 CPU 与 GPU 的并行性能。

所以为了提高 CPU 和 GPU 的并行性能，采用双缓存区，CPU 和 GPU 可以同时处理不同缓存区中的数据，但是这要求两者处理任务的结束时间相近。可以增加缓存区来防止 CPU 或 GPU 处于空闲状态，但是该操作会消耗额外的内存空间。

另外，OpenGL ES 保存着当前复杂的状态数据，当前着色器程序，全局变量，纹理单元，顶点数据缓存以及顶点数据的关联属性等。改变这些状态需要耗费资源，所以应尽量避免不必要的状态改变，也不要重复设置状态，即使状态值相同，OpenGL ES 也不会去校验，而是直接去更新状态值。并且状态值设置后并不是立即生效，而是当绘制命令执行时，使用必要的状态信息去进行绘制，所以可以在绘制之前或需要该状态去绘制时，设置相应的状态。

## 性能调优
不同与 OS X 及其他桌面系统，基于 iOS 系统的设备的内存资源及 CPU 性能终究要差一点。嵌入的 GPU 所用的算法为适应低内存和有限的电量进行了优化，不同于普通电脑 GPU 所用的算法，所以如果不能高效的渲染图像，不仅会造成帧的刷新频率过低，还会降低电池的寿命。

### 调试
在上线应用前，要对应用做性能测试及调优，使用 Xcode 中的调试功能查看应用的整体性能。使用 OpenGL ES Analysis 和 OpenGL ES Driver 工具获取更详细的信息分析应用运行时的性能。使用 OpenGL ES Frame Debugger 和 Performance Analyser 工具定位性能问题。通过逐个执行 OpenGL ES 指令来观察每一条指令对状态、资源和输出的帧数据的影响；还可以查看着色程序源码并进行修改，观察修改后对渲染图像的影响。

通过调用 glGetError 函数可以获取调用 OpenGL ES API 时产生的错误，或者其他性能问题，但是频繁的调用该函数本就会降低应用的性能，所以在调优过程中，应使用工具直接查看其记录的错误，还可以添加 OpenGL ES Error 断点，当 OpenGL ES 报错时，程序会自动停止。

为了调试的可读性，可以通过 **EXT_debug_marker** 和 **EXT_debug_label** 扩展将一组相关的绘制指令添加到一个逻辑分组中并且可以为 OpenGL ES 对象添加一个可读的名称。

使用 **glPushGroupMarkerEXT** 函数定义一个命令组的开始，并提供组名，然后后面添加相关的指令函数，最后使用**glPopGroupMarkerEXT** 函数结束一个组，组与组之间可以进行嵌套。当使用 GLKView 进行绘制时，所有的指令函数都放在 **Rendering** 中。

```
glPushGroupMarkerEXT(0, "Draw Spaceship");
glBindTexture(GL_TEXTURE_2D, _spaceshipTexture);
glUseProgram(_diffuseShading);
glBindVertexArrayOES(_spaceshipMesh);
glDrawElements(GL_TRIANGLE_STRIP, 256, GL_UNSIGNED_SHORT, 0);
glPopGroupMarkerEXT();
```

同样，使用 glLabelObjectEXT 函数为 OpenGL ES 对象指定一个可读的名称，如使用 GLKTextureLoader 加载纹理数据对象，那么该对象命名为其所在的文件名称。

```
glGenVertexArraysOES(1, &_spaceshipMesh);
glBindVertexArrayOES(_spaceshipMesh);
glLabelObjectEXT(GL_VERTEX_ARRAY_OBJECT_EXT, _spaceshipMesh, 0, "Spaceship");
```

### 性能优化
为了尽可能的节省系统资源，应对应用进行调优。

* Core Animation 会缓存渲染的结果，当数据未发生变化时，不应重新渲染图像，当数据发生变化时，也不应以最快的速度进行渲染，而是以适当且稳定的速度进行渲染，这样既能流畅平滑的现实内容，也能节约电量。

* 对于能够预先计算保存的数据，不应放在运行时进行计算。
* 在使用 OpenGL ES 2.0 及之后版本的框架时，应该针对不同的人物创建多个着色器，不应让一个着色器完成所有的任务。
* 禁用所有不必要的函数，如禁用 OpenGL ES 1.1 中不需要的固定函数操作；禁用不需要的高亮、混合操作函数；在 2D 绘制时，禁用雾化和深度测试。

### 基于瓦片的延迟渲染
在 iOS 设备上的所有 GPU 都使用了 tile-based deffered rendering（TBDR）技术。当 OpenGL ES 函数将渲染指令提交到硬件时，其只是被保存在命令缓存区中，并没有立即执行。当要显示渲染缓存区中的内容或刷新命令缓存区中的命令时，硬件才开始对像素进行处理。在处理过程中，整个帧会被分为许多个瓦片，然后对每一个瓦片执行一遍渲染命令。瓦片的内存是 GPU 硬件中的一部分，所以渲染过程相较于传统流模式快。因为在这种 GPU 结构中可以一次处理整个场景中的所有顶点，并且消除隐藏面的片段数据。对于不可见且不参与抽样处理的像素会被遗弃，这样减少 GPU 的计算量。

当 TBDR 图形处理器开始渲染一个瓦片时，其必需先将帧缓存中的部分内容从共享内存空间中转换到 GPU 中的瓦片内存中，这个过程叫做 logical buffer load ，为了避免不必要的时间和电量的消耗，应先调用 glClear 函数清空前一帧缓存的数据内容。当 GPU 结束了一个瓦片的渲染，其必需将瓦片像素数据写回共享内存中，这个转换过程叫做 logical buffer store 。这个过程同样消耗资源，所以除了需要显示在屏幕上的颜色渲染数据必需要写回共享内存外，其他与帧缓存相关联的数据会在下一个帧渲染时重新生成，所以不必进行保存。对于 OpenGL ES 而言，其会自动保存这些缓存到共享内存，可以调用 glInvalidateFramebuffer（OpenGL ES 3.0）或 glDiscardFramebufferEXT（OpenGL ES 1.1～2.0）函数明确废弃这些缓存。当渲染目标发生切换时，logical buffer load 和 store 步骤也会重新执行，所以对于同一个目标的渲染应放在一起进行，尽量避免反复切换目标。

当 TBDR 图形处理器使用深度值缓存数据自动处理整个场景的隐藏界面消除操作时，需要确保只有一个片段着色器是有效的。并且，当颜色混合、透明度测试有效或片段着色器使用了废弃指令或输出 gl_FlagDepth 变量时，GPU 便无法使用深度缓存数据来判断一个片段是否是可见的来，此时，便需要片段着色器对每一个像素进行计算。这样会增加额外的消耗，所以要尽量避免这些操作。如果无法避免，可以使用下面的方法来减少性能的消耗。

* 根据透明度进行排序，先绘制不透明的对象，在绘制有着色器参与的图形（使用了废弃指令或透明度测试），最后绘制透明度混合的对象。
* 裁剪空白的区域，以减少片段处理的数据量。
* 尽早使用废弃指令以减少不必要的计算。
* 将透明度的值设为 0 ，而不是使用透明度测试或废弃指令来消除像素。
* 考虑使用 Z-Prepass 策略进行渲染，先用包含要废弃的数据的着色器简单的渲染整个场景，保存到深度缓存中。然后，使用深度测试函数 GL_EQUAL 和灯光渲染器再次渲染整个场景。虽然多通道的渲染相较于单通道的渲染会带来性能上的损耗，但是如果有大量的丢弃性操作，那么这种方式性能更优。

> 上述节约内存和计算资源的对于大型场景的处理有效，但是并不适用于简单场景的情况。

### 减少绘制命令调用
每当提交数据进行处理时，CPU 都要向图形硬件发送相关的指令，如果频繁调用 glDrawArrays 和 glDrawElements 函数渲染场景，那么 CPU 的性能可能会限制 GPU 的性能发挥，所以减少不必要的绘制命令很有必要。

* 将多个数据合并为一组数据
* 用纹理中的不同部分组成一个纹理集合
* 使用一个绘制命令渲染多个类似的对象

instanced drawing commands 可以实现一次绘制函数的调用实现相同顶点数据的多次绘制，而不必耗费 CPU 时间来设置不同实例的相关的绘制参数，如位置偏移、变换矩阵、颜色或纹理坐标等。

如下面的代码，过度的调用绘制函数，导致 CPU 负载过重。

```
for (x = 0; x < 10; x++) {
    for (y = 0; y < 10; y++) {
        glUniform4fv(uniformPositionOffset, 1, positionOffsets[x][y]);
        glDrawArrays(GL_TRIANGLES, 0, numVertices);
    }
}
```
要避免使用这种循环方式，首先要使用 glDrawArraysInstanced 和 glDrawElementsInstanced 替换 glDrawArrays 和 glDrawElements 函数，然后为顶点着色器提供绘制每个实例时需要的信息。OpenGL ES 中有两种方式提供相关的信息。

* shader instance ID 策略，每一次顶点着色器运行时，其内建的 gl_InstanceID 变量存储着当前需要绘制的实例标识，通过该值可以计算出所需的信息。

```
#version 300 es 
in vec4 position; 
uniform mat4 modelViewProjectionMatrix;
 
void main()
{
    float xOffset = float(gl_InstanceID % 10) * 0.5 - 2.5;
    float yOffset = float(gl_InstanceID / 10) * 0.5 - 2.5;
    vec4 offset = vec4(xOffset, yOffset, 0, 0);
 
    gl_Position = modelViewProjectionMatrix * (position + offset);
}
```

* instanced arrays 策略，将每个实例的信息保存在顶点数组属性中，着色器需要时可以访问这些信息。

```
//保存
#define kMyInstanceDataAttrib 5
 
glGenBuffers(1, &_instBuffer);
glBindBuffer(GL_ARRAY_BUFFER, _instBuffer);
glBufferData(GL_ARRAY_BUFFER, sizeof(instData), instData, GL_STATIC_DRAW);
glEnableVertexAttribArray(kMyInstanceDataAttrib);
glVertexAttribPointer(kMyInstanceDataAttrib, 2, GL_FLOAT, GL_FALSE, 0, 0);
glVertexAttribDivisor(kMyInstanceDataAttrib, 1);
```

```
#version 300 es
 
layout(location = 0) in vec4 position;
layout(location = 5) in vec2 inOffset;
 
uniform mat4 modelViewProjectionMatrix;
 
void main()
{
    vec4 offset = vec4(inOffset, 0.0, 0.0)
    gl_Position = modelViewProjectionMatrix * (position + offset);
}
```

## 顶点数据的处理
不管用户提交了那些原始图形以及对图形管线进行了怎样的配置，OpenGL ES 总是要对顶点进行处理。一个顶点数据由一个或多个属性组成，如位置、颜色、法向量或纹理坐标等。在 OpenGL ES 2.0 和 3.0 版本中，可以自由定义相关的属性，但是在 OpenGL ES 1.1 版本中，只能使用由固定的图形管线函数定义的属性。

定义个属性作为向量由一个或多个通道组成，所有属性中包含的通道的数据类型是统一的。当这些属性作为参数被加载到着色器的变量中时，未提供的通道的值采用 OpenGL ES 的默认值，即最后一个通道填充 1 ，其他通道填充 0 。

如果在绘制的过程中，所有的或部分的点共享相同的属性，那么可以定义一个属性常量，将其作为处理点的命令的一部分提交到图形硬件。

对于需要提交大量原始数据进行渲染的应用，应该小心处理顶点数据以及其提交到 OpenGL ES 的方式。

* 应减少顶点的数据量
* 应减少 OpenGL ES 转换顶点数据到图形硬件之前的预处理过程
* 应减少拷贝顶点数据到图形硬件中的时间
* 应减少对每个顶点数据的计算量

### 简化模型
iOS 中的图形硬件很强大，但是没必要使用过于复杂的模型去显示图形。减少绘制模型时使用的点的数量，就直接减少了顶点的数据量，同时减少了顶点数据的计算量。

* 提供不同细节程度的模型，在运行时根据相机距离物体的距离和显示的尺寸来选择合适的模型。
* 使用纹理来取代顶点信息的提供。
* 一些模型通过添加点来改善光照细节或渲染质量，该步骤通常放在对每一个点进行计算的光栅化阶段，但是这样做会增加顶点的数据量和模型的计算量。所以，可以考虑将计算过程放在片段着色阶段，而不是直接添加额外的点。

	* 使用 OpenGL ES 2.0 或之后的版本，顶点着色器的计算结果经图形硬件处理后，传递给片段着色器，这样可以将顶点着色器的负担分给片段着色器一些，避免顶点处理程序被阻塞。
	* 在 OpenGL ES 1.1 中，可以通过 DOT3 对每个片段进行光照的处理，该过程使用 GL_DOT3_TGB 模式组合包含法向量信息的纹理。

### 避免常量的重复保存
在整个模型中都要用到的常量，不应该复制到每个顶点数据中，可以设置顶点属性常量，或者保存到着色器的全局变量中。

### 使用最小的数据类型
当指定属性的通道的大小时，应选择其中最小的数据类型，可以参考下面几条建议：

* 顶点颜色使用 4 个无符号字节（GL_UNSIGNED_BYTE）
* 纹理坐标使用 2 个或 4 个无符号字节（GL_UNSIGNED_BYTE）或无符号短整型（GL_UNSIGNED_SHORT），不宜将一系列纹理坐标放在一个属性中。
* 避免使用 GL_FIXED 数据类型，因为其与 GL_FLOAT 数据类型占用相同的内存空间，但是表示的数据范围较小，而且 iOS 设备硬件支持浮点数据快速处理。
* OpenGL ES 3.0 上下文支持使用更小的数据类型表示更大的范围，如 GL_HALF_FLOAT 和 GL_INT_2_10_10_10_REV 比 GL_FLOAT 占用更小的内存但能够方便精准的表达诸如法向量等属性。

如果指定更小的通道数据类型，需要重新排列顶点数据以避免出错。

### 使用交错的顶点数据
在使用顶点数据时，其结构可以是一个结构体包含多个数组，也可以是一个数组中包含多个结构体。在 iOS 中，采用第二种方式组织数据。将顶点所有的属性结构体放在一起组成一个数据组，而后每个顶点数据依次排列，这样整个数据区域由多个结构体交错排列，能够更好的利用内存空间。

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2018/pic-20180117-01.png)

当然，如果存在需要共享的顶点属性数据，或者某个属性数据需要按时刷新，那么，可以将该数据从交错的内存区域中分离出来，单独保存在一个结构体中。

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2018/pic-20180117-02.png)

### 顶点数据的排列
自定义顶点数据结构时，需要注意其属性数据的偏移量必需是通道大小的倍数并且必需要是 4 个字节的倍数，否则，当数据被提交到图形硬件进行处理时，系统需要先将数据进行拷贝然后排列成所需的格式，才能进行提交。如下图所示，法向量属性的偏移量为 6 个字节，虽然是通道 2 个字节的倍数，但是不是 4 个字节的倍数，所以要补充 2 个字节。

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2018/pic-20180117-03.png)

### 使用三角形带批量处理顶点数据
使用三角形带可以避免重合点的重复计算，降低性能的损耗。如下图，将 9 个点缩减到 5 个点，大大减少了计算量。

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2018/pic-20180117-04.png)

通常，可以将多个三角形带关联起来进行绘制，但是这也意味着在绘制图形的过程中使用相同的顶点属性和着色器。

在关联两个三角形带时，复制第一个三角形带的最后一个点和第二个三角形带的第一个点，插入到数据中，当数据提交时，相同点构不成三角形会自动忽略。

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2018/pic-20180117-05.png)

当然，为了更好的性能，最好单独提交三角形带数据，并且为了避免在同一个顶点缓存中多次设置相同顶点的数据，可以单独创建一个索引缓存记录三角形带在内存中的位置，然后使用 glDrawElements 函数进行绘制（合适时，可以使用 glDrawElementsInstanced 或 glDrawRangeElements 函数）。

在 OpenGL ES 3.0 中，可以在索引表中插入极大值来表示一个三角形带的结束，这样便不必重复保存顶点的数据而实现了三角形带的组合。

```
GLushort indexData[11] = {
    0, 1, 2, 3, 4,    // triangle strip ABCDE
    0xFFFF,           // primitive restart index (largest possible GLushort value)
    5, 6, 7, 8, 9,    // triangle strip FGHIJ
};
 
// Draw triangle strips
glEnable(GL_PRIMITIVE_RESTART_FIXED_INDEX);
glDrawElements(GL_TRIANGLE_STRIP, 11, GL_UNSIGNED_SHORT, 0);
```
在提交数据前，可以对顶点和索引进行排序，这样相近的点在一起进行绘制，图形硬件会保存最近的计算的点的结果，可以避免相关信息的重复计算。

### 使用顶点缓存对象
下面的例子中定义了一个结构体，结构体中包含要传递给顶点着色器的位置和颜色数据。在 DrawModel 函数中，配置了两个属性，最后进行三角形带的渲染。

```
typedef struct _vertexStruct
{
    GLfloat position[2];
    GLubyte color[4];
} vertexStruct;
 
void DrawModel()
{
    const vertexStruct vertices[] = {...};
    const GLubyte indices[] = {...};
 
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE,
        sizeof(vertexStruct), &vertices[0].position);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_UNSIGNED_BYTE, GL_TRUE,
        sizeof(vertexStruct), &vertices[0].color);
    glEnableVertexAttribArray(GLKVertexAttribColor);
 
    glDrawElements(GL_TRIANGLE_STRIP, sizeof(indices)/sizeof(GLubyte), GL_UNSIGNED_BYTE, indices);
}

```
每一次调用这个函数时，都需要将顶点数据拷贝到 OpenGL ES 然后进行转换，再传递给图形硬件。如果反复进行调用，并且顶点数据并没有改变，那么不必要的拷贝及转换操作造成了性能的浪费。为了避免这种情况，应当使用 vertex buffer object (VBO)，OpenGL ES 持有这些内存，并且可以进行预处理，将数据转换为需要的格式，方便图形硬件的访问。

在应用启动时，创建顶点缓存，并将其绑定到当前的图形上下文。

```
GLuint    vertexBuffer;
GLuint    indexBuffer;
 
void CreateVertexBuffers()
{
 
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
 
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
 
}
```
下面的代码对上述的 DrawModel 函数进行了改写，主要的区别在于 glVertexAttribPointer 函数中不在提供指向顶点数组中数据的指针，而是提供顶点缓存的属性偏移量。

```
void DrawModelUsingVertexBuffers()
{
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE,
        sizeof(vertexStruct), (void *)offsetof(vertexStruct, position));
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_UNSIGNED_BYTE, GL_TRUE,
        sizeof(vertexStruct), (void *)offsetof(vertexStruct, color));
    glEnableVertexAttribArray(GLKVertexAttribColor);
 
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glDrawElements(GL_TRIANGLE_STRIP, sizeof(indices)/sizeof(GLubyte), GL_UNSIGNED_BYTE, (void*)0);
}
```

```
void glVertexAttribPointer( GLuint index, GLint size, 
								 GLenum type, GLboolean normalized, 
								 GLsizei stride, const GLvoid *pointer);
```

* index 指定要修改的顶点属性的索引值
* size 指定要修改的顶点属性的通道数量。必须为 1、2、3 或者 4。初始值为 4（如 position（x,y,z）有 3 个通道，而颜色（r,g,b,a）有 4 个）。
* type 指定通道的数据类型（如 GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT,GL_UNSIGNED_SHORT, GL_FIXED, GL_FLOAT，默认为 GL_FLOAT）。
* normalized 指定当被访问时，固定点数据值是否应该被归一化（GL_TRUE）或者直接转换为固定点值（GL_FALSE）。
* stride 指定连续顶点属性之间的偏移量，默认值为 0 表示属性依次排列（其实就是顶点所占内存的大小）。
* pointer 指定顶点数据中第一个顶点属性的偏移量，默认值为 0 。

### 缓存数据的方式
在顶点缓存对象中，一个关键的设计是其可以告知 OpenGL ES 数据以何种方式进行存储。在 CreateVertexBuffers  函数中调用了厦门的函数：

```
glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
```
其中 GL_STATIC_DRAW 表示存储的内容不会进行修改，这样 OpenGL ES 可以在存储过程中进行优化。除此之外，还有 GL_DYNAMIC_DRAW 值，表示顶点缓存会多次使用，并且存储的内容在渲染循环中会发生改变，而 GL_STREAM_DRAW 则表示缓存区在使用几次后便被遗弃。

当然，在 iOS 系统中，GL_DYNAMIC_DRAW 和 GL_STREAM_DRAW 没什么区别，可以使用 glBufferSubData 函数刷新缓存区数据，但是这会增加系统开销，因为命令缓存区中的命令会被提交并等待提交的命令执行完毕，不过采用双缓存区或多缓存区可以减少性能消耗。

当顶点属性无法统一格式或者某一个属性会不断变更时，应将相关的属性分离出来，创建多个缓存进行存储。如下面的例程，单独定义一个缓存来存储颜色数据，并且使用 GL_DYNAMIC_DRAW 来表明该缓存中的内容是可变的。

```
typedef struct _vertexStatic
{
    GLfloat position[2];
} vertexStatic;
 
typedef struct _vertexDynamic
{
    GLubyte color[4];
} vertexDynamic;
 
//定义两个缓存，分别存储可变内容和不变的内容
GLuint    staticBuffer;
GLuint    dynamicBuffer;
GLuint    indexBuffer;
 
const vertexStatic staticVertexData[] = {...};
vertexDynamic dynamicVertexData[] = {...};
const GLubyte indices[] = {...};
 
void CreateBuffers()
{
// Static position data
    glGenBuffers(1, &staticBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, staticBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(staticVertexData), staticVertexData, GL_STATIC_DRAW);
 
// Dynamic color data
// While not shown here, the expectation is that the data in this buffer changes between frames.
    glGenBuffers(1, &dynamicBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, dynamicBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(dynamicVertexData), dynamicVertexData, GL_DYNAMIC_DRAW);
 
// Static index data
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
}
 
void DrawModelUsingMultipleVertexBuffers()
{
    glBindBuffer(GL_ARRAY_BUFFER, staticBuffer);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE,
        sizeof(vertexStruct), (void *)offsetof(vertexStruct, position));
    glEnableVertexAttribArray(GLKVertexAttribPosition);
 
    glBindBuffer(GL_ARRAY_BUFFER, dynamicBuffer);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_UNSIGNED_BYTE, GL_TRUE,
        sizeof(vertexStruct), (void *)offsetof(vertexStruct, color));
    glEnableVertexAttribArray(GLKVertexAttribColor);
 
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glDrawElements(GL_TRIANGLE_STRIP, sizeof(indices)/sizeof(GLubyte), GL_UNSIGNED_BYTE, (void*)0);
}
```

### 使用顶点数组对象管理顶点数组状态的改变
在上述的 DrawModelUsingMultipleVertexBuffers 函数中，启用了一些属性，绑定了一些顶点缓存对象并且进行了一些配置。但是每一帧的渲染调用这个函数时，其中的许多图形管线的设置都进行了重复的设置，这是对性能的浪费。使用顶点数组对象来保存整个属性配置，这样可以重复使用配置参数，提高渲染的效率。

如下图，用两个顶点数组对象保存了两个不相互影响的顶点属性配置，并且配置的不同属性可以保存在一个顶点缓存区中或多个缓存区中。

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2018/pic-20180117-06.png)

实现上图的例程如下：

```
void ConfigureVertexArrayObject()
{
    // Create and bind the vertex array object.
    glGenVertexArrays(1,&vao1);
    glBindVertexArray(vao1);
    
    // Configure the attributes in the VAO.
    glBindBuffer(GL_ARRAY_BUFFER, vbo1);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE,
        sizeof(staticFmt), (void*)offsetof(staticFmt,position));
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_UNSIGNED_SHORT, GL_TRUE,
        sizeof(staticFmt), (void*)offsetof(staticFmt,texcoord));
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE,
        sizeof(staticFmt), (void*)offsetof(staticFmt,normal));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
 
    glBindBuffer(GL_ARRAY_BUFFER, vbo2);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_UNSIGNED_BYTE, GL_TRUE,
        sizeof(dynamicFmt), (void*)offsetof(dynamicFmt,color));
    glEnableVertexAttribArray(GLKVertexAttribColor);
 
    // Bind back to the default state.
    glBindBuffer(GL_ARRAY_BUFFER,0);
    glBindVertexArray(0); 
}
```
在上面的例程中，生成的顶点数组对象被绑定到当前上下文中，而生成的顶点配置属性则是保存在顶点数组对象中，而不是绑定到上下文中。当顶点数组对象设置完成后，不应在运行时进行修改，如果有需要，应创建多个顶点数组对象。如在双缓存应用中，配置一组顶点数组对象用来渲染奇数帧，另一组用来渲染偶数帧，当然所使用的顶点数组对象要连接到待渲染的帧的顶点缓存对象中。

### 快速渲染的缓存映射
在 OpenGL ES 中，一个难点是实现动态资源的快速渲染。如在渲染每一帧时，顶点数据都发生了变化，那么如何管理数据在应用和 OpenGL ES 之间的传递是平衡 CPU 和 GPU 性能的关键。传统技术，如 glBufferSubData 函数，其会强制 GPU 等待数据传入，即使 GPU 可以从当前缓冲区中获取所需的渲染数据，所以这种做法并不高效。

在渲染帧频繁的应用中，同时想要修改顶点缓存中的内容，但是如果上一帧的渲染命令正在执行，GPU 正在使用中，此时想要修改缓存准备下一帧的内容，那么，CPU 会被阻塞，直到 GPU 执行完毕。对于这种情况，可以手动同步 CPU 和 GPU 。通过调用 glMapBufferRange 函数来获取 OpenGL ES 的内存范围，任何写入新的数据。另外，该函数还可以将缓冲区中的数据保存到应用缓存中，还允许使用同步对象对缓存进行异步修改。

````
GLsync fence;
GLboolean UpdateAndDraw(GLuint vbo, GLuint offset, GLuint length, void *data) {
    GLboolean success;
 
    // Bind and map buffer.
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    void *old_data = glMapBufferRange(GL_ARRAY_BUFFER, offset, length,
        GL_MAP_WRITE_BIT | GL_MAP_FLUSH_EXPLICIT_BIT |
        GL_MAP_UNSYNCHRONIZED_BIT );
 
    // Wait for fence (set below) before modifying buffer.
    glClientWaitSync(fence, GL_SYNC_FLUSH_COMMANDS_BIT, GL_TIMEOUT_IGNORED);
 
    // Modify buffer, flush, and unmap.
    memcpy(old_data, data, length);
    glFlushMappedBufferRange(GL_ARRAY_BUFFER, offset, length);
    success = glUnmapBuffer(GL_ARRAY_BUFFER);
 
    // Issue other OpenGL ES commands that use other ranges of the VBO's data.
 
    // Issue draw commands that use this range of the VBO's data.
    DrawMyVBO(vbo);
 
    // Create a fence that the next frame will wait for.
    fence = glFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
    return success;
}
```
在上面的例程中，在最后使用 glFenceSync 函数标记了一个同步点，每一次调用该函数时，都会调用 glClientWaitSync 函数对同步点进行校验。如果在新的渲染周期中，上一周期提交的命令 GPU 还未执行完毕，那么就阻塞 CPU 进行等待，如果已经执行完毕，则可以修改缓冲区中的数据。






