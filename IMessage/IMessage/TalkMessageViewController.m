//
//  TalkMessageViewController.m
//  IMessage
//
//  Created by shi feng on 13-6-8.
//  Copyright (c) 2013年 yishubus. All rights reserved.
//

#import "TalkMessageViewController.h"
#import "IMessageAppDelegate.h"
#import "SqliteData.h"
#import "AddressBook.h"
#import "TalkMessage.h"
#import "Constants.h"
#import "IMessageService.h"
#import "NetWorkData.h"
#import "RequestURL.h"

@interface TalkMessageViewController ()
{
    NSMutableArray *messageArray;
    NSString *chatWithUser;
}
@end

@implementation TalkMessageViewController
@synthesize tView;
@synthesize myTextField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void) setChatWithUser:(NSString *)userid
{
    chatWithUser = userid;
    SqliteData *util = [[SqliteData alloc] init];
    
    AddressBook *friend = [util getFriend:chatWithUser];
    self.navigationItem.title = friend.name;
    
    self.tView.delegate = self;
    self.tView.dataSource = self;
    messageArray = [NSMutableArray array];
    
    [util updateFriendIsLoad:chatWithUser];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    [textField becomeFirstResponder];
    
    IMessageAppDelegate *appDelegate = [self appDelegate];
    appDelegate.messageReceiveDelegate = self;
    
    myTextField.delegate = self;
    myTextField.borderStyle = UITextBorderStyleRoundedRect;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void) keyboardWillShow:(NSNotification *)notification
{
    NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardBounds;
    [keyboardBoundsValue getValue:&keyboardBounds];
    NSInteger offset = self.view.frame.size.height - keyboardBounds.origin.y + 64;
    CGRect listFrame = CGRectMake(0, -offset, self.view.frame.size.width, self.view.frame.size.height);
    [UIView beginAnimations:@"anim" context:NULL];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    
    self.view.frame = listFrame;
    [UIView commitAnimations];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    NSTimeInterval animationDuration = 0.3f;
    [UIView beginAnimations:@"closeKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    CGRect rect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.view.frame = rect;
    [UIView commitAnimations];
    [textField resignFirstResponder];
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [messageArray count];
}

- (IBAction)clickMessage:(id)sender {
    NSString *message = self.myTextField.text;
    if (message.length > 0) {
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:message];
        
        NSXMLElement *mes = [NSXMLElement elementWithName:@"message"];
        [mes addAttributeWithName:@"type" stringValue:@"chat"];
        
        NSString *mid = [[NSUserDefaults standardUserDefaults] objectForKey:@"id"];
        NSString *toOpenfire = [chatWithUser stringByAppendingString:OPEN_FILE_SERVER];
        NSString *fromOpenfire = [mid stringByAppendingString:OPEN_FILE_SERVER];
        [mes addAttributeWithName:@"to" stringValue:toOpenfire];
        [mes addAttributeWithName:@"from" stringValue:fromOpenfire];
        [mes addChild:body];
        
        [[self xmppStream] sendElement:mes];
        
        // -- add native message
        NSString *talkTime = [IMessageService getCurrentTime];
        SqliteData *util = [[SqliteData alloc] init];
        [util addMessage:mid fromid:mid toid:chatWithUser talkMessage:message talkTime:talkTime load:2 userid:chatWithUser];
        
        // -- add server message
        dispatch_queue_t queuemessage = dispatch_queue_create("queuemessage", nil);
        dispatch_async(queuemessage, ^{
            NSString *titleUrl = [RequestURL getUrlByKey:SAVE_MESSAGE];
            [NetWorkData addMessage:mid toUser:chatWithUser sendDate:@"" msgtype:@"0" msg:message url:titleUrl];
        });

    }
    
    self.myTextField.text = @"";
}

- (void) messageReceive:(NSDictionary *)messageContent
{
    
}

- (IMessageAppDelegate *) appDelegate
{
    return (IMessageAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (XMPPStream *) xmppStream
{
    return [[self appDelegate] xmppStream];
}

@end
