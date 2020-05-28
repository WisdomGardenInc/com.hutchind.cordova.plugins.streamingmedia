#import "CustomPlayerView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface CustomPlayerView ()
@property(nonatomic, assign) CGFloat currVolume;
@property(nonatomic, assign) NSInteger touchType; //0 No Action 1,Volume 2,Speed 3 Disable
@end

@implementation CustomPlayerView
@synthesize delegate;

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *) [self layer] player];
}

- (void)setPlayer:(AVPlayer *)thePlayer {
    return [(AVPlayerLayer *) [self layer] setPlayer:thePlayer];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    MPMusicPlayerController *mpc = [MPMusicPlayerController applicationMusicPlayer];
    self.touchType = 0;
    self.currVolume = mpc.volume;

    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    self.x = (touchPoint.x);
    self.y = (touchPoint.y);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];

    if (self.touchType == 0) {
        if (fabs(touchPoint.y - self.y) > 30) {
            self.touchType = 1;
            return;
        }

        if (fabs(touchPoint.x - self.x) > 30) {
            self.touchType = 2;
            if ([self.delegate respondsToSelector:@selector(startChangePoint)]) {
                [self.delegate startChangePoint];
            }
        }
    }

    if (self.touchType == 1) {
        if (fabs(touchPoint.x - self.x) > self.bounds.size.width / 5) {
            self.touchType = 3;
            return;
        }

        MPMusicPlayerController *mpc = [MPMusicPlayerController applicationMusicPlayer];
        CGFloat tempVolume = fabs(touchPoint.y - self.y) / (self.bounds.size.height / 2);
        CGFloat volume;
        if (touchPoint.y > self.y) {
            //NSLog(@"减小音量");
            volume = self.currVolume - tempVolume;
            volume = volume < 0 ? 0 : volume;
        } else {
            //NSLog(@"增大音量");
            volume = self.currVolume + tempVolume;
            volume = volume > 1 ? 1 : volume;
        }

        mpc.volume = volume;
        return;
    }

    if (self.touchType == 2) {

//        if (fabs(touchPoint.y - self.y) > self.bounds.size.width / 5) {
//            self.touchType = 3;
//            return;
//        }
        CGFloat tempSpeed = (touchPoint.x - self.x) / (self.bounds.size.width);
        if ([self.delegate respondsToSelector:@selector(willChangeToPoint:)]) {
            [self.delegate willChangeToPoint:tempSpeed];
        }
        //NSLog(@"调整进度 %f", tempSpeed);
    }


}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    if (self.touchType == 2) {
        CGFloat tempSpeed = (touchPoint.x - self.x) / (self.bounds.size.width);
        if ([self.delegate respondsToSelector:@selector(didChangeToPoint:)]) {
            [self.delegate didChangeToPoint:tempSpeed];
        }
    }
}

@end
