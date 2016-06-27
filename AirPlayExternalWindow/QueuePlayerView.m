//
//  QueuePlayerView.m
//  AirPlayExternalWindow
//
//  Created by Deepak on 27/06/16.
//  Copyright © 2016 Dipak. All rights reserved.
//

#import "QueuePlayerView.h"

#include <CoreMedia/CMTime.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>


// Contexts for KVO
static void *kAirplayKVO                = &kAirplayKVO;
static void *kBufferEmptyKVO            = &kBufferEmptyKVO;
static void *kStatusDidChangeKVO        = &kStatusDidChangeKVO;
static void *kTimeRangesKVO             = &kTimeRangesKVO;
static void *kBufferKeepup              = &kBufferKeepup;


@interface QueuePlayerView() <AVAssetResourceLoaderDelegate>

@property (nonatomic, readonly) AVPlayerLayer *playerLayer;
@property (nonatomic, strong)   AVQueuePlayer *player;
@end

@implementation QueuePlayerView

-(void)setup
{
    [self.playerLayer setOpacity:1.0];
    [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [self.playerLayer setNeedsDisplayOnBoundsChange:YES];
    [self.layer setNeedsDisplayOnBoundsChange:YES];
    self.player = [[AVQueuePlayer alloc] init];
}


- (void)addObservers
{
    [self removeObservers];
    
    [self.player addObserver:self forKeyPath:@"currentItem.playbackBufferEmpty"         options:NSKeyValueObservingOptionNew context:kBufferEmptyKVO];
    [self.player addObserver:self forKeyPath:@"airPlayVideoActive"                      options:NSKeyValueObservingOptionNew context:kAirplayKVO];
    [self.player addObserver:self forKeyPath:@"currentItem.status"                      options:NSKeyValueObservingOptionNew context:kStatusDidChangeKVO];
    [self.player addObserver:self forKeyPath:@"currentItem.loadedTimeRanges"            options:NSKeyValueObservingOptionNew context:kTimeRangesKVO];
    [self.player addObserver:self forKeyPath:@"currentItem.playbackLikelyToKeepUp"      options:NSKeyValueObservingOptionNew context:kBufferKeepup];
}

-(void)removeObservers
{
    @try
    {
        [self.player removeObserver:self forKeyPath:@"currentItem.playbackBufferEmpty"      context:kBufferEmptyKVO];
        [self.player removeObserver:self forKeyPath:@"airPlayVideoActive"                   context:kAirplayKVO];
        [self.player removeObserver:self forKeyPath:@"currentItem.status"                   context:kStatusDidChangeKVO];
        [self.player removeObserver:self forKeyPath:@"currentItem.loadedTimeRanges"         context:kTimeRangesKVO];
        [self.player removeObserver:self forKeyPath:@"currentItem.playbackLikelyToKeepUp"   context:kBufferKeepup];
        
    }
    @catch (NSException *exception) {
        
    }
}

#pragma mark - Self methods
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

+ (void)initialize
{
    if (self == [QueuePlayerView class]) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [self removeObservers];
    self.player = nil;
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVQueuePlayer *)player
{
    [(AVPlayerLayer *) [self layer] setPlayer:player];
    
    if ([player respondsToSelector:@selector(allowsAirPlayVideo)])
    {
        [player setAllowsExternalPlayback:NO];
        [player setUsesExternalPlaybackWhileExternalScreenIsActive:NO];
    }
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)[self layer];
}


#pragma mark - public methods
-(void)initWithURLString:(NSString*)urlString
{
    if (!urlString) {
        urlString = @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8";
    }
    [self reloadItems:@[urlString]];
    [self addObservers];
}

-(void)reloadItems:(NSArray*)items
{
    [self.player pause];
    [self.player removeAllItems];
    
    for (NSString *urlString in items)
    {
        NSURL *url                  = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSLog(@"Queue player URLS %@", url);
        AVURLAsset *asset           = [AVURLAsset URLAssetWithURL:url options:nil];
        
        AVAssetResourceLoader *resourceLoader = asset.resourceLoader;
        [resourceLoader setDelegate:self queue:dispatch_queue_create("QueuePlayerAsset loader", nil)];
        
        AVPlayerItem *playerItem    = [[AVPlayerItem alloc] initWithAsset:asset];
        if([self.player canInsertItem:playerItem afterItem:nil]) {
            [self.player insertItem:playerItem afterItem:nil];
        }
    }
}

- (void)play {
    [self.player setRate:1.0];
}

-(void)stopPlayer
{
    [self.player pause];
    [self removeObservers];
    [self.player removeAllItems];
}

#pragma mark Player observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    AVPlayerItemStatus status = self.player.currentItem.status;
    
    NSLog(@"AVPlayerItemStatus:%ld",(long)status);
    if(context == kStatusDidChangeKVO)
    {
        if(status == AVPlayerItemStatusReadyToPlay)
        {
            [self play];
        }
    }
    else if(context == kBufferEmptyKVO)
    {
    }
    else if(context == kTimeRangesKVO)
    {
    }
    else
    {

    }
}

#pragma mark - AVAssetResourceLoader delegate methods
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    return YES;
}

@end
