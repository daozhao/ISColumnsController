#import <UIKit/UIKit.h>
#import "ARCSupporDefine.h"

@protocol ISColumnsControllerChild <NSObject>
@optional
- (void)didBecomeActive;
- (void)didResignActive;
@end

@protocol ISColumnsControllerDelegate <NSObject>
@optional
- (void)didChangePage:(UIViewController *) viewController currentPage:(NSInteger) page numberOfPages:(NSInteger) count;
@end

@interface ISColumnsController : UIViewController <UIScrollViewDelegate>

@property (retain, nonatomic) NSMutableArray *viewControllers;
@property (retain, nonatomic) UIScrollView  *scrollView;
@property (retain, nonatomic) UIImageView  *backgroundImageView;
@property (retain, nonatomic) UIImage  *backgroundImage;
@property (retain, nonatomic) UIColor  *backgroundColor;

@property (assign, nonatomic) id<ISColumnsControllerDelegate> delegate;
@property(nonatomic) NSInteger currentPage;

- (id)initWithBackgroundImage:(UIImage *)image backgroundColor:(UIColor *)color;

- (void) resizeSubViewControler;

- (void) delCurrentViewContrller;
- (void) delViewControllerAtIndex:(int) index;
- (void) delViewController:(UIViewController *) viewController;

- (void) addViewController:(UIViewController *) viewController withAnimations:(BOOL) animations;

- (void) moveToViewController:(UIViewController *) viewController withAnimations:(BOOL) animations;
- (void) moveToViewControllerAtIndex:(NSUInteger) index withAnimations:(BOOL) animations;


@end
