//
//  HDNotificationView.m
//  HDNotificationView
//
//  Created by iOS Developer on 4/3/15.
//  Copyright (c) 2015 AnG. All rights reserved.
//

#import "HDNotificationView.h"

#define APP_DELEGATE        [UIApplication sharedApplication].delegate

#define NOTIFICATION_VIEW_FRAME_HEIGHT       64.0f

#define LABEL_TITLE_FONT_SIZE   14.0f
#define LABEL_MESSAGE_FONT_SIZE 13.0f

#define IMAGE_ICON_CORNER_RADIUS    3.0f
#define IMAGE_ICON_FRAME    CGRectMake(15.0f, 8.0f, 20.0f, 20.0f)
#define LABEL_TITLE_FRAME       CGRectMake(45.0f, 3.0f, [[UIScreen mainScreen] bounds].size.width - 45.0f, 26.0f)
#define LABEL_MESSAGE_FRAME     CGRectMake(45.0f, 25.0f, [[UIScreen mainScreen] bounds].size.width - 45.0f, 35.0f)

#define NOTIFICATION_VIEW_SHOWING_TIME                  7.0f    //second
#define NOTIFICATION_VIEW_SHOWING_ANIMATION_TIME        0.5f    //second

@implementation HDNotificationView

+ (instancetype)sharedInstance
{
    static id _sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[[self class] alloc] init];
    });
    
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, [[UIScreen mainScreen] bounds].size.width, NOTIFICATION_VIEW_FRAME_HEIGHT)];
    if (self) {
        [self setUpUI];
    }
    
    return self;
}

- (void)setUpUI
{
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0) {
        self.barTintColor = nil;
        self.translucent = YES;
        self.barStyle = UIBarStyleBlack;
    }
    else {
        [self setTintColor:[UIColor colorWithRed:5 green:31 blue:75 alpha:1]];
    }
    
    self.layer.zPosition = MAXFLOAT;
    self.backgroundColor = [UIColor clearColor];
    self.multipleTouchEnabled = NO;
    self.exclusiveTouch = YES;
    
    _imgIcon = [[UIImageView alloc] initWithFrame:IMAGE_ICON_FRAME];
    [_imgIcon setContentMode:UIViewContentModeScaleAspectFill];
    [_imgIcon.layer setCornerRadius:IMAGE_ICON_CORNER_RADIUS];
    [_imgIcon setClipsToBounds:YES];
    [self addSubview:_imgIcon];
    
    _lblTitle = [[UILabel alloc] initWithFrame:LABEL_TITLE_FRAME];
    [_lblTitle setTextColor:[UIColor whiteColor]];
    [_lblTitle setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:LABEL_TITLE_FONT_SIZE]];
    [_lblTitle setNumberOfLines:1];
    [self addSubview:_lblTitle];
    
    _lblMessage = [[UILabel alloc] initWithFrame:LABEL_MESSAGE_FRAME];
    [_lblMessage setTextColor:[UIColor whiteColor]];
    [_lblMessage setFont:[UIFont fontWithName:@"HelveticaNeue" size:LABEL_MESSAGE_FONT_SIZE]];
    [_lblMessage setNumberOfLines:2];
    [self addSubview:_lblMessage];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(notificationViewDidTap:)];
    [self addGestureRecognizer:tapGesture];
}

- (void)showNotificationViewWithImage:(UIImage *)image title:(NSString *)title message:(NSString *)message isAutoClose:(BOOL)isAutoClose onTouch:(void (^)())onTouch
{
    // Invalidate _timerAutoClose
    if (_timerHideAuto) {
        [_timerHideAuto invalidate];
        _timerHideAuto = nil;
    }
    
    // onTouch
    _onTouch = onTouch;
    
    // Image
    if (image) {
        [_imgIcon setImage:image];
    }
    else {
        [_imgIcon setImage:nil];
    }
    
    // Title
    if (title) {
        [_lblTitle setText:title];
    }
    else {
        [_lblTitle setText:@""];
    }
    
    // Message
    if (message) {
        [_lblMessage setText:message];
    }
    else {
        [_lblMessage setText:@""];
    }
    [_lblMessage sizeToFit];
    
    
    // Prepare frame
    CGRect frame = self.frame;
    frame.origin.y = -frame.size.height;
    self.frame = frame;
    
    // Add to window
    APP_DELEGATE.window.windowLevel = UIWindowLevelStatusBar;
    [APP_DELEGATE.window addSubview:self];
    
    [UIView animateWithDuration:NOTIFICATION_VIEW_SHOWING_ANIMATION_TIME
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         
                         CGRect frame = self.frame;
                         frame.origin.y += frame.size.height;
                         self.frame = frame;
                         
                     } completion:^(BOOL finished) {
                         
                     }];
    
    // Schedule to hide
    if (isAutoClose) {
        _timerHideAuto = [NSTimer scheduledTimerWithTimeInterval:NOTIFICATION_VIEW_SHOWING_TIME
                                                          target:self
                                                        selector:@selector(hideNotificationView)
                                                        userInfo:nil
                                                         repeats:NO];
    }
}
- (void)hideNotificationView
{
    [self hideNotificationViewOnComplete:nil];
}
- (void)hideNotificationViewOnComplete:(void (^)())onComplete
{
    [UIView animateWithDuration:NOTIFICATION_VIEW_SHOWING_ANIMATION_TIME
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         
                         CGRect frame = self.frame;
                         frame.origin.y -= frame.size.height;
                         self.frame = frame;
                         
                     } completion:^(BOOL finished) {
                         
                         [self removeFromSuperview];
                         APP_DELEGATE.window.windowLevel = UIWindowLevelNormal;
                         
                         // Invalidate _timerAutoClose
                         if (_timerHideAuto) {
                             [_timerHideAuto invalidate];
                             _timerHideAuto = nil;
                         }
                         
                         if (onComplete) {
                             onComplete();
                         }
                     }];
}
- (void)notificationViewDidTap:(UIGestureRecognizer *)gesture
{
    [self hideNotificationViewOnComplete:nil];
    
    if (_onTouch) {
        _onTouch();
    }
}

//----------------------------------------------------------------------------------
#pragma mark - UTILITY FUNCS
//----------------------------------------------------------------------------------
+ (void)showNotificationViewWithImage:(UIImage *)image title:(NSString *)title message:(NSString *)message
{
    [HDNotificationView showNotificationViewWithImage:image title:title message:message isAutoClose:YES onTouch:nil];
}
+ (void)showNotificationViewWithImage:(UIImage *)image title:(NSString *)title message:(NSString *)message isAutoClose:(BOOL)isAutoClose onTouch:(void (^)())onTouch
{
    [[HDNotificationView sharedInstance] showNotificationViewWithImage:image title:title message:message isAutoClose:isAutoClose onTouch:onTouch];
}
+ (void)hideNotificationViewOnComplete:(void (^)())onComplete
{
    [[HDNotificationView sharedInstance] hideNotificationViewOnComplete:onComplete];
}





@end