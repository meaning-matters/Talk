#import <UIKit/UIKit.h>

@interface FirstViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, retain) IBOutlet UITextField *textField;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) NSString *text;
@property (nonatomic) bool hasInput;

@end
