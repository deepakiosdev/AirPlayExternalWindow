//
//  AirPlayVC.m
//  AirPlayExternalWindow
//
//  Created by dipak on 6/14/16.
//  Copyright © 2016 Dipak. All rights reserved.
//

#import "AirPlayVC.h"

@interface AirPlayVC ()
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *greenView;
@property (nonatomic, strong)   UIWindow                     *externalWindow;
@property (nonatomic, strong)   UIScreen                     *externalScreen;

@end

@implementation AirPlayVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
    [super viewWillDisappear: animated];
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
   // NSLog(@"1......._externalWindow:%@",_externalWindow);
    if(!_externalWindow) {
        _externalWindow = [[UIWindow alloc] initWithFrame:[self.externalScreen bounds]];
    }
    [_externalWindow setHidden:NO];
    
    [[_externalWindow layer] setContentsGravity:kCAGravityResizeAspect];
    [_externalWindow setScreen:self.externalScreen];
    [[_externalWindow screen] setOverscanCompensation:UIScreenOverscanCompensationScale];
    
    [_greenView setFrame:[_externalWindow bounds]];
    [_externalWindow addSubview:_greenView];
    
    [_greenView updateConstraintsIfNeeded];
    [_greenView setNeedsLayout];
    [_greenView setTranslatesAutoresizingMaskIntoConstraints:YES];
    for(NSLayoutConstraint *c in _containerView.constraints)
    {
        if(c.firstItem == _greenView || c.secondItem == _greenView) {
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
    [_greenView setFrame:[_containerView bounds]];
    [_containerView addSubview:_greenView];
    
    [_greenView updateConstraintsIfNeeded];
    [_greenView setNeedsLayout];
    [_greenView setTranslatesAutoresizingMaskIntoConstraints:YES];
    
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
