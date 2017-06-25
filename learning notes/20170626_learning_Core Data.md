#Core Data 学习总结

### 基本使用
使用 Core Data 基本功能时，涉及到的类

|涉及的类|描述|
|:----------:|:----------:|
|NSManagedObjectModel|对象模型|
|NSPersistentStoreCoordinator|存储协调器|
|NSPersistentStore|持久化存储文件|
|NSManagedObjectContext|上下文|
|NSEntityDescription|实体描述|
|NSManagedObject|实体对应的类|
|NSPredicate|谓词，即查询条件|
|NSFetchRequest|查询数据的描述|


使用 Core Data 时，增删改查等操作均是通过对象上下文来完成的，而构造一个对象上下文，则需要先构造存储协调器，要构造存储协调器则要先有一个对象模型，而对象模型则是由我们创建设计的 .xcdatamodeld 文件初始化得到的，得到存储协调器后，为其添加持久化存储文件。

这样，一个上下文便创建成功，可使用其进行数据的增删改查，具体步骤如下：

1. 获取模型文件路径，创建模型对象

	```
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
	NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	```

2. 根据模型对象，创建持久化存储协调器对象

	```
	NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
	```

3. 为协调器添加持久化存储文件	

	```
	NSURL *documentURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject]
	NSURL *storeURL = [documentURL URLByAppendingPathComponent:@"Model.sqlite"];
	NSPersistentStore *persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
	if(!persistentStore){
		NSLog(@"error!");
		abort();
	}
	```

4. 创建上下文，并设置协调器

	```
	NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	[managedObjectContext setPersistentStoreCoordinator: persistentStoreCoordinator];
	```

5. 使用上下文插入数据
	
	```
	Student *stu = [NSEntityDescription insertNewObjectForEntityForName:@"Student" inManagedObjectContext:managedObjectContext];
	stu.name = @"小明";
	stu.age = @(10);
	stu.sex = true;
	stu.grade = @(2);
	stu.classNumber = @(3);
	NSError *error = nil;
   [managedObjectContext save:&error];
   if(error){
   		NSLog(@"插入数据失败")；
   	}
	```

6. 使用上下文查询数据 

	```
	NSFetchRequest *request = [[NSFetchRequest alloc]init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	// 设定查询条件
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = '小明'"];
	[request setPredicate:predicate];	
	NSError *error = nil;
	NSArray *result = [managedObjectContext executeFetchRequest:request error:&error];
	if(error){
   		NSLog(@"查询数据失败")；
   	}
   ```

7. 使用上下文删除数据
	
	```
	for(Student *stu in result) {
	    [managedObjectContext deleteObject:stu];
	}
	NSError *error = nil;
   [managedObjectContext save:&error];
   if(error){
   		NSLog(@"删除数据失败")；
   	}
	```

**增删改查数据，主要是查询，因为修改或者删除，均要先将数据查询出来，主要使用了类 NSPredicate、NSEntityDescription、NSFetchRequest**

### 数据与视图相关联
Cocoa Touch 中提供了将 Core Data 中的数据与视图相关联的方法，使用 NSFetchedResultsController 类与代理 NSFetchedResultsControllerDelegate 可以方便的将数据与 UITableView 视图相关联，相关代码如下：

```
@property (nonatomic, strong) NSFetchedResultsController *fetchedController;
@property (nonatomic, strong) UITableView *tableView;

self.fetchedController = [[NSFetchedResultsController alloc]initWithFetchRequest:request
                                                            managedObjectContext: managedObjectContext
                                                              sectionNameKeyPath:nil 
                                                                       cacheName:nil];
[self.fetchedController performFetch:nil];
self.fetchedController.delegate = self;

#pragma mark - UITableViewDelegate,UITableViewDataSource
	
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
	return [self.fetchedController.sections[0]numberOfObjects];
}
	
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	static NSString *cellID = @"cell";
	Student *stu = [self.fetchedController objectAtIndexPath:indexPath];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
	if (cell == nil){
		cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	}
	cell.textLabel.text = stu.name;
	return cell;
}
	
#pragma mark - NSFetchedResultsControllerDelegate
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
	switch(type) {
		case NSFetchedResultsChangeInsert:
		    [[self tableView] insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
		    break;
		case NSFetchedResultsChangeDelete:
		    [[self tableView] deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		    break;
		case NSFetchedResultsChangeUpdate:
		    
		    break;
		case NSFetchedResultsChangeMove:
		    [[self tableView] deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		    [[self tableView] insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
		    break;
	}
}    
```
[测试代码](https://github.com/hanxuejian/hello-world/tree/master/test/Test-CoreData)

### 数据冲突处理
当 Core Data 从存储文件中获取数据室，会生成一份快照，保存数据的状态，经过修改进而保存时，其会先对比快照与本地文件中的数据，如果一致，则说明数据没有被修改过，然后再进行保存，同时快照也相应更新，如若不一致，说明存储文件中的数据被改动了，那么就需要处理冲突了。

设置 NSManagedObjectContext 的 mergePolicy 属性可以选择不同的处理方式。

`@property (strong) id mergePolicy;    // default: NSErrorMergePolicy`

|数据冲突处理策略|描述|
|:-----------:|:----:|
|NSErrorMergePolicy|返回错误（默认值）|
| NSMergeByPropertyStoreTrumpMergePolicy |合并修改的部分，冲突的部分使用存储文件中的值|
| NSMergeByPropertyObjectTrumpMergePolicy |合并修改的部分，冲突的部分使用内存中类的属性值|
| NSOverwriteMergePolicy |使用内存中的值，覆盖文件中的所有值|
| NSRollbackMergePolicy |舍弃内存中的值，使用存储文件中的值|
 
另外，我们可以注册通知 NSManagedObjectContextObjectsDidChangeNotification 、NSManagedObjectContextWillSaveNotification 、NSManagedObjectContextDidSaveNotification 监听数据的变动，当2个或多个上下文对象使用同一个存储文件协调器对象时，则其中一个上下文改变了数据，我们可以使用通知，来决定其他的上下文需要做出怎样的反应。