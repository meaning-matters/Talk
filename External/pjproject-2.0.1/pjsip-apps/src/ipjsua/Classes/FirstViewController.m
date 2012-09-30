#import "FirstViewController.h"
#import "ipjsuaAppDelegate.h"


@implementation FirstViewController
@synthesize textField;
@synthesize textView;
@synthesize text;
@synthesize hasInput;


- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
    if ([textField.text length] == 0)
    {
        
    }
    else
    {
        self.hasInput = true;
        self.text = [textField.text stringByAppendingString:@"\n"];
        textField.text = @"";
    }
    
    return YES;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ipjsuaAppDelegate *appd = (ipjsuaAppDelegate *)[[UIApplication sharedApplication] delegate];
    appd.mainView = self;
    textField.delegate = self;    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)dealloc
{
    [super dealloc];
}

@end
