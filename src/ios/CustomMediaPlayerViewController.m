//
//  CustomMediaPlayerViewController.m
//  video-demo
//
//  Created by Lei Huang
//
//

#import "CustomMediaPlayerViewController.h"
#import "CustomPlayerView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIView+Toast.h"
#import "CDVReachability.h"

#define NLSystemVersionGreaterOrEqualThan(version) ([[[UIDevice currentDevice] systemVersion] floatValue] >= version)
#define IOS7 NLSystemVersionGreaterOrEqualThan(7.0)


@interface CustomMediaPlayerViewController ()<CustomPlayerDelegate>

@property(weak, nonatomic) IBOutlet CustomPlayerView *customPlayerView;
@property(weak, nonatomic) IBOutlet UIView *navView;
@property(weak, nonatomic) IBOutlet UIView *bottomView;
@property(weak, nonatomic) IBOutlet UIView *itemSelectView;
@property(weak, nonatomic) IBOutlet UIView *itemDefiniationSelectView;


@property(weak, nonatomic) IBOutlet UIButton *playButton;
@property(weak, nonatomic) IBOutlet UIButton *sourceButton;
@property(weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property(weak, nonatomic) IBOutlet UILabel *durationLabel;
@property(weak, nonatomic) IBOutlet UISlider *movieProgressSlider;
@property(weak, nonatomic) IBOutlet UIProgressView *progressView;

@property(weak, nonatomic) IBOutlet UIView *activityBackView;
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property(weak, nonatomic) IBOutlet UIView *reminderView;
@property(weak, nonatomic) IBOutlet UILabel *reminderLabel;
@property(weak, nonatomic) IBOutlet UIImageView *playStyeimageView;
@property(weak, nonatomic) IBOutlet UILabel *mediaTitleLabel;

@property(assign, nonatomic) CGFloat totalMovieDuration;
@property(assign, nonatomic) CGFloat currentDuration;

@property(assign, nonatomic) BOOL showItem;
@property(assign, nonatomic) BOOL showCtrlView;
@property(assign, nonatomic) BOOL isPlaying;
@property(assign, nonatomic) NSInteger playingIndex;

@property(strong, nonatomic) NSMutableArray *itemButtons;

@property(strong, nonatomic) NSArray *videoDefinitionTypes;

@end

@implementation CustomMediaPlayerViewController


#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.videoDefinitionTypes = @[NSLocalizedString(@"VIDEO_QVGA", nil),NSLocalizedString(@"VIDEO_VGA", nil),NSLocalizedString(@"VIDEO_HD", nil)];
    
    if (self.movieUrls.count == 0) {
        
        if ([self.delegate respondsToSelector:@selector(playFailed)]) {
            [self.delegate playFailed];
        }
        
        [self closeViewController];
        return;
    }
    
    [self buildPlayerView];
    
    [self buildItemButtons];
    
    [self buildReminderView];
    
    [self buildMovieProgress];
    
    [self buildSourceButton];
    
    [self buildTapRecognizer];
    
    [self hiddenCtrlViewWithDelay:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [super viewWillAppear:animated];
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
    [self.customPlayerView.player play];
    if ([self.delegate respondsToSelector:@selector(playAtTime:)]) {
        [self.delegate playAtTime:self.currentDuration];
    }
    self.isPlaying = YES;
}

- (void)seekToLastWatchForTheFirstTime {
    if(self.seekTo != 0){
        CMTime seekTo = CMTimeMake(self.seekTo, 1);
        [self.customPlayerView.player seekToTime:seekTo toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:
         ^(BOOL finish) {
             [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
             [self.customPlayerView.player play];
             self.isPlaying = YES;
         }];
        self.seekTo = 0;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self removeObserverAndNotifationToPlayerItem:self.customPlayerView.player.currentItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    if ([self.delegate respondsToSelector:@selector(destroyAtTime:)]) {
        [self.delegate destroyAtTime:self.currentDuration];
    }
    self.delegate = nil;

    // release the player
    [self.customPlayerView.player replaceCurrentItemWithPlayerItem:nil];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}


#pragma mark - Build Views

- (void)buildPlayerView {
    NSString *videoPath = NULL;
    self.playingIndex = 0;
    if (self.isDefinitionSource) {
        for (NSInteger i=0; i<3; i++) {
            if ([self.movieUrls[i] length] > 0) {
                self.playingIndex = i;
                videoPath = self.movieUrls[i];
                break;
            }
        }
    }
    else {
        videoPath = self.movieUrls[0];
        self.playingIndex = 0;
    }
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:videoPath]];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    [self setObserverAndNotifationToPlayerItem:playerItem];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.customPlayerView.player];
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.customPlayerView setPlayer:player];
    self.customPlayerView.player.allowsExternalPlayback = YES;
    self.customPlayerView.delegate = self;
    self.mediaTitleLabel.text = self.mediaTitle;
    
    if (!IOS7) {
        //计算视频总时间
        CMTime totalTime = playerItem.duration;
        //因为slider的值是小数，要转成float，当前时间和总时间相除才能得到小数,因为5/10=0
        self.totalMovieDuration = (CGFloat) totalTime.value / totalTime.timescale;
        NSString *showtimeNew = [self formatTime:self.totalMovieDuration];
        //在totalTimeLabel上显示总时间
        self.durationLabel.text = showtimeNew;
    }
}

- (void)buildTapRecognizer {
    //轻触手势（单击，双击）
    UITapGestureRecognizer *oneTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(oneTap:)];
    oneTap.numberOfTapsRequired = 1;
    [self.customPlayerView addGestureRecognizer:oneTap];
}

- (void)buildItemButtons {
    
    if (!self.isDefinitionSource) {
        [self.itemDefiniationSelectView removeFromSuperview];
        
        self.itemButtons = [NSMutableArray array];
        NSInteger baseButtonTag = 1000;
        NSArray *buttonsArray = self.itemSelectView.subviews;
        [buttonsArray enumerateObjectsUsingBlock:^(UIButton *obj, NSUInteger idx, BOOL *stop) {
            [self setItemButtonStyle:obj withBorder:YES];
            if (obj.tag - baseButtonTag <= self.movieUrls.count) {
                [self.itemButtons addObject:obj];
                if (obj.tag == baseButtonTag +1) {
                    obj.selected = YES;
                }
            } else {
                obj.hidden = YES;
            }
        }];
    } else {
        [self.itemSelectView removeFromSuperview];
        
        self.itemButtons = [NSMutableArray array];
        NSInteger baseButtonTag = 2000;
        NSArray *buttonsArray = self.itemDefiniationSelectView.subviews;
        
        buttonsArray = [buttonsArray sortedArrayUsingComparator:^NSComparisonResult(UIButton *obj1, UIButton *obj2) {
        NSComparisonResult result = [[NSNumber numberWithInteger:obj1.tag] compare:[NSNumber numberWithInteger:obj2.tag]];
            return result == NSOrderedDescending; // 升序
        }];
        
        [buttonsArray enumerateObjectsUsingBlock:^(UIButton *obj, NSUInteger idx, BOOL *stop) {
            [self setItemButtonStyle:obj withBorder:NO];
            if (obj.tag - baseButtonTag <= self.movieUrls.count) {
                [obj setTitle:self.videoDefinitionTypes[idx] forState:UIControlStateNormal];
                
                if ([self.movieUrls[idx] length] == 0) {
                    obj.enabled = NO;
                }
                
                [self.itemButtons addObject:obj];
                
                if (obj.tag == baseButtonTag + self.playingIndex + 1) {
                    obj.selected = YES;
                }
            } else {
                obj.hidden = YES;
            }
        }];
    }
}

- (void)setSourceButtonTitle:(NSString *)title {
    NSString *buttonTitle = [NSString stringWithFormat:@"   %@",title];
    [self.sourceButton setTitle:buttonTitle forState:UIControlStateNormal];
}

- (void)buildSourceButton {
    NSString *buttonTitle = [NSString stringWithFormat:@"   %@",NSLocalizedString(@"VIDEO_SOURCES", nil)];
    if (self.isDefinitionSource) {
        buttonTitle = [NSString stringWithFormat:@"   %@",self.videoDefinitionTypes[self.playingIndex]];
    }
    [self.sourceButton setTitle:buttonTitle forState:UIControlStateNormal];
    self.showItem = NO;
}

- (void)buildReminderView {
    CALayer *lay = self.reminderView.layer;
    [lay setMasksToBounds:YES];
    [lay setCornerRadius:10];
    self.reminderView.hidden = YES;
    
    CALayer *activityLayer = self.activityBackView.layer;
    [activityLayer setMasksToBounds:YES];
    [activityLayer setCornerRadius:5];
    self.activityBackView.hidden = YES;
    
}

- (void)buildMovieProgress {
    //self.movieProgressSlider.userInteractionEnabled = self.shouldSpeed;
    self.movieProgressSlider.value = 0;
    [self shouldShowAcitvityView:YES];
    //使用movieProgressSlider反应视频播放的进度
    __weak __typeof(&*self) weakSelf = self;
    [self.customPlayerView.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        //获取当前时间
        CMTime currentTime = weakSelf.customPlayerView.player.currentItem.currentTime;
        //转成秒数
        CGFloat currentPlayTime = (CGFloat) currentTime.value / currentTime.timescale;
        weakSelf.movieProgressSlider.value = currentPlayTime / weakSelf.totalMovieDuration;
        self.currentProgress = weakSelf.movieProgressSlider.value;
        NSString *showtime = [self formatTime:currentPlayTime];
        weakSelf.currentTimeLabel.text = showtime;
        
        //[self shouldShowAcitvityView:NO];
        if ([self.delegate respondsToSelector:@selector(eachChangeAtTime:)]) {
            [self.delegate eachChangeAtTime:currentPlayTime];
        }
        
        if(![self isConnectionAvailable]) {
            [self.customPlayerView makeToast:NSLocalizedString(@"NETWORK_FAIL_TOAST", nil)];
        }
    }];
    
    
    self.progressView.progressTintColor = [UIColor whiteColor];
    self.progressView.trackTintColor = [UIColor clearColor];
    [self.progressView setProgress:0 animated:NO];
    
    //左右轨的图片
    [self.movieProgressSlider setMinimumTrackTintColor:[UIColor colorWithRed:37/255.0 green:231/255.0 blue:232/255.0 alpha:1]];
    [self.movieProgressSlider setMaximumTrackTintColor:[UIColor clearColor]];
    //滑块图片
    UIImage *thumbImage = [UIImage imageNamed:@"ic_progress_button.png"];
    self.movieProgressSlider.backgroundColor = [UIColor clearColor];
    //注意这里要加UIControlStateHightlighted的状态，否则当拖动滑块时滑块将变成原生的控件
    [self.movieProgressSlider setThumbImage:thumbImage forState:UIControlStateHighlighted];
    [self.movieProgressSlider setThumbImage:thumbImage forState:UIControlStateNormal];
    [self.movieProgressSlider addTarget:self action:@selector(scrubbingDidBegin) forControlEvents:UIControlEventTouchDown];
    [self.movieProgressSlider addTarget:self action:@selector(scrubberIsScrolling) forControlEvents:UIControlEventValueChanged];
    [self.movieProgressSlider addTarget:self action:@selector(scrubbingDidEnd) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchCancel)];
}


#pragma mark - Button Action

- (void)setItemButtonStyle:(UIButton *)button withBorder:(BOOL)isBorder{

    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [button setTitleColor:[UIColor colorWithRed:37/255.0 green:231/255.0 blue:232/255.0 alpha:1] forState:UIControlStateSelected];
    if (isBorder) {
        self.itemSelectView.layer.borderColor = [UIColor colorWithRed:118/255.0 green:118/255.0 blue:118/255.0 alpha:1].CGColor;
        self.itemSelectView.layer.borderWidth = 1.f;
        button.layer.borderWidth = 0.5f;
        button.layer.borderColor = [UIColor colorWithRed:118/255.0 green:118/255.0 blue:118/255.0 alpha:1].CGColor;
    }
}


- (IBAction)backBtn:(id)sender {
    [self.customPlayerView.player pause];
    self.isPlaying = NO;
    [self closeViewController];
}

- (IBAction)playAndStopBtn:(id)sender {
    [self hiddenCtrlViewWithDelay:YES];
    [self setDuration];
    if (self.isPlaying == YES) {
        [self.customPlayerView.player pause];
        [self.playButton setImage:[UIImage imageNamed:@"ic_play"] forState:UIControlStateNormal];
        self.isPlaying = NO;
        
        if ([self.delegate respondsToSelector:@selector(pauseAtTime:)]) {
            [self.delegate pauseAtTime:self.currentDuration];
        }
    }
    else {
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
        [self.customPlayerView.player play];
        [self.playButton setImage:[UIImage imageNamed:@"ic_pause"] forState:UIControlStateNormal];
        self.isPlaying = YES;
        
        if ([self.delegate respondsToSelector:@selector(playAtTime:)]) {
            [self.delegate playAtTime:self.currentDuration];
        }
    }
}

- (void)oneTap:(UITapGestureRecognizer *)sender {
    self.showCtrlView = !self.showCtrlView;
}

- (IBAction)pressShowItemButton:(id)sender {
    [self hiddenCtrlViewWithDelay:YES];
    UIButton *button = (UIButton *)sender;
    button.selected = YES;
    self.showItem = !self.showItem;
}

- (IBAction)pressItemButton:(id)sender{
    UIButton *button = (UIButton *)sender;
    [self selectAItemButton:button];
    NSInteger index = 0;
    if (self.isDefinitionSource) {
        index = button.tag - 2001;
        [self setSourceButtonTitle:self.videoDefinitionTypes[index]];
    }else {
        index = button.titleLabel.text.integerValue - 1;
    }
    if (index >= self.movieUrls.count || [self.movieUrls[index] length] == 0 || self.playingIndex == index) {
        return;
    }
    [self playItemWithIndex:index];
    self.itemDefiniationSelectView.hidden = YES;
    self.showItem = NO;
}

- (void)selectAItemButton:(UIButton *)button {
    [self.itemButtons enumerateObjectsUsingBlock:^(UIButton *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.selected = [button isEqual:obj];
    }];
}




#pragma mark - Method

- (NSString *)formatTime:(CGFloat)time {
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (time / 3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    }
    else {
        [formatter setDateFormat:@"mm:ss"];
    }
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    return [formatter stringFromDate:d];
}

- (void)setShowItem:(BOOL)showItem {
    _showItem = showItem;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5f];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    self.itemSelectView.hidden = !showItem;
    self.itemDefiniationSelectView.hidden = !showItem;
    UIImage *image = showItem? [UIImage imageNamed:@"ic_source_selected.png"] : [UIImage imageNamed:@"ic_source.png"];
    UIColor *color = showItem ? [UIColor colorWithRed:37/255.0 green:231/255.0 blue:232/255.0 alpha:1] : [UIColor whiteColor];
    [self.sourceButton setImage:image forState:UIControlStateNormal];
    [self.sourceButton setTitleColor:color forState:UIControlStateNormal];
    [UIView commitAnimations];
}

- (void)setShowCtrlView:(BOOL)showCtrlView {
    _showCtrlView = showCtrlView;
    if (showCtrlView) {
        [self hiddenCtrlViewWithDelay:YES];
    }
    self.navView.hidden = !showCtrlView;
    self.bottomView.hidden = !showCtrlView;
    if (showCtrlView && self.showItem) {
        self.itemSelectView.hidden = NO;
        self.itemDefiniationSelectView.hidden = NO;
    } else {
        self.itemSelectView.hidden = YES;
        self.itemDefiniationSelectView.hidden = YES;
    }
}

- (void)playItemWithIndex:(NSInteger)index{
    [self setDuration];
    [self removeObserverAndNotifationToPlayerItem:self.customPlayerView.player.currentItem];
    self.playingIndex = index;
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.movieUrls[index]]];
    [self.customPlayerView.player replaceCurrentItemWithPlayerItem:playerItem];
    [self setObserverAndNotifationToPlayerItem:self.customPlayerView.player.currentItem];
    
    [self playWithTime:self.currentDuration];
}

- (void)setDuration {
    CMTime currentTime = self.customPlayerView.player.currentItem.currentTime;
    self.currentDuration = (CGFloat) currentTime.value / currentTime.timescale;
}

- (void)speedWithTime:(NSInteger)time {
    CGFloat newTime = self.currentDuration + time;
    if (newTime >= self.totalMovieDuration) {
        return;
    }
    [self playWithTime:newTime];
}

- (void)playWithTime:(CGFloat)newTime {
    //转换成CMTime才能给player来控制播放进度
    CMTime dragedCMTime = CMTimeMake(newTime, 1);
    [self shouldShowAcitvityView:YES];
    
    [self.customPlayerView.player seekToTime:dragedCMTime completionHandler:
     ^(BOOL finish) {
         [self shouldShowAcitvityView:NO];
     }];
    self.isPlaying = YES;
}

// 加载进度
- (float)availableDuration {
    NSArray *loadedTimeRanges = [[self.customPlayerView.player currentItem] loadedTimeRanges];
    if ([loadedTimeRanges count] > 0) {
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        return (startSeconds + durationSeconds);
    } else {
        return 0.0f;
    }
}

// 按动滑块
- (void)scrubbingDidBegin {
//    [self.customPlayerView.player pause];
}

// 进度调整
- (void)scrubberIsScrolling {
    
    if (!self.shouldSpeed && (self.movieProgressSlider.value > self.currentProgress)) {
        self.movieProgressSlider.value = self.currentProgress;
        [self.customPlayerView makeToast:NSLocalizedString(@"UNSEEKABLE_TOAST", nil)];
        return;
    }
    
    double currentTime = floor(self.totalMovieDuration * self.movieProgressSlider.value);
    //转换成CMTime才能给player来控制播放进度
    CMTime dragedCMTime = CMTimeMake(currentTime, 1);
    [self.customPlayerView.player seekToTime:dragedCMTime completionHandler:
     ^(BOOL finish) {
         [self shouldShowAcitvityView:NO];
     }];
}

- (void)scrubbingDidEnd {
//    [self shouldShowAcitvityView:YES];
}

- (void)shouldShowAcitvityView:(BOOL)shouldShow {
    self.activityBackView.hidden = !shouldShow;
    shouldShow ? [self.activityIndicatorView startAnimating] : [self.activityIndicatorView stopAnimating];
}

- (void)hideReminderView {
    self.reminderView.hidden = YES;
}

- (void)closeViewController {
    if ([self.delegate respondsToSelector:@selector(closeView)]) {
        [self.delegate closeView];
    }
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)hiddenCtrlViewWithDelay:(BOOL)isDelay {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setShowCtrlView:) object:[NSNumber numberWithBool:NO]];
    if (isDelay) {
        [self performSelector:@selector(setShowCtrlView:) withObject:[NSNumber numberWithBool:NO] afterDelay:5.0f];
    } else {
        self.showCtrlView = NO;
    }
}

#pragma mark - NSNotification & Observer handler


- (void)setObserverAndNotifationToPlayerItem:(AVPlayerItem *)playerItem {
    //检测视频加载状态，加载完成隐藏风火轮
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    //添加视频播放完成的notifation
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayFailed:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
}

- (void)removeObserverAndNotifationToPlayerItem:(AVPlayerItem *)playerItem {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
    
    //释放掉对playItem的观察
    [playerItem removeObserver:self
                    forKeyPath:@"status"
                       context:nil];
    [playerItem removeObserver:self
                    forKeyPath:@"loadedTimeRanges"
                       context:nil];
    [playerItem removeObserver:self
                    forKeyPath:@"playbackBufferEmpty"
                       context:nil];
    [playerItem removeObserver:self
                    forKeyPath:@"playbackLikelyToKeepUp"
                       context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *) object;
    
    if ([keyPath isEqualToString:@"status"]) {
        if (playerItem.status == AVPlayerStatusReadyToPlay) {
            //视频加载完成
            //[self shouldShowAcitvityView:NO];
            if (IOS7) {
                //计算视频总时间
                CMTime totalTime = playerItem.duration;
                self.totalMovieDuration = (CGFloat) totalTime.value / totalTime.timescale;
                NSDate *d = [NSDate dateWithTimeIntervalSince1970:self.totalMovieDuration];
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                if (self.totalMovieDuration / 3600 >= 1) {
                    [formatter setDateFormat:@"HH:mm:ss"];
                }
                else {
                    [formatter setDateFormat:@"mm:ss"];
                }
                formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
                NSString *showtimeNew = [formatter stringFromDate:d];
                self.durationLabel.text = showtimeNew;
            }

            [self seekToLastWatchForTheFirstTime];
        }
    }
    
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        float bufferTime = [self availableDuration];
        float durationTime = CMTimeGetSeconds([[self.customPlayerView.player currentItem] duration]);
        [self.progressView setProgress:bufferTime / durationTime animated:YES];
    }
    
    if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        if (playerItem.playbackBufferEmpty) {
            [self shouldShowAcitvityView:YES];
        }
    }
    if (object == playerItem && [keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        if (playerItem.playbackLikelyToKeepUp){
            [self shouldShowAcitvityView:NO];
        }
    }
}

- (void)moviePlayDidEnd:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(playFinished)]) {
        [self.delegate playFinished];
    }
    [self.customPlayerView.player pause];
    [self.playButton setImage:[UIImage imageNamed:@"ic_play"] forState:UIControlStateNormal];
    self.isPlaying = NO;

    if ([self.delegate respondsToSelector:@selector(pauseAtTime:)]) {
        [self.delegate pauseAtTime:self.currentDuration];
    }

    [self.customPlayerView.player seekToTime:CMTimeMake(0, 1)];
}

- (void)moviePlayFailed:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(playFailed)]) {
        [self.delegate playFailed];
    }
    [self performSelectorOnMainThread:@selector(closeViewController) withObject:nil waitUntilDone:YES];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    self.isPlaying = NO;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
    [self.customPlayerView.player play];
    self.isPlaying = YES;
}


#pragma mark - CustomPlayerDelegate

- (void)startChangePoint {
//    [self.customPlayerView.player pause];
    [self setDuration];
    
    if ([self.delegate respondsToSelector:@selector(beginSeekingAtTime:)]) {
        [self.delegate beginSeekingAtTime:self.currentDuration];
    }
}

- (void)willChangeToPoint:(CGFloat)point {
    if (!self.shouldSpeed && point > 0) {
        [self.customPlayerView makeToast:NSLocalizedString(@"UNSEEKABLE_TOAST", nil)];
        return;
    }
    float durationTime = CMTimeGetSeconds([[self.customPlayerView.player currentItem] duration]);
    if (isnan(durationTime)) { durationTime = 0; }
    CGFloat newTime = self.currentDuration + point * durationTime / 2;
    if (newTime <= 0) {
        newTime = 0;
        self.playStyeimageView.image = point > 0 ? [UIImage imageNamed:@"ic_speed.png"] : [UIImage imageNamed:@"ic_retreat.png"];
    } else {
        self.playStyeimageView.image = newTime > self.currentDuration ? [UIImage imageNamed:@"ic_speed.png"] : [UIImage imageNamed:@"ic_retreat.png"];
    }
    self.reminderView.hidden = NO;
    self.reminderLabel.text = [self formatTime:newTime];
    self.movieProgressSlider.value = newTime/self.totalMovieDuration;
}

- (void)didChangeToPoint:(CGFloat)point {
    if (!self.shouldSpeed && point > 0) {
        if ([self.delegate respondsToSelector:@selector(endSeekingAtTime:)]) {
            [self.delegate endSeekingAtTime:self.currentDuration];
        }
        return;
    }
    float durationTime = CMTimeGetSeconds([[self.customPlayerView.player currentItem] duration]);
    if (isnan(durationTime)) { durationTime = 0; }
    [self speedWithTime:point * durationTime / 2];
    [self hideReminderView];
//    [self shouldShowAcitvityView:YES];
    
    if ([self.delegate respondsToSelector:@selector(endSeekingAtTime:)]) {
        [self.delegate endSeekingAtTime:durationTime];
    }
}

-(BOOL) isConnectionAvailable{
    
    BOOL isExistenceNetwork = YES;
    CDVReachability *reach = [CDVReachability reachabilityWithHostName:@"www.baidu.com"];
    switch ([reach currentReachabilityStatus]) {
        case NotReachable:
            isExistenceNetwork = NO;
            //NSLog(@"notReachable");
            break;
        case ReachableViaWiFi:
            isExistenceNetwork = YES;
            //NSLog(@"WIFI");
            break;
        case ReachableViaWWAN:
            isExistenceNetwork = YES;
            //NSLog(@"3G");
            break;
    }
    
    return isExistenceNetwork;
}

@end
