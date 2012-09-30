#import <UIKit/UIKit.h>
#import "FirstViewController.h"

@interface ipjsuaAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate>

@property (nonatomic, retain) IBOutlet UIWindow*            window;
@property (nonatomic, retain) IBOutlet UITabBarController*  tabBarController;
@property (nonatomic, retain) FirstViewController*          mainView;


@end
