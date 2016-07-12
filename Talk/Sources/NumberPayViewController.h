//
//  NumberPayViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 09/07/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumberType.h"
#import "AddressData.h"


@interface NumberPayViewController : UITableViewController

- (instancetype)initWithMonthFee:(float)monthFee
                      oneTimeFee:(float)oneTimeFee
                     isExtension:(BOOL)isExtension
                            name:(NSString*)name
                  numberTypeMask:(NumberTypeMask)numberTypeMask
                  isoCountryCode:(NSString*)isoCountryCode
                            area:(NSDictionary*)area
                        areaCode:(NSString*)areaCode
                        areaName:(NSString*)areaName
                           state:(NSDictionary*)state
                         areadId:(NSString*)areaId
                         address:(AddressData*)address;

@end
