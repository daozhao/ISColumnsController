#import "ISAppDelegate.h"
#import "ISViewController.h"
#import "ISColumnsController.h"

@implementation ISAppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize columnsController = _columnsController;
@synthesize pageControl = _pageControl;
@synthesize titleLabel = _titleLabel;

- (void)dealloc
{
    [_window release], _window = nil;
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.columnsController = [[[ISColumnsController alloc] init] autorelease];
    self.columnsController.delegate = self;
    self.columnsController.navigationItem.titleView = [self loadTitleView];
    self.columnsController.navigationItem.rightBarButtonItem =
    [[[UIBarButtonItem alloc] initWithTitle:@"Reload"
                                      style:UIBarButtonItemStylePlain
                                     target:self
                                     action:@selector(reloadViewControllers)] autorelease];
    [self.columnsController setToolbarItems:[NSArray arrayWithObjects:
                                             [[[UIBarButtonItem alloc] initWithTitle:@"Add"
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(addController)] autorelease]
                                             ,[[[UIBarButtonItem alloc] initWithTitle:@"Add@A"
                                                                                style:UIBarButtonItemStyleBordered
                                                                               target:self
                                                                               action:@selector(addControllerWithAnimations)] autorelease]
                                             ,[[[UIBarButtonItem alloc] initWithTitle:@"Del"
                                                                                style:UIBarButtonItemStyleBordered
                                                                               target:self
                                                                               action:@selector(delController)] autorelease]
                                             ,[[[UIBarButtonItem alloc] initWithTitle:@"Del@1"
                                                                                style:UIBarButtonItemStyleBordered
                                                                               target:self
                                                                               action:@selector(delControllerAtOne)] autorelease]
                                             ,[[[UIBarButtonItem alloc] initWithTitle:@"Resize"
                                                                                style:UIBarButtonItemStyleBordered
                                                                               target:self
                                                                               action:@selector(resizeView)] autorelease]
                                             , nil]];
    [self reloadViewControllers];
    
    self.navigationController = [[[UINavigationController alloc] init] autorelease];
    self.navigationController.viewControllers = [NSArray arrayWithObject:self.columnsController];
    [self.navigationController setToolbarHidden:NO];
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)reloadViewControllers
{
    ISViewController *viewController1 = [[[ISViewController alloc] init] autorelease];
    viewController1.navigationItem.title = @"ViewController 1";
    
    ISViewController *viewController2 = [[[ISViewController alloc] init] autorelease];
    viewController2.navigationItem.title = @"ViewController 2";
    
    ISViewController *viewController3 = [[[ISViewController alloc] init] autorelease];
    viewController3.navigationItem.title = @"ViewController 3";
    
    self.columnsController.viewControllers = [NSMutableArray arrayWithObjects:
                                              viewController1,
                                              viewController2,
                                              viewController3, nil];
}

- (UIView *)loadTitleView
{
    UIView *titleView = [[[UIView alloc] init] autorelease];
    titleView.frame = CGRectMake(0, 0, 150, 44);
    titleView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    self.pageControl = [[[UIPageControl alloc] init] autorelease];
    self.pageControl.numberOfPages = 3;
    self.pageControl.frame = CGRectMake(0, 27, 150, 14);
    self.pageControl.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin|
                                         UIViewAutoresizingFlexibleBottomMargin|
                                         UIViewAutoresizingFlexibleHeight);
    [self.pageControl addTarget:self
                         action:@selector(didTapPageControl)
               forControlEvents:UIControlEventValueChanged];
    
    [titleView addSubview:self.pageControl];
    
    self.titleLabel = [[[UILabel alloc] init] autorelease];
    self.titleLabel.frame = CGRectMake(0, 5, 150, 24);
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textAlignment = UITextAlignmentCenter;
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.shadowColor = [UIColor darkGrayColor];
    self.titleLabel.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin|
                                        UIViewAutoresizingFlexibleBottomMargin|
                                        UIViewAutoresizingFlexibleHeight);
    
    [titleView addSubview:self.titleLabel];
    
    //self.navigationItem.titleView = titleView;
    return titleView;
}

- (void) resizeView
{
    [self.columnsController resizeSubViewControler];
}

-(void) delController
{
    [self.columnsController delCurrentViewContrller];
}

-(void) delControllerAtOne
{
    [self.columnsController delViewControllerAtIndex:0];
}

- (void)addControllerWithAnimations
{
    ISViewController *viewController3 = [[[ISViewController alloc] init] autorelease];
    viewController3.navigationItem.title = @"ViewController 3";
    [self.columnsController addViewController: viewController3 withAnimations:YES];
}

- (void)addController
{
    ISViewController *viewController3 = [[[ISViewController alloc] init] autorelease];
    viewController3.navigationItem.title = @"ViewController 3";
    [self.columnsController addViewController: viewController3 withAnimations:NO];
}

- (void)didChangePage:(UIViewController *) viewController currentPage:(NSInteger) page numberOfPages:(NSInteger) count
{
    NSLog(@"didChangePage:%@ currentPage:%d numberOfPages:%d",viewController,page,count);
    self.pageControl.numberOfPages = count;
    self.pageControl.currentPage = page;
    if (viewController) {
        self.titleLabel.text = viewController.navigationItem.title;
    } else {
        self.titleLabel.text = @"";
    }
    
}


@end
