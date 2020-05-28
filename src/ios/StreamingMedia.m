#import "StreamingMedia.h"
#import "CustomMediaPlayerViewController.h"

@interface StreamingMedia () <CustomMediaPlayerViewControllerDelegate>
- (void)parseOptions:(NSDictionary *)options type:(NSString *)type;

- (void)play:(CDVInvokedUrlCommand *)command type:(NSString *)type;

- (void)setBackgroundColor:(NSString *)color;

- (void)setImage:(NSString *)imagePath withScaleType:(NSString *)imageScaleType;

- (UIImage *)getImage:(NSString *)imageName;

@end

@implementation StreamingMedia {
    NSString *callbackId;
    MPMoviePlayerController *moviePlayer;
    BOOL shouldAutoClose;
    UIColor *backgroundColor;
    UIImageView *imageView;
    BOOL initFullscreen;
}

NSString *const TYPE_VIDEO = @"VIDEO";
NSString *const TYPE_VIDEO_DEFINITION = @"VIDEO_DEFINITION";
NSString *const TYPE_AUDIO = @"AUDIO";

NSString *const DEFAULT_IMAGE_SCALE = @"center";

// QVGA VGA HD
NSString *const VIDEO_TYPE_QVGA = @"QVGA";
NSString *const VIDEO_TYPE_VGA = @"VGA";
NSString *const VIDEO_TYPE_HD = @"HD";

NSString *const PARAMS_ALLOW_SEEK = @"allowSeek";
NSString *const PARAMS_SEEK_TO = @"seekTo";
NSString *const PARAMS_TITLE = @"title";
NSString *const PARAMS_URLS = @"urls";
NSString *const PARAMS_OPTIONS = @"options";


- (void)parseOptions:(NSDictionary *)options type:(NSString *)type {
    // Common options
    if (![options isKindOfClass:[NSNull class]] && [options objectForKey:@"shouldAutoClose"]) {
        shouldAutoClose = [[options objectForKey:@"shouldAutoClose"] boolValue];
    } else {
        shouldAutoClose = true;
    }
    if (![options isKindOfClass:[NSNull class]] && [options objectForKey:@"bgColor"]) {
        [self setBackgroundColor:[options objectForKey:@"bgColor"]];
    } else {
        backgroundColor = [UIColor blackColor];
    }

    if (![options isKindOfClass:[NSNull class]] && [options objectForKey:@"initFullscreen"]) {
        initFullscreen = [[options objectForKey:@"initFullscreen"] boolValue];
    } else {
        initFullscreen = true;
    }

    if ([type isEqualToString:TYPE_AUDIO]) {
        // bgImage
        // bgImageScale
        if (![options isKindOfClass:[NSNull class]] && [options objectForKey:@"bgImage"]) {
            NSString *imageScale = DEFAULT_IMAGE_SCALE;
            if (![options isKindOfClass:[NSNull class]] && [options objectForKey:@"bgImageScale"]) {
                imageScale = [options objectForKey:@"bgImageScale"];
            }
            [self setImage:[options objectForKey:@"bgImage"] withScaleType:imageScale];
        }
        // bgColor
        if (![options isKindOfClass:[NSNull class]] && [options objectForKey:@"bgColor"]) {
            NSLog(@"Found option for bgColor");
            [self setBackgroundColor:[options objectForKey:@"bgColor"]];
        } else {
            backgroundColor = [UIColor blackColor];
        }
    }
    // No specific options for video yet
}

- (void)play:(CDVInvokedUrlCommand *)command type:(NSString *)type {
    NSDictionary *params = [command.arguments objectAtIndex:0];
    callbackId = command.callbackId;
    NSArray *mediaUrls = nil;
    BOOL isDefinition = NO;
    
    if ([type isEqualToString:TYPE_VIDEO]) {
        mediaUrls = [params objectForKey:PARAMS_URLS];
    }
    else if ([type isEqualToString:TYPE_VIDEO_DEFINITION]) {
        NSDictionary *definitionDict = [params objectForKey:PARAMS_URLS];
        mediaUrls = [self getUrlsFromDefinitionDictionary:definitionDict];
        isDefinition = YES;
    }
    
    NSString *title = [params objectForKey:PARAMS_TITLE];
    BOOL shouldSpeed = [[params objectForKey:PARAMS_ALLOW_SEEK] boolValue];
    NSInteger seekTo = [[params objectForKey:PARAMS_SEEK_TO] integerValue];
    [self parseOptions:[params objectForKey:PARAMS_OPTIONS] type:type];
    
    [self startPlayer:mediaUrls shouldSpeed:shouldSpeed seekTo:seekTo isDefinition:isDefinition title:title];
}

- (NSArray *)getUrlsFromDefinitionDictionary:(NSDictionary *)definitionDict {
    NSArray *videoTypes = @[VIDEO_TYPE_QVGA,VIDEO_TYPE_VGA,VIDEO_TYPE_HD];
    NSMutableArray *results = [NSMutableArray array];
    // QVGA VGA HD
    for(int i = 0; i < 3; i++) {
        if([definitionDict objectForKey: videoTypes[i]]) {
            [results addObject:[definitionDict objectForKey: videoTypes[i]]];
        } else {
            [results addObject: @""];
        }
    }
    return results;
}

- (void)stop:(CDVInvokedUrlCommand *)command type:(NSString *)type {
    callbackId = command.callbackId;
    if (moviePlayer) {
        [moviePlayer stop];
    }
}

- (void)playVideo:(CDVInvokedUrlCommand *)command {
    [self play:command type:[NSString stringWithString:TYPE_VIDEO]];
}

- (void)playVideoWithMultiDefinition:(CDVInvokedUrlCommand *)command {
    [self play:command type:[NSString stringWithString:TYPE_VIDEO_DEFINITION]];
}

- (void)playAudio:(CDVInvokedUrlCommand *)command {
    callbackId = command.callbackId;
    
    NSDictionary *params = [command.arguments objectAtIndex:0];
    
    NSArray *mediaUrl = @[[params objectForKey:PARAMS_URLS]];
    NSString *title = [params objectForKey:PARAMS_TITLE];
    [self parseOptions:[params objectForKey:PARAMS_OPTIONS] type:TYPE_AUDIO];
    
    [self startPlayer:mediaUrl shouldSpeed:YES seekTo:0 isDefinition:NO title:title];
}

- (void)stopAudio:(CDVInvokedUrlCommand *)command {
    [self stop:command type:[NSString stringWithString:TYPE_AUDIO]];
}

- (void)setBackgroundColor:(NSString *)color {
    if ([color hasPrefix:@"#"]) {
        // HEX value
        unsigned rgbValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:color];
        [scanner setScanLocation:1]; // bypass '#' character
        [scanner scanHexInt:&rgbValue];
        backgroundColor = [UIColor colorWithRed:((float) ((rgbValue & 0xFF0000) >> 16)) / 255.0 green:((float) ((rgbValue & 0xFF00) >> 8)) / 255.0 blue:((float) (rgbValue & 0xFF)) / 255.0 alpha:1.0];
    } else {
        // Color name
        NSString *selectorString = [[color lowercaseString] stringByAppendingString:@"Color"];
        SEL selector = NSSelectorFromString(selectorString);
        UIColor *colorObj = [UIColor blackColor];
        if ([UIColor respondsToSelector:selector]) {
            colorObj = [UIColor performSelector:selector];
        }
        backgroundColor = colorObj;
    }
}

- (UIImage *)getImage:(NSString *)imageName {
    UIImage *image = nil;
    if (imageName != (id) [NSNull null]) {
        if ([imageName hasPrefix:@"http"]) {
            // Web image
            image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageName]]];
        } else if ([imageName hasPrefix:@"www/"]) {
            // Asset image
            image = [UIImage imageNamed:imageName];
        } else if ([imageName hasPrefix:@"file://"]) {
            // Stored image
            image = [UIImage imageWithData:[NSData dataWithContentsOfFile:[[NSURL URLWithString:imageName] path]]];
        } else if ([imageName hasPrefix:@"data:"]) {
            // base64 encoded string
            NSURL *imageURL = [NSURL URLWithString:imageName];
            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
            image = [UIImage imageWithData:imageData];
        } else {
            // explicit path
            image = [UIImage imageWithData:[NSData dataWithContentsOfFile:imageName]];
        }
    }
    return image;
}

- (void)orientationChanged:(NSNotification *)notification {
    if (imageView != nil) {
        // adjust imageView for rotation
        imageView.bounds = moviePlayer.backgroundView.bounds;
        imageView.frame = moviePlayer.backgroundView.frame;
    }
}

- (void)setImage:(NSString *)imagePath withScaleType:(NSString *)imageScaleType {
    imageView = [[UIImageView alloc] initWithFrame:self.viewController.view.bounds];
    if (imageScaleType == nil) {
        NSLog(@"imagescaletype was NIL");
        imageScaleType = DEFAULT_IMAGE_SCALE;
    }
    if ([imageScaleType isEqualToString:@"stretch"]) {
        // Stretches image to fill all available background space, disregarding aspect ratio
        imageView.contentMode = UIViewContentModeScaleToFill;
        moviePlayer.backgroundView.contentMode = UIViewContentModeScaleToFill;
    } else if ([imageScaleType isEqualToString:@"fit"]) {
        // Stretches image to fill all possible space while retaining aspect ratio
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        moviePlayer.backgroundView.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        // Places image in the center of the screen
        imageView.contentMode = UIViewContentModeCenter;
        moviePlayer.backgroundView.contentMode = UIViewContentModeCenter;
    }

    [imageView setImage:[self getImage:imagePath]];
}

- (void)startPlayer:(NSArray *)urls shouldSpeed:(BOOL)shouldSpeed seekTo:(NSInteger)seekTo isDefinition:(BOOL)isDefinition title:(NSString *)title{
    CustomMediaPlayerViewController *playerViewController = [[CustomMediaPlayerViewController alloc] initWithNibName:@"CustomMediaPlayerViewController" bundle:nil];
    playerViewController.movieUrls = urls;
    playerViewController.shouldSpeed = shouldSpeed;
    playerViewController.seekTo = seekTo;
    playerViewController.isDefinitionSource = isDefinition;
    playerViewController.mediaTitle = title;
    playerViewController.delegate = self;
    [self.viewController presentViewController:playerViewController animated:NO completion:^{
    }];
    //[self setOrientation];
}

- (void)setOrientation {
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = UIInterfaceOrientationLandscapeRight;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

- (void)reSetOrientation {
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = UIInterfaceOrientationPortrait;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}


#pragma mark - CustomMediaPlayerViewControllerDelegate

- (void)sendSuccessCallbackWithType:(NSString *)type time:(CGFloat)time {
    NSNumber *timeNumber = [NSNumber numberWithFloat:time];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"type": type, @"currentTime": timeNumber}];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)playAtTime:(CGFloat)time {
    [self sendSuccessCallbackWithType:CALLBACK_PLAY time:time];
}

- (void)pauseAtTime:(CGFloat)time {
    [self sendSuccessCallbackWithType:CALLBACK_PAUSE time:time];
}

- (void)beginSeekingAtTime:(CGFloat)time {
    [self sendSuccessCallbackWithType:CALLBACK_SEEKING time:time];
}

- (void)endSeekingAtTime:(CGFloat)time {
    [self sendSuccessCallbackWithType:CALLBACK_SEEKED time:time];
}

- (void)eachChangeAtTime:(CGFloat)time {
    [self sendSuccessCallbackWithType:CALLBACK_EACH time:time];
}

- (void)destroyAtTime:(CGFloat)time {
    [self sendSuccessCallbackWithType:CALLBACK_DESTROY time:time];
}

- (void)playFailed {
    NSString *errorMsg = @"Play failed";
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMsg];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)playFinished {
    [self sendSuccessCallbackWithType:CALLBACK_FINISHED time:0];
}

- (void)closeView {
    [self reSetOrientation];
}

@end
