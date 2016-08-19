//
//  ExportEffects
//  VideoTheme
//
//  Created by Johnny Xu(徐景周) on 5/30/15.
//  Copyright (c) 2015 Future Studio. All rights reserved.
//  制作/录制视频导出（保存到相册）

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define TrackIDCustom 1

typedef NSString *(^JZOutputFilenameBlock)();
typedef void (^JZFinishVideoBlock)(BOOL success, id result);
typedef void (^JZExportProgressBlock)(NSNumber *percentage);

@interface ExportEffects : NSObject

@property (copy, nonatomic) JZFinishVideoBlock finishVideoBlock;
@property (copy, nonatomic) JZExportProgressBlock exportProgressBlock;
@property (copy, nonatomic) JZOutputFilenameBlock filenameBlock;

@property (nonatomic, strong) NSMutableArray *gifArray;

+ (ExportEffects *)sharedInstance;

- (void)addEffectToVideo:(NSString *)videoFilePath withAudioFilePath:(NSString *)audioFilePath withAniBeginTime:(CFTimeInterval)beginTime;
// 将制作好的视频保存到相册中
- (void)writeExportedVideoToAssetsLibrary:(NSString *)outputPath;
@end
