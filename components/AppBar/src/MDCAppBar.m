/*
 Copyright 2016-present Google Inc. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "MDCAppBar.h"

#import "MDCAppBarContainerViewController.h"
#import "private/MDCAppBarButtonBarBuilder.h"

#import "MaterialFlexibleHeader.h"
#import "MaterialShadowElevations.h"
#import "MaterialShadowLayer.h"
#import "MaterialTypography.h"

static NSString *const kBundleName = @"MaterialAppBar";
static NSString *const kBackIconName = @"arrow_back";

static NSString *const kBarStackKey = @"barStack";
static NSString *const kStatusBarHeightKey = @"statusBarHeight";
static const CGFloat kStatusBarHeight = 20;

@interface MDCAppBarViewController : UIViewController

@property(nonatomic, strong) MDCAppBarButtonBarBuilder *buttonItemBuilder;
@property(nonatomic, strong) MDCHeaderStackView *headerStackView;
@property(nonatomic, strong) MDCNavigationBar *navigationBar;

@end

@implementation MDCAppBarViewController

- (MDCHeaderStackView *)headerStackView {
  [self loadViewIfNeeded];
  return _headerStackView;
}

- (MDCNavigationBar *)navigationBar {
  [self loadViewIfNeeded];
  return _navigationBar;
}

- (UIViewController *)flexibleHeaderParentViewController {
  NSAssert([self.parentViewController isKindOfClass:[MDCFlexibleHeaderViewController class]],
           @"Expected the parent of %@ to be a type of %@",
           NSStringFromClass([self class]),
           NSStringFromClass([MDCFlexibleHeaderViewController class]));
  return self.parentViewController.parentViewController;
}

- (UIBarButtonItem *)backButtonItem {
  UIViewController *fhvParent = self.flexibleHeaderParentViewController;
  UINavigationController *navigationController = fhvParent.navigationController;

  NSArray *viewControllerStack = navigationController.viewControllers;

  // This will be zero if there is no navigation controller, so a view controller which is not
  // inside a navigation controller will be treated the same as a view controller at the root of a
  // navigation controller
  NSUInteger index = [viewControllerStack indexOfObject:fhvParent];

  UIViewController *iterator = fhvParent;

  // In complex cases it might actually be a parent of |fhvParent| which is on the nav stack.
  while (index == NSNotFound && iterator && ![iterator isEqual:navigationController]) {
    iterator = iterator.parentViewController;
    index = [viewControllerStack indexOfObject:iterator];
  }

  if (index == NSNotFound) {
    NSCAssert(NO, @"View controller not present in its own navigation controller.");
    // This is not something which should ever happen, but just in case.
    return nil;
  }
  if (index == 0) {
    // The view controller is at the root of a navigation stack (or not in one).
    return nil;
  }
  UIViewController *previousViewControler = navigationController.viewControllers[index - 1];
  if ([previousViewControler isKindOfClass:[MDCAppBarContainerViewController class]]) {
    // Special case: if the previous view controller is a container controller, use its content
    // view controller.
    MDCAppBarContainerViewController *chvc =
        (MDCAppBarContainerViewController *)previousViewControler;
    previousViewControler = chvc.contentViewController;
  }
  UIBarButtonItem *backBarButtonItem = previousViewControler.navigationItem.backBarButtonItem;
  if (!backBarButtonItem) {
    NSBundle *baseBundle = [[self class] baseBundle];
    NSString *bundlePath = [baseBundle pathForResource:kBundleName ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSString *path = [bundle pathForResource:kBackIconName ofType:@"png"];
    UIImage *backButtonImage = [UIImage imageWithContentsOfFile:path];
    backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backButtonImage
                                                         style:UIBarButtonItemStyleDone
                                                        target:self
                                                        action:@selector(didTapBackButton:)];
  }
  return backBarButtonItem;
}

+ (NSBundle *)baseBundle {
  static NSBundle *bundle = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // We may not be included by the main bundle, but rather by an embedded framework, so figure out
    // to which bundle our code is compiled, and use that as the starting point for bundle loading.
    bundle = [NSBundle bundleForClass:[self class]];
  });

  return bundle;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.buttonItemBuilder = [MDCAppBarButtonBarBuilder new];

  self.headerStackView = [[MDCHeaderStackView alloc] initWithFrame:self.view.bounds];
  self.headerStackView.translatesAutoresizingMaskIntoConstraints = NO;

  self.navigationBar = [MDCNavigationBar new];
  self.headerStackView.topBar = self.navigationBar;

  self.navigationBar.leftButtonBarDelegate = self.buttonItemBuilder;
  self.navigationBar.rightButtonBarDelegate = self.buttonItemBuilder;

  [self.view addSubview:self.headerStackView];

  // Bar stack expands vertically, but has a margin above it for the status bar.

  NSArray *horizontalConstraints =
      [NSLayoutConstraint constraintsWithVisualFormat:
                              [NSString stringWithFormat:
                                            @"H:|[%@]|",
                                            kBarStackKey]
                                              options:0
                                              metrics:nil
                                                views:@{kBarStackKey : self.headerStackView}];
  [self.view addConstraints:horizontalConstraints];

  NSArray *verticalConstraints =
      [NSLayoutConstraint constraintsWithVisualFormat:
                              [NSString stringWithFormat:
                                            @"V:|-%@-[%@]|",
                                            kStatusBarHeightKey,
                                            kBarStackKey]
                                              options:0
                                              metrics:@{ kStatusBarHeightKey : @(kStatusBarHeight) }
                                                views:@{kBarStackKey : self.headerStackView}];
  [self.view addConstraints:verticalConstraints];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  UIBarButtonItem *backBarButtonItem = [self backButtonItem];
  if (backBarButtonItem && !self.navigationBar.backItem) {
    self.navigationBar.backItem = backBarButtonItem;
  }
}

#pragma mark User actions

- (void)didTapBackButton:(id)sender {
  UIViewController *pvc = self.flexibleHeaderParentViewController;
  if (pvc.navigationController && pvc.navigationController.viewControllers.count > 1) {
    [pvc.navigationController popViewControllerAnimated:YES];
  } else {
    [pvc dismissViewControllerAnimated:YES completion:nil];
  }
}

@end

void MDCAppBarPrepareParent(id<MDCAppBarParenting> parent) {
  if (parent.headerViewController) {
    return;
  }
  MDCFlexibleHeaderViewController *hvc = [MDCFlexibleHeaderViewController new];
  parent.headerViewController = hvc;

  MDCFlexibleHeaderView *headerView = parent.headerViewController.headerView;

  // Shadow layer

  MDCFlexibleHeaderShadowIntensityChangeBlock intensityBlock = ^(CALayer *_Nonnull shadowLayer,
                                                                 CGFloat intensity) {
    CGFloat elevation = MDCShadowElevationAppBar * intensity;
    [(MDCShadowLayer *)shadowLayer setElevation:elevation];
  };
  [headerView setShadowLayer:[MDCShadowLayer new] intensityDidChangeBlock:intensityBlock];

  // Header stack view + navigation bar
  MDCAppBarViewController *appBarViewController = [MDCAppBarViewController new];
  [hvc addChildViewController:appBarViewController];
  [hvc.view addSubview:appBarViewController.view];
  [appBarViewController didMoveToParentViewController:hvc];

  [headerView forwardTouchEventsForView:appBarViewController.headerStackView];
  [headerView forwardTouchEventsForView:appBarViewController.navigationBar];

  parent.headerStackView = appBarViewController.headerStackView;
  parent.navigationBar = appBarViewController.navigationBar;

  if ([parent isKindOfClass:[UIViewController class]]) {
    [(UIViewController *)parent addChildViewController:hvc];
  }
}

void MDCAppBarAddViews(id<MDCAppBarParenting> parent) {
  MDCFlexibleHeaderViewController *fhvc = [parent headerViewController];
  if (fhvc.view.superview == fhvc.parentViewController.view) {
    return;
  }

  // Enforce the header's desire to fully cover the width of its parent view.
  CGRect frame = fhvc.view.frame;
  frame.origin.x = 0;
  frame.size.width = fhvc.parentViewController.view.bounds.size.width;
  fhvc.view.frame = frame;

  [fhvc.parentViewController.view addSubview:fhvc.view];
  [fhvc didMoveToParentViewController:fhvc.parentViewController];

  if ([parent isKindOfClass:[UIViewController class]]) {
    UIViewController *viewController = (UIViewController *)parent;
    [[parent navigationBar] observeNavigationItem:viewController.navigationItem];
  }
}