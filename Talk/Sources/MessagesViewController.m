//
//  MessagesViewController.m
//  Talk
//
//  Created by Jeroen Kooiker on 11/9/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "MessagesViewController.h"
#import "DataManager.h"
#import "Common.h"
#import "Settings.h"
#import "MessageData.h"
#import "WebClient.h"



@interface MessagesViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedMessagesController;

//@property (nonatomic, strong) NSArray*         chatsArray;
@property (nonatomic, strong) MessageData*     message;
@property (nonatomic, strong) UIBarButtonItem* addButton;

@end


@implementation MessagesViewController

- (instancetype)init
{
    return [self initWithManagedObjectContext:[DataManager sharedManager].managedObjectContext];
}


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super init])
    {
        self.title = NSLocalizedString(@"Sms", @"Sms tab title");
        
        //        self.managedObjectContect = managedObjectContext;ma
//        self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
//                                                                       target:self
//                                                                       action:@selector(newChat:)];
        
//        self.navigationItem.rightBarButtonItem = self.addButton;
        
        self.managedObjectContext = managedObjectContext;
        
        
//        self.tableView.dataSource   = self;
//        self.tableView.delegate     = self;
    }
    
    return self;
}


//- (void)newChat:(id)sender
//{
//    NSLog(@"button pushed");
//    
////    NewSmsViewController* newSms = [[NewSmsViewController alloc] init];
////    [self.navigationController pushViewController:newSms animated:YES];
//    
//    UINavigationController* modalViewController;
//    NewSmsViewController*   viewController;
//    
//    viewController = [[NewSmsViewController alloc] init];
//    
//    modalViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
//    modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
//    
//    [AppDelegate.appDelegate.tabBarController presentViewController:modalViewController
//                                                           animated:YES
//                                                         completion:nil];
//    
//    /*
//    
//     
//     if ([Settings sharedSettings].haveAccount == YES)
//     {
//     UINavigationController* modalViewController;
//     PhoneViewController*    viewController;
//     
//     viewController = [[PhoneViewController alloc] initWithPhone:nil managedObjectContext:self.managedObjectContext];
//     
//     modalViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
//     modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
//     
//     [AppDelegate.appDelegate.tabBarController presentViewController:modalViewController
//     animated:YES
//     completion:nil];
//     }
//     
//     
//     
//     
//     viewController = [[PhoneViewController alloc] initWithPhone:phone managedObjectContext:self.managedObjectContext];
//     
//     [self.navigationController pushViewController:viewController animated:YES];
//     
//     
//     
//     BITFeedbackListViewController* controller = [[BITHockeyManager sharedHockeyManager].feedbackManager feedbackListViewController:NO];
//     [self.navigationController pushViewController:controller animated:YES];
//     break;
//     
//     */
//}


//- (void)dealloc
//{
//    [[NSNotificationCenter defaultCenter] removeObserver:self.defaultsObserver];
//    
//    [[Settings sharedSettings] removeObserver:self forKeyPath:@"sortSegment" context:nil];
//}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fetchedMessagesController = [[DataManager sharedManager] fetchResultsForEntityName:@"Message" withSortKeys:@[@"uuid"] managedObjectContext:self.managedObjectContext];
    
    self.fetchedMessagesController.delegate = self;
    
    
    
//    self.isLoading = YES;
//    [[WebClient sharedClient] retrieveMessages:^(NSError* error, id content)
//    {
//        if (error == nil)
//        {
//            self.chats = content;
//            
//            for (NSDictionary* chat in self.chats)
//            {
//                [self.chatsArray addObject:chat];
//            }
//            
//            NSLog(@"%@", self.chats);
//            [self.tableView reloadData];
//        }
//    }];
//    
//    self.isLoading = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

//- (void)viewWillDisappear:(BOOL)animated
//{
//    [super viewWillDisappear:animated];
//    
//    [[WebClient sharedClient] cancelAllRetrieveMessages];
//}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"%d", [self.fetchedMessagesController.sections[0] numberOfObjects]);
    return [self.fetchedMessagesController.sections[0] numberOfObjects];
}


-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Section header..";
}


-(NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"Section footer..";
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell;
    
    return [self messageCellForIndexPath:indexPath];
    
//    
//    
//    UITableViewCell*    cell;
//    NSString*           extern_e164 = [[self.chatsArray objectAtIndex:indexPath.row] valueForKey:@"extern_e164"];
//    NSString*           text = [[self.chatsArray objectAtIndex:indexPath.row] valueForKey:@"text"];
//    NSString*           time = [[self.chatsArray objectAtIndex:indexPath.row] valueForKey:@"datetime"];
//    
//    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
//    if (cell == nil)
//    {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
//    }
//    
//    cell.textLabel.text         = extern_e164;
//    cell.detailTextLabel.text   = text;
//    cell.accessoryType          = UITableViewCellAccessoryNone;
//    
//    
//    NSLog(@"--- --- --- --- message --- --- --- ---");
//    NSLog(@"%@ - %@ - %@", extern_e164, text, time);
//    
//    return cell;
}


-(UITableViewCell*)messageCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
    }
    
    MessageData* message = [self.fetchedMessagesController objectAtIndexPath:indexPath];
    cell.textLabel.text = [message text];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selected row %ld section %ld", (long)indexPath.row, (long)indexPath.section);
}


@end
