//
//  ConversationViewController.m
//  Talk
//
//  Created by Jeroen Kooiker on 18/10/2017.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConversationViewController.h"


@interface ConversationViewController ()

@end


@implementation ConversationViewController

// @TODO:
// - When navigating back from this view to the conversations-view, the inputToolbar shows a bit of black for a short time.
//   Maybe because it's removed too early?
//   For slow animations, pause debugger and execute: p [(CALayer *)[[[[UIApplication sharedApplication] windows] objectAtIndex:0] layer] setSpeed:.1f]

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.inputToolbar.contentView.leftBarButtonItem = nil; // Disable the attachement button.
    
    // GestureRecognizer for when the CollectionView is tapped.
    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleCollectionTapRecognizer:)];
    [self.collectionView addGestureRecognizer:tapRecognizer];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    self.title = [self getTitle];
}


// @TODO: Return the correct screen title (Contact name or correct number-format if not in contacts)
- (NSString*)getTitle
{
    return self.extern_e164;
}


-(NSString*)senderDisplayName
{
    return self.extern_e164;
}


-(NSString*)senderId
{
    return self.extern_e164;
}


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 5;
}


- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView*)collectionView messageDataForItemAtIndexPath:(NSIndexPath*)indexPath
{
    JSQMessage* message = [[JSQMessage alloc] initWithSenderId:indexPath.row % 2 == 0 ? [self senderId] : @"sdffsd"
                                             senderDisplayName:indexPath.row % 2 == 0 ? [self senderDisplayName] : @"sdffsd"
                                                          date:[[[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian] dateBySettingHour:10
                                                                                                                                                          minute:0
                                                                                                                                                          second:0
                                                                                                                                                          ofDate:[NSDate date]
                                                                                                                                                         options:0] text:@"text.."];    
    
    return message;
}


- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage* message = [[JSQMessage alloc] initWithSenderId:indexPath.row % 2 == 0 ? [self senderId] : @"sdffsd"
                                             senderDisplayName:indexPath.row % 2 == 0 ? [self senderDisplayName] : @"sdffsd"
                                                          date:[[[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian] dateBySettingHour:10
                                                                                                                                                          minute:0
                                                                                                                                                          second:0
                                                                                                                                                          ofDate:[NSDate date]
                                                                                                                                                         options:0] text:@"text.."];
    
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    if ([message.senderId isEqualToString:self.senderId]) {
        return [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    }
    
    return [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
}


- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath
{
    
}


// Hides the keyboard when the CollectionView is tapped.
- (void)handleCollectionTapRecognizer:(UITapGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        if ([self.inputToolbar.contentView.textView isFirstResponder])
        {
            [self.inputToolbar.contentView.textView resignFirstResponder];
        }
    }
}

@end



/*
 - (void)didPressSendButton:(UIButton *)button
 withMessageText:(NSString *)text
 senderId:(NSString *)senderId
 senderDisplayName:(NSString *)senderDisplayName
 date:(NSDate *)date
 
 - (void)didPressAccessoryButton:(UIButton *)sender

 - (NSString *)senderDisplayName
 
 - (NSString *)senderId

 - (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath

 - (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath

 - (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath

 - (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath

 ?? - (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath

 ?? - (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath

 ?? - (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath

 ???? - (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section

 ???? - (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView

 
 */
