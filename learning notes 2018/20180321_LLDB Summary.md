# LLDB 小结
## 简介
LLDB 是新一代高性能调试器，其是一组可重用组件的集合，这些组件大多是 LLVM 工程中的类库，如 Clang 表达式解析器或 LLVM 反汇编程序等。LLDB 是 Xcode 中默认的调试器，并且支持调试 C／C++ 程序。

## LLDB 命令
LLDB 的命令格式不同于 GDB 的命令格式的随意，而是统一为如下格式：

**`<命令名称> <命令动作> [-可选项 [可选项的值]] [参数1 [参数2···]]`**

需要注意的是，不管是命令名称、命令动作、可选项还是参数，它们都是由空格分隔的，所以如果，参数本身包含由空格符号，那么，使用双引号来包裹参数，如果，参数中包含有反斜杠或双引号，那么使用反斜杠对它们进行转义。

多个可选项在命令行中的顺序并不是固定的，但是如果可选项后的参数是以 `-` 开始的，那么需要使用 `--` 标记可选项的结束，如下面的命令：

```
(lldb) process launch --stop-at-entry -- -program_arg_1 value -program_arg_2 value

//可选项顺序可以不固定
(lldb) breakpoint set -l 34 -f UIView+Theme.m
(lldb) breakpoint set -f UIView+Theme.m -l 35
```

### 开启调试
打开命令行，使用如下命令：

```
Martin-mini:Applications hanxuejian$ lldb zoom.us.app/
(lldb) target create "zoom.us.app/"
Current executable set to 'zoom.us.app/' (i386).
```
或者

```
Martin-mini:Applications hanxuejian$ lldb
(lldb) file zoom.us.app/
Current executable set to 'zoom.us.app/' (i386).
(lldb) quit
Martin-mini:Applications hanxuejian$ 
```
或者使用 Xcode 进入调试模式。

### 结束调试

```
(lldb) quit
```

### 设置命令别名
对于常用的命令，可以设置别名，使其简单化，如：

```
(lldb) breakpoint set --file foo.c --line 12

(lldb) command alias bfl breakpoint set -f %1 -l %2 
(lldb) bfl foo.c 12
```

### 取消命令的别名

```
(lldb) command unalias b
(lldb) command alias b breakpoint
```

### 设置断点
1. 指定文件及代码行

	```
	(lldb) breakpoint set --file foo.c --line 12 
	(lldb) breakpoint set -f foo.c -l 12
	```

2. 指定函数名称

	```
	(lldb) breakpoint set --name foo 
	(lldb) breakpoint set -n foo
	(lldb) breakpoint set --name foo --name bar
	```

3. 指定方法名称

	```
	(lldb) breakpoint set --method foo 
	(lldb) breakpoint set -M foo
	```

4. 指定 OC 选择器

	```
	(lldb) breakpoint set --selector alignLeftEdges: 
	(lldb) breakpoint set -S alignLeftEdges:
	```

5. 指定映像文件

	```
	(lldb) breakpoint set --shlib foo.dylib --name foo 
	(lldb) breakpoint set -s foo.dylib -n foo
	
	//--shlib 可以重复使用
	(lldb) breakpoint set --shlib foo.dylib --name foo --shlib foo1.dylib --name foo1
	```

### 编辑断点
1. 查看设置的断点

	```
	(lldb) breakpoint list
	```

	如下面的例子：

	```
	(lldb) breakpoint set -M load
	Breakpoint 12: 25 locations.
	(lldb) breakpoint list
	Current breakpoints:
	12: name = 'load', locations = 25, resolved = 25, hit count = 0
	  12.1: where = MobileCoreServices`_LSPreferences::load(), address = 0x00000001072bc684, resolved, hit count = 0 
	  12.2: where = libicucore.A.dylib`icu::CollationRoot::load(UErrorCode&), address = 0x00000001074eef18, resolved, hit count = 0 
	  12.3: where = libicucore.A.dylib`icu::VTimeZone::load(icu::VTZReader&, UErrorCode&), address = 0x00000001075c2b34, resolved, hit count = 0 
	  12.4: where = WebCore`WebCore::CachedFont::load(WebCore::CachedResourceLoader&, WebCore::ResourceLoaderOptions const&), address = 0x000000010aa16a20, resolved, hit count = 0 
	  12.5: where = WebCore`WebCore::CachedImage::load(WebCore::CachedResourceLoader&, WebCore::ResourceLoaderOptions const&), address = 0x000000010aa18170, resolved, hit count = 0 
	  12.6: where = WebCore`WebCore::CachedResource::load(WebCore::CachedResourceLoader&, WebCore::ResourceLoaderOptions const&), address = 0x000000010aa1dc40, resolved, hit count = 0 
	  12.7: where = WebCore`WebCore::CachedSVGDocumentReference::load(WebCore::CachedResourceLoader&, WebCore::ResourceLoaderOptions const&), address = 0x000000010aa2ad20, resolved, hit count = 0 
	  12.8: where = WebCore`WebCore::CSSFontFace::load(), address = 0x000000010aafab20, resolved, hit count = 0 
	  12.9: where = WebCore`WebCore::CSSFontFaceSource::load(WebCore::CSSFontSelector&), address = 0x000000010ab028a0, resolved, hit count = 0 
	  12.10: where = WebCore`WebCore::FontFace::load(), address = 0x000000010ad5a2a0, resolved, hit count = 0 
	  12.11: where = WebCore`WebCore::FontFaceSet::load(WTF::String const&, WTF::String const&, WebCore::DOMPromise<WTF::Vector<WTF::RefPtr<WebCore::FontFace>, 0ul, WTF::CrashOnOverflow, 16ul> >&&), address = 0x000000010ad5ad60, resolved, hit count = 0 
	  12.12: where = WebCore`WebCore::FrameLoader::load(WebCore::DocumentLoader*), address = 0x000000010ad9fc70, resolved, hit count = 0 
	  12.13: where = WebCore`WebCore::HRTFDatabaseLoader::load(), address = 0x000000010ae22e20, resolved, hit count = 0 
	  12.14: where = WebCore`WebCore::HTMLMediaElement::load(), address = 0x000000010ae7e7f0, resolved, hit count = 0 
	  12.15: where = WebCore`WebCore::JSFontFace::load(JSC::ExecState&), address = 0x000000010b1017f0, resolved, hit count = 0 
	  12.16: where = WebCore`WebCore::MediaPlayer::load(WebCore::URL const&, WebCore::ContentType const&, WTF::String const&), address = 0x000000010b3d3ad0, resolved, hit count = 0 
	  12.17: where = WebCore`WebCore::NullMediaPlayerPrivate::load(WTF::String const&), address = 0x000000010b3d6820, resolved, hit count = 0 
	  12.18: where = WebCore`WebCore::MediaPlayerPrivateAVFoundation::load(WTF::String const&), address = 0x000000010b3d7880, resolved, hit count = 0 
	  12.19: where = WebCore`WebCore::TextTrackLoader::load(WebCore::URL const&, WTF::String const&, bool), address = 0x000000010b8d89d0, resolved, hit count = 0 
	  12.20: where = WebCore`WebCore::FrameLoader::load(WebCore::FrameLoadRequest const&), address = 0x000000010ada2570, resolved, hit count = 0 
	  12.21: where = NLP`NL::SpotlightQueryConverter::load(NLSearchAppContext), address = 0x000000010fc3a4ca, resolved, hit count = 0 
	  12.22: where = NLP`NL::SearchDateDisplayFormatter::load(), address = 0x000000010fc7c354, resolved, hit count = 0 
	  12.23: where = libmarisa.dylib`marisa::Trie::load(char const*), address = 0x000000010fda4618, resolved, hit count = 0 
	  12.24: where = JavaScriptCore`JSC::DFG::ByteCodeParser::load(unsigned int, unsigned int, JSC::DFG::GetByOffsetMethod const&, JSC::DFG::NodeType), address = 0x0000000110184900, resolved, hit count = 0 
	  12.25: where = JavaScriptCore`JSC::DFG::ByteCodeParser::load(unsigned int, JSC::ObjectPropertyConditionSet const&, JSC::DFG::NodeType), address = 0x0000000110184ad0, resolved, hit count = 0 
	
	(lldb)
	```
	
	在使用命令设置断点时，符合条件的断点可能不止一个，并且，如果新加载文件后，符合条件的断点可能还会增加。当然，设置不存在的断点，断点信息也可以查看得到，但是其 locations 为 0 。

	```
	(lldb) breakpoint set --file test.m --line 100
	Breakpoint 13: no locations (pending).
	WARNING:  Unable to resolve breakpoint to any actual locations.
	(lldb) breakpoint list
	Current breakpoints:
	13: file = 'test.m', line = 100, exact_match = 0, locations = 0 (pending)
	```

1. 将断点置为不可用

	```
	(lldb) breakpoint disable 1
	1 breakpoints disabled.
	```

1. 将断点置为可用

	```
	(lldb) breakpoint enable 1
	1 breakpoints enabled.
	```

2. 删除断点

	```
	(lldb) breakpoint delete 1
	1 breakpoints deleted; 0 breakpoint locations disabled.
	```

2. 为断点添加命令或脚本

	```
	(lldb) breakpoint command add
	Enter your debugger command(s).  Type 'DONE' to end.
	> bt
	> DONE
	(lldb) breakpoint command list 2
	Breakpoint 2:
	    Breakpoint commands:
	      bt
	(lldb) 
	```

	从下面的错误命令可知断点所支持的语言：

	```
	(lldb) breakpoint command add -s OC
	error: invalid enumeration value, valid values are: "command", "python", "default-script"
	```

### 观察变量
1. 设置观察变量

	```
	(lldb) watchpoint set variable backgroundColor
	Watchpoint created: Watchpoint 2: addr = 0x7fff52dcdb38 size = 8 state = enabled type = w
	    declare @ '/Users/hanxuejian/Downloads/ThemeChange-master/TestTheme/TestTheme/UIView+Theme.m:31'
	    watchpoint spec = 'backgroundColor'
	    new value: 0x000061000007e780
	```

2. 查看观察变量

	```
	(lldb) watchpoint list
	Number of supported hardware watchpoints: 4
	Current watchpoints:
	Watchpoint 1: addr = 0x7fff52dcd6d8 size = 8 state = disabled type = w
	    declare @ '/Users/hanxuejian/Downloads/ThemeChange-master/TestTheme/TestTheme/UIView+Theme.m:31'
	    watchpoint spec = 'backgroundColor'
	    old value: 0xffff8067ddcff720
	    new value: 0xffff8067ddcff720
	Watchpoint 2: addr = 0x7fff52dcdb38 size = 8 state = enabled type = w
	    declare @ '/Users/hanxuejian/Downloads/ThemeChange-master/TestTheme/TestTheme/UIView+Theme.m:31'
	    watchpoint spec = 'backgroundColor'
	    new value: 0x000061000007e780
	```

3. 设置查看条件

	```
	(lldb) watchpoint set variable num
	Watchpoint created: Watchpoint 1: addr = 0x10f932558 size = 4 state = enabled type = w
	    declare @ '/Users/hanxuejian/Downloads/ThemeChange-master/TestTheme/TestTheme/UIView+Theme.m:31'
	    watchpoint spec = 'num'
	    new value: 16
	
	//添加条件
	(lldb) watchpoint modify -c "(num == 25)"
	(lldb) watchpoint list
	Number of supported hardware watchpoints: 4
	Current watchpoints:
	Watchpoint 1: addr = 0x10f932558 size = 4 state = enabled type = w
	    declare @ '/Users/hanxuejian/Downloads/ThemeChange-master/TestTheme/TestTheme/UIView+Theme.m:31'
	    watchpoint spec = 'num'
	    old value: 20
	    new value: 21
	    condition = '(num == 25)'
	
	//条件达成
	2018-03-21 19:11:44.302 TestTheme[6938:828079] XPC connection interrupted
	
	Watchpoint 1 hit:
	old value: 21
	new value: 25
	```

### 开始程序
使用 LLDB 调试程序，可以直接加载可执行程序，或者绑定已经在执行的程序，而后开始进行调试。

如下面的例子，先创建一个简单 C 程序。

```
#include <stdio.h>
int main(int argc, char const *argv[])
{ 
	int i = 1;
	while(true) {
		char *c = "this is a test";
		printf("%s %i\n", c,i++);	
	}
	return 0;
}
```
编辑后，保存为 test.cpp 文件，然后在命令行中执行下面的命令：

```
gcc test.cpp -o test
```
得到可执行文件，而后执行下面的命令。

```
(lldb) target create test
Current executable set to 'test' (x86_64).
(lldb) process launch test
Process 7169 launched: '/Users/hanxuejian/Desktop/Temp/test' (x86_64)
this is a test 1
this is a test 2
this is a test 3
this is a test 4
```
当然，也可以先运行 test 可执行文件，而后使用下面的命令进行调试绑定。

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2018/pic-20180321-01.png)

```
(lldb) process attach --pid 7232 
(lldb) process attach --name test 
(lldb) process attach --name test --waitfor
```
但是要注意的是，如果存在两个名称相同的进程，那么绑定是无法成功的。

![](https://github.com/hanxuejian/hello-world/raw/master/pictures/2018/pic-20180321-02.png)

### 线程控制
在加载进程开始调试后，当执行到设置断点时，可以使用 thread 命令控制代码的执行。

1. 线程继续执行

	```
	(lldb) thread continue 
	Resuming thread 0x2c03 in process 46915 
	Resuming process 46915 
	(lldb)
	```

2. 线程进入、单步执行或跳出

	```
	(lldb) thread step-in    
	(lldb) thread step-over  
	(lldb) thread step-out
	```

3. 单步指令的执行

	```
	(lldb) thread step-inst  
	(lldb) thread step-over-ins
	```

4. 执行指定代码行数直到退出当前帧

	```
	(lldb) thread until 100
	```

5. 查看线程列表，第一个线程为当前执行线程

	```
	(lldb) thread list
	Process 46915 state is Stopped
	* thread #1: tid = 0x2c03, 0x00007fff85cac76a, where = libSystem.B.dylib`__getdirentries64 + 10, stop reason = signal = SIGSTOP, queue = com.apple.main-thread
	  thread #2: tid = 0x2e03, 0x0000
	```

6. 查看当前线程栈

	```
	(lldb) thread backtrace
	thread #1: tid = 0x2c03, stop reason = breakpoint 1.1, queue = com.apple.main-thread
	 frame #0: 0x0000000100010d5b, where = Sketch`-[SKTGraphicView alignLeftEdges:] + 33 at /Projects/Sketch/SKTGraphicView.m:1405
	 frame #1: 0x00007fff8602d152, where = AppKit`-[NSApplication sendAction:to:from:] + 95
	 frame #2: 0

	//查看所有线程的调用栈
	(lldb) thread backtrace all
	```

7. 设置当前线程

	```
	(lldb) thread select 2
	```

