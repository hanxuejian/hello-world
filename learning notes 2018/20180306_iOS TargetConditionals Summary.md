# 编译目标配置文件
在苹果提供的 SDK 中的 usr/include/TargetConditionals.h 文件中会自动配置编译器所要编译的代码将要使用的微处理器指令集、运行系统以及运行时环境。

TargetConditionals.h 适用于所有的编译器，但是它只能被运行于 Mac OS X 系统上的编译器所识别。

## CPU
在该文件中，`TARGET_CPU_*` 表示微处理器指令集，编译器在编译代码时，只能指定生成一个指令集，所以对于下面的宏变量，编译时，只能有一个值为 1 。

|宏|含义|
|---|---|
|`TARGET_CPU_PPC`|编译器会生成用于 32 bits 的 PowerPC 的指令集|
|`TARGET_CPU_PPC64`|编译器会生成用于 64 bits 的 PowerPC 的指令集|
|`TARGET_CPU_68K`|编译器会生成用于 680x0 系列的微处理器的指令集|
|`TARGET_CPU_X86`|编译器会生成用于 x86 系列的微处理器的指令集|
|`TARGET_CPU_ARM`|编译器会生成用于 ARM 微处理器的指令集|
|`TARGET_CPU_MIPS`|编译器会生成用于 MIPS 微处理器的指令集|
|`TARGET_CPU_SPARC`|编译器会生成用于 SPARC 微处理器的指令集|
|`TARGET_CPU_ALPHA`|编译器会生成用于 Dec Alpha 微处理器的指令集|

1. **PowerPC／PPC**（Performance Optimization With Enhanced RISC – Performance Computing）是一种精简指令集（RISC）架构的中央处理器（CPU），其基本的设计源自Apple（苹果电脑）、IBM（国际商用机器公司）、Motorola（摩托罗拉）组成的 AIM 联盟所发展出的微处理器架构 POWER（Performance Optimized With Enhanced RISC，增强RISC性能优化）。

1. **680x0** 系列的微处理器是 Motorola 公司生产的拥有复杂指令集（CISC）结构的处理器。

1. **x86** 是 Intel 推出的一种 CISC 处理器，广泛用于个人 PC 领域。

1. **ARM**（Advanced RISC Machine）处理器是英国 Acorn 公司设计的低功耗成本的第一款 RISC 微处理器。

1. **MIPS**（Microprocessor without interlocked piped stages，无内部互锁流水级的微处理器）最早是由斯坦福大学研究出来的，也是最早的商用 RISC 架构芯片之一。

1. **SPARC**（Scalable Processor ARChitecture，可扩充处理器架构)，是 RISC 微处理器架构之一。

1. **DEC Alpha**（也称为 Alpha AXP）是 64 位的 RISC 微处理器，最初由 DEC 公司制造，并被用于 DEC 自己的工作站和服务器中。

> 精简指令集（RISC，Reduced Instruction Set Computing）、复杂指令集（CISC，Complex Instruction Set Computing）是计算机中央处理器的一种设计模式。它们之间的不同之处就在于 RISC 指令集的指令数目少，而且每条指令采用相同的字节长度，一般长度为4个字节，并且在字边界上对齐，字段位置固定，特别是操作码的位置。而 CISC 指令集特点就是指令数目多而且复杂，每条指令的长度也不相等。在操作上，RISC 指令集中大多数操作都是寄存器到寄存器之间的操作，只以简单的 Load（读取）和 Sotre（存储）操作访问内存地址。

## OS
在该文件中，`TARGET_OS_*` 表示生成的代码将运行在哪个操作系统上。

1. **`TARGET_OS_WIN32`** 表示 32 位的 windows 系统

2. **`TARGET_OS_UNIX`** 表示非 OS X 系统的类 UNIX 系统

3. **`TARGET_OS_MAC`** 表示 Mac OS X 系统及其变种
	
	1）**`TARGET_OS_OSX`** 表示代码将运行在 OS X 系统设备上
	
	2）**`TARGET_OS_IPHONE`** 表示代码运行在非 OS X 系统设备上
		
	* **`TARGET_OS_IOS`** 表示代码将运行在 iOS 系统上
	* **`TARGET_OS_TV`** 表示代码将运行在 Apple TV OS 系统上
	* **`TARGET_OS_WATCH`** 表示代码将运行在 Apple Watch OS 系统上
		* **`TARGET_OS_BRIDGE`** 表示代码将运行在桥接设备上
		
	3）**`TARGET_OS_SIMULATOR`** 表示代码将运行在模拟器上
	
	4）**`TARGET_OS_EMBEDDED`** 表示代码将运行在固件上

4. **`TARGET_IPHONE_SIMULATOR`** 同 `TARGET_OS_SIMULATOR` 但是已经废弃
5. **`TARGET_OS_NANO`** 同 `TARGET_OS_WATCH` 但是已经废弃

由此可见，`TARGET_OS_WIN32`/`TARGET_OS_UNIX`/`TARGET_OS_MAC` 中只能有一个有效，
而 `TARGET_OS_IOS`/`TARGET_OS_TV`/`TARGET_OS_WATCH` 中也只能有一个生效。

## RT
在该文件中，`TARGET_RT_*` 表示生成的代码将运行在何种运行时环境上（CPU 及 OS 可能支持多种运行时环境）。

1. **`TARGET_RT_LITTLE_ENDIAN`** 表示整数遵循低地址编址存储
2. **`TARGET_RT_BIG_ENDIAN `** 表示整数遵循高地址编址存储
3. **`TARGET_RT_64_BIT`** 表示使用 64 bits 存储指针
4. **`TARGET_RT_MAC_CFM`** `TARGET_OS_MAC` 为真且使用了 CFM68K 或 PowerPC CFM (TVectors)
5. **`TARGET_RT_MAC_MACHO`** `TARGET_OS_MAC` 为真且使用  Mach-O/dlyd 运行时

> Little-endian：将低序字节存储在起始地址（低位编址）

> Big-endian：将高序字节存储在起始地址（高位编址）

## 文件
文件 TargetConditionals.h 中会根据条件指定上述的宏，其整体的判断条件如下：

```
#if defined(__GNUC__) && ( defined(__APPLE_CPP__) || defined(__APPLE_CC__) || defined(__MACOS_CLASSIC__) )

	//当前 Mac OS X 系统上运行的是基于 gcc 的编译器时，进行的宏变量定义

#elif defined(__MWERKS__)

	//当前编译器是来自 Metrowerks/Motorola 的 CodeWarrior 时，进行宏变量定义

#else

	//无法识别当前编译器，进行的宏定义

#endif
```
这里用来进行判断的诸如 `__GNUC__` 、`__APPLE_CPP__ ` 、`__APPLE_CC__` 、`__MACOS_CLASSIC__` 、`__x86_64__`、 `__arm64__` 等宏，都是当前系统处理器或编译器预定义的，使用命令 **`cpp -dM /dev/null`** 可以查看预定义宏变量列表。