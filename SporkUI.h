#import <UIKit/UIKit.h>

extern NSMutableArray<NSString *> *g_logs;
void SporkLog(NSString *format, ...);

@interface SporkViewController : UIViewController
@property (nonatomic, strong, readonly) UIView *mainContainer;
@property (nonatomic, strong, readonly) UIButton *floatingButton;
@end
