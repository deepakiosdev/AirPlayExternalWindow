//
//  AVPlayerVC.m
//  AirPlayExternalWindow
//
//  Created by dipak on 6/14/16.
//  Copyright © 2016 Dipak. All rights reserved.
//

#import "AVPlayerVC.h"
#import "AVPlayerDemoPlaybackView.h"
@import AVKit;

static void *AVPlayerDemoPlaybackViewControllerRateObservationContext = &AVPlayerDemoPlaybackViewControllerRateObservationContext;
static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;
static void *AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext = &AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext;

@interface AVPlayerVC ()
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet AVPlayerDemoPlaybackView *playerView;
@property (weak, nonatomic) IBOutlet UILabel *connectedLabel;

@property (nonatomic, strong)   UIWindow                     *externalWindow;
@property (nonatomic, strong)   UIScreen                     *externalScreen;
@property (nonatomic, strong)   AVQueuePlayer *player;
@property (nonatomic, strong) AVPlayerViewController *playerController;
@property (strong) AVPlayerItem* mPlayerItem;

@end

@implementation AVPlayerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpPlayer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    
    [self.player removeObserver:self forKeyPath:@"rate"];
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player removeObserver:self forKeyPath:@"currentItem"];


    [self.player pause];
    
    
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


-(void)setUpPlayer {
    

    // grab a local URL to our video
    //NSURL *videoURL = [[NSBundle mainBundle]URLForResource:@"video" withExtension:@"mp4"];
    
    NSURL *videoURL = [NSURL URLWithString:@"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"];
//    NSURL *videoURL = [NSURL URLWithString:@"http://192.168.150.205:1001/nmdcVIACOMUSA/20160125/others/89.mp4"];

    // create an AVPlayer
    /*AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    
    // create a player view controller
    self.playerController = [[AVPlayerViewController alloc]init];
    self.playerController.player = player;
    [player play];
    
    // show the view controller
    [self addChildViewController:self.playerController];
    CGRect frame = self.playerView.frame;
    self.playerController.view.frame = CGRectMake(50, 50, frame.size.width - 50, frame.size.height - 50);
    //self.playerController.view.frame = frame;

    [self.playerView addSubview:self.playerController.view];
    self.playerController.view.frame = CGRectMake(50, 50, frame.size.width - 50, frame.size.height - 50);

    return;*/
    
    [self.player removeAllItems];
    self.player = [[AVQueuePlayer alloc] init];
     NSLog(@"Video URL %@", videoURL);
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    
    NSArray *requestedKeys = @[@"playable"];
    
    /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
     ^{
         dispatch_async( dispatch_get_main_queue(),
                        ^{
                            /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
                            [self prepareToPlayAsset:asset withKeys:requestedKeys];
                        });
     }];
}


#pragma mark -
#pragma mark Loading the Asset Keys Asynchronously

#pragma mark -
#pragma mark Error Handling - Preparing Assets for Playback Failed

/* --------------------------------------------------------------
 **  Called when an asset fails to prepare for playback for any of
 **  the following reasons:
 **
 **  1) values of asset keys did not load successfully,
 **  2) the asset keys did load successfully, but the asset is not
 **     playable
 **  3) the item did not become ready to play.
 ** ----------------------------------------------------------- */

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
//    [self removePlayerTimeObserver];
//    [self syncScrubber];
//    [self disableScrubber];
//    [self disablePlayerButtons];
//    
    /* Display the error. */
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                        message:[error localizedFailureReason]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

#pragma mark Prepare to play asset, URL

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    /* Make sure that the value of each key has loaded successfully. */
    for (NSString *thisKey in requestedKeys)
    {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed)
        {
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
        /* If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation. */
    }
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable)
    {
        /* Generate an error describing the failure. */
        NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
        NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   localizedDescription, NSLocalizedDescriptionKey,
                                   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
                                   nil];
        NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
    
    /* At this point we're ready to set up for playback of the asset. */
    
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.mPlayerItem)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [self.mPlayerItem removeObserver:self forKeyPath:@"status"];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.mPlayerItem];
    }
    
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.mPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    /* Observe the player item "status" key to determine when it is ready to play. */
    [self.mPlayerItem addObserver:self
                       forKeyPath:@"status"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
    

    /* Create new player, if we don't already have one. */
    if (!self.player)
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
       // [self setPlayer:[AVPlayer playerWithPlayerItem:self.mPlayerItem]];
        if([self.player canInsertItem:self.mPlayerItem afterItem:nil]) {
            [self.player insertItem:self.mPlayerItem afterItem:nil];
        }
        [self.playerView setPlayer:self.player];

        /* Observe the AVPlayer "currentItem" property to find out when any
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
         occur.*/
        [self.player addObserver:self
                      forKeyPath:@"currentItem"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self
                      forKeyPath:@"rate"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerDemoPlaybackViewControllerRateObservationContext];
        // ...
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.player.currentItem != self.mPlayerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs
         asynchronously; observe the currentItem property to find out when the
         replacement will/did occur
         
         If needed, configure player item here (example: adding outputs, setting text style rules,
         selecting media options) before associating it with a player
         */
        //[self.player replaceCurrentItemWithPlayerItem:self.mPlayerItem];
       if([self.player canInsertItem:self.mPlayerItem afterItem:nil]) {
            [self.player insertItem:self.mPlayerItem afterItem:nil];
        }
        [self.player addObserver:self
                      forKeyPath:@"currentItem"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext];
        
       //  Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self
                      forKeyPath:@"rate"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerDemoPlaybackViewControllerRateObservationContext];
        //[self.playerView setPlayer:self.player];

        // ...
    }
}


#pragma mark -
#pragma mark Asset Key Value Observing
#pragma mark

#pragma mark Key Value Observer for player rate, currentItem, player item status

/* ---------------------------------------------------------
 **  Called when the value at the specified key path relative
 **  to the given object has changed.
 **  Adjust the movie play and pause button controls when the
 **  player item "status" value changes. Update the movie
 **  scrubber control when the player item is ready to play.
 **  Adjust the movie scrubber control when the player item
 **  "rate" value changes. For updates of the player
 **  "currentItem" property, set the AVPlayer for which the
 **  player layer displays visual output.
 **  NOTE: this method is invoked on the main queue.
 ** ------------------------------------------------------- */

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    /* AVPlayerItem "status" property value observer. */
    if (context == AVPlayerDemoPlaybackViewControllerStatusObservationContext)
    {
        
        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerItemStatusUnknown:
            {

            }
                break;
                
            case AVPlayerItemStatusReadyToPlay:
            {
                [self.player play];

            }
                break;
                
            case AVPlayerItemStatusFailed:
            {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:playerItem.error];
            }
                break;
        }
    }
    /* AVPlayer "rate" property value observer. */
    else if (context == AVPlayerDemoPlaybackViewControllerRateObservationContext)
    {
    }
    /* AVPlayer "currentItem" property observer.
     Called when the AVPlayer replaceCurrentItemWithPlayerItem:
     replacement will/did occur. */
    else if (context == AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext)
    {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* Is the new player item null? */
        if (newPlayerItem == (id)[NSNull null])
        {
 
        }
        else /* Replacement of player currentItem has occurred */
        {
            [self.playerView setPlayer:self.player];

            /* Set the AVPlayer for which the player layer displays visual output. */
        }
    }
    else
    {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
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

