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
    self.scrollView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
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
    self.scrollView = nil;
    
    [super viewDidUnload];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"viewControllers"];
    [self removeObserver:self forKeyPath:@"currentPage"];
    
    [_viewControllers release];
    [_scrollView release];
    
    [super dealloc];
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
        }
    }
}

#pragma mark - action

- (void)didChangeCurrentPage:(NSInteger)currentIndex previousPage:(NSInteger)previousIndex
{
    UIViewController <ISColumnsControllerChild> *previousViewController = [self.viewControllers objectAtIndex:previousIndex];
    if ([previousViewController respondsToSelector:@selector(didResignActive)]) {
        [previousViewController didResignActive];
    }
    
    UIViewController <ISColumnsControllerChild> *currentViewController = [self.viewControllers objectAtIndex:currentIndex];
    if ([currentViewController respondsToSelector:@selector(didBecomeActive)]) {
        [currentViewController didBecomeActive];
    }

    [self didChangeCurrentPageDelegate];
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
            // 这里负责缩小页面的。
            viewController.view.transform = CGAffineTransformMakeScale(scale, scale);
            viewController.view.userInteractionEnabled = (1.0 <= scale) ? YES : NO;
            CALayer *layer = viewController.view.layer;
            layer.shadowPath = [UIBezierPath bezierPathWithRect:viewController.view.bounds].CGPath;
        }
    } completion:^(BOOL finished) {
        self.isSmallSize = (1.0 <= scale) ? NO : YES;
        if ( self.isSmallSize ){
            _tap.enabled = YES;
        } else {
            _tap.enabled = NO;
        }
    }];
}

- (void) resizeSubViewControler
{
    [self resizeSubViewControlerToSize:(self.isSmallSize) ? 1.0 : 0.8];
}

#pragma mark - IScolumnsControllerdelegate
- (void) didChangeCurrentPageDelegate
{
    if ( _delegate && [_delegate respondsToSelector:@selector(didChangePage:currentPage:numberOfPages:)] ){
        if ( self.currentPage < self.viewControllers.count ){
            [_delegate didChangePage:[self.viewControllers objectAtIndex:self.currentPage] currentPage:self.currentPage numberOfPages:self.viewControllers.count];
        } else {
            [_delegate didChangePage:nil currentPage:self.currentPage numberOfPages:self.viewControllers.count];
        }
    }
}


@end
