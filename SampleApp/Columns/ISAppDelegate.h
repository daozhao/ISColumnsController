#import <UIKit/UIKit.h>
#import "ISColumnsController.h"

@class ISColumnsController;

@interface ISAppDelegate : UIResponder <UIApplicationDelegate,ISColumnsControllerDelegate>

@property (retain, nonatomic) UIWindow *window;
@property (retain, nonatomic) UINavigationController *navigationController;
@property (retain, nonatomic) ISColumnsController *columnsController;

@property (retain, nonatomic) UILabel       *titleLabel;
@property (retain, nonatomic) UIPageControl *pageControl;

@end
