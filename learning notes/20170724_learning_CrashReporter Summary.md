# CrashReporter 简介
CrashReporter 是 Mac OS X 下的调试工具，其会记录 Mac 下所有应用程序的崩溃信息。这些日志信息通常保存在路径 ~/Library/Logs/CrashReporter/ 下，当然，如果 CrashReporter 无法确定崩溃程序的所属用户，或者其用户是根用户，或者所属用户的路径无效或不可写，那么，崩溃日志信息会保存在路径 /Library/Logs/CrashReporter/ 下。

每个崩溃日志信息均会分开保存在一个文件中，文件的命名形如：`PPP_YYYY-MM-DD-HHMMSS_NNN.crash` ，PPP 是应用程序名称，`YYYY-MM-DD-HHMMSS` 是崩溃发生的日期及时间，NNN 则是主机用户名。当然，CrashReporter 也会创建名称如 `.PPP_NNN_CrashHistory.plist` 的隐藏文件。
为了避免日志信息占用大量存储空间，这些日志文件限制为20个。

> 在 Mac OS X 10.5 之前，CrashReporter 创建的日志文件名称形如：PPP.crash.log ，PPP 是程序名称，同一个应用产生的崩溃信息均会被追加到同一个文件中，并且没有存储容量的限制。
 
# 崩溃日志信息
崩溃日志文件中包含许多信息，阅读理解这些信息有利于问题的查找。

## 进程信息
崩溃日志信息的第一部分记录的是崩溃的应用程序的信息，其中包含程序线程号、父线程号、程序路径、程序唯一标识（bundle identifier）、版本等信息，如下：

```
Process:         TextEdit [8752]
Path:            /Applications/TextEdit.app/Contents/MacOS/TextEdit
Identifier:      com.apple.TextEdit
Version:         1.5 (244)
Build Info:      TextEdit-2440000~2
Code Type:       X86 (Native)
Parent Process:  launchd [241]
```

## 基本信息
该部分记录的是崩溃日志本身的相关信息，包括崩溃发生的时间、系统版本、CrashReporter 版本等，如下：

```
Date/Time:       2008-01-29 12:32:46.239 +0000
OS Version:      Mac OS X 10.5.1 (9B18)
Report Version:  6
```

## 异常信息
该部分记录了导致本次崩溃的异常信息，包含异常类型、异常码、崩溃线程等，如下：

```
Exception Type:  EXC_BAD_ACCESS (SIGBUS)
Exception Codes: KERN_PROTECTION_FAILURE at 0x0000000000000000
Crashed Thread:  0
```
最常见的异常类型如下：

|异常类型|含义|
|:----:|:----:|
| **`EXC_BAD_ACCESS/KERN_INVALID_ADDRESS`**  | 访问未分配的内存地址造成，多是由数据访问或提取指令触发|
| **`EXC_BAD_ACCESS/KERN_PROTECTION_FAILURE`** |  向只读区域写数据造成|
| **`EXC_BAD_INSTRUCTION`** |  线程执行了非法指令|
| **`EXC_ARITHMETIC/EXC_I386_DIV`** |  在基于 intel 计算机上执行了除零操作|

## 回溯信息
该部分保存了崩溃进程的所有线程的方法栈信息，如下：

```
Thread 0 Crashed:
0   ???                             0000000000 0 + 0
1   com.apple.CoreFoundation        0x942cf0fe CFRunLoopRunSpecific + 18…
2   com.apple.CoreFoundation        0x942cfd38 CFRunLoopRunInMode + 88
3   com.apple.HIToolbox             0x919e58a4 RunCurrentEventLoopInMode…
4   com.apple.HIToolbox             0x919e56bd ReceiveNextEventCommon + …
5   com.apple.HIToolbox             0x919e5531 BlockUntilNextEventMatchi…
6   com.apple.AppKit                0x9390bd5b _DPSNextEvent + 657
7   com.apple.AppKit                0x9390b6a0 -[NSApplication nextEvent…
8   com.apple.AppKit                0x939046d1 -[NSApplication run] + 79…
9   com.apple.AppKit                0x938d19ba NSApplicationMain + 574
10  com.apple.TextEdit              0x00001df6 0x1000 + 3574
```
当崩溃的程序是多线程时，那么每个线程都会有一个方法栈信息记录，而至于哪个记录是崩溃的栈信息，则需要开发者自己注意 Thread <ThreadNumber> Crashed: 标识。方法调用栈记录的每一行信息都包含4个部分，每部分含义如下：

* 第一列：方法调用栈中的序号，第0行表示造成崩溃的方法调用，下面依次递增，表示本方法的调用方法
* 第二列：是包含该执行代码的二进制文件的映像名称
* 第三列：执行该行记录中相应代码的地址，第0行表示导致崩溃的指令地址
* 第四列：执行代码的符号名称，对于最后分发给用户的应用，若分离了符号，那么该列为16进制数值，根据该数值也能找到相应的符号名称

## 线程状态
该部分记录的是崩溃的线程状态，这个记录与电脑系统架构相关，不同架构，记录的信息不同。

### PowerPC 架构
PowerPC 是 IBM 与 Apple 公司联合生产的个人台式机，其记录信息如下：

```
Thread 0 crashed with PPC Thread State 64:
  srr0: 0x0000000000000000 srr1: 0x000000004000d030                  …
    cr: 0x44022282           …                 lr: 0x000000009000a6bc…
    r0: 0x00000000ffffffe1   r1: 0x00000000bfffeb10   r2: 0x00000000a…
    r4: 0x0000000003000006   r5: 0x0000000000000000   r6: 0x000000000…
    r8: 0x0000000000000000   r9: 0x0000000000000000  r10: 0x000000000…
   r12: 0x000000009000a770  r13: 0x0000000000000000  r14: 0x000000000…
   r16: 0x0000000000000000  r17: 0x0000000000000000  r18: 0x000000000…
   r20: 0x00000000101a7026  r21: 0x00000000be5b19d8  r22: 0x000000000…
   r24: 0x0000000000000450  r25: 0x0000000000001203  r26: 0x000000000…
   r28: 0x0000000000000000  r29: 0x0000000003000006  r30: 0x000000000…
```
这里要关注的是 ssr0 、lr 及崩溃地址，ssr 记录了程序发生崩溃时指令的地址，lr 记录着函数调用的返回地址。对于内存访问时的异常，有以下情况：

* 若 srr0 保存的地址与崩溃地址相等，那么崩溃通常是由提取指令造成的，调用者可能使用了非法的函数指针或者非法对象，而 lr 中则保存了函数返回的地址，即调用该非法函数的代码地址。
* 若 srr0 、lr 、崩溃地址均相等，那么说明崩溃发生在函数返回的时候，这意味着保存函数地址的栈遭到了破环，函数返回时，指向了一个非法地址。
* 若 ssr0 保存的地址与崩溃地址不同，那么说明崩溃是内存访问指令造成的。

### 32位 Intel 架构
对于32位 intel 架构的电脑，其记录的线程状态信息如下：

```
Thread 0 crashed with X86 Thread State (32-bit):
  eax: 0x00000000  ebx: 0x942cea07  ecx: 0xbfffed1c  edx: 0x94b3a8e6
  edi: 0x00000000  esi: 0x00000000  ebp: 0xbfffed58  esp: 0xbfffed1c
   ss: 0x0000001f  efl: 0x00010206  eip: 0x00000000   cs: 0x00000017
   ds: 0x0000001f   es: 0x0000001f   fs: 0x00000000   gs: 0x00000037
  cr2: 0x00000000
```
这里的信息，主要关注 eip 与崩溃地址，eip 是异常发生时，程序计数器中的值，所以其是导致异常发生的指令的地址。对于内存访问时的异常，有以下情况：

* 如果 eip 的值与崩溃地址相同，这说明提取指令异常，可能是使用了非法函数指针、非法对象或返回了非法地址
* 如果 eip 的值与崩溃地址不同，那么这通常是由内存访问指令造成的

> 因为 intel 架构的工作方式不同，其相较于 PowerPC 更难获取线程的状态信息，如，在 PowerPC 中，返回的地址保存在寄存器 lr 中，而 intel 架构中的返回地址则保存在栈中。

### 64位 intel 架构
对于64位 intel 架构的电脑，其记录的线程状态信息如下：

```
Thread 0 crashed with X86 Thread State (64-bit):
  rax: 0x0000000000000000  rbx: 0x0000000000000000  rcx: 0x00007fff5fbfec48…
  rdi: 0x00007fff5fbfed40  rsi: 0x0000000003000006  rbp: 0x00007fff5fbfeca0…
   r8: 0x0000000000001003   r9: 0x0000000000000000  r10: 0x0000000000000450…
  r12: 0x0000000000001003  r13: 0x0000000000000450  r14: 0x00007fff5fbfed40…
  rip: 0x0000000000000000  rfl: 0x0000000000010206  cr2: 0x0000000000000000
```
该信息的解读同32位 intel 架构类似，不同的是 eip 中的值如今保存在 rip 中。

## 二进制映像
该部分保存所有加载到进程中的二进制映像的描述，其信息格式如下：

```
Binary Images:
    0x1000 -    0x18feb  com.apple.TextEdit 1.5 (244) <e1480af78e2746195aa…
 0xc648000 -  0xc72eff7  com.apple.RawCamera.bundle 2.0 (2.0) /System/Libr…
0x8fe00000 - 0x8fe2d883  dyld 95.3 (???) <81592e798780564b5d46b988f7ee1a6a…
0x90046000 - 0x9004efff  com.apple.DiskArbitration 2.2 (2.2) <1551b2af557f…
0x9004f000 - 0x9004fff8  com.apple.ApplicationServices 34 (34) <8f910fa65f…
0x90056000 - 0x900affff  libGLU.dylib ??? (???) /System/Library/Frameworks…
0x900b0000 - 0x900b0ffc  com.apple.audio.units.AudioUnit 1.5 (1.5) /System…
0x900b1000 - 0x90163ffb  libcrypto.0.9.7.dylib ??? (???) <330b0e48e67faffc…
[…]
```
对于日志中无标识符号的回溯信息，可根据此描述信息找到相应的标识符号。另外，可以查看所有加载到进程的插件和库。信息中的括号中的值是映像的 UUID 值，该值对于查找无标识符号的信息很有用处。

## Rosetta 额外信息
当进程在运行时使用了 Rosetta ，那么其崩溃信息中则会记录一些额外信息，如下，进程信息中包含 Code Type 记录项，则说明 Rosetta 被使用了。

```
Process:         TextEdit [9031]
Path:            /Applications/TextEdit.app/Contents/MacOS/TextEdit
Identifier:      com.apple.TextEdit
Version:         1.5 (244)
Code Type:       PPC (Translated)
Parent Process:  launchd [241]
```
另外，Translated 编码信息会被添加在二进制映像部分后面，包含有 Rosetta 版本号、进程命令行参数、崩溃信息、线程状态。

```
Translated Code Information:
Rosetta Version:  20.44
Args:    /Applications/TextEdit.app/Contents/MacOS/TextEdit -psn_0_2761378
Exception: EXC_BAD_ACCESS (0x0001)

Thread 0: Crashed (0xb7fff9d0, 0xb80bc8c8)
0x40400000: No symbol
0x90a9b35c: /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit…
0x90a9b290: /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit…
0x90a9a7a8: /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit…
0x90a9a0e0: /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit…
0x90a99a1c: /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit…
0x90a98458: /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit…
0x90a6b8f4: /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit…
0x909d8ed8: /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit…
0x909a9930: /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit…
0x00001e18: /Applications/TextEdit.app/Contents/MacOS/TextEdit : start + …
0x00000000: /Applications/TextEdit.app/Contents/MacOS/TextEdit :   + 0

PPC Thread State
srr0: 0x00000000  srr1: 0x00000000                 vrsave: 0x00000000
cr:  0xXXXXXXXX    xer: 0x00000000     lr: 0x90a9b35c    ctr: 0x0000e814
r00: 0x90a9b35c   r01: 0xbfffe5d0   r02: 0xa0bcf924   r03: 0x00234840
r04: 0x00020000   r05: 0x002adce0   r06: 0x002adce0   r07: 0x002adce0
r08: 0xa1b1c1d3   r09: 0x00000000   r10: 0x00000004   r11: 0x00000001
r12: 0x0000e814   r13: 0xa01da174   r14: 0xa01da174   r15: 0xa01da174
r16: 0xa01da174   r17: 0xa01da174   r18: 0x00000000   r19: 0x002c00b0
r20: 0xbfffe760   r21: 0xa01da174   r22: 0xa01da174   r23: 0xa01da174
r24: 0xa01ea174   r25: 0x002adce0   r26: 0x002475c0   r27: 0x00015dd4
r28: 0x00234840   r29: 0x00020000   r30: 0x00234840   r31: 0x90a9b2f0
```

## 无标识符号的崩溃日志信息
调试时使用的标识符号会一定程度的影响代码的大小及执行速度，所以，对于现在的 Xcode 可以在分发应用给用户之前取消标识符号，在分析日志信息时，将16进制数值翻译为相应的标识符号。

### 符号类型
在使用 Xcode 编写程序时，其需要处理两种完全不同的符号类型：

* **Mach-O** 符号，该符号由连接器翻译
* **Debugger** 符号，该符号由调试器翻译

Mach-O 也被分为两种类型：

* 本地符号（**local symbols**）—— 该符号会被连接器忽略，其仅仅被如 CrashReporter 的工具使用。当在 C 中使用 static 声明函数时，其会被记录为本地符号。
* 全局符号（**global symbols**）—— 该符号会被静态、动态连接器翻译。当在 C 中使用 extern 声明函数时，其会被记录为全局符号。

Xcode 支持两种格式的调试符号：

* **DWARF** —— 这种较新的调试符号从 Xcode 2.3 开始支持，其不仅仅能够很好的集成 CrashReporter ，还有其他优点。
* **STABS** —— 这种调试符号其实是存储在 Mach-O 符号表中，两种不同概念的符号混合在一起，导致进程管理的混乱，所以其已经废弃。

### 分离调试符号
Xcode 中 DWARF 的使用使得分发程序时，分离调试符号变得简单，只需要在 Build Setting 中将配置项 Debug Information Format 设置为 DWARF with dSYM File（DEBUG_INFORMATION_FORMAT = dwarf-with-dsym）即可，这样，在创建分发应用包时，Xcode 会自动提取程序中所有的调试信息，并保存在 .dSYM 文件中。当未来某个时刻，需要调试分发的程序时，只需要将程序和 .dSYM 文件放在相同路径下，GDB 就会自动找到并使用调试符号。

### 分离 Mach-O 符号
一些 Mach-O 符号是由动态连接器在运行时时翻译的，这些符号在构建应用时不能分离。而在构建不同的应用时，要进行不同的设置。首先，要在 Build Setting 中将 Deployment Postprocessing 设置为 YES（DEPLOYMENT_POSTPROCESSING = YES），而后，根据不同情况设置 Strip Style 的值：

* All Symbols (STRIP_STYLE = all) —— 将分离所有不是动态连接器需要在运行时时使用的符号
* Non-Global Symbols (STRIP_STYLE = non-global) —— 将分离所有本地符号
* Debugging Symbols (STRIP_STYLE = debugging) —— 将分离调试符号，但使用 DWARF 时，不会影响生成的 .dSYM 文件

对于分离 Mach-O 符号，通常有两种处理方式：

* 通常的做法是在分发应用中保留全局及本地的 Mach-O 符号，这些符号并不会占用太多的空间，且在 CrashReporter 中记录基本符号，或者设置 Dtrace 标记。
* 另外，为了尽可能的减小应用的大小，或者出于保密考虑，可以将所有不需要的符号移除。

对于第一种情况，只需在 Build Setting 中 设置 Strip Style 的值为 Debugging Symbols 即可，但第二种需要根据工程目标的不同而定，对于应用和命令行工具，将值设为 All Symbols ，对于包、框架、动态库应分离本地符号，要将 Strip Style 设置为 Non-Global Symbols ，当然，也可以设置 Exported Symbols File 项，明确需要分离的符号，相反，也可以用其他方法明确需保留的符号。

### 符号与 CrashReporter
将工程正确设置后，CrashReporter 产生的日志信息会因设置不同而不同，若保留了本地符号，那么日志中会记录崩溃的函数名称，若分离了所有符号，那么，日志中不会记录相应的函数名称。幸运的是，可以使用 .dSYM 文件获取相关源码层的信息，这个获取信息的过程分为位置相关的代码与位置不相关的代码两种，区别不大。

#### 位置相关代码
对于位置相关的代码（应用程序及命令行工具），使用 GDB 将数值地址转化为符号，较为简单，只需将分发的应用与 .dSYM 文件放在同一个路径下，然后使用 GDB 命令即可，如下：

```
$ # Get the numeric values from the backtrace...
$ grep "Thread 0 Crashed:" -A 19 NoSymbolsTest_[…]_guy-smiley.crash
Thread 0 Crashed:
0   ...le.dts.NoSymbolsTest.Bundle  0x107cbf99 0x107cb000 + 3993
1   ...le.dts.NoSymbolsTest.Bundle  0x107cbfcb 0x107cb000 + 4043
2   ...dts.NoSymbolsTest.Framework  0x10005f2e 0x10005000 + 3886
3   ...dts.NoSymbolsTest.Framework  0x10005f59 0x10005000 + 3929
4   com.apple.dts.NoSymbolsTest     0x10000edf 0x10000000 + 3807
5   com.apple.AppKit                0x939dcf94 -[NSApplication sendAction…
6   com.apple.AppKit                0x939dced4 -[NSControl sendAction:to:…
7   com.apple.AppKit                0x939dcd5a -[NSCell _sendActionFrom:]…
8   com.apple.AppKit                0x939dc3bb -[NSCell trackMouse:inRect…
9   com.apple.AppKit                0x939dbc12 -[NSButtonCell trackMouse:…
10  com.apple.AppKit                0x939db4cc -[NSControl mouseDown:] + …
11  com.apple.AppKit                0x939d9d9b -[NSWindow sendEvent:] + 5…
12  com.apple.AppKit                0x939a6a2c -[NSApplication sendEvent:…
13  com.apple.AppKit                0x93904705 -[NSApplication run] + 847…
14  com.apple.AppKit                0x938d19ba NSApplicationMain + 574
15  com.apple.dts.NoSymbolsTest     0x10000e36 0x10000000 + 3638
16  com.apple.dts.NoSymbolsTest     0x10000e02 0x10000000 + 3586
17  com.apple.dts.NoSymbolsTest     0x10000d29 0x10000000 + 3369

$ # Run GDB to get the symbolic information for the address in frame 4.
$ gdb NoSymbolsTest.app
GNU gdb 6.3.50-20050815 (Apple version gdb-768) […]
(gdb) info line *0x10000edf
Line 86 of "/Users/quinn/Crash Reporter/NoSymbolsTest/AppDelegate.m" \
starts at address
0x10000edf <-[AppDelegate testAction:]+104> and ends at \
0x10000ee1 <-[AppDelegate testAction:]+106>.
```
这里需要注意以下几点：

* 上面使用 GDB 将地址转换为符号，也可以使用 atos ，但是对于分离了所有 Mach-O 符号的应用，不可以使用 atos 。
* 上面的技术要正常工作，那么分析崩溃日志的用户需要有访问工程的权限并且工程与 .dSYM 文件需要一致。那么工程的 UUID（Universally Unique Identifier）、崩溃日志信息中 UUID 与 .dSYM 中的 UUID ，三者要相等（使用 dwarfdump 获取 UUID）。
* 这里默认应用的使用者运行应用的环境同分析者使用的环境相同，若不同，可在分析时，添加可选项参数，形如 -arch xxx（对于 dwarfdump，如 --arch xxx ），其中 xxx 是使用的环境架构，如 i386 、ppc 。

使用 UUID 判断获取的符号是否与应用程序一致

```
$ # Get the UUID from the binary images part of the crash log.
$ # The UUID is displayed in angle brackets.
$ grep "0x.*com.apple.dts.NoSymbolsTest .*<" NoSymbolsTest_[…]_guy-smiley.crash
0x10000000 - 0x10000ffe  com.apple.dts.NoSymbolsTest ??? (1.0) \
<6264534bd26d5d39f7960cea770c4ea8> /Users/quinn/Crash Reporter/NoSymbolsTest/\
build/Release/NoSymbolsTest.app/Contents/MacOS/NoSymbolsTest
$ # Get the UUID from the binary that we have.
$ dwarfdump --uuid NoSymbolsTest.app/Contents/MacOS/NoSymbolsTest
UUID: 6264534B-D26D-5D39-F796-0CEA770C4EA8 (i386) NoSymbolsTest.app[…]
UUID: AA201B24-D09B-49E2-55E5-AB15AF63B12A (ppc) NoSymbolsTest.app[…]
$ # Get the UUIDs from the .dSYM file.
$ dwarfdump --uuid NoSymbolsTest.app.dSYM
UUID: 6264534B-D26D-5D39-F796-0CEA770C4EA8 (i386) NoSymbolsTest.app.dSYM
UUID: AA201B24-D09B-49E2-55E5-AB15AF63B12A (ppc) NoSymbolsTest.app.dSYM
$ # Note that all three UUIDs match!
```

#### 位置不相关的代码
对于位置不相关的代码，如框架、动态库或者包，这些代码的分析要复杂点。分析者需要找出代码名义上加载的位置与实际中加载的位置的差值，这个值叫做偏移量（slide）。

从崩溃日志信息中的二进制映射信息部分，可以找到代码实际加载的地址。如下，是 __TEXT 段的加载地址：

```
$ # Determine the addresses that the programs were loaded.
$ grep "0x.*com.apple.dts" NoSymbolsTest_[…]_guy-smiley.crash
0x10000000 - 0x10000ffe  com.apple.dts.NoSymbolsTest ??? (1.0) […]
0x10005000 - 0x10005ffd  com.apple.dts.NoSymbolsTest.Framework ??? (1.0) […]
0x107cb000 - 0x107cbffc  com.apple.dts.NoSymbolsTest.Bundle ??? (1.0) […]
```
另外，可以使用 otool 获取 __TEXT 段的目的加载地址，如下：

```
$ otool -l NoSymbolsTest.app/Contents/MacOS/NoSymbolsTest \
| grep -B 3 -A 2 -m 1 "__TEXT"
Load command 1
      cmd LC_SEGMENT
  cmdsize 192
  segname __TEXT
   vmaddr 0x10000000
   vmsize 0x00001000
$ otool -l NoSymbolsTest.app/Contents/Frameworks/Framework.framework/Framework \
| grep -B 3 -A 8 -m 1 "__TEXT"
Load command 0
      cmd LC_SEGMENT
  cmdsize 192
  segname __TEXT
   vmaddr 0x01000000
   vmsize 0x00001000
$ otool -l NoSymbolsTest.app/Contents/Resources/Bundle.bundle/Contents/MacOS/Bundle \
| grep -B 3 -A 8 -m 1 "__TEXT"
Load command 0
      cmd LC_SEGMENT
  cmdsize 192
  segname __TEXT
   vmaddr 0x00000000
   vmsize 0x00001000
```
将得到结果，进行计算，得到偏移量，如下：

|程序|实际加载地址（A）|目的加载地址（I）|偏移量（slide = A - I）|
|:----:|:----:|:-----:|:----:|
|main executable|0x10000000|0x10000000|0|
|framework|0x10005000|0x01000000|0x0F005000|
|bundle|0x107cb000|0x00000000|0x107cb000|

> 对于主函数中执行的代码（main executable），总是位置相关的。

如果使用 atos 获取符号，可以使用参数可选项 -S 填充获取的偏移量，如果使用 GDB ，那么过程较复杂，操作如下：

```
$ # Get the addresses from the backtrace.
$ grep "Thread 0 Crashed:" -A 5 NoSymbolsTest_2008-02-04-111412_guy-smiley.crash
Thread 0 Crashed:
0   ...le.dts.NoSymbolsTest.Bundle  0x107cbf99 0x107cb000 + 3993
1   ...le.dts.NoSymbolsTest.Bundle  0x107cbfcb 0x107cb000 + 4043
2   ...dts.NoSymbolsTest.Framework  0x10005f2e 0x10005000 + 3886
3   ...dts.NoSymbolsTest.Framework  0x10005f59 0x10005000 + 3929
4   com.apple.dts.NoSymbolsTest     0x10000edf 0x10000000 + 3807
$ # Now map the addresses for the frames in the bundle (0 and 1).
$ # Run GDB with no arguments.
$ gdb
GNU gdb 6.3.50-20050815 (Apple version gdb-768) […]
(gdb) # Disable shared library preloading.  See below for why.
(gdb) set sharedlibrary preload-libraries off
(gdb) # Target the bundle.
(gdb) file Bundle.bundle/Contents/MacOS/Bundle
Reading symbols from […]
(gdb) # Subtract the bundle slide from the frame 0 address and then map it.
(gdb) p/x 0x107cbf99-0x107cb000
$1 = 0xf99
(gdb) info line *$1
Line 28 of "/Users/quinn/Crash Reporter/NoSymbolsTest/Bundle.m" starts at address \
0xf94 <-[Bundle testInner]+50> and ends at \
0xfa5 <-[Bundle testInner]+67>.
(gdb) # Subtract the bundle slide from the frame 1 address and then map it.
(gdb) p/x 0x107cbfcb-0x107cb000
$2 = 0xfcb
(gdb) info line *$2
Line 34 of "/Users/quinn/Crash Reporter/NoSymbolsTest/Bundle.m" starts at address \
0xfcb <-[Bundle testOuter]+36> and ends at \
0xfd1 <-[Bundle testOuter]+42>.
(gdb) quit
$ # Now do the same for the framework.
$ gdb
GNU gdb 6.3.50-20050815 (Apple version gdb-768) […]
(gdb) # Disable shared library preloading.
(gdb) set sharedlibrary preload-libraries off
(gdb) # Target the framework.
(gdb) file Framework.framework/Framework
Reading symbols from […]
(gdb) # Subtract the framework slide from the frame 2 address and then map it.
(gdb) p/x 0x10005f2e-0x0F005000
$1 = 0x1000f2e
(gdb) info line *$1
Line 39 of "/Users/quinn/Crash Reporter/NoSymbolsTest/Framework.m" starts at address \
0x1000f2e <-[Framework testInner]+308> and ends at
0x1000f35 <-[Framework testOuter]>.
(gdb) # Subtract the framework slide from the frame 3 address and then map it.
(gdb) p/x 0x10005f59-0x0F005000
$2 = 0x1000f59
(gdb) info line *$2
Line 44 of "/Users/Crash Reporter/NoSymbolsTest/Framework.m" starts at address \
0x1000f59 <-[Framework testOuter]+36> and ends at \
0x1000f5f <-[Framework testOuter]+42>.
```
默认情况下，在 GDB 中使用 file 命令设置目标文件时，GDB 会加载目标文件的所有符号，以及共享库中的符号，而共享库中的符号可能会覆盖程序中的符号，所以在设置目标文件之前，使用 set sharedlibrary preload-libraries off 命令取消加载共享库中的符号。

## CrashReporterPrefs
CrashReporterPrefs 是 Xcode 中开发者工具的一种，用于记录崩溃日志，有三种模式：

* 基本模式（Basic），是默认模式，只会提示应用崩溃闪退。
* 开发者模式（Developer），为开发者设计，会提示更多与崩溃相关的信息。
* 服务器模式（Server），用于不必提示崩溃信息的服务器，尽管不会弹出提示信息，但崩溃信息仍然会记录在磁盘中。

CrashReporter 现在仍有一些限制，如第三方开发者是不能够访问 CrashReporter 产生的日志文件的，当然，一些第三方开发者实现了自己的日志报告机制。另外，如果在日志中加入栈信息，那么有利于一些崩溃的原因查找。

在 Mac OS X 10.5 之前，若崩溃是由调用系统方法 abort 导致的，那么 CrashReporter 不会生产崩溃信息日志，并且如果程序导致了异常，但是这个异常有其相应的处理方法，CrashReporter 仍然会生成一个崩溃日志记录。