//
//  Common.h
//  Talk
//
//  Created by Cornelis van der Bent on 30/09/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"


// http://stackoverflow.com/questions/3172794/scope-bar-for-uitableview-like-app-store
#define UndocumentedSearchScopeBarSegmentedControlStyle 7

#define CFReleaseSafe(x)                                { if ((x) != NULL) CFRelease(x); }


static const int TextFieldCellTag = 1111;


@interface Common : NSObject <MFMailComposeViewControllerDelegate>

+ (NSURL*)documentsDirectoryUrl;

+ (NSURL*)documentUrl:(NSString*)name;

+ (NSURL*)audioDirectoryUrl;

+ (NSURL*)audioUrlForFileName:(NSString*)fileName;

+ (NSData*)dataForResource:(NSString*)resourse ofType:(NSString*)type;

+ (NSString*)bundleVersion;

+ (NSString*)bundleName;

+ (NSString*)appStoreUrlString;

+ (void)openAppStoreReviewPage;

+ (void)addCompanyToAddressBook:(ABAddressBookRef)addressBook;

+ (UIViewController*)topViewController; // View controller from which to present a modal.

+ (NSData*)jsonDataWithObject:(id)object;

+ (NSString*)jsonStringWithObject:(id)object;

+ (id)objectWithJsonData:(NSData*)data;

+ (id)objectWithJsonString:(NSString*)string;

+ (id)mutableObjectWithJsonData:(NSData*)data;

+ (id)mutableObjectWithJsonString:(NSString*)string;

+ (BOOL)object:(id)object isEqualToJsonString:(NSString*)string;

+ (NSError*)errorWithCode:(NSInteger)code description:(NSString*)description;

+ (BOOL)deviceHasReceiver;

+ (NSString*)deviceModel;

+ (NSString*)deviceOs;

+ (void)setCornerRadius:(CGFloat)radius ofView:(UIView*)view;

+ (void)setBorderWidth:(CGFloat)width ofView:(UIView*)view;

+ (void)setBorderColor:(UIColor*)color ofView:(UIView*)view;

+ (void)setX:(CGFloat)x ofView:(UIView*)view;

+ (void)setY:(CGFloat)y ofView:(UIView*)view;

+ (void)setWidth:(CGFloat)width ofView:(UIView*)view;

+ (void)setHeight:(CGFloat)height ofView:(UIView*)view;

+ (void)addShadowToView:(UIView*)view;  // Adds a small shadow; used for texts.

// Must be custom button style.
+ (void)styleButton:(UIButton*)button withColor:(UIColor*)color highlightTextColor:(UIColor*)highlightTextColor;

// Must be custom button style.
+ (void)styleButton:(UIButton*)button;

+ (UIFont*)phoneFontOfSize:(CGFloat)size;

+ (NSString*)stringWithOsStatus:(OSStatus)status;

+ (BOOL)checkRemoteNotifications;

+ (BOOL)checkSendingEmail;

+ (void)sendEmailTo:(NSString*)emailAddress
            subject:(NSString*)subject
               body:(NSString*)body
         completion:(void (^)(BOOL success))completion;

+ (BOOL)checkSendingTextMessage;

// Works only for non-emergency numbers.
+ (BOOL)checkCountryOfPhoneNumber:(PhoneNumber*)phoneNumber
                       completion:(void (^)(BOOL cancelled, PhoneNumber* phoneNumber))completion;

+ (void)enableNetworkActivityIndicator:(BOOL)enable;

+ (void)redirectStderrToFile;

+ (unsigned)bitsSetCount:(unsigned long)value;                          // Gives number of sections by supplying mask.

+ (unsigned long)nthBitSet:(NSUInteger)n inValue:(unsigned long)value;  // With n == 0 return first bit set.

+ (unsigned)nOfBit:(unsigned long)bit inValue:(unsigned long)value;     // Converts table section mask to section.

+ (unsigned)bitIndexOfMask:(unsigned long)mask;

+ (NSString*)capitalizedString:(NSString*)string;

+ (void)showGetStartedViewController;

+ (void)dispatchAfterInterval:(NSTimeInterval)interval onMain:(void (^)(void))block;

// Resolves an issue with NSIndexPath's isEqual: http://stackoverflow.com/a/18920573/1971013
+ (BOOL)indexPath:(NSIndexPath*)indexPathA isEqual:(NSIndexPath*)indexPathB;

+ (UIImage*)invertImage:(UIImage*)image;

+ (UIImage*)maskedImageNamed:(NSString*)name color:(UIColor*)color;

+ (UIImage *)gradientImageNamed:(NSString*)name startColor:(UIColor*)startColor endColor:(UIColor*)endColor;

+ (void)addCountryImageToCell:(UITableViewCell*)cell isoCountryCode:(NSString*)isoCountryCode;

+ (NumberLabel*)addNumberLabelToCell:(UITableViewCell*)cell;

+ (UITextField*)addTextFieldToCell:(UITableViewCell*)cell delegate:(id<UITextFieldDelegate>)delegate;

+ (void)getCostForCallbackE164:(NSString*)callbackE164
                  callthruE164:(NSString*)callthruE164
                    completion:(void (^)(NSString* costString))completion;

+ (void)aksForCallbackPhoneNumber:(PhoneNumber*)phoneNumber
                       completion:(void (^)(BOOL cancelled, PhoneNumber* phoneNumber))completion;

+ (NSString*)callingCodeForCountry:(NSString*)isoCountryCode;

+ (NSArray*)sortKeys;

+ (NSAttributedString*)strikethroughAttributedString:(NSString*)string;

+ (void)openApplicationSettings;

+ (BOOL)moveFileFromUrlString:(NSString*)destinationUrlString toUrlString:(NSString*)destinationUrlString;

+ (void)setImageNamed:(NSString*)name ofCell:(UITableViewCell*)cell;

@end
