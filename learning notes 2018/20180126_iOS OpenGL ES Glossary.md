## iOS 中 OpenGL ES 实现的术语表
下表给出的术语不仅仅用于 OpenGL ES 在 Apple 上的实现，大多也同样适用于 OpenGL ES 图形编程语言中。

|术语|说明|
|:---:|---|
|aliased|走样，多指图形边界处呈锯齿形，可使用反走样操作进行修正|
|antialiasing|反走样技术，用于消除图形绘制时出现的锯齿形走样|
|attach|关联，将两个已经存在的对象相关联|
|bind|绑定，将一个对象绑定到一个图形渲染上下文中|
|bitmap|位图，一个二进制的矩形集合|
|buffer|缓存，一片由 OpenGL ES 管理的用来存储诸如顶点属性、颜色数据等指定种类数据的内存|
|clipping|裁剪，一种限定绘制区域的技术，对区域之外的内容不进行绘制|
|clip coordinates|裁剪坐标，该坐标用于体视图的裁剪，其作用在投影坐标之后，透视分割之前|
|completeness|完成状态，表示帧缓存对象是否满足所有的绘制要求|
|context|上下文，一组 OpenGL ES 状态变量的集合，其所关联的绘制对象影响着最终图形的绘制，也称作 rendering context|
|culling|剔除，消除场景中对于观察者不可见的部分|
|current context|当前上下文，OpenGL ES 绘制使用的上下文|
|current matrix|当前矩阵，在 OpenGL ES 中将坐标从一个坐标系转换到另一个坐标系中时使用的矩阵|
|depth|深度，在 OpenGL 中坐标 z 表示像素距离视点的距离|
|depth buffer|深度缓存，一片用于存储每一个像素的深度值的缓存，在 OpenGL ES 的光栅化阶段，每个片段都需要进行深度测试，使用深度缓存中的值同传入的深度值进行比较，只有通过测试的片段才会被保存在帧缓存中|
|double buffering|双缓冲区，用于避免绘图子系统中资源的冲突，前缓冲区和后缓冲去，一个被使用，一个被修改，两者可适时交换位置|
|drawable object|可绘制对象，在 OpenGL ES 之外进行声明和分配的对象，但可以被用作帧缓存的一部分。iOS 中，只有用来合成 OpenGL ES 渲染和动画的 CAEAGLLayer 类一种|
|extension|扩展，不是 OpenGL ES 核心 API 的一部分|
|eye coordinates|视觉坐标系，视点所在的原始坐标系，由视图模型矩阵产生并会传递给投影矩阵|
|filtering|过滤，一种通过组合像素和纹素修改图像的过程|
|fog|雾化，使基于视点距离的背景色褪色，其中包含有深度值的细节|
|fragment|片段，光栅化过程中的生成的颜色和深度值，每个片段中的数据在同帧缓存中的像素混合之前都要经过一系列的测试|
|system framebuffer|系统缓存，由系统提供的帧缓存用来将 OpenGL ES 集合到窗口系统，但在 iOS 系统中，使用同动画图层相关联的帧缓存|
|framebuffer attachable image|帧缓存对象的渲染目标|
|framebuffer object|帧缓存对象，该对象包含有 OpenGL ES 帧缓存的状态信息及其图片子集（renderbuffers），在 OpenGL ES 1.1 中使用扩展 `OES_framebuffer_object` 支持帧缓存对象|
|frustum|锥截体，可以被观察者看到的区域，该区域是经过透视分割修改过的|
|image|像素的矩形数组|
|interleaved data|交错数据类型的数组，可以提高数据的读取速度|
|mipmaps|纹理集合，不同分辨率和尺寸大小的纹理集合，用于适配不同的设备|
|modelview matrix|模型视图矩阵，一个 4 阶矩阵，OpenGL ES 使用该矩阵将点、线、基本图形和位置等的坐标从物体坐标系转换到视点坐标系中|
|multisampling|多重抽样，对每个像素抽取多个样本，使用他们的平均值作为最后的输出值，得到最后的片段|
|mutex|互斥量，多线程应用中的互斥量，用来防止线程死锁或保护共享资源|
|packing|将像素颜色值格式转换为应用需要的格式|
|pixel|像素，图片元素，是图形硬件能够在屏幕上显示的最小单元，由二进制位组成|
|pixel depth|像素深度，每个像素所占用的二进制位数|
|pixel format|内存中存储像素数据的格式，该格式由像素通道描述，包含通道的数量、顺序及其他信息，如模版和深度值|
|premultiplied alpha|预乘透明度，即其他像素通道值被透明度通道值乘，如 RGBA(1.0,0.5,0,0.5) 预乘后为 RGBA(0.5,0.25,0,0.5)|
|primitives|原始数据，OpenGL 中最基本的元素，如点、线、多边形、位图、图片等|
|projection matrix|投影矩阵，将 OpenGL 中基本元素从视点坐标系转换到裁剪坐标系中时使用的矩阵|
|rasterization|光栅化，将顶点缓存中的数据转换为片段数据的过程|
|renderbuffer|渲染缓存，在 2D 像素图片中的渲染目标，通常用于离屏渲染|
|renderer|渲染器，软件与硬件相结合的，被 OpenGL ES 用来生成图片的技术|
|rendering context|渲染上下文，包含渲染过程中的各种状态|
|rendering pipeline|渲染管线，OpenGL ES 将像素和顶点数据转化为图片的操作过程顺序|
|render-to-texture|直接渲染纹理目标的操作|
|RGBA|颜色通道（红、绿、蓝、透明度）|
|shader|渲染程序，用于计算表面特性|
|shading language|渲染语言，计算机高级语言，用于为图片增加额外的特性|
|stencil buffer|模板缓存，用于模板测试的缓存区。目标测试通常用来识别掩蔽区域、需要封闭的立体几何图像或交叉的半透明几何图形|
|tearing|图像撕裂，当前帧的数据并未全部显示在屏幕上时，部分区域被上一帧的图像覆盖，iOS 中通过动画整体处理所有的 OpenGL ES 内容来避免图片的撕裂|
|tessellation|镶嵌分解，将表面分解为多个多边形，或将曲线分解为一系列的直线|
|texel|纹素，纹理元素，用来指定片段中的颜色|
|texture|纹理，用来改变光栅化后的片段颜色的图片数据，该数据可以是一维的、二维的、三维的或者是立体图像|
|texture mapping|纹理用于原始数据的过程|
|texture matrix|纹理矩阵，OpenGL ES 1.1 中用来转换纹理坐标从而查找纹理并可以对其进行修改|
|texture object|保存纹理相关数据的结构体，可以包含图片、纹理集合、纹理属性（宽、高、分辨率、格式等）等信息|
|vertex|顶点，一系列的三维顶点可以指定一个几何图形，并且顶点可以拥有颜色、纹理等关联属性|
|vertex array|顶点数组，保存诸如顶点坐标、纹理坐标、表面标量、颜色值等信息的数据结构体|
|vertex array object|顶点数组对象，保存了有效顶点及其属性的一个列表，该对象简化了图形管线配置的过程|