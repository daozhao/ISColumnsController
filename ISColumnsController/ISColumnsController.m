#import "ISColumnsController.h"
#import <QuartzCore/QuartzCore.h>

@interface ISColumnsController ()

@property (nonatomic, assign) BOOL isSmallSize;
@property (nonatomic, assign) UITapGestureRecognizer *tap;

- (void)reloadChildViewControllers;
- (void)enableScrollsToTop;
- (void)disableScrollsToTop;

@end

@implementation ISColumnsController

#pragma mark - life cycle

- (id)init
{
    self = [super init];
    if (self) {
        [self view];
        [self addObserver:self
               forKeyPath:@"viewControllers"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
        [self addObserver:self
                       forKeyPath:@"currentPage"
                          options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)
                          context:nil];
        
    }
    self.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    self.scrollView.backgroundColor = self.backgroundColor;
    
    return self;
}

- (id)initWithBackgroundImage:(UIImage *)image backgroundColor:(UIColor *)color
{
    self = [self init];
    self.backgroundColor = color;
    self.backgroundImage = image;
    
//    self.scrollView.backgroundColor = self.backgroundColor;
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.backgroundImageView.image = self.backgroundImage;
    [self.backgroundImageView sizeToFit];
    
    return self;
}

- (void)loadView
{
    [super loadView];

    self.scrollView = [[[UIScrollView alloc] init] autorelease];
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    self.scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    self.scrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
//    self.scrollView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    
    self.backgroundImageView = [[UIImageView alloc] init];
    self.backgroundImageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    self.scrollView.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:self.backgroundImageView];
    [self.view addSubview:self.scrollView];
    
    if (!_tap) {
        UITapGestureRecognizer *t = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        t.delegate = (id<UIGestureRecognizerDelegate>)self;
        [self.view addGestureRecognizer:t];
        [t setEnabled:NO];
        _tap = t;
    }
    
    CALayer *topShadowLayer = [CALayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(-10, -10, 10000, 13)];
    topShadowLayer.frame = CGRectMake(-320, 0, 10000, 20);
    topShadowLayer.masksToBounds = YES;
    topShadowLayer.shadowOffset = CGSizeMake(2.5, 2.5);
    topShadowLayer.shadowOpacity = 0.5;
    topShadowLayer.shadowPath = [path CGPath];
    [self.scrollView.layer addSublayer:topShadowLayer];

    CALayer *bottomShadowLayer = [CALayer layer];
    path = [UIBezierPath bezierPathWithRect:CGRectMake(10, 10, 10000, 13)];
    bottomShadowLayer.frame = CGRectMake(-320, self.scrollView.frame.size.height-58, 10000, 20);
    bottomShadowLayer.masksToBounds = YES;
    bottomShadowLayer.shadowOffset = CGSizeMake(-2.5, -2.5);
    bottomShadowLayer.shadowOpacity = 0.5;
    bottomShadowLayer.shadowPath = [path CGPath];
    [self.scrollView.layer addSublayer:bottomShadowLayer];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self reloadChildViewControllers];
}

- (void)viewDidUnload
{
    self.viewControllers = nil;
    self.scrollView = nil;

    self.backgroundColor = nil;
    self.backgroundImage = nil;
    self.backgroundImageView = nil;
    
    [super viewDidUnload];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"viewControllers"];
    [self removeObserver:self forKeyPath:@"currentPage"];
    
    [_viewControllers release];
    [_scrollView release];
    [_backgroundColor release];
    [_backgroundImage release];
    [_backgroundImageView release];
    
    [super don_dealloc];
}

#pragma mark - interface orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    for (UIViewController *viewController in self.viewControllers) {
        NSInteger index = [self.viewControllers indexOfObject:viewController];
        
        viewController.view.transform = CGAffineTransformIdentity;
        viewController.view.frame = CGRectMake(self.scrollView.frame.size.width * index,
                                               0,
                                               self.scrollView.frame.size.width,
                                               self.scrollView.frame.size.height);
    }
    
    // go to the right page
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [self.viewControllers count], 1);
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width*self.currentPage, 0) animated:NO];
}

#pragma mark - key value observation

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [keyPath isEqualToString:@"viewControllers"]) {
        [self reloadChildViewControllers];
        [self disableScrollsToTop];
    }
    
    if (object == self && [keyPath isEqualToString:@"currentPage"]) {
        NSInteger previousIndex = [[change objectForKey:@"old"] integerValue];
        NSInteger currentIndex  = [[change objectForKey:@"new"] integerValue];
        
        if (previousIndex != currentIndex) {
            [self didChangeCurrentPage:currentIndex previousPage:previousIndex];
            [self didChangeCurrentPageDelegate];
        }
    }
}

#pragma mark - action

- (void)didChangeCurrentPage:(NSInteger)currentIndex previousPage:(NSInteger)previousIndex
{
    if ( previousIndex < self.viewControllers.count ){
        UIViewController <ISColumnsControllerChild> *previousViewController = [self.viewControllers objectAtIndex:previousIndex];
        if ([previousViewController respondsToSelector:@selector(didResignActive)]) {
            [previousViewController didResignActive];
        }
    }
    
    if ( currentIndex < self.viewControllers.count ){
        UIViewController <ISColumnsControllerChild> *currentViewController = [self.viewControllers objectAtIndex:currentIndex];
        if ([currentViewController respondsToSelector:@selector(didBecomeActive)]) {
            [currentViewController didBecomeActive];
        }
    }

    //[self didChangeCurrentPageDelegate];
}

- (void)reloadChildViewControllers
{
    for (UIViewController *viewController in self.childViewControllers) {
        [viewController willMoveToParentViewController:nil];
        [viewController removeFromParentViewController];
        [viewController.view removeFromSuperview];
    }
    for (UIViewController *viewController in self.viewControllers) {
        NSInteger index = [self.viewControllers indexOfObject:viewController];
        viewController.view.frame = CGRectMake(self.scrollView.frame.size.width * index,
                                               0,
                                               self.scrollView.frame.size.width,
                                               self.scrollView.frame.size.height);
        
        [self addChildViewController:viewController];
        [self.scrollView addSubview:viewController.view];
        [viewController didMoveToParentViewController:self];
        if (index == self.currentPage) {
            [self didChangeCurrentPageDelegate];
            if ([viewController respondsToSelector:@selector(didBecomeActive)]) {
                [(id)viewController didBecomeActive];
            }
        }
    }
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [self.viewControllers count], 1);
    
    for (UIViewController *viewController in self.childViewControllers) {
        CALayer *layer = viewController.view.layer;
        layer.shadowOpacity = .5f;
        layer.shadowOffset = CGSizeMake(10, 10);
        layer.shadowPath = [UIBezierPath bezierPathWithRect:viewController.view.bounds].CGPath;
    }
}

- (void)enableScrollsToTop
{
    // FIXME: this code affects all scroll view
    for (UIViewController *viewController in self.viewControllers) {
        for (UIView *subview in [viewController.view subviews]) {
            if ([subview respondsToSelector:@selector(scrollsToTop)]) {
                [(UIScrollView *)subview setScrollsToTop:YES];
            }
        }
    }
}

- (void)disableScrollsToTop
{
    for (UIViewController *viewController in self.viewControllers) {
        NSInteger index = [self.viewControllers indexOfObject:viewController];
        if (index != self.currentPage) {
            for (UIView *subview in [viewController.view subviews]) {
                if ([subview respondsToSelector:@selector(scrollsToTop)]) {
                    [(UIScrollView *)subview setScrollsToTop:NO];
                }
            }
        }
    }
}

#pragma mark - scroll view delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self enableScrollsToTop];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat offset = self.scrollView.contentOffset.x;
    CGFloat width = self.scrollView.frame.size.width;
    self.currentPage = (offset+(width/2))/width;
    
    [self disableScrollsToTop];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offset = scrollView.contentOffset.x;
    
    if ( !self.isSmallSize )
    {
        for (UIViewController *viewController in self.viewControllers) {
            NSInteger index = [self.viewControllers indexOfObject:viewController];
            CGFloat width = self.scrollView.frame.size.width;
            CGFloat y = index * width;
            CGFloat value = (offset-y)/width;
            CGFloat scale = 1.f-fabs(value);
            if (scale > 1.f) scale = 1.f;
            if (scale < .8f) scale = .8f;
            
            viewController.view.transform = CGAffineTransformMakeScale(scale, scale);
        }
    }

    for (UIViewController *viewController in self.childViewControllers) {
        CALayer *layer = viewController.view.layer;
        layer.shadowPath = [UIBezierPath bezierPathWithRect:viewController.view.bounds].CGPath;
    }
}


- (void)tap:(UITapGestureRecognizer*)gesture {
    
    [gesture setEnabled:NO];
    [self resizeSubViewControler];
    
}

- (void) resizeSubViewControlerToSize:(CGFloat) scale
{
    scale = (scale > 1.0) ? 1.0 : scale;
    [UIView animateWithDuration:.3 animations:^{
        for (UIViewController *viewController in self.viewControllers) {
            viewController.view.transform = CGAffineTransformMakeScale(scale, scale);
            viewController.view.userInteractionEnabled = (1.0 <= scale) ? YES : NO;
            CALayer *layer = viewController.view.layer;
            layer.shadowPath = [UIBezierPath bezierPathWithRect:viewController.view.bounds].CGPath;
        }
        self.isSmallSize = (1.0 <= scale) ? NO : YES;
        _tap.enabled = self.isSmallSize ? YES : NO;
    } completion:^(BOOL finished) {
        
    }];
}

- (void) resizeSubViewControler
{
    [self resizeSubViewControlerToSize:(self.isSmallSize) ? 1.0 : 0.8];
}

- (void) addViewController:(UIViewController *) viewController withAnimations:(BOOL) animations
{
    
    CGFloat originScale = self.isSmallSize ? 0.8 : 1.0;
    
    if ( nil == self.viewControllers ) {
        _viewControllers = [[NSMutableArray alloc] init];
    }
    [self.viewControllers addObject:viewController];
    
    NSInteger index = [self.viewControllers indexOfObject:viewController];
    viewController.view.frame = CGRectMake(self.scrollView.frame.size.width * index,
                                           (!animations) ? 0 : self.scrollView.frame.size.height,
                                           self.scrollView.frame.size.width,
                                           self.scrollView.frame.size.height);
    CALayer *layer = viewController.view.layer;
    layer.shadowOpacity = .5f;
    layer.shadowOffset = CGSizeMake(10, 10);
    layer.shadowPath = [UIBezierPath bezierPathWithRect:viewController.view.bounds].CGPath;
    
    [self addChildViewController:viewController];
    [self.scrollView addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
    if ( self.isSmallSize ){
        viewController.view.transform = CGAffineTransformMakeScale(0.8, 0.8);
    }
    
    if ( ! animations ){
        if ( 1 == self.viewControllers.count ){
            self.currentPage = 0;
        }
        [self didChangeCurrentPageDelegate];
    }
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [self.viewControllers count], 1);
    
    if ( animations ){
        
        CGFloat scale = 0.8;
        [UIView animateWithDuration:.3 animations:^{
            for (UIViewController *viewController in self.viewControllers) {
                // 这里负责缩小页面的。
                viewController.view.transform = CGAffineTransformMakeScale(scale, scale);
                viewController.view.userInteractionEnabled = (1.0 <= scale) ? YES : NO;
                CALayer *layer = viewController.view.layer;
                layer.shadowPath = [UIBezierPath bezierPathWithRect:viewController.view.bounds].CGPath;
            }
        } completion:^(BOOL finished) {
            self.isSmallSize = (1.0 <= scale) ? NO : YES;
            _tap.enabled = self.isSmallSize ? YES : NO;
            
            [UIView animateWithDuration:.3 animations:^{
                self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * (self.viewControllers.count -1), 0);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:.3 animations:^{
                    viewController.view.frame = CGRectMake(viewController.view.frame.origin.x,
                                                           viewController.view.frame.origin.y - self.scrollView.frame.size.height,
                                                           viewController.view.frame.size.width,
                                                           viewController.view.frame.size.height);
                } completion:^(BOOL finished) {
                    self.currentPage = self.viewControllers.count - 1;
                    if ( 1.0 == originScale ){
                        [self resizeSubViewControlerToSize:originScale];
                    }
                    
                    [self didChangeCurrentPageDelegate];
                }];
            }];
            
        }];
        
    } else {
        //RECTLOG(viewController.view.frame,@" after del frame:");
    }
}

- (void) delViewController:(UIViewController *) viewController
{
    NSInteger index = [self.viewControllers indexOfObject:viewController];
    if ( NSNotFound != index ) {
        [self delViewControllerAtIndex:index];
    }
    
}
- (void) delViewControllerAtIndex:(int) index
{
    if (index >= self.viewControllers.count ){
        return;
    }
    
    if ( index != self.currentPage ){
        UIViewController<ISColumnsControllerChild> *removeViewController = [self.viewControllers objectAtIndex:index];
        [removeViewController.view removeFromSuperview];
        [removeViewController removeFromParentViewController];
        [self.viewControllers removeObjectAtIndex:index];
        
        if ([removeViewController respondsToSelector:@selector(didResignActive)]) {
            [removeViewController didResignActive];
        }
       
        for ( int i = index; i < [self.viewControllers count] ; i++ ){
            UIViewController *viewController = [self.viewControllers objectAtIndex:i];
            viewController.view.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
            viewController.view.frame = CGRectMake(self.scrollView.frame.size.width * i,
                                                   0,
                                                   self.scrollView.frame.size.width,
                                                   viewController.view.frame.size.height
                                                   //self.scrollView.frame.size.height
                                                   );
        }
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [self.viewControllers count], 1);
        
        if ( self.currentPage >= self.viewControllers.count ){
            self.currentPage = self.viewControllers.count - 1;
        } else if ( index < self.currentPage ) {
            self.currentPage = self.currentPage ? self.currentPage - 1 : 0;
            self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * self.currentPage,0);
        }else {
            [self didChangeCurrentPageDelegate];
        }
        
    } else {
        CGFloat originScale = self.isSmallSize ? 0.8 : 1.0;
        CGFloat scale = 0.8f;
        [UIView animateWithDuration:.3 animations:^{
            for (UIViewController *viewController in self.viewControllers) {
                // 这里负责缩小页面的。
                viewController.view.transform = CGAffineTransformMakeScale(scale, scale);
                viewController.view.userInteractionEnabled = (1.0 <= scale) ? YES : NO;
                CALayer *layer = viewController.view.layer;
                layer.shadowPath = [UIBezierPath bezierPathWithRect:viewController.view.bounds].CGPath;
            }
        } completion:^(BOOL finished) {
            self.isSmallSize = (1.0 <= scale) ? NO : YES;
            _tap.enabled = self.isSmallSize ? YES : NO;
            
            [UIView animateWithDuration:.3 animations:^{
                UIViewController *removeViewController = [self.viewControllers objectAtIndex:index];
                //removeViewController.view.alpha = 0.0;
                removeViewController.view.frame = CGRectMake(removeViewController.view.frame.origin.x
                                                             ,removeViewController.view.frame.origin.y - self.scrollView.frame.size.height
                                                             ,removeViewController.view.frame.size.width
                                                             ,removeViewController.view.frame.size.height
                                                             );
                
            } completion:^(BOOL finished) {
                
                UIViewController<ISColumnsControllerChild> *removeViewController = [self.viewControllers objectAtIndex:index];
                
                if ([removeViewController respondsToSelector:@selector(didResignActive)]) {
                    [removeViewController didResignActive];
                }
                [removeViewController.view removeFromSuperview];
                [removeViewController removeFromParentViewController];
                [self.viewControllers removeObjectAtIndex:index];
                
                [UIView animateWithDuration:.3 animations:^{
                    for ( int i = index; i < [self.viewControllers count] ; i++ ){
                        UIViewController *viewController = [self.viewControllers objectAtIndex:i];
                        viewController.view.frame = CGRectMake(viewController.view.frame.origin.x - self.scrollView.frame.size.width
                                                               ,viewController.view.frame.origin.y
                                                               ,viewController.view.frame.size.width
                                                               ,viewController.view.frame.size.height
                                                               );
                    }
                } completion:^(BOOL finished) {
                    //self.pageControl.numberOfPages = [self.viewControllers count];
                    if ( self.currentPage >= self.viewControllers.count ){
                        self.currentPage = self.viewControllers.count ? self.viewControllers.count - 1 : 0 ;
                    } else {
                        UIViewController<ISColumnsControllerChild> *viewController = [self.viewControllers objectAtIndex:index];
                        if ([viewController respondsToSelector:@selector(didBecomeActive)]) {
                            [viewController didBecomeActive];
                        }
                    }
                    [self didChangeCurrentPageDelegate];
                    
                    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [self.viewControllers count], 1);
                    if ( 1.0 == originScale ){
                        [self resizeSubViewControlerToSize:originScale];
                    }
                    
                }];
                
            }];
            
            
        }];
        
    }
    
}


- (void) moveToViewController:(UIViewController *) viewController withAnimations:(BOOL) animations
{
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    if ( NSNotFound != index ){
        [self moveToViewControllerAtIndex:index withAnimations:animations];
    }
    
}
- (void) moveToViewControllerAtIndex:(NSUInteger) index withAnimations:(BOOL) animations
{
    if ( index == self.currentPage ){
        return;
    }
    if (index >= self.viewControllers.count ){
        return;
    }
        
    if ( animations ){
        CGFloat originScale = self.isSmallSize ? 0.8 : 1.0;
        CGFloat scale = 0.8f;
        [UIView animateWithDuration:.3 animations:^{
            for (UIViewController *viewController in self.viewControllers) {
                // 这里负责缩小页面的。
                viewController.view.transform = CGAffineTransformMakeScale(scale, scale);
                viewController.view.userInteractionEnabled = (1.0 <= scale) ? YES : NO;
                CALayer *layer = viewController.view.layer;
                layer.shadowPath = [UIBezierPath bezierPathWithRect:viewController.view.bounds].CGPath;
            }
            self.isSmallSize = YES;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.3 animations:^{
                self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * index , 0);
            } completion:^(BOOL finished) {
                self.currentPage = index;
                [self didChangeCurrentPageDelegate];
                if ( 1.0 == originScale ){
                    [self resizeSubViewControlerToSize:originScale];
                }
                
            }];
        }];
        
    } else {
        self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * index , 0);
        self.currentPage = index;
        [self didChangeCurrentPageDelegate];
    }
}

- (void) delCurrentViewContrller
{
    [self delViewControllerAtIndex:self.currentPage];
    
}

#pragma mark - IScolumnsControllerdelegate
- (void) didChangeCurrentPageDelegate
{
    if ( self.backgroundImage ){
        self.scrollView.backgroundColor =  0 == self.viewControllers.count ? [UIColor clearColor] : self.backgroundColor ;
    }
    if ( _delegate && [_delegate respondsToSelector:@selector(didChangePage:currentPage:numberOfPages:)] ){
        if ( self.currentPage < self.viewControllers.count ){
            [_delegate didChangePage:[self.viewControllers objectAtIndex:self.currentPage] currentPage:self.currentPage numberOfPages:self.viewControllers.count];
        } else {
            [_delegate didChangePage:nil currentPage:self.currentPage numberOfPages:self.viewControllers.count];
        }
    }
}


@end
