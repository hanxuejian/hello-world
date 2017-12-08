# iOS 多线程小结
在 iOS 系统中，应用打开后会生成一个进程，这个进程保存程序运行过程中的资源，进程会开启一个主线程执行代码。在 iOS 系统中，所有的 UI 操作都应放在主线程中进行，所以主线程又称作 UI 线程，除了主线程之外的线程，统称为子线程。为了避免主线程阻塞而造成应用卡顿，所有的耗时操作都应放在子线程中进行。

## Pthreads
POSIX 线程（POSIX threads），简称Pthreads，是线程的 POSIX 标准。该标准定义了创建和操纵线程的一整套 API。该 API 是 C 语言编写的，所以移植性较好。

使用 **pthread_create()** 方法创建一个自动执行的线程，它有4个参数，第一个参数是指向 pthread_t 的指针，用来返回所生成线程的唯一标识；第二个参数是指向 pthread_attr_t 的指针，用来设置线程的属性；第三个参数是线程运行函数的起始地址；最后一个参数是运行函数的参数。

使用 **pthread_exit()** 方法终止当前线程，除此之外还有一些其他方法以供操作线程。

## NSThread
使用 **NSThread** 的实例方法创建线程，可以设置线程的名称、优先级、所占内存大小等属性，设置完成后，调用 **start** 方法，告知 CPU 线程准备完毕，可以执行。

```
- (void)taskThread {
    NSThread *thread = [[NSThread alloc]initWithTarget:self selector:@selector(threadStart:) object:nil];
    thread.name = @"taskThread";
    thread.threadPriority = 0.5;
    thread.stackSize = 1024*1024;
    self.thread = thread;
    [thread start];
}

- (void)threadStart:(id)obj {    
    NSLog(@"thread : %@",self.thread);
}
```
除了实例方法外，还可以使用 NSThread 的类方法从当前线程中分离出来一个新的线程，但是无法设置新线程的属性。

```
+ (void)detachNewThreadWithBlock:(void (^)(void))block API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));
+ (void)detachNewThreadSelector:(SEL)selector toTarget:(id)target withObject:(nullable id)argument;
```
另外，还可以使用 NSObject 的分类中的方法，隐式的创建线程

```
- (void)performSelectorInBackground:(SEL)aSelector withObject:(nullable id)arg NS_AVAILABLE(10_5, 2_0);
```

## GCD
GCD 是苹果公司为多核并发处理器设计的的面向任务（ NSThread 是面向线程的）的 C 语言框架，使用时无需手动管理内存。使用 GCD 时，将任务代码封装在块中，放在任务队列中，最后由线程执行。

### 队列
GCD 中的队列分为：**串行队列**、**并行队列**和**主队列**。在 GCD 中，可以直接获取全局并发队列和主队列，或者自己创建指定并发性和优先级的队列。

1. 获取主队列

    `dispatch_queue_t mainQueue = dispatch_get_main_queue();`

    
2. 获取全局并发队列

	```
	//使用该方法获取并发队列，第一个参数指定队列的优先级，第二个参数为预留参数
	dispatch_queue_t dispatch_get_global_queue(long identifier, unsigned long flags);

	//队列的优先级分为三种：默认、低优先级、高优先级
	dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_queue_t lowQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	dispatch_queue_t highQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	```

3. 创建串行队列

	```
	dispatch_queue_t serialQueue = dispatch_queue_create("serialQueue", DISPATCH_QUEUE_SERIAL);
	```
4. 创建并行队列

	```
	dispatch_queue_t concurrentQueue = dispatch_queue_create("concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
	```

### 执行函数
获取队列并且确定了任务后，便需要调用 GCD 中的函数，将任务添加到所获取的队列中。选择不同的添加函数，任务的执行过程也会不同。常用的函数如下：

```
//同步执行函数
void dispatch_sync(dispatch_queue_t queue, dispatch_block_t block);

//异步执行函数
void dispatch_async(dispatch_queue_t queue, dispatch_block_t block);
```

### 同步执行函数
使用同步执行函数向指定的队列中添加任务时，并不会创建新的线程，而是暂停当前的任务，去执行这个加入到队列中的新任务，当新的任务执行结束后，在继续往下执行中断的任务。

每个串行队列中的任务都遵循先进先出的原则，先加入到队列中的任务先执行，一个任务执行结束后，再接着执行第二个任务。所以，当一个串行队列的任务在执行的过程中，使用同步执行函数向这个串行队列添加了一个新的任务，那么这个串行队列的执行线程会中断当前的任务，要去执行新添加的任务，但是串行队列遵循先进先出的原则，所以造成了两个任务相互等待，形成死锁。如下例程：

```
dispatch_queue_t serialQueue = dispatch_queue_create("serialQueue", DISPATCH_QUEUE_SERIAL);
dispatch_sync(serialQueue, ^{    
    NSLog(@"block execute 0: %@",[NSThread currentThread] );
    dispatch_sync(serialQueue, ^{        
        NSLog(@"block execute 1: %@",[NSThread currentThread]);
    });
});
```
这里需要注意的是，主队列是个特殊的串行队列，其中的任务都是由主线程执行的，所以在主线程中使用同步执行函数添加任务也会造成死锁，如下：

```
dispatch_queue_t mainQueue = dispatch_get_main_queue();
dispatch_sync(mainQueue, ^{
    NSLog(@"block execute : %@",[NSThread currentThread]);
});
```
并且，在子线程中使用同步执行函数向主队列中添加任务，此时，当前线程会被阻塞，等待新添加的任务被主线程执行结束后，才会继续执行。如下面的测试代码：

```
- (void)test {
    NSLog(@"test execute : %@",[NSThread currentThread]);
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"block execute 0: %@",[NSThread currentThread] );
        NSLog(@"block end 0");
    });
    NSLog(@"test end 0");
}
```
在主线程中执行 `[self performSelectorInBackground:@selector(test) withObject:nil];` 代码，得到如下结果：

```
2017-11-27 00:15:16.090 test[1198:128015] test execute : <NSThread: 0x610000260640>{number = 3, name = (null)}
2017-11-27 00:15:16.157 test[1198:127964] block execute 0: <NSThread: 0x6180000798c0>{number = 1, name = main}
2017-11-27 00:15:16.157 test[1198:127964] block end 0
2017-11-27 00:15:16.157 test[1198:128015] test end 0
```

所以，所谓同步执行，是指与当前执行线程相同步，同步执行函数中指定的队列不论是串行队列、并行队列或者是主队列，效果都是一样的。如在主线程中执行下面的代码，新添加到其他队列中的任务始终是主线程在执行，只是任务中有新的任务被执行。

```
dispatch_queue_t serialQueue = dispatch_queue_create("serialQueue", DISPATCH_QUEUE_SERIAL);
dispatch_queue_t serialQueue1 = dispatch_queue_create("serialQueue", DISPATCH_QUEUE_SERIAL);
dispatch_sync(serialQueue, ^{    
    NSLog(@"block execute 0: %@",[NSThread currentThread] );
    dispatch_sync(serialQueue1, ^{        
        NSLog(@"block execute 1: %@",[NSThread currentThread]);
	     NSLog(@"block end 1");
    });
    NSLog(@"block end 0");
});
```
得到的结果如下：

```
2017-11-26 23:06:23.003 test[875:70799] block execute 0: <NSThread: 0x60800006e340>{number = 1, name = main}
2017-11-26 23:06:23.003 test[875:70799] block execute 1: <NSThread: 0x60800006e340>{number = 1, name = main}
2017-11-26 23:06:23.003 test[875:70799] block end 1
2017-11-26 23:06:23.003 test[875:70799] block end 0
```

> 每个串行队列都有一个相对应的执行线程，顺序的执行队列中的任务，但是这些线程之间是并发的。

并发队列中的任务可以并发的被执行，所以使用同步执行函数向并发队列中添加任务，并不会造成死锁，但是这些任务其实是同一个线程执行的，只是执行过程中，任务可能会被中断。如在主线程中执行下面的代码：

```
dispatch_queue_t highQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
dispatch_sync(highQueue, ^{
    NSLog(@"block execute 0: %@",[NSThread currentThread] );
    dispatch_sync(highQueue, ^{
        NSLog(@"block execute 1: %@",[NSThread currentThread]);
        dispatch_sync(highQueue, ^{
            NSLog(@"block execute 2: %@",[NSThread currentThread]);
            NSLog(@"block end 2");
        });
        NSLog(@"block end 1");
    });        
    NSLog(@"block end 0");
});
NSLog(@"origin thread end");
```
得到结果如下：

```
2017-11-26 23:18:18.338 test[953:81540] block execute 0: <NSThread: 0x6000000728c0>{number = 1, name = main}
2017-11-26 23:18:18.338 test[953:81540] block execute 1: <NSThread: 0x6000000728c0>{number = 1, name = main}
2017-11-26 23:18:18.338 test[953:81540] block execute 2: <NSThread: 0x6000000728c0>{number = 1, name = main}
2017-11-26 23:18:18.338 test[953:81540] block end 2
2017-11-26 23:18:18.338 test[953:81540] block end 1
2017-11-26 23:18:18.338 test[953:81540] block end 0
2017-11-26 23:18:18.338 test[953:81540] origin thread end
```

### 异步执行函数
使用异步执行函数向串行队列中添加任务时，可能有新的线程创建用来执行新添加的任务，而当前线程不会被阻塞而继续执行当前的任务。这些新加入串行队列中的任务会由该队列相应的线程顺序执行。如在主线程中执行下面的两个代码片段，其结果是一致的。

```
dispatch_queue_t serialQueue = dispatch_queue_create("serialQueue", DISPATCH_QUEUE_SERIAL);
    
dispatch_async(serialQueue, ^{
    NSLog(@"block execute 0: %@",[NSThread currentThread] );
    dispatch_async(serialQueue, ^{
        NSLog(@"block execute 1: %@",[NSThread currentThread]);
        dispatch_async(serialQueue, ^{
            NSLog(@"block execute 2: %@",[NSThread currentThread]);
            NSLog(@"block end 2");
        });
        NSLog(@"block end 1");
    });
    NSLog(@"block end 0");
});
NSLog(@"origin thread end");
```

```
dispatch_queue_t serialQueue = dispatch_queue_create("serialQueue", DISPATCH_QUEUE_SERIAL);
    
dispatch_async(serialQueue, ^{
    NSLog(@"block execute 0: %@",[NSThread currentThread] );
    NSLog(@"block end 0");
});
dispatch_async(serialQueue, ^{
    NSLog(@"block execute 1: %@",[NSThread currentThread]);
    NSLog(@"block end 1");
});
dispatch_async(serialQueue, ^{
    NSLog(@"block execute 2: %@",[NSThread currentThread]);
    NSLog(@"block end 2");
});
NSLog(@"origin thread end");
```
得到的结果如下：

```
2017-11-26 23:41:31.369 test[1091:102612] origin thread end
2017-11-26 23:41:31.369 test[1091:102650] block execute 0: <NSThread: 0x6100000794c0>{number = 3, name = (null)}
2017-11-26 23:41:31.369 test[1091:102650] block end 0
2017-11-26 23:41:31.370 test[1091:102650] block execute 1: <NSThread: 0x6100000794c0>{number = 3, name = (null)}
2017-11-26 23:41:31.370 test[1091:102650] block end 1
2017-11-26 23:41:31.370 test[1091:102650] block execute 2: <NSThread: 0x6100000794c0>{number = 3, name = (null)}
2017-11-26 23:41:31.370 test[1091:102650] block end 2
```

使用异步执行函数向并行队列中添加任务时，GCD 会根据队列中的任务数量开启一定数量的线程执行队列中的任务，并且这些任务执行的先后顺序是不确定的。

使用异步执行函数向主队列中添加任务时，不会有新线程创建，并且这些任务顺序执行。

### 小结
|执行函数|队列|特性|
|:----:|:----:|:---:|
|dispatch_sync()|主队列、串行队列、并行队列|不会有新的线程被创建，任务都是由调用执行函数的线程或者主线程执行的|
|dispatch_async()|主队列|不会创建新的线程，任务被主线程顺序执行|
|dispatch_async()|串行队列|如果该串行队列没有自己相应的线程，那么会有新的线程被创建，用来执行该串行队列中的任务|
|dispatch_async()|并行队列|GCD 会根据任务数量创建多条线程来执行任务|

## NSOperation
NSOperation 是抽象类，封装了一个待执行的任务，一般使用它的子类 **NSBlockOperation**、**NSInvocationOperation**，如果必要，还可以自定义 NSOperation 的子类。

封装好任务得到一个 NSOperation 的子类后，可以直接调用 NSOperation 的 start 方法，那么当前线程会去执行这个封装好的任务。当然，调用 start 方法时，会去校验任务的状态是否是已经可以执行，如果不可以会报错，若可以，则执行 NSOperation 中的 main 方法，从而执行任务。对于一个任务而言，如果它存在依赖的任务尚未完成，那么这个任务是不可被执行的。如下测试代码：

```
- (void)test {
    NSLog(@"current thread : %@",[NSThread currentThread]);
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    NSBlockOperation *task1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task1 executed : %@",[NSThread currentThread]);
    }];
    NSBlockOperation *task2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task2 executed : %@",[NSThread currentThread]);
    }];
    [task1 addDependency:task2];
    [task2 start];
    [task1 start];
}
```
在主线程中执行下面的代码：

```
[self test];
[self performSelectorInBackground:@selector(test) withObject:nil];
```
得到下面的结果：

```
2017-11-27 22:11:20.981 test[923:39869] current thread : <NSThread: 0x600000063e40>{number = 1, name = main}
2017-11-27 22:11:20.981 test[923:39869] task2 executed : <NSThread: 0x600000063e40>{number = 1, name = main}
2017-11-27 22:11:20.981 test[923:39869] task1 executed : <NSThread: 0x600000063e40>{number = 1, name = main}
2017-11-27 22:11:20.982 test[923:39921] current thread : <NSThread: 0x60800006a480>{number = 3, name = (null)}
2017-11-27 22:11:20.982 test[923:39921] task2 executed : <NSThread: 0x60800006a480>{number = 3, name = (null)}
2017-11-27 22:11:20.982 test[923:39921] task1 executed : <NSThread: 0x60800006a480>{number = 3, name = (null)}
```
如果将 `[task2 start];` 与 `[task1 start];` 改变顺序，那么则会报错，所以可以使用添加依赖的方法，来控制任务执行的先后顺序，这个顺序是确定的，不会因为任务被添加到不同的队列中而改变。

> 创建 NSOperation 的子类时，要根据情况实现 NSOperation 的 start 和 main 方法。

## NSOperationQueue
NSOperationQueue 类是对 GCD 队列的封装，这样性能虽然有所降低，但是操作更加方便，能够设置队列最大的线程并发数量，可以取消、暂停、恢复队列中的任务，通常与 NSOperation 类一起使用。将 NSOperation 任务添加到队列中后，队列会根据任务状态、优先级等情况自动执行任务。队列分为主队列与非主队列，加入主队列中的任务，由主线程执行，其他队列中的任务由子线程执行。

```
//创建一个非主队列
NSOperationQueue *queue = [[NSOperationQueue alloc]init];

//获取主队列
NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
```

如下测试代码：

```
- (void)test {
    NSThread *currentThread = [NSThread currentThread];
    NSLog(@"current thread start : %@",currentThread);
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    NSBlockOperation *task1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task1 executed in : %@ and added in : %@",[NSThread currentThread],currentThread);
    }];
    NSBlockOperation *task2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"task2 executed in : %@ and added in : %@",[NSThread currentThread],currentThread);
    }];
    [task1 addDependency:task2];
    [mainQueue addOperation:task1];
    [queue addOperation:task2];
    NSLog(@"current thread end : %@",currentThread);
}
```
在主线程中执行下面的代码：

```
[self test];
[self performSelectorInBackground:@selector(test) withObject:nil];
```
得到下面的结果：

```
2017-11-27 22:42:50.605 test[1017:62483] current thread start : <NSThread: 0x60000006ae00>{number = 1, name = main}
2017-11-27 22:42:50.606 test[1017:62483] current thread end : <NSThread: 0x60000006ae00>{number = 1, name = main}
2017-11-27 22:42:50.606 test[1017:62539] task2 executed in : <NSThread: 0x61800006cfc0>{number = 3, name = (null)} and added in : <NSThread: 0x60000006ae00>{number = 1, name = (null)}
2017-11-27 22:42:50.606 test[1017:62541] current thread start : <NSThread: 0x608000074dc0>{number = 4, name = (null)}
2017-11-27 22:42:50.606 test[1017:62541] current thread end : <NSThread: 0x608000074dc0>{number = 4, name = (null)}
2017-11-27 22:42:50.606 test[1017:62539] task2 executed in : <NSThread: 0x61800006cfc0>{number = 3, name = (null)} and added in : <NSThread: 0x608000074dc0>{number = 4, name = (null)}
2017-11-27 22:42:50.681 test[1017:62483] task1 executed in : <NSThread: 0x60000006ae00>{number = 1, name = main} and added in : <NSThread: 0x60000006ae00>{number = 1, name = main}
2017-11-27 22:42:50.681 test[1017:62483] -[AppDelegate application:didRegisterUserNotificationSettings:]
2017-11-27 22:42:50.682 test[1017:62483] task1 executed in : <NSThread: 0x60000006ae00>{number = 1, name = main} and added in : <NSThread: 0x608000074dc0>{number = 4, name = main}
```
由结果可知，添加到不同队列中的任务的依赖关系仍然有效，并且确定了任务的执行顺序。