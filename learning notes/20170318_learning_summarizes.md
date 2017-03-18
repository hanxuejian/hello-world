iOS技术小结
-----
1. #### 在iOS中，OC的方法签名是什么?
在iOS中，OC的方法签名包含因素有

	* 方法类型：（类方法（+）、实例方法（-））
	* 方法名称
	* 参数个数有关
	
	而与方法的**返回值**、**参数类型**无关。

2. #### A类和A类的实例对象，监听一个相同名称的通知，两者会相互影响么?
两者不会相互影响，推送通知时的参数指定了是类或者类的实例对象接收通知，因为在方法签名的影响因素中，方法类型是其中一个因素，所以当两个方法的**方法名称**相同，**参数个数**相同，**方法类型**不同时，那么这两个方法是不同方法。

3. #### 静态变量声明在方法的内部和外部有什么区别？
	* 当静态变量声明在方法内部，则所有调用该方法的对象共享该变量； 
	* 当静态变量声明在方法外部，则整个类共享该变量；

4. #### .h文件中和.m文件中的类扩展中能有相同的属性名称或变量名称么？ 
两个文件中相同的类扩展不能有同名的变量，可以有相同名称的属性，但是该属性在.h文件中必须是只读的，而在.m文件中必须是可读可写的。

5. #### 在不同线程注册通知，推送通知时，接收到通知的对象的方法是在哪个线程执行的？ 
	* 子线程注册监听方法，主线程推送通知，主线程执行了方法
	* 子线程注册监听方法，子线程推送通知，推送通知的子线程执行了方法
	* 主线程注册监听方法，子线程推送通知，子线程执行了方法
	* 主线程注册监听方法，主线程推送通知，主线程执行了方法

	可知，在哪个线程推送的通知，监听到该通知的对象的方法就在哪个线程执行，并且当一个对象注册了多少次相同的通知时，其不会覆盖，推送一次通知时，注册的方法就会执行多少次。

6. #### 块代码的声明和定义的格式有什么区别？ 
	* 当声明block代码时，必须有变量名，此时符号^必须在括号内且在block返回类型之后，而变量名在符号^之后或者在声明语句的最后，声明时，返回类型不可省略，参数可为空，但参数的括号不能省略； 
	* 当定义block代码时，没有变量名，此时符号^必须在定义语句的开始位置，之后的返回值类型和参数均可省略； 
	* 对于內联的block，在定义时可以直接调用
				
			NSString * a = ^ NSString *(NSString *string){
				return string;
			}(@"hello world");
			
7. #### UIView实例对象在调用drawRect:方法之前，会先判断其属性frame的值，只有在frame的宽高不为零时才执行，且不应该在该方法中修改该实例对象的frame和bounds属性值

8. #### 对于同一个设备，iOS系统会根据bundleID以区分不同的应用

9. #### 一个按钮绑定多个事件时，当点击按钮时，事件的执行的顺序如何确定？
	* 用代码添加的点击事件，按方法的添加顺序进行响应
	* 在XIB文件中连线添加点击事件时，比较方法的签名（比较时包含 ‘ **:** ’），按其结果从小到大进行响应
	* 对于一个方法可以绑定到多个按钮，但是，多次绑定到同一个按钮时，会覆盖上一次的绑定（包含XIB中的连线绑定），并且其执行顺序也会改变

	测试代码如下：
			
			- (instancetype)init{
    			self = [super init];
    			if (self) {
    		   		self = [[[NSBundle mainBundle]loadNibNamed:@"TestView" owner:nil options:nil]lastObject];
    			}
    
    			[self.button addTarget:self action:@selector(btnClicked2:) forControlEvents:(UIControlEventTouchUpInside)];
    
    			[self.button addTarget:self action:@selector(btnClicked1:) forControlEvents:(UIControlEventTouchUpInside)];
    
    			[self.button addTarget:self action:@selector(btnClicked2:) forControlEvents:(UIControlEventTouchUpInside)];
    
    			return self;
			}
						
			- (IBAction)btnClicked3:(id)sender{
			    NSLog(@"%s",__FUNCTION__);
			}
			
			- (IBAction)btnClicked4:(id)sender{
			    NSLog(@"%s",__FUNCTION__);
			}
			- (IBAction)btnClicked2:(id)sender{
			    NSLog(@"%s",__FUNCTION__);
			}
			- (IBAction)btnClicked1:(id)sender{
			    NSLog(@"%s",__FUNCTION__);
			}
			
			- (IBAction)abtnClicked3:(id)sender{
			    NSLog(@"%s",__FUNCTION__);
			}
			
			- (IBAction)btnClicked0:(id)sender{
			    NSLog(@"%s",__FUNCTION__);
			}
			
			-(IBAction)btnClicked33:(id)sender{
			    NSLog(@"%s",__FUNCTION__);
			}
			-(IBAction)btnClicked33333333:(id)sender{
			    NSLog(@"%s",__FUNCTION__);
			}
			-(IBAction)bbtnClicked4:(id)sender{
			    NSLog(@"%s",__FUNCTION__);
			}
			-(IBAction)bbtnClickedb:(id)sender{
			    NSLog(@"%s",__FUNCTION__);
			}
			
			-(IBAction)bbtnClickedbb:(id)sender{
			    NSLog(@"%s",__FUNCTION__);
			}
			-(IBAction)bbtnClickedbbbbb:(id)sender{
			    NSLog(@"%s",__FUNCTION__);
			}
			-(IBAction)bbtnClicked123bb:(id)sender{
			    NSLog(@"%s",__FUNCTION__);
			}
			-(IBAction)bbtnClicked1245bbbbb:(id)sender{
			    NSLog(@"%s",__FUNCTION__);
			}
			
			-(IBAction)bbtnClicked123bbbbbb:(id)sender{
			    NSLog(@"%s",__FUNCTION__);
			}
			-(IBAction)bbtnClicked1235bbbbb:(id)sender{
			    NSLog(@"%s",__FUNCTION__);
			}

	测试结果如下：

		2017-03-19 00:20:51.182 MyfirstIOSAPP[2334:165227] -[TestView abtnClicked3:]
		2017-03-19 00:20:51.183 MyfirstIOSAPP[2334:165227] -[TestView bbtnClicked1235bbbbb:]
		2017-03-19 00:20:51.183 MyfirstIOSAPP[2334:165227] -[TestView bbtnClicked123bb:]
		2017-03-19 00:20:51.184 MyfirstIOSAPP[2334:165227] -[TestView bbtnClicked123bbbbbb:]
		2017-03-19 00:20:51.184 MyfirstIOSAPP[2334:165227] -[TestView bbtnClicked1245bbbbb:]
		2017-03-19 00:20:51.184 MyfirstIOSAPP[2334:165227] -[TestView bbtnClicked4:]
		2017-03-19 00:20:51.184 MyfirstIOSAPP[2334:165227] -[TestView bbtnClickedb:]
		2017-03-19 00:20:51.185 MyfirstIOSAPP[2334:165227] -[TestView bbtnClickedbb:]
		2017-03-19 00:20:51.185 MyfirstIOSAPP[2334:165227] -[TestView bbtnClickedbbbbb:]
		2017-03-19 00:20:51.185 MyfirstIOSAPP[2334:165227] -[TestView btnClicked0:]
		2017-03-19 00:20:51.185 MyfirstIOSAPP[2334:165227] -[TestView btnClicked33333333:]
		2017-03-19 00:20:51.186 MyfirstIOSAPP[2334:165227] -[TestView btnClicked33:]
		2017-03-19 00:20:51.186 MyfirstIOSAPP[2334:165227] -[TestView btnClicked3:]
		2017-03-19 00:20:51.186 MyfirstIOSAPP[2334:165227] -[TestView btnClicked4:]
		2017-03-19 00:20:51.187 MyfirstIOSAPP[2334:165227] -[TestView btnClicked1:]
		2017-03-19 00:20:51.189 MyfirstIOSAPP[2334:165227] -[TestView btnClicked2:]
