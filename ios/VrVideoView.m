//
//  PanoramaView.m
//  panorama
//
//  Created by Marco Argentieri on 28/12/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "VrVideoView.h"
#import "GVRWidgetView.h"
#import <React/RCTConvert.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventDispatcher.h>

@implementation RCTConvert(GVRWidgetDisplayMode)

RCT_ENUM_CONVERTER(GVRWidgetDisplayMode, (@{
                                            @"fullscreen": @(kGVRWidgetDisplayModeFullscreen),
                                            @"embedded": @(kGVRWidgetDisplayModeEmbedded),
                                            @"cardboard": @(kGVRWidgetDisplayModeFullscreenVR),
                                            }), NSNotFound, integerValue)

@end



@implementation VrVideoView {
  BOOL _isPaused;
  GVRVideoView *_videoView;
  GVRVideoType __videoType;
  RCTEventDispatcher *_eventDispatcher;
  
}

- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  _videoView = [[GVRVideoView alloc] init];
  _videoView.delegate = self;
  _isPaused = YES;
  [self addSubview:_videoView];
  
  return self;
}

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
 if ((self = [super init])) {
    _eventDispatcher = eventDispatcher;
 }
  return self;
}



- (void)layoutSubviews
{
  float rootViewWidth = self.frame.size.width;
  float rootViewHeight = self.frame.size.height;
  [_videoView setFrame:CGRectMake(0, 0, rootViewWidth, rootViewHeight)];

}

-(void)setVolume:(float)volume
{
  _videoView.volume = volume;
}

-(void)setSrc:(NSDictionary *)src
{
  NSString *uri = [src objectForKey:@"uri"];
  NSURL *url = [NSURL URLWithString:uri];
  NSString *strType = [src objectForKey:@"type"];
  BOOL isNetwork = [src objectForKey:@"isNetwork"];
  
  GVRVideoType videoType = kGVRVideoTypeMono;
  if ([strType isEqualToString:@"stereo"]) {
    videoType = kGVRVideoTypeStereoOverUnder;
  }
  
  //play from remote url
  if ( isNetwork ) {
    
    [_videoView loadFromUrl:url ofType:videoType];
    
  } else { // play from local
    //Local asset: Can be in the bundle or the uri can be an absolute path of a stored video in the application
    
    //Check whether the file loaded from the Bundle,
    NSString *localPath = [[NSBundle mainBundle] pathForResource:uri ofType:@"mp4"];
    if (localPath) {
      //Let's replace the `uri` to the full path'
      uri = localPath;
    }
    url = [NSURL fileURLWithPath:uri];
    // [_videoView loadFromUrl:[[NSURL alloc] initFileURLWithPath:videoPath]
    //                   ofType:videoType];
    [_videoView loadFromUrl:url ofType:videoType];
  }
  
  [_videoView pause];
}

- (void)setDisplayMode:(NSString *)displayMode
{
  //Display mode default Embedded
  _videoView.displayMode = [RCTConvert GVRWidgetDisplayMode:displayMode];
}


- (void)setEnableFullscreenButton:(BOOL)enableFullscreenButton
{
  _videoView.enableFullscreenButton = enableFullscreenButton;
}

-(void)setEnableInfoButton:(BOOL)enableInfoButton
{
  _videoView.enableInfoButton = enableInfoButton;
}

-(void)setEnableTouchTracking:(BOOL)enableTouchTracking
{
  _videoView.enableTouchTracking = enableTouchTracking;
}

-(void)setHidesTransitionView:(BOOL)hidesTransitionView
{
  _videoView.hidesTransitionView = hidesTransitionView;
}

-(void)setEnableCardboardButton:(BOOL)enableCardboardButton
{
  _videoView.enableCardboardButton = enableCardboardButton;
}


#pragma mark - GVRVideoViewDelegate

- (void)widgetViewDidTap:(GVRWidgetView *)widgetView {
  if (_isPaused) {
    [_videoView play];
  } else {
    [_videoView pause];
  }
  _isPaused = !_isPaused;
}

- (void)widgetView:(GVRWidgetView *)widgetView didLoadContent:(id)content {
  RCTLogInfo(@"Finished loading video");
  // UIAlertView *alert = [[UIAlertView alloc]
  //  initWithTitle:@"Make an informed choice"
  //  message:nil
  //  delegate:self
  //  cancelButtonTitle:@"Cancel"
  //  otherButtonTitles:@"OK", nil];
  // [alert show];
    // [_eventDispatcher sendInputEventWithName:@"onDidloadVideo" body:@{
    //                                                                   @"payload": [NSNumber numberWithFloat:100],
    //                                                                   }];
    if(self.onLoadVideoSuccess) {
                self.onLoadVideoSuccess(@{ @"payload": [NSNumber numberWithFloat:100]});
            }
  [_videoView play];
  _isPaused = NO;
}

- (void)widgetView:(GVRWidgetView *)widgetView didFailToLoadContent:(id)content
  withErrorMessage:(NSString *)errorMessage {
  RCTLogInfo(@"Failed to load video: %@", errorMessage);
  if(self.onLoadVideoFailed){
    self.onLoadVideoFailed(@{ @"payload": [NSNumber numberWithFloat:100]});
  }
  [_videoView pause];
  _isPaused = YES;

   UIAlertView *alert = [[UIAlertView alloc]
   initWithTitle:@"Error load video"
   message:errorMessage
   delegate:self
   cancelButtonTitle:@"Cancel"
   otherButtonTitles:@"OK", nil];
  [alert show];
}

- (void)videoView:(GVRVideoView*)videoView didUpdatePosition:(NSTimeInterval)position {
  // Loop the video when it reaches the end.
  if (position == videoView.duration) {
    [_videoView seekTo:0];
    [_videoView play];
  }
}


@end
