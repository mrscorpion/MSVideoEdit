//
//  ViewController.m
//  MSVideoEdit
//
//  Created by mr.scorpion on 16/5/19.
//  Copyright © 2016年 mr.scorpion. All rights reserved.
//

#import "ViewController.h"
#import "CommonDefine.h"
#import "ExportEffects.h" // 制作视频导出（保存到相册）
#import "UIAlertView+Blocks.h" // UIAlertView的分类 - 使用block回调
#import "PBJVideoPlayerController.h"  // 播放预览视频的控制器
#import "KGModal.h"  // 弹出视频预览视图的模型
#import "StickerView.h" // 贴纸view
#import "JGActionSheet.h" // 自定义底部弹出框 Action Sheet
#import <AssetsLibrary/AssetsLibrary.h>   // ALAuthorizationStatus
#import "DBPrivateHelperController.h" // 获取用户授权访问
#import "CaptureViewController.h"  // 录像，使用相机拍摄功能进行录制
#import "CMPopTipView.h"  // 提示条view
#import "SAVideoRangeSlider.h"
#import "NSString+Height.h"
#import "btSimpleSideMenu.h" // 侧边栏

#import <StoreKit/StoreKit.h> // 苹果APP Store上架应用

#define MaxVideoLength MAX_VIDEO_DUR  // 15.0f 短视频录制的最大时间为15秒
#define DemoVideoName @"Demo.mp4"

@interface ViewController ()
<
PBJVideoPlayerControllerDelegate,
SAVideoRangeSliderDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
BTSimpleSideMenuDelegate,
SKStoreProductViewControllerDelegate //APP Store
>
{
    CMPopTipView *_popTipView;
}
@property (nonatomic, copy) NSURL *videoPickURL; // 从相册挑选视频的URL
@property (nonatomic, strong) UIView *demoVideoContentView; // 演示视频Demo的view
@property (nonatomic, strong) PBJVideoPlayerController *demoVideoPlayerController; // 播放预览视频的控制器
@property (nonatomic, strong) PBJVideoPlayerController *videoPlayerController; // 播放制作好的视频的控制器
@property (nonatomic, strong) UIImageView *demoPlayButton; // 点击演示视频Demo的button
@property (nonatomic, strong) UIButton *closeVideoPlayerButton; // 点击关闭视频demo左上角的“X”小图标
@property (nonatomic, copy) NSString *audioPickFile; // 从系统默认提供的音乐列表中挑选的背景音频file路径
@property (nonatomic, assign) CFTimeInterval startTime; // 起始时间
@property (nonatomic, strong) UIScrollView *videoContentView; // 盛放制作视频的容器view
@property (nonatomic, strong) UIButton *videoView; // 点击挑选制作视频的button
@property (nonatomic, strong) UIScrollView *captureContentView; // 点击挑选制作视频的button背后的scrollview
@property (nonatomic, strong) UIView *parentView; // 视频父view
@property (nonatomic, strong) UIImageView *playButton; // 播放的imageView
// 侧边栏 menu side
@property (nonatomic, strong) NSMutableArray *gifArray; // 添加的GIF数组
@property (nonatomic, strong) SAVideoRangeSlider *videoRangeSlider; //
@property (nonatomic, strong) UILabel *videoRangeLabel; // 还不确定是？？
@property(nonatomic, strong) BTSimpleSideMenu *sideMenu; // 侧边栏

@property (nonatomic, strong) UIButton *demoButton; // 底部预览button
@end

@implementation ViewController
#pragma mark - Life Cycle
- (void)dealloc
{
    NSLog(@"dealloc");
    [self clearEmbeddedGifArray];
}
#pragma mark - Clear
- (void)clearEmbeddedGifArray
{
    [StickerView setActiveStickerView:nil];
    if (_gifArray && [_gifArray count] > 0)
    {
        for (StickerView *view in _gifArray)
        {
            [view removeFromSuperview];
        }
        [_gifArray removeAllObjects];
        _gifArray = nil;
    }
}
#pragma mark - Delete Temp Files 删除临时文件
- (void)deleteTempDirectory
{
    NSString *dir = NSTemporaryDirectory();
    deleteFilesAt(dir, @"mov");
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor orangeColor];
    // 数据初始化
    _videoPickURL = nil; // 从相册挑选视频的URL
    _gifArray = nil;  // 添加的GIF数组
    _startTime = 1.0f; // 起始时间
    // 创建导航栏
    [self createNavigationBar];
    [self createNavigationItem];
    [self createVideoView];
    // 创建推荐的APPView
    [self createRecommendAppView];
    // 创建侧边栏
    [self createSideMenu];
    
    // Hint
    NSInteger appRunCount = [self getAppRunCount], maxRunCount = 6;
    if (appRunCount < maxRunCount)
    {
        [self createPopTipView];
    }
    
    [self addAppRunCount];
    [self showVideoPlayView:NO];
    // Delete temp files 删除临时文件
    [self deleteTempDirectory];
    // Test in simulator
    //    [self setPickedVideo:getFileURL(getFilePath(DemoVideoName))];
}
#pragma mark - 导航栏
- (void)createNavigationBar
{
    // 设置字体
    NSString *fontName = GBLocalizedString(@"FontName"); // "迷你简启体"
    CGFloat fontSize = 20;
    // 设置阴影
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor lightTextColor]; //[UIColor colorWithRed:0 green:0.7 blue:0.8 alpha:1];
    shadow.shadowBlurRadius = 0.5;
    shadow.shadowOffset = CGSizeMake(2, -1);
    // 设置navigation的标题颜色，阴影，大小
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor blackColor], NSForegroundColorAttributeName, shadow, NSShadowAttributeName, [UIFont fontWithName:fontName size:fontSize], NSFontAttributeName, nil]];
    // 标题："视频制作"
    self.title = GBLocalizedString(@"FunVideoCrop");
}
- (void)createNavigationItem
{
    // 设置字体
    NSString *fontName = GBLocalizedString(@"FontName");
    CGFloat fontSize = 18;
    // 右侧：导出
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:GBLocalizedString(@"Export") style:UIBarButtonItemStylePlain target:self action:@selector(handleConvert)];
    [rightItem setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[UIFont fontWithName:fontName size:fontSize]} forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = rightItem;
    // 左侧：主题
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:GBLocalizedString(@"Theme") style:UIBarButtonItemStylePlain target:self action:@selector(handleVideoThemeButton:)];
    [leftItem setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[UIFont fontWithName:fontName size:fontSize]} forState:UIControlStateNormal];
    self.navigationItem.leftBarButtonItem = leftItem;
}
#pragma mark - 创建侧边栏
- (void)createSideMenu
{
    _sideMenu = [[BTSimpleSideMenu alloc]initWithItemTitles:@[GBLocalizedString(@"Lightning"), GBLocalizedString(@"Fart"), GBLocalizedString(@"Fork"), GBLocalizedString(@"Kiss"), GBLocalizedString(@"ShutUp"), GBLocalizedString(@"Dance"), GBLocalizedString(@"Love"), GBLocalizedString(@"SayHi")] andItemImages:@[
                                                      [UIImage imageNamed:@"Theme_1.gif"],
                                                      [UIImage imageNamed:@"Theme_2.gif"],
                                                      [UIImage imageNamed:@"Theme_3.gif"],
                                                      [UIImage imageNamed:@"Theme_4.gif"],
                                                      [UIImage imageNamed:@"Theme_5.gif"],
                                                      [UIImage imageNamed:@"Theme_6.gif"],
                                                      [UIImage imageNamed:@"Theme_7.gif"],
                                                      [UIImage imageNamed:@"Theme_8.gif"],
                                                      ]  addToViewController:self];
    _sideMenu.delegate = self;
}
#pragma mark - 创建引导指引文字
- (void)createPopTipView
{
    NSArray *colorSchemes = [NSArray arrayWithObjects:
                             [NSArray arrayWithObjects:[NSNull null], [NSNull null], nil],
                             [NSArray arrayWithObjects:[UIColor colorWithRed:134.0/255.0 green:74.0/255.0 blue:110.0/255.0 alpha:1.0], [NSNull null], nil],
                             [NSArray arrayWithObjects:[UIColor darkGrayColor], [NSNull null], nil],
                             [NSArray arrayWithObjects:[UIColor lightGrayColor], [UIColor darkTextColor], nil],
                             nil];
    NSArray *colorScheme = [colorSchemes objectAtIndex:foo4random()*[colorSchemes count]];
    UIColor *backgroundColor = [colorScheme objectAtIndex:0];
    UIColor *textColor = [colorScheme objectAtIndex:1];
    // 指示条：UsageHint 点击此处开始
    NSString *hint = GBLocalizedString(@"UsageHint");
    _popTipView = [[CMPopTipView alloc] initWithMessage:hint];
    if (backgroundColor && ![backgroundColor isEqual:[NSNull null]])
    {
        _popTipView.backgroundColor = backgroundColor;
    }
    if (textColor && ![textColor isEqual:[NSNull null]])
    {
        _popTipView.textColor = textColor;
    }
    _popTipView.animation = arc4random() % 2;
    _popTipView.has3DStyle = NO;
    _popTipView.dismissTapAnywhere = YES;
    [_popTipView autoDismissAnimated:YES atTimeInterval:5.0];
    [_popTipView presentPointingAtView:_playButton inView:_parentView animated:YES];
}
#pragma mark - 创建底部推荐AppButton
- (void)createRecommendAppView
{
    CGFloat statusBarHeight = 0; //iOS7AddStatusHeight;
    CGFloat navHeight = 0; //CGRectGetHeight(self.navigationController.navigationBar.bounds);
    CGFloat height = 30;
    UIView *recommendAppView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame) - height - navHeight - statusBarHeight, CGRectGetWidth(self.view.frame), height)];
    [recommendAppView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:recommendAppView];
    [self createRecommendAppButtons:recommendAppView];
    // Demo button
    CGFloat width = 60;
    _demoButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)/2 - width/2, CGRectGetHeight(self.view.frame) - width, width, width)];
    UIImage *image = [UIImage imageNamed:@"demo"];
    [_demoButton setImage:image forState:UIControlStateNormal];
    [_demoButton addTarget:self action:@selector(handleDemoButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_demoButton];
}
#pragma mark - Handle Event
- (void)handleDemoButton
{
    NSString *demoVideoPath = getFilePath(DemoVideoName);
    [self showDemoVideo:demoVideoPath];
}
#pragma mark - 视频制作view
- (void)createVideoView
{
    _parentView = [[UIView alloc] initWithFrame:self.view.bounds];
    _parentView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_parentView];
    // 添加视频制作容器view
    [self createContentView:_parentView];
//    [self createVideoPlayView:_parentView];
}
- (void)createContentView:(UIView *)parentView
{
    CGFloat statusBarHeight = 0; //iOS7AddStatusHeight;
    CGFloat navHeight = CGRectGetHeight(self.navigationController.navigationBar.bounds);
    CGFloat gap = 15, len = MIN((CGRectGetHeight(self.view.frame) - navHeight - statusBarHeight - 2*gap), (CGRectGetWidth(self.view.frame) - navHeight - statusBarHeight - 2*gap));
    // 点击挑选制作视频的button背后的scrollview
    _captureContentView =  [[UIScrollView alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.view.frame) - len/2, CGRectGetMidY(self.view.frame) - len/2, len, len)];
    [_captureContentView setBackgroundColor:[UIColor clearColor]];
    [parentView addSubview:_captureContentView];
    // 点击挑选视频的button （_videoView 是 UIButton）
    _videoView = [[UIButton alloc] initWithFrame:_captureContentView.frame];
    [_videoView setBackgroundColor:[UIColor clearColor]];
    _videoView.layer.cornerRadius = 5;
    _videoView.layer.masksToBounds = YES;
    _videoView.layer.borderWidth = 1.0;
    _videoView.layer.borderColor = [UIColor whiteColor].CGColor;
    UIImage *addFileImage = [UIImage imageNamed:@"Video_Add"];
    [_videoView setImage:addFileImage forState:UIControlStateNormal];
    [_videoView addTarget:self action:@selector(showCustomActionSheetByView:) forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:_videoView];
}
#pragma mark - Custom ActionSheet  自定义底部弹框 Action Sheet
// 自定义底部弹框 Action Sheet (选择背景视频 -- 拍摄 、 相册 、 取消)
- (void)showCustomActionSheetByView:(UIView *)anchor
{
    UIView *locationAnchor = anchor;
    NSString *videoTitle = [NSString stringWithFormat:@"%@", GBLocalizedString(@"SelectVideo")];
    JGActionSheetSection *sectionVideo = [JGActionSheetSection sectionWithTitle:videoTitle message:nil buttonTitles:@[GBLocalizedString(@"Camera"), GBLocalizedString(@"PhotoAlbum")] buttonStyle:JGActionSheetButtonStyleDefault];
    [sectionVideo setButtonStyle:JGActionSheetButtonStyleBlue forButtonAtIndex:0];
    [sectionVideo setButtonStyle:JGActionSheetButtonStyleBlue forButtonAtIndex:1];
    
    NSArray *sections = (iPad ? @[sectionVideo] : @[sectionVideo, [JGActionSheetSection sectionWithTitle:nil message:nil buttonTitles:@[GBLocalizedString(@"Cancel")] buttonStyle:JGActionSheetButtonStyleCancel]]);
    JGActionSheet *sheet = [[JGActionSheet alloc] initWithSections:sections];
    [sheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath)
     {
         NSLog(@"indexPath: %ld; section: %ld", (long)indexPath.row, (long)indexPath.section);
         if (indexPath.section == 0)
         {
             if (indexPath.row == 0)
             {
                 // Check permission for Video & Audio
                 [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted)
                  {
                      if (!granted)
                      {
                          [self performSelectorOnMainThread:@selector(popupAlertView) withObject:nil waitUntilDone:YES];
                          return;
                      }
                      else
                      {
                          [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted)
                           {
                               if (!granted)
                               {
                                   [self performSelectorOnMainThread:@selector(popupAuthorizationHelper:) withObject:[NSNumber numberWithLong:DBPrivacyTypeCamera] waitUntilDone:YES];
                                   return;
                               }
                               else
                               {
                                   // Has permisstion 使用相机拍摄
                                   [self performSelectorOnMainThread:@selector(pickBackgroundVideoFromCamera) withObject:nil waitUntilDone:NO];
                               }
                           }];
                      }
                  }];
             }
             else if (indexPath.row == 1)
             {
                 // Check permisstion for photo album
                 // 询问并获得用户授权访问相册和相机
                 ALAuthorizationStatus authStatus = [ALAssetsLibrary authorizationStatus];
                 if (authStatus == ALAuthorizationStatusRestricted || authStatus == ALAuthorizationStatusDenied) {
                     [self performSelectorOnMainThread:@selector(popupAuthorizationHelper:) withObject:[NSNumber numberWithLong:DBPrivacyTypePhoto] waitUntilDone:YES];
                     return;
                 } else {
                     // Has permisstion to execute
                     [self performSelector:@selector(pickBackgroundVideoFromPhotosAlbum) withObject:nil afterDelay:0.1];
                 }
             }
         }
         [sheet dismissAnimated:YES];
     }];
    
    if (iPad) {
        [sheet setOutsidePressBlock:^(JGActionSheet *sheet)
         {
             [sheet dismissAnimated:YES];
         }];
        
        CGPoint point = (CGPoint){ CGRectGetMidX(locationAnchor.bounds), CGRectGetMaxY(locationAnchor.bounds) };
        point = [self.navigationController.view convertPoint:point fromView:locationAnchor];
        
        [sheet showFromPoint:point inView:self.navigationController.view arrowDirection:JGActionSheetArrowDirectionTop animated:YES];
    } else {
        [sheet setOutsidePressBlock:^(JGActionSheet *sheet)
         {
             [sheet dismissAnimated:YES];
         }];
        [sheet showInView:self.navigationController.view animated:YES];
    }
}
#pragma mark - pickBackgroundVideoFromCamera  使用相机拍摄【点击“拍摄”】
- (void)pickBackgroundVideoFromCamera
{
    [self pickVideoFromCamera];
}
- (void)pickVideoFromCamera
{
    CaptureViewController *captureVC = [[CaptureViewController alloc] init];
    [captureVC setCallback:^(BOOL success, id result)
     {
         if (success) {
             NSURL *fileURL = result;
             // 检查所挑选的视频是否符合制作要求
             [self setPickedVideo:fileURL checkVideoLength:NO];
         } else {
             NSLog(@"Video Picker Failed: %@", result);
         }
     }];
    [self presentViewController:captureVC animated:YES completion:^{
        NSLog(@"PickVideo present");
    }];
}
#pragma mark - pickBackgroundVideoFromPhotosAlbum 选择视频
- (void)pickBackgroundVideoFromPhotosAlbum
{
    [self pickVideoFromPhotoAlbum];
}
- (void)pickVideoFromPhotoAlbum
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        // Only movie
        NSArray* availableMedia = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        picker.mediaTypes = [NSArray arrayWithObject:availableMedia[1]];
    }
    [self presentViewController:picker animated:YES completion:nil];
}




#pragma mark - Default Setting
- (void)defaultVideoSetting:(NSURL *)url
{
    [self showVideoPlayView:YES];
    [self playDemoVideo:[url absoluteString] withinVideoPlayerController:_videoPlayerController];
}
#pragma mark - NSUserDefaults
#pragma mark - AppRunCount
- (void)addAppRunCount
{
    NSUInteger appRunCount = [self getAppRunCount];
    NSInteger limitCount = 6;
    if (appRunCount < limitCount)
    {
        ++appRunCount;
        NSString *appRunCountKey = @"AppRunCount";
        NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
        [userDefaultes setInteger:appRunCount forKey:appRunCountKey];
        [userDefaultes synchronize];
    }
}
- (NSUInteger)getAppRunCount
{
    NSUInteger appRunCount = 0;
    NSString *appRunCountKey = @"AppRunCount";
    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
    if ([userDefaultes integerForKey:appRunCountKey])
    {
        appRunCount = [userDefaultes integerForKey:appRunCountKey];
    }
    NSLog(@"getAppRunCount: %lu", (unsigned long)appRunCount);
    return appRunCount;
}


#pragma mark - getNextStepCondition
// 下一步:如果视频路径不存在
- (BOOL)getNextStepRunCondition
{
    BOOL result = TRUE;
    if (!_videoPickURL)
    {
        result = FALSE;
    }
    return result;
}
/**
 *  “导出”操作 -- EXPORT
 */
- (void)handleConvert
{
    // 提示框：背景视频文件为空, 请先选择一个视频
    if (![self getNextStepRunCondition])
    {
        NSString *message = nil;
        message = GBLocalizedString(@"VideoIsEmptyHint");
        showAlertMessage(message, nil);
        return;
    }

    // 隐藏侧边栏 menu
//    [_sideMenu hide];
//    [StickerView setActiveStickerView:nil];
//    if (_gifArray && [_gifArray count] > 0)
//    {
//        for (StickerView *view in _gifArray)
//        {
//            [view setVideoContentRect:_videoContentView.frame];
//        }
//    }
    // 进度 提示 “正在处理...”
    ProgressBarShowLoading(GBLocalizedString(@"Processing"));
    // 导出操作
    [[ExportEffects sharedInstance] setExportProgressBlock: ^(NSNumber *percentage) {
        // Export progress 提示 “正在保存..."
        [self retrievingProgress:percentage title:GBLocalizedString(@"SavingVideo")];
    }];
    // 选择视频完成回调
    [[ExportEffects sharedInstance] setFinishVideoBlock: ^(BOOL success, id result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                ProgressBarDismissLoading(GBLocalizedString(@"Success"));
            } else {
                ProgressBarDismissLoading(GBLocalizedString(@"Failed"));
            }
            
            // Alert
            NSString *ok = GBLocalizedString(@"OK");
            [UIAlertView showWithTitle:nil message:result cancelButtonTitle:ok otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
              if (buttonIndex == [alertView cancelButtonIndex])
              {
                  NSLog(@"Alert Cancelled");
                  [NSThread sleepForTimeInterval:0.5];
                  // Demo result video
                  if (!isStringEmpty([ExportEffects sharedInstance].filenameBlock()))
                  {
                      // demo演示
                      NSString *outputPath = [ExportEffects sharedInstance].filenameBlock();
                      [self showDemoVideo:outputPath];
                  }
              }
          }];
            [self showVideoPlayView:TRUE];
        });
    }];
    // 将GIF动效添加到视频特定帧中
    [[ExportEffects sharedInstance] addEffectToVideo:[_videoPickURL relativePath] withAudioFilePath:getFilePath(_audioPickFile) withAniBeginTime:_startTime];
}
#pragma mark - Progress callback 进度条回调
- (void)retrievingProgress:(id)progress title:(NSString *)text
{
    if (progress && [progress isKindOfClass:[NSNumber class]])
    {
        NSString *title = text ?text :GBLocalizedString(@"SavingVideo");
        NSString *currentPrecentage = [NSString stringWithFormat:@"%d%%", (int)([progress floatValue] * 100)];
        ProgressBarUpdateLoading(title, currentPrecentage);
    }
}

- (void)handleVideoThemeButton:(UIBarButtonItem *)sender
{
//    if (![self getNextStepRunCondition])
//    {
//        NSString *message = nil;
//        message = GBLocalizedString(@"VideoIsEmptyHint");
//        showAlertMessage(message, nil);
//        return;
//    }
//    [self.view bringSubviewToFront:_sideMenu];
//    [_sideMenu toggleMenu];
}

#pragma mark - showDemoVideo  演示Demo
- (void)showDemoVideo:(NSString *)videoPath
{
    CGFloat statusBarHeight = iOS7AddStatusHeight;
    CGFloat navHeight = CGRectGetHeight(self.navigationController.navigationBar.bounds);
    CGSize size = [self reCalcVideoViewSize:videoPath];
    _demoVideoContentView =  [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.view.frame) - size.width/2, CGRectGetMidY(self.view.frame) - size.height/2 - navHeight - statusBarHeight, size.width, size.height)];
    [self.view addSubview:_demoVideoContentView];
    
    // Video player of destination
    _demoVideoPlayerController = [[PBJVideoPlayerController alloc] init];
    _demoVideoPlayerController.view.frame = _demoVideoContentView.bounds;
    _demoVideoPlayerController.view.clipsToBounds = YES;
    _demoVideoPlayerController.videoView.videoFillMode = AVLayerVideoGravityResizeAspect;
    _demoVideoPlayerController.delegate = self;
    //    _demoVideoPlayerController.playbackLoops = YES;
    [_demoVideoContentView addSubview:_demoVideoPlayerController.view];
    
    // 点击演示Demo的button
    _demoPlayButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play_button"]];
    _demoPlayButton.center = _demoVideoPlayerController.view.center;
    [_demoVideoPlayerController.view addSubview:_demoPlayButton];
    
    // Popup modal view
    [[KGModal sharedInstance] setCloseButtonType:KGModalCloseButtonTypeLeft];
    [[KGModal sharedInstance] showWithContentView:_demoVideoContentView andAnimated:YES];
    [self playDemoVideo:videoPath withinVideoPlayerController:_demoVideoPlayerController];
}
#pragma mark - playDemoVideo 播放demo视频
- (void)playDemoVideo:(NSString*)inputVideoPath withinVideoPlayerController:(PBJVideoPlayerController*)videoPlayerController
{
    dispatch_async(dispatch_get_main_queue(), ^{
        videoPlayerController.videoPath = inputVideoPath;
        [videoPlayerController playFromBeginning];
    });
}


#pragma mark - reCalc on the basis of video size & view size
- (void)adjustVideoRangeSlider:(BOOL)referVideoContentView
{
    CGFloat gap = 5;
    CGRect referRect = _videoContentView.frame;
    if (!referVideoContentView)
    {
        referRect = _captureContentView.frame;
    }
    _videoRangeLabel.frame = CGRectMake(CGRectGetMinX(_videoRangeLabel.frame), CGRectGetMinY(referRect) - gap - CGRectGetHeight(_videoRangeLabel.frame), CGRectGetWidth(_videoRangeLabel.frame), CGRectGetHeight(_videoRangeLabel.frame));
    _videoRangeSlider.frame = CGRectMake(CGRectGetMaxX(_videoRangeLabel.frame) + gap, CGRectGetMinY(_videoRangeLabel.frame), CGRectGetWidth(_videoRangeSlider.frame), CGRectGetHeight(_videoRangeSlider.frame));
}
#pragma mark - 视频 视图框尺寸
- (CGSize)reCalcVideoViewSize:(NSString *)videoPath
{
    CGSize resultSize = CGSizeZero;
    if (isStringEmpty(videoPath))
    {
        return resultSize;
    }
    
    UIImage *videoFrame = getImageFromVideoFrame(getFileURL(videoPath), kCMTimeZero);
    if (!videoFrame || videoFrame.size.height < 1 || videoFrame.size.width < 1)
    {
        return resultSize;
    }
    
    NSLog(@"reCalcVideoViewSize: %@, width: %f, height: %f", videoPath, videoFrame.size.width, videoFrame.size.height);
    
    CGFloat statusBarHeight = 0; //iOS7AddStatusHeight;
    CGFloat navHeight = 0; //CGRectGetHeight(self.navigationController.navigationBar.bounds);
    CGFloat gap = 15;
    CGFloat height = CGRectGetHeight(self.view.frame) - navHeight - statusBarHeight - 2*gap;
    CGFloat width = CGRectGetWidth(self.view.frame) - 2*gap;
    if (height < width)
    {
        width = height;
    }
    else if (height > width)
    {
        height = width;
    }
    CGFloat videoHeight = videoFrame.size.height, videoWidth = videoFrame.size.width;
    CGFloat scaleRatio = videoHeight/videoWidth;
    CGFloat resultHeight = 0, resultWidth = 0;
    if (videoHeight <= height && videoWidth <= width)
    {
        resultHeight = videoHeight;
        resultWidth = videoWidth;
    }
    else if (videoHeight <= height && videoWidth > width)
    {
        resultWidth = width;
        resultHeight = height*scaleRatio;
    }
    else if (videoHeight > height && videoWidth <= width)
    {
        resultHeight = height;
        resultWidth = width/scaleRatio;
    }
    else
    {
        if (videoHeight < videoWidth)
        {
            resultWidth = width;
            resultHeight = height*scaleRatio;
        }
        else if (videoHeight == videoWidth)
        {
            resultWidth = width;
            resultHeight = height;
        }
        else
        {
            resultHeight = height;
            resultWidth = width/scaleRatio;
        }
    }
    
    resultSize = CGSizeMake(resultWidth, resultHeight);
    return resultSize;
}
// 重新计算视频尺寸
- (void)reCalcVideoSize:(NSString *)videoPath
{
    CGFloat statusBarHeight = iOS7AddStatusHeight;
    CGFloat navHeight = 0; //CGRectGetHeight(self.navigationController.navigationBar.bounds);
    CGSize sizeVideo = [self reCalcVideoViewSize:videoPath];
    _videoContentView.frame =  CGRectMake(CGRectGetMidX(self.view.frame) - sizeVideo.width/2, CGRectGetMidY(self.view.frame) - sizeVideo.height/2 + statusBarHeight + navHeight, sizeVideo.width, sizeVideo.height);
    _videoPlayerController.view.frame = _videoContentView.bounds;
    // 播放的imageView
    _playButton.center = _videoPlayerController.view.center;
    _closeVideoPlayerButton.center = _videoContentView.frame.origin;
    if (_videoPickURL)
    {
        [self createVideoRangeSlider:_videoPickURL];
        [self adjustVideoRangeSlider:YES];
//        [self.view bringSubviewToFront:_sideMenu];
//        [_sideMenu show];
    }
}



#pragma mark - Show/Hide  显示和隐藏 视频预览播放
- (void)showVideoPlayView:(BOOL)show
{
    if (show) {
        _videoContentView.hidden = NO;  // 盛放视频的容器view
        _closeVideoPlayerButton.hidden = NO;
        _videoView.hidden = YES;
    } else {
        [self stopAllVideo];
        _videoView.hidden = NO;
        _videoContentView.hidden = YES;
        _closeVideoPlayerButton.hidden = YES;
    }
}
#pragma mark - StopAllVideo 停止所有视频的播放
- (void)stopAllVideo
{
    if (_videoPlayerController.playbackState == PBJVideoPlayerPlaybackStatePlaying)
    {
        [_videoPlayerController stop];
    }
}



#pragma mark - Authorization Helper 获取用户授权访问（相册和相机）
- (void)popupAlertView
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:GBLocalizedString(@"Private_Setting_Audio_Tips") delegate:nil cancelButtonTitle:GBLocalizedString(@"IKnow") otherButtonTitles:nil, nil];
    [alertView show];
}
- (void)popupAuthorizationHelper:(id)type
{
    DBPrivateHelperController *privateHelper = [DBPrivateHelperController helperForType:[type longValue]];
    privateHelper.snapshot = [self snapshot];
    privateHelper.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:privateHelper animated:YES completion:nil];
}
// 截屏 -- 生成快照（snapshot）
- (UIImage *)snapshot
{
    id <UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
    UIGraphicsBeginImageContextWithOptions(appDelegate.window.bounds.size, NO, appDelegate.window.screen.scale);
    [appDelegate.window drawViewHierarchyInRect:appDelegate.window.bounds afterScreenUpdates:NO];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshotImage;
}


#pragma mark - 侧边栏
// 创建slider
- (void)createVideoRangeSlider:(NSURL *)videoUrl
{
    [self clearVideoRangeSlider];
    CGFloat height = 45, width = 160, gap = 10;
    CGFloat fontHeight = 15;
    NSString *text = GBLocalizedString(@"Position");
    CGFloat labelWidth = [text maxWidthForText:text height:fontHeight font:[UIFont systemFontOfSize:fontHeight]];  // 最大的文字高度
    _videoRangeLabel = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMidX(_videoContentView.frame) - (width + gap + labelWidth)/2, CGRectGetMinY(_videoContentView.frame) - gap - height, labelWidth, height)];
    _videoRangeLabel.font = [UIFont systemFontOfSize:fontHeight];
    _videoRangeLabel.text = text;
    [self.view addSubview:_videoRangeLabel];
    
    _videoRangeSlider = [[SAVideoRangeSlider alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_videoRangeLabel.frame) + gap, CGRectGetMinY(_videoRangeLabel.frame), width, height) videoUrl:videoUrl];
    _videoRangeSlider.delegate = self;
    _videoRangeSlider.bubleText.font = [UIFont systemFontOfSize:12];
    [_videoRangeSlider setPopoverBubbleSize:120 height:60];
    _videoRangeSlider.minGap = 4;
    _videoRangeSlider.maxGap = 4;
    // Purple
    _videoRangeSlider.topBorder.backgroundColor = [UIColor colorWithRed: 0.768 green: 0.665 blue: 0.853 alpha: 1];
    _videoRangeSlider.bottomBorder.backgroundColor = [UIColor colorWithRed: 0.535 green: 0.329 blue: 0.707 alpha: 1];
    [self.view addSubview:_videoRangeSlider];
}
// 清除slider
- (void)clearVideoRangeSlider
{
    if (_videoRangeLabel)
    {
        [_videoRangeLabel removeFromSuperview];
        _videoRangeLabel = nil;
    }
    if (_videoRangeSlider)
    {
        [_videoRangeSlider removeFromSuperview];
        _videoRangeSlider = nil;
    }
}


#pragma mark - PBJVideoPlayerControllerDelegate
- (void)videoPlayerReady:(PBJVideoPlayerController *)videoPlayer
{
    //NSLog(@"Max duration of the video: %f", videoPlayer.maxDuration);
}
- (void)videoPlayerPlaybackStateDidChange:(PBJVideoPlayerController *)videoPlayer
{}
- (void)videoPlayerPlaybackWillStartFromBeginning:(PBJVideoPlayerController *)videoPlayer
{
    if (videoPlayer == _videoPlayerController)
    {
        _playButton.alpha = 1.0f;
        _playButton.hidden = NO;
        
        [UIView animateWithDuration:0.1f animations:^{
            _playButton.alpha = 0.0f;
        } completion:^(BOOL finished)
         {
             _playButton.hidden = YES;
         }];
    }
    else if (videoPlayer == _demoVideoPlayerController)
    {
        _demoPlayButton.alpha = 1.0f;
        _demoPlayButton.hidden = NO;
        [UIView animateWithDuration:0.1f animations:^{
            _demoPlayButton.alpha = 0.0f;
        } completion:^(BOOL finished)
         {
             _demoPlayButton.hidden = YES;
         }];
    }
}
- (void)videoPlayerPlaybackDidEnd:(PBJVideoPlayerController *)videoPlayer
{
    if (videoPlayer == _videoPlayerController)
    {
        _playButton.hidden = NO;
        [UIView animateWithDuration:0.1f animations:^{
            _playButton.alpha = 1.0f;
        } completion:^(BOOL finished) { }];
    } else if (videoPlayer == _demoVideoPlayerController) {
        _demoPlayButton.hidden = NO;
        [UIView animateWithDuration:0.1f animations:^{
            _demoPlayButton.alpha = 1.0f;
        } completion:^(BOOL finished) { }];
    }
}


#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // 1.
    [self dismissViewControllerAnimated:NO completion:nil];
    NSLog(@"info = %@",info);
    // 2.
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if([mediaType isEqualToString:@"public.movie"])
    {
        NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
        [self setPickedVideo:url];
    } else {
        NSLog(@"Error media type");
        return;
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:NO completion:nil];
}
- (void)setPickedVideo:(NSURL *)url
{
    [self setPickedVideo:url checkVideoLength:YES];
}
// 检查所挑选的视频是否符合制作要求
- (void)setPickedVideo:(NSURL *)url checkVideoLength:(BOOL)checkVideoLength
{
    if (!url || (url && ![url isFileURL]))
    {
        NSLog(@"Input video url is invalid.");
        return;
    }
    if (checkVideoLength)
    {
        // 获取视频总时长
        if (getVideoDuration(url) > MaxVideoLength)
        {
            NSString *ok = GBLocalizedString(@"OK");
            NSString *error = GBLocalizedString(@"Error");
            NSString *fileLenHint = GBLocalizedString(@"FileLenHint");
            NSString *seconds = GBLocalizedString(@"Seconds");
            NSString *hint = [fileLenHint stringByAppendingFormat:@" %.0f ", MaxVideoLength];
            hint = [hint stringByAppendingString:seconds];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:error message:hint delegate:nil cancelButtonTitle:ok otherButtonTitles: nil];
            [alert show];
            return;
        }
    }
    _videoPickURL = url;
    NSLog(@"Pick background video is success: %@", _videoPickURL);
    // 重新计算视频尺寸
    [self reCalcVideoSize:[url relativePath]];
    // Setting 默认视频设置
    [self defaultVideoSetting:url];
    // Hint to next step
    if ([self getAppRunCount] < 6 && [self getNextStepRunCondition])
    {
        if (_popTipView)
        {
            NSString *hint = GBLocalizedString(@"UsageNextHint"); // 下一步提示
            _popTipView.message = hint;
            [_popTipView autoDismissAnimated:YES atTimeInterval:5.0];
            [_popTipView presentPointingAtBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
        }
    }
}



#pragma mark - 侧边栏
#pragma mark - BTSimpleSideMenuDelegate
-(void)BTSimpleSideMenu:(BTSimpleSideMenu *)menu didSelectItemAtIndex:(NSInteger)index
{
    NSLog(@"Item Cliecked : %ld", (long)index);
    NSInteger styleIndex = index+1;
    [self initEmbededGifView:styleIndex];
    
    if (styleIndex != NSNotFound)
    {
        NSString *musicFile = [NSString stringWithFormat:@"Theme_%lu.m4a", (long)styleIndex];
        _audioPickFile = musicFile;
    }
    else
    {
        _audioPickFile = nil;
    }
    
    // Hint to next step
    if ([self getAppRunCount] < 6 && [self getNextStepRunCondition])
    {
        if (_popTipView)
        {
            NSString *hint = GBLocalizedString(@"UsageNextHint");
            _popTipView.message = hint;
            [_popTipView autoDismissAnimated:YES atTimeInterval:5.0];
            [_popTipView presentPointingAtBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
        }
    }
}
- (void)initEmbededGifView:(NSInteger)styleIndex
{
    // Only 1 embeds gif is supported now
    [self clearEmbeddedGifArray];
    
    NSString *imageName = [NSString stringWithFormat:@"Theme_%lu.gif", (long)styleIndex];
    StickerView *view = [[StickerView alloc] initWithFilePath:getFilePath(imageName)];
    CGFloat ratio = MIN( self.videoContentView.width / view.width, self.videoContentView.height / view.height);
    [view setScale:ratio];
    view.center = CGPointMake(self.videoContentView.width/2, self.videoContentView.height/2);
    [_videoContentView addSubview:view];
    
    [StickerView setActiveStickerView:view];
    
    if (!_gifArray)
    {
        _gifArray = [NSMutableArray arrayWithCapacity:1];
    }
    [_gifArray addObject:view];
    
    [view setDeleteFinishBlock:^(BOOL success, id result) {
        if (success)
        {
            if (_gifArray && [_gifArray count] > 0)
            {
                if ([_gifArray containsObject:result])
                {
                    [_gifArray removeObject:result];
                }
            }
        }
    }];
    
    [[ExportEffects sharedInstance] setGifArray:_gifArray];
}
- (void)BTSimpleSideMenu:(BTSimpleSideMenu *)menu selectedItemTitle:(NSString *)title
{
    NSLog(@"Menu Clicked, Item Title : %@", title);
}


#pragma mark - Touchs 点击屏幕隐藏侧边栏
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    // Deselect
    [StickerView setActiveStickerView:nil];
    [_sideMenu hide];
}
#pragma mark - 底部推荐的APP button
- (void)createRecommendAppButtons:(UIView *)containerView
{
    // Recommend App
    UIButton *beautyTime = [[UIButton alloc] init];
    [beautyTime setTitle:GBLocalizedString(@"BeautyTime")
                forState:UIControlStateNormal];
    
    UIButton *photoBeautify = [[UIButton alloc] init];
    [photoBeautify setTitle:GBLocalizedString(@"PhotoBeautify")
                   forState:UIControlStateNormal];
    
    [photoBeautify setTag:1];
    [beautyTime setTag:2];
    
    CGFloat gap = 0, height = 30, width = 80;
    CGFloat fontSize = 16;
    NSString *fontName = @"迷你简启体"; // GBLocalizedString(@"FontName");
    photoBeautify.frame =  CGRectMake(gap, gap, width, height);
    [photoBeautify.titleLabel setFont:[UIFont fontWithName:fontName size:fontSize]];
    [photoBeautify.titleLabel setTextAlignment:NSTextAlignmentLeft];
    [photoBeautify setTitleColor:kLightBlue forState:UIControlStateNormal];
    [photoBeautify addTarget:self action:@selector(recommendAppButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    beautyTime.frame =  CGRectMake(CGRectGetWidth(containerView.frame) - width - gap, gap, width, height);
    [beautyTime.titleLabel setFont:[UIFont fontWithName:fontName size:fontSize]];
    [beautyTime.titleLabel setTextAlignment:NSTextAlignmentRight];
    [beautyTime setTitleColor:kLightBlue forState:UIControlStateNormal];
    [beautyTime addTarget:self action:@selector(recommendAppButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [containerView addSubview:photoBeautify];
    [containerView addSubview:beautyTime];
}
- (void)recommendAppButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    switch (button.tag)
    {
        case 1:
        {
            // Picture in Picture
            [self showAppInAppStore:@"1006401631"];
            break;
        }
        case 2:
        {
            // BeautyTime
            [self showAppInAppStore:@"1002437952"];
            break;
        }
        default:
            break;
    }
    [button setSelected:YES];
}
#pragma mark AppStore Open
- (void)showAppInAppStore:(NSString *)appId
{
    Class isAllow = NSClassFromString(@"SKStoreProductViewController");
    if (isAllow)
    {
        // > iOS6.0
        SKStoreProductViewController *sKStoreProductViewController = [[SKStoreProductViewController alloc] init];
        sKStoreProductViewController.delegate = self;
        [self presentViewController:sKStoreProductViewController
                           animated:YES
                         completion:nil];
        [sKStoreProductViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier: appId}completionBlock:^(BOOL result, NSError *error)
         {
             if (error)
             {
                 NSLog(@"%@",error);
             }
         }];
    }
    else
    {
        // < iOS6.0
        NSString *appUrl = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/us/app/id%@?mt=8", appId];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appUrl]];
        
        //        UIWebView *callWebview = [[UIWebView alloc] init];
        //        NSURL *appURL =[NSURL URLWithString:appStore];
        //        [callWebview loadRequest:[NSURLRequest requestWithURL:appURL]];
        //        [self.view addSubview:callWebview];
    }
}
#pragma mark - SKStoreProductViewControllerDelegate
// Dismiss contorller
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
