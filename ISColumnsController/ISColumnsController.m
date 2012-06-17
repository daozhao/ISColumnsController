#import "ISColumnsController.h"

@interface ISColumnsController ()

- (void)reloadChildViewControllers;
- (void)enableScrollsToTop;
- (void)disableScrollsToTop;

@end

@implementation ISColumnsController

@synthesize viewControllers = _viewControllers;
@synthesize scrollView = _scrollView;
@synthesize titleLabel = _titleLabel;
@synthesize pageControl = _pageControl;

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
    [self.view addSubview:self.scrollView];
    
    UIView *titleView = [[[UIView alloc] init] autorelease];
    titleView.frame = CGRectMake(0, 0, 150, 44);
    
    self.pageControl = [[[UIPageControl alloc] init] autorelease];
    self.pageControl.numberOfPages = 3;
    self.pageControl.frame = CGRectMake(0, 27, 150, 14);
    [titleView addSubview:self.pageControl];
    
    self.titleLabel = [[[UILabel alloc] init] autorelease];
    self.titleLabel.frame = CGRectMake(0, 7, 150, 20);
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textAlignment = UITextAlignmentCenter;
    self.titleLabel.textColor = [UIColor whiteColor];
    [titleView addSubview:self.titleLabel];
    
    self.navigationItem.titleView = titleView;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"viewControllers"];
    [_viewControllers release], _viewControllers = nil;
    [_scrollView release], _scrollView = nil;
    [_titleLabel release], _titleLabel = nil;
    [_pageControl release], _pageControl = nil;
    [super dealloc];
}

#pragma mark - key value observation

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [keyPath isEqualToString:@"viewControllers"]) {
        [self reloadChildViewControllers];
        [self disableScrollsToTop];
    }
}

#pragma mark - action

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
        if (index == self.pageControl.currentPage) {
            self.titleLabel.text = viewController.navigationItem.title;
        }
    }
    self.scrollView.contentSize = 
    CGSizeMake(self.scrollView.frame.size.width * [self.viewControllers count], 1);
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
        if (index != self.pageControl.currentPage) {
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
    [self disableScrollsToTop];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offset = scrollView.contentOffset.x;
    CGFloat width = scrollView.frame.size.width;
    NSInteger currentPage = (offset+(width/2))/width;
    if (currentPage != self.pageControl.currentPage && currentPage < [self.viewControllers count]) {
        UIViewController <ISColumnsControllerChild> *previousViewController = [self.viewControllers objectAtIndex:self.pageControl.currentPage];
        if ([previousViewController respondsToSelector:@selector(didResignActive)]) {
            [previousViewController didResignActive];
        }
        
        UIViewController <ISColumnsControllerChild> *currentViewController = [self.viewControllers objectAtIndex:currentPage];
        if ([currentViewController respondsToSelector:@selector(didBecomeActive)]) {
            [currentViewController didBecomeActive];
        }
        self.titleLabel.text = currentViewController.navigationItem.title;
        self.pageControl.currentPage = currentPage;
    }
    
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

@end
