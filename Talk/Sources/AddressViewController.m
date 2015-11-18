//
//  AddressViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 16/11/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import "AddressViewController.h"
#import "Strings.h"


@interface AddressViewController ()

@property (nonatomic, assign) BOOL isNew;

@end


@implementation AddressViewController

- (instancetype)initWithAddress:(AddressData*)address
           managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super initWithManagedObjectContext:managedObjectContext])
    {
        self.isNew                = (address == nil);
        self.address              = address;
        self.managedObjectContext = managedObjectContext;
        self.title                = self.isNew ? [Strings newAddressString] : [Strings addressesString];
        
        self.name                 = address.isoCountryCode;
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}

@end
