//
//  QueuePlayerView.h
//  AirPlayExternalWindow
//
//  Created by Deepak on 27/06/16.
//  Copyright © 2016 Dipak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QueuePlayerView : UIView

-(void)initWithURLString:(NSString*)urlString;
- (void)play;
- (void)stopPlayer;
@end
