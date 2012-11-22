#import <UIKit/UIKit.h>

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

@property (assign, nonatomic) id<ISColumnsControllerDelegate> delegate;
@property(nonatomic) NSInteger currentPage;

- (void) resizeSubViewControler;

- (void) delCurrentViewContrller;
- (void) delViewControllerAtIndex:(int) index;
- (void) delViewController:(UIViewController *) viewController;

- (void) addViewController:(UIViewController *) viewController withAnimations:(BOOL) animations;

@end
