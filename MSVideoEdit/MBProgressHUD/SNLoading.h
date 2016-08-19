
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SNLoading : NSObject

+ (void)showWithTitle:(NSString *)title;
+ (void)hideWithTitle:(NSString *)title;
+ (void)updateWithTitle:(NSString *)title detailsText:(NSString *)detailsText;
@end
