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

@property (retain, nonatomic) NSArray       *viewControllers;
@property (retain, nonatomic) UIScrollView  *scrollView;

@property (assign, nonatomic) id<ISColumnsControllerDelegate> delegate;
@property(nonatomic) NSInteger currentPage;

@end
