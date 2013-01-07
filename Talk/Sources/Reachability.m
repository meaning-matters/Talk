//
//  Reachability.m
//  Talk
//
//  Created by Cornelis van der Bent on 08/11/12.
//  Copyright (c) 2011 Tony Million.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.

#import "Reachability.h"


NSString* const kReachabilityChangedNotification = @"kReachabilityChangedNotification";


@interface Reachability ()

@property (nonatomic, assign) SCNetworkReachabilityRef  reachabilityRef;
@property (nonatomic, strong) dispatch_queue_t          reachabilitySerialQueue;
@property (nonatomic, strong) id                        reachabilityObject;

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags;
- (BOOL)isReachableWithFlags:(SCNetworkReachabilityFlags)flags;

@end


static NSString* reachabilityFlags(SCNetworkReachabilityFlags flags) 
{
    return [NSString stringWithFormat:@"%c%c %c%c%c%c%c%c%c",
            (flags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W' : '-',
            (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
            (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
            (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
            (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
            (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-'];
}


// Start listening for reachability notifications on the current run loop
static void TMReachabilityCallback(SCNetworkReachabilityRef   target,
                                   SCNetworkReachabilityFlags flags,
                                   void*                      info)
{
#pragma unused (target)
    
    Reachability*   reachability = ((__bridge Reachability*)info);
    
    // We probably don't need an autoreleasepool here as GCD docs state that
    // each queue has its own autorelease pool; but what the heck eh?
    @autoreleasepool
    {
        [reachability reachabilityChanged:flags];
    }
}


@implementation Reachability

@synthesize reachabilityRef         = _reachabilityRef;
@synthesize reachabilitySerialQueue = _reachabilitySerialQueue;
@synthesize reachableBlock          = _reachableBlock;
@synthesize unreachableBlock        = _unreachableBlock;
@synthesize reachabilityObject      = _reachabilityObject;


#pragma mark - Constructor Methods

+ (Reachability*)reachabilityWithHostname:(NSString*)hostname
{
    SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithName(NULL, [hostname UTF8String]);
    if (ref) 
    {
        id reachability = [[self alloc] initWithReachabilityRef:ref];

        return reachability;
    }
    
    return nil;
}


+ (Reachability*)reachabilityWithAddress:(const struct sockaddr_in*)hostAddress 
{
    SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault,
                                                                          (const struct sockaddr*)hostAddress);
    if (ref) 
    {
        id reachability = [[self alloc] initWithReachabilityRef:ref];
        
        return reachability;
    }
    
    return nil;
}


+ (Reachability*)reachabilityForInternetConnection 
{   
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    return [self reachabilityWithAddress:&zeroAddress];
}


+ (Reachability*)reachabilityForLocalWiFi
{
    struct sockaddr_in localWifiAddress;
    bzero(&localWifiAddress, sizeof(localWifiAddress));
    localWifiAddress.sin_len            = sizeof(localWifiAddress);
    localWifiAddress.sin_family         = AF_INET;
    localWifiAddress.sin_addr.s_addr    = htonl(IN_LINKLOCALNETNUM);    // 169.254.0.0
    
    return [self reachabilityWithAddress:&localWifiAddress];
}


#pragma mark - Lifecycle

- (Reachability*)initWithReachabilityRef:(SCNetworkReachabilityRef)ref 
{
    if (self = [super init]) 
    {
        self.reachabilityRef = ref;
    }

    return self;    
}


- (void)dealloc
{
    [self stopNotifier];

    if (self.reachabilityRef)
    {
        CFRelease(self.reachabilityRef);
        self.reachabilityRef = nil;
    }

    self.reachableBlock   = nil;
    self.unreachableBlock = nil;
}


#pragma mark - notifier methods

// Notifier 
// NOTE: this uses GCD to trigger the blocks - they *WILL NOT* be called on THE MAIN THREAD
// - In other words DO NOT DO ANY UI UPDATES IN THE BLOCKS.
//   INSTEAD USE dispatch_async(dispatch_get_main_queue(), ^{UISTUFF}) (or dispatch_sync if you want)
- (BOOL)startNotifier
{
    SCNetworkReachabilityContext    context = { 0, NULL, NULL, NULL, NULL };
    
    // This should do a retain on ourself, so as long as we're in notifier mode
    // we shouldn't disappear out from under ourselves woah.
    self.reachabilityObject = self;
    
    // First we need to create a serial queue.  We allocate this once for the
    // lifetime of the notifier
    self.reachabilitySerialQueue = dispatch_queue_create("Reachability.m", DISPATCH_QUEUE_CONCURRENT);
    if(!self.reachabilitySerialQueue)
    {
        return NO;
    }
    
    context.info = (__bridge void*)self;
    
    if (!SCNetworkReachabilitySetCallback(self.reachabilityRef, TMReachabilityCallback, &context)) 
    {
#ifdef DEBUG
        NSLog(@"SCNetworkReachabilitySetCallback() failed: %s", SCErrorString(SCError()));
#endif

        // Clear out the dispatch queue
        if(self.reachabilitySerialQueue)
        {
            self.reachabilitySerialQueue = nil;
        }
        
        self.reachabilityObject = nil;

        return NO;
    }
    
    // set it as our reachability queue which will retain the queue
    if (!SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, self.reachabilitySerialQueue))
    {
#ifdef DEBUG
        NSLog(@"SCNetworkReachabilitySetDispatchQueue() failed: %s", SCErrorString(SCError()));
#endif
        // First stop any callbacks!
        SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);
        
        // Then clear out the dispatch queue.
        if(self.reachabilitySerialQueue)
        {
            self.reachabilitySerialQueue = nil;
        }
        
        self.reachabilityObject = nil;
        
        return NO;
    }
    
    return YES;
}


- (void)stopNotifier
{
    // First stop any callbacks!
    SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);

    // Unregister target from the GCD serial dispatch queue
    SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, NULL);
    
    if (self.reachabilitySerialQueue)
    {
        self.reachabilitySerialQueue = nil;
    }
    
    self.reachabilityObject = nil;
}


#pragma mark - reachability tests

- (BOOL)isReachableWithFlags:(SCNetworkReachabilityFlags)flags
{
    BOOL reachable = YES;
    
    if (!(flags & kSCNetworkReachabilityFlagsReachable))
    {
        reachable = NO;
    }

    // When Airplane Mode is switched off there are a lot of events passing by.
    // Something like this for example:
    //     Host Reachability: WR ct-----
    //     Host Reachability: WR ct-----
    //     Host Reachability: WR ct-----
    //     Host Reachability: WR ct-----
    //     Host Reachability: WR ct-----
    //     Host Reachability: -- -------
    //     Host Reachability: WR -t-----
    // This filter these away.
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
        (flags & kSCNetworkReachabilityFlagsTransientConnection))
    {
        reachable = NO;
    }

    return reachable;
}


#pragma mark - External API Methods

- (BOOL)isReachable
{
    SCNetworkReachabilityFlags  flags;
    
    if (!SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags))
    {
        return NO;
    }

    return [self isReachableWithFlags:flags];
}


- (BOOL)isReachableViaWWAN
{
    SCNetworkReachabilityFlags  flags;
    
    if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags))
    {
        if (flags & kSCNetworkReachabilityFlagsIsWWAN)
        {
            return [self isReachableWithFlags:flags];
        }
    }
    
    return NO;
}


- (BOOL)isReachableViaWiFi 
{
    SCNetworkReachabilityFlags  flags;
    
    if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags))
    {
        if ((flags & kSCNetworkReachabilityFlagsReachable))
        {
            if (!(flags & kSCNetworkReachabilityFlagsIsWWAN))
            {
                return YES;
            }
        }
    }
    
    return NO;
}


// WWAN may be available, but not active until a connection has been established.
// WiFi may require a connection for VPN on Demand.
- (BOOL)isConnectionRequired
{
    SCNetworkReachabilityFlags  flags;
	
    if(SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags))
    {
        return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
    }
    
    return NO;
}


// Dynamic, on demand connection?
- (BOOL)isConnectionOnDemand
{
    SCNetworkReachabilityFlags  flags;
	
    if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags))
    {
        return ((flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
                (flags & (kSCNetworkReachabilityFlagsConnectionOnTraffic |
                          kSCNetworkReachabilityFlagsConnectionOnDemand)));
    }
    
    return NO;
}


// Is user intervention required?
- (BOOL)isInterventionRequired
{
    SCNetworkReachabilityFlags  flags;
	
    if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags))
    {
        return ((flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
                (flags & kSCNetworkReachabilityFlagsInterventionRequired));
    }
    
    return NO;
}


#pragma mark - Additional Status Stuff

- (ReachableStatus)currentReachabilityStatus
{
    if ([self isReachable])
    {
        return [self isReachableViaWiFi] ? ReachableViaWiFi : ReachableViaWWAN;
    }
    else
    {
        return NotReachable;
    }
}


- (SCNetworkReachabilityFlags)reachabilityFlags
{
    SCNetworkReachabilityFlags flags = 0;
    
    if(SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags))
    {
        return flags;
    }
    
    return 0;
}


- (NSString*)currentReachabilityString
{
    ReachableStatus status = [self currentReachabilityStatus];

    if (status == ReachableViaWWAN)
    {
        // Updated for the fact we have CDMA phones now!
        return NSLocalizedString(@"Cellular", @"Network connection state (3G/Edge/CDMA)");
    }
    
    if (status == ReachableViaWiFi)
    {
        return NSLocalizedString(@"Wi-Fi", @"Network connection state (Wi-Fi)");
    }

    return NSLocalizedString(@"No Connection", @"Network connection state (not connected)");
}


- (NSString*)currentReachabilityFlags
{
    return reachabilityFlags([self reachabilityFlags]);
}


#pragma mark - callback function calls this method

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags
{
    if ([self isReachableWithFlags:flags])
    {
        if (self.reachableBlock)
        {
            self.reachableBlock(self);
        }
    }
    else
    {
        if (self.unreachableBlock)
        {
            self.unreachableBlock(self);
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:self];
    });
}

@end
