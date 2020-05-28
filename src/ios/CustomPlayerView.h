#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol CustomPlayerDelegate <NSObject>

- (void)startChangePoint;
- (void)willChangeToPoint:(CGFloat)point;
- (void)didChangeToPoint:(CGFloat)point;
@end

@interface CustomPlayerView : UIView

@property(nonatomic, strong) AVPlayer *player;
@property(nonatomic, assign) float x;
@property(nonatomic, assign) float y;
@property(nonatomic, assign) id <CustomPlayerDelegate> delegate;

@end
