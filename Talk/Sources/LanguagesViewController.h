//
//  LanguagesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 23/04/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LanguagesViewController : UITableViewController

- (instancetype)initWithLanguageCodes:(NSArray*)languageCodes
                         languageCode:(NSString*)languageCode
                           completion:(void (^)(NSString* languageCode))completion;

@end
