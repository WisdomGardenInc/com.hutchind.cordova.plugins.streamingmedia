#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Cordova/CDVPlugin.h>


NSString *const CALLBACK_PLAY = @"play";
NSString *const CALLBACK_PAUSE = @"pause";
NSString *const CALLBACK_SEEKING = @"seeking";
NSString *const CALLBACK_SEEKED = @"seek";
NSString *const CALLBACK_EACH = @"playing";
NSString *const CALLBACK_FINISHED = @"ended";
NSString *const CALLBACK_DESTROY = @"destroy";

@interface StreamingMedia : CDVPlugin

- (void)playVideo:(CDVInvokedUrlCommand *)command;
- (void)playVideoWithMultiDefinition:(CDVInvokedUrlCommand *)command;
- (void)playAudio:(CDVInvokedUrlCommand *)command;

@end