//
//  SMSViewController.m
//  Talk
//
//  Created by Jeroen Kooiker on 11/9/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "SMSViewController.h"

@interface SMSViewController ()

@end

@implementation SMSViewController

- (instancetype)init
{
    if (self = [super initWithNibName:@"SearchTableView" bundle:nil])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
        self.title = NSLocalizedString(@"SMS", @"SMS tab title");
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
