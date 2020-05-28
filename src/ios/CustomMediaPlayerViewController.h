//
//  CustomMediaPlayerViewController.h
//  video-demo
//
//  Created by Lei Huang
//
//

#import <UIKit/UIKit.h>

@protocol CustomMediaPlayerViewControllerDelegate <NSObject>

- (void)playAtTime:(CGFloat)time;
- (void)pauseAtTime:(CGFloat)time;
- (void)beginSeekingAtTime:(CGFloat)time;
- (void)endSeekingAtTime:(CGFloat)time;
- (void)eachChangeAtTime:(CGFloat)time;
- (void)destroyAtTime:(CGFloat)time;
- (void)playFailed;
- (void)playFinished;
- (void)closeView;
@end
@interface CustomMediaPlayerViewController : UIViewController
@property(strong, nonatomic) NSArray *movieUrls;
@property(assign, nonatomic) BOOL shouldSpeed;
@property(assign, nonatomic) NSInteger seekTo;
@property(assign, nonatomic) float currentProgress;
@property(assign, nonatomic) BOOL isDefinitionSource;
@property(assign, nonatomic) NSString *mediaTitle;
@property(nonatomic, assign) id <CustomMediaPlayerViewControllerDelegate> delegate;
@end
