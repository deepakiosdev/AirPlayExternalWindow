//
//  AVQueuePlayerVC.m
//  AirPlayExternalWindow
//
//  Created by Deepak on 28/06/16.
//  Copyright © 2016 Dipak. All rights reserved.
//

#import "AVQueuePlayerVC.h"
#import "QueuePlayerView.h"

@interface AVQueuePlayerVC ()
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet QueuePlayerView *playerView;
@property (weak, nonatomic) IBOutlet UILabel *connectedLabel;

@property (nonatomic, strong)   UIWindow                     *externalWindow;
@property (nonatomic, strong)   UIScreen                     *externalScreen;
@end

@implementation AVQueuePlayerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.playerView initWithURLString:@"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(externalScreenDidConnect:) name:UIScreenDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(externalScreenDidDisconnect:) name:UIScreenDidDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exteralScreenModeDidChange:) name:UIScreenModeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(externalScreenDidDisconnect:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(externalScreenDidDisconnect:) name:UIApplicationWillTerminateNotification object:nil];
    
    [self setupExternalScreen];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self externalScreenDidDisconnect:nil];
    [self.playerView stopPlayer];
    [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenModeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}


- (void)setupExternalScreen
{
    // Setup screen mirroring for an existing screen
    NSArray *connectedScreens = [UIScreen screens];
    NSLog(@"connectedScreens count:%lu: ",(unsigned long)connectedScreens.count);
    if ([connectedScreens count] > 1)
    {
        UIScreen *mainScreen = [UIScreen mainScreen];
        for (UIScreen *aScreen in connectedScreens)
        {
            if (aScreen != mainScreen)
            {
                [self configureExternalScreen:aScreen];
                break;
            }
        }
    }
}


-(void)configureExternalScreen:(UIScreen *)externalScreen
{
    NSLog(@"configureExternalScreen....");
    
    self.externalScreen = externalScreen;
    self.connectedLabel.hidden = NO;
    // NSLog(@"1......._externalWindow:%@",_externalWindow);
    if(!_externalWindow) {
        _externalWindow = [[UIWindow alloc] initWithFrame:[self.externalScreen bounds]];
    }
    [_externalWindow setHidden:NO];
    
    [[_externalWindow layer] setContentsGravity:kCAGravityResizeAspect];
    [_externalWindow setScreen:self.externalScreen];
    [[_externalWindow screen] setOverscanCompensation:UIScreenOverscanCompensationScale];
    
    [_playerView setFrame:[_externalWindow bounds]];
    [_externalWindow addSubview:_playerView];
    
    [_playerView updateConstraintsIfNeeded];
    [_playerView setNeedsLayout];
    [_playerView setTranslatesAutoresizingMaskIntoConstraints:YES];
    for(NSLayoutConstraint *c in _containerView.constraints)
    {
        if(c.firstItem == _playerView || c.secondItem == _playerView) {
            [_containerView removeConstraint:c];
        }
    }
    
    [_externalWindow makeKeyAndVisible];
    
    //NSLog(@"2.......screen:%@",_externalWindow.screen);
    // NSLog(@"2......._externalWindow:%@",_externalWindow);
    //NSLog(@"subviews.count:%lu \n_externalWindow.subviews:%@",(unsigned long)_externalWindow.subviews.count, _externalWindow.subviews);
    //  NSLog(@"keyWindow:%@",[[UIApplication sharedApplication] keyWindow]);
    // NSLog(@"windows:%@",[[UIApplication sharedApplication] windows]);
    
}

-(void)externalScreenDidConnect:(NSNotification*)notification
{
    UIScreen *externalScreen = [notification object];
    [self configureExternalScreen:externalScreen];
}

-(void)externalScreenDidDisconnect:(NSNotification*)notification
{
    NSLog(@"externalScreenDidDisconnect....");
    self.connectedLabel.hidden = YES;
    [_playerView setFrame:[_containerView bounds]];
    [_containerView addSubview:_playerView];
    
    [_playerView updateConstraintsIfNeeded];
    [_playerView setNeedsLayout];
    [_playerView setTranslatesAutoresizingMaskIntoConstraints:YES];
    
    if(_externalWindow)
    {
        self.externalScreen = nil;
        [_externalWindow setHidden:YES];
        [_externalWindow resignKeyWindow];
    }
    _externalWindow = nil;
    
}

-(void)exteralScreenModeDidChange:(NSNotification*)notification
{
}

@end
