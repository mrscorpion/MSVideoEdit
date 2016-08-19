//
//  CommonDefine.h
//  MSVideoEdit
//
//  Created by mr.scorpion on 16/5/19.
//  Copyright © 2016年 mr.scorpion. All rights reserved.
//

#ifndef CommonDefine_h
#define CommonDefine_h

#import <AVFoundation/AVFoundation.h>
#import "SNLoading.h"

// Color
#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)]
#define kNavigationBarBottomSeperatorColor RGBCOLOR(255, 207, 51)
#define kTableViewSeperatorColor RGBCOLOR(75, 72, 72)
#define kBackgroundColor RGBCOLOR(40, 39, 37)
#define kTableViewCellTitleColor RGBCOLOR(172, 171, 169)
#define kTextGrayColor RGBCOLOR(148, 147, 146)
#define kLightBlue [UIColor colorWithRed:155/255.0f green:188/255.0f blue:220/255.0f alpha:1]
#define kBrightBlue [UIColor colorWithRed:100/255.0f green:100/255.0f blue:230/255.0f alpha:1]


// OS Version iOS版本
#define iPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IOS7 [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0
#define iOS6 ((([[UIDevice currentDevice].systemVersion intValue] >= 6) && ([[UIDevice currentDevice].systemVersion intValue] < 7)) ? YES : NO )
#define iOS5 ((([[UIDevice currentDevice].systemVersion intValue] >= 5) && ([[UIDevice currentDevice].systemVersion intValue] < 6)) ? YES : NO )

#define LargeScreen ([UIScreen mainScreen].bounds.size.height > 480)
#define iOS7AddStatusHeight (IOS7?20:0)


// Progress Bar 进度条
#define ProgressBarShowLoading(_Title_) [SNLoading showWithTitle:_Title_]
#define ProgressBarDismissLoading(_Title_) [SNLoading hideWithTitle:_Title_]
#define ProgressBarUpdateLoading(_Title_, _DetailsText_) [SNLoading updateWithTitle:_Title_ detailsText:_DetailsText_]

#define degreesToRadians(degrees) ((degrees) / 180.0 * M_PI)
#define foo4random() (1.0 * (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX)

// Callback 通用（Generic）回调block
typedef void(^GenericCallback)(BOOL success, id result);

#pragma mark - dispatch_async_main_after
static inline void dispatch_async_main_after(NSTimeInterval after, dispatch_block_t block)
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(after * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), block);
}

#pragma mark - Local String 本地化与国际化
#define CURR_LANG ([[NSLocale preferredLanguages] objectAtIndex: 0])
static inline NSString* GBLocalizedString(NSString *translation_key)
{
    NSString * string = NSLocalizedString(translation_key, nil );
    if (![CURR_LANG isEqualToString:@"en"] && ![CURR_LANG hasPrefix:@"zh-Hans"])
    {
        NSString * path = [[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"];
        NSBundle * languageBundle = [NSBundle bundleWithPath:path];
        string = [languageBundle localizedStringForKey:translation_key value:@"" table:nil];
    }
    return string;
}

#pragma mark - Show Alert 显示提示框
static inline void showAlertMessage(NSString *text, NSString *title)
{
    NSString *ok = GBLocalizedString(@"OK");
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:nil
                      cancelButtonTitle:ok
                      otherButtonTitles:nil] show];
}


#pragma mark - String 是否为空字符串
static inline BOOL isStringEmpty(NSString *value)
{
    BOOL result = FALSE;
    if (!value || [value isKindOfClass:[NSNull class]])
    {
        // null object
        result = TRUE;
    } else {
        NSString *trimedString = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([value isKindOfClass:[NSString class]] && [trimedString length] == 0)
        {
            // empty string
            result = TRUE;
        }
    }
    return result;
}


#pragma mark - Video Helper
// 获取视频总时长
static inline CGFloat getVideoDuration(NSURL *URL)
{
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:URL options:opts];
    float second = 0;
    second = urlAsset.duration.value/urlAsset.duration.timescale;
    return second;
}
#pragma mark - 获取录制视频的图像帧/缩略图（thumbnailImage）
static inline UIImage* getImageFromVideoFrame(NSURL *videoFileURL, CMTime atTime)
{
    NSURL *inputUrl = videoFileURL;
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:inputUrl options:nil];
    
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:atTime actualTime:NULL error:&thumbnailImageGenerationError];
    
    if (!thumbnailImageRef)
    {
        NSLog(@"thumbnailImageGenerationError %@", thumbnailImageGenerationError);
    }
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage:thumbnailImageRef] : nil;
    
    if (thumbnailImageRef)
    {
        CGImageRelease(thumbnailImageRef);
    }
    return thumbnailImage;
}

#pragma mark - Delete Files/Directory  删除文件
static inline void deleteFilesAt(NSString *directory, NSString *suffixName)
{
    NSError *err = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:directory];
    NSString *toDelFile;
    while (toDelFile = [dirEnum nextObject])
    {
        NSComparisonResult result = [[toDelFile pathExtension] compare:suffixName options:NSCaseInsensitiveSearch|NSNumericSearch];
        if (result == NSOrderedSame)
        {
            NSLog(@"removing file：%@", toDelFile);
            
            if(![fileManager removeItemAtPath:[directory stringByAppendingPathComponent:toDelFile] error:&err])
            {
                NSLog(@"Error: %@", [err localizedDescription]);
            }
        }
    }
}

#pragma mark - 检查文件路径是否存在
static inline BOOL isFileExistAtPath(NSString *fileFullPath)
{
    BOOL isExist = NO;
    isExist = [[NSFileManager defaultManager] fileExistsAtPath:fileFullPath];
    return isExist;
}
#pragma mark - 通过文件名获取文件路径 （获取文件路径filepath）
static inline NSString* getFilePath(NSString *name)
{
    NSString *fileName = [name stringByDeletingPathExtension];
    NSLog(@"%@",fileName);
    NSString *fileExt = [name pathExtension];
    NSLog(@"%@",fileExt);
    NSString *inputVideoPath = [[NSBundle mainBundle] pathForResource:fileName ofType:fileExt];
    return inputVideoPath;
}
#pragma mark - 获取URL （filepath（NSString）转化URL）
static inline NSURL* getFileURL(NSString *filePath)
{
    if (!filePath || [filePath length] == 0)
        return nil;
    NSURL *fileURL = [NSURL URLWithString:filePath];
    if (!fileURL || ![fileURL scheme])
    {
        fileURL = [NSURL fileURLWithPath:filePath];
    }
    return fileURL;
}
#pragma mark - File Helper 获取系统文件列表
static inline NSArray* getFilelistBySymbol(NSString *symbol, NSString *dirPath, NSString *type)
{
    NSMutableArray *filelist = [NSMutableArray arrayWithCapacity:1];
    NSArray *tmplist = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:nil];
    NSString *symbolResult = [symbol lowercaseStringWithLocale:[NSLocale currentLocale]];
    NSString *typeResult = [type lowercaseStringWithLocale:[NSLocale currentLocale]];
    for (NSString *filename in tmplist)
    {
        NSString *fullpath = [dirPath stringByAppendingPathComponent:filename];
        BOOL fileExisted = [[NSFileManager defaultManager] fileExistsAtPath:fullpath];
        if (fileExisted)
        {
            NSString *filenameResult = [filename lowercaseStringWithLocale:[NSLocale currentLocale]];
            if ([[filenameResult lastPathComponent] hasPrefix:symbolResult] && [filenameResult hasSuffix:typeResult])
            {
                [filelist  addObject:filename];
            }
        }
    }
    return filelist;
}


#pragma mark - 跟踪（Track）屏幕视图方向（orientation）
static inline UIInterfaceOrientation orientationForTrack(AVAsset *asset)
{
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize size = [videoTrack naturalSize];
    CGAffineTransform txf = [videoTrack preferredTransform];
    
    if (size.width == txf.tx && size.height == txf.ty)
        return UIInterfaceOrientationLandscapeRight;
    else if (txf.tx == 0 && txf.ty == 0)
        return UIInterfaceOrientationLandscapeLeft;
    else if (txf.tx == 0 && txf.ty == size.width)
        return UIInterfaceOrientationPortraitUpsideDown;
    else
        return UIInterfaceOrientationPortrait;
}



#pragma mark - App Info
static inline NSString* getAppVersion()
{
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *versionNum =[infoDict objectForKey:@"CFBundleVersion"];
    NSLog(@"App version: %@", versionNum);
    return versionNum;
}
static inline NSString* getAppName()
{
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appName = [infoDict objectForKey:@"CFBundleDisplayName"];
    NSLog(@"App name: %@", appName);
    return appName;
}
static inline NSString* getAppNameByInfoPlist()
{
    NSString *appName = NSLocalizedStringFromTable(@"CFBundleDisplayName", @"InfoPlist", nil);
    NSLog(@"App name: %@", appName);
    return appName;
}
/* 获取本机正在使用的语言  * en:英文  zh-Hans:简体中文   zh-Hant:繁体中文    ja:日本 ...... */
static inline NSString* getPreferredLanguage()
{
    NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
    NSArray* languages = [defs objectForKey:@"AppleLanguages"];
    NSString* preferredLang = [languages objectAtIndex:0];
    
    NSLog(@"Preferred Language: %@", preferredLang);
    return preferredLang;
}
static inline NSString* getCurrentlyLanguage()
{
    NSArray *languages = [NSLocale preferredLanguages];
    NSString *currentLanguage = [languages objectAtIndex:0];
    
    NSLog(@"currentLanguage: %@", currentLanguage);
    return currentLanguage;
}
static inline BOOL isZHHansFromCurrentlyLanguage()
{
    BOOL bResult = FALSE;
    NSString *curLauguage = getCurrentlyLanguage();
    NSString *cnLauguage = @"zh-Hans";
    if ([curLauguage compare:cnLauguage options:NSCaseInsensitiveSearch | NSNumericSearch] == NSOrderedSame)
    {
        bResult = TRUE;
    }
    
    return bResult;
}

#pragma mark - FindRightNavBarItemView
// Get view for navigarion right item
static inline UIView* findRightNavBarItemView(UINavigationBar *navbar)
{
    UIView* rightView = nil;
    for (UIView* view in navbar.subviews)
    {
        if (!rightView)
        {
            rightView = view;
        }
        else if (view.frame.origin.x > rightView.frame.origin.x)
        {
            rightView = view;
        }
    }
    
    return rightView;
}
#endif /* CommonDefine_h */
