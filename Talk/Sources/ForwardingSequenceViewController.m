//
//  ForwardingSequenceViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 30/04/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "ForwardingSequenceViewController.h"
#import "Common.h"


typedef enum
{
    TableSectionName       = 1UL << 0, // User-given name.
    TableSectionStatements = 1UL << 1,
} TableSections;


static const int    TextFieldCellTag = 1111;


@interface ForwardingSequenceViewController ()
{
    TableSections               sections;

    NSFetchedResultsController* fetchedResultsController;
    ForwardingData*             forwarding;
    NSMutableArray*             rootSequence;
    NSMutableArray*             sequence;
}

@end


@implementation ForwardingSequenceViewController

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController*)resultsController
                                      forwarding:(ForwardingData*)theForwarding
                                    rootSequence:(NSMutableArray*)theRootSequence
                                        sequence:(NSMutableArray*)theSequence
{
    fetchedResultsController = resultsController;
    forwarding               = theForwarding;
    rootSequence             = theRootSequence;
    sequence                 = theSequence;

    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"ForwardingSequenceView ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Sequence",
                                                       @"Title of app screen with details of a call forwarding\n"
                                                       @"[1 line larger font].");

        sections |= TableSectionName;
        sections |= TableSectionStatements;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common bitsSetCount:sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger   numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionName:
            numberOfRows = 1;
            break;

        case TableSectionStatements:
            numberOfRows = sequence.count;
            break;
    }

    return numberOfRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
