//
//  ViewController.m
//  Test-CoreData
//
//  Created by han on 2017/5/31.
//  Copyright © 2017年 han. All rights reserved.
//

#import "ViewController.h"
#import "SACoreDataManager.h"
#import "Student.h"

@interface ViewController () <NSFetchedResultsControllerDelegate,UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) NSFetchedResultsController *fetchedController;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) SACoreDataManager *coredataManager;

@end

@implementation ViewController

#pragma mark - view cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
    [self initData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - inside
- (void)initView {
    CGRect rect = self.view.bounds;
    rect.size.height = 600;
    self.tableView = [[UITableView alloc]initWithFrame:rect];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)initData {
    self.coredataManager = [SACoreDataManager sharedCoreDataManager];
    NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:@"Student"];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]initWithKey:@"name" ascending:YES];
    request.sortDescriptors = @[sort];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name like '小明 *'"];
    request.predicate = predicate;
    self.fetchedController = [[NSFetchedResultsController alloc]initWithFetchRequest:request
                                                                managedObjectContext:[SACoreDataManager sharedContext]
                                                                  sectionNameKeyPath:nil
                                                                           cacheName:nil];
    [self.fetchedController performFetch:nil];
    self.fetchedController.delegate = self;
    
}

- (IBAction)addData {
    NSFetchRequest *quest = [[NSFetchRequest alloc]initWithEntityName:@"Student"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"1=1"];
    quest.predicate = predicate;
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"classNumber" ascending:NO];
    quest.sortDescriptors = @[sort];
    quest.fetchLimit = 1;
    NSError *error;
    NSArray *arr = [[SACoreDataManager sharedContext] executeFetchRequest:quest error:&error];
    int index = 1;
    if (arr.count != 0) {
        index = [[arr[0]classNumber]intValue];
        index ++ ;
    }
    Student *stu = [self.coredataManager insertObjectForEntityName:@"Student"];
    stu.name = [NSString stringWithFormat:@"小明 %i",index];
    stu.age = @(10);
    stu.sex = true;
    stu.grade = @(2);
    stu.classNumber = @(index);
    [self.coredataManager saveChanges];    
}

#pragma mark - UITableViewDelegate,UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.fetchedController.sections[0]numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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

@end
