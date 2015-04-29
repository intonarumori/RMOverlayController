//
//  RMOverlayViewController.m
//  OverlayMenuApp
//
//  Created by Daniel Langh on 27/01/15.
//  Copyright (c) 2015 rumori. All rights reserved.
//

#import "RMOverlayController.h"

#import <objc/runtime.h>


#define kOverlayAnimationDuration 0.2f
#define kOverlaySpringAnimationDuration 0.4f
#define kFadeMaxAlpha 0.5f
#define kPanVelocityThreshold 700.0f

// this is a guess: it's used to remove the gesture detection threshold jump when swiping from the edge
#define kEdgePanThreshold 20.0f


#import <Foundation/Foundation.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

typedef NS_ENUM(NSUInteger, RMDirectionPangestureRecognizerDirection) {
    RMDirectionPangestureRecognizerVertical,
    RMDirectionPanGestureRecognizerHorizontal
};

@interface RMDirectionPanGestureRecognizer : UIPanGestureRecognizer {
    BOOL _drag;
    int _moveX;
    int _moveY;
}

@property (nonatomic, assign) RMDirectionPangestureRecognizerDirection direction;
@property (nonatomic, assign) CGPoint globalStartPoint;

@end


/**-----------------------------------------------------------------------------
 * @name Direction Pan Gesture Recognizer
 * -----------------------------------------------------------------------------
 */

int const static kDirectionPanThreshold = 5;

@implementation RMDirectionPanGestureRecognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [super touchesBegan:touches withEvent:event];
    self.globalStartPoint = [self locationInView:nil];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    if (self.state == UIGestureRecognizerStateFailed) return;
    
    CGPoint nowPoint = [[touches anyObject] locationInView:self.view];
    CGPoint prevPoint = [[touches anyObject] previousLocationInView:self.view];
    _moveX += prevPoint.x - nowPoint.x;
    _moveY += prevPoint.y - nowPoint.y;
    if (!_drag) {
        if (abs(_moveX) > kDirectionPanThreshold) {
            if (_direction == RMDirectionPangestureRecognizerVertical) {
                self.state = UIGestureRecognizerStateFailed;
            } else {
                _drag = YES;
            }
        }
        else if (abs(_moveY) > kDirectionPanThreshold) {
            if (_direction == RMDirectionPanGestureRecognizerHorizontal) {
                self.state = UIGestureRecognizerStateFailed;
            } else {
                _drag = YES;
            }
        }
    }
}

- (void)reset
{
    [super reset];
    _drag = NO;
    _moveX = 0;
    _moveY = 0;
}

@end

#pragma mark -


@interface RMOverlayController () <UIGestureRecognizerDelegate>

// menu parts
@property (nonatomic, strong) UIView *fadeView;
@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *edgePanGestureRecognizer;
@property (nonatomic, strong) RMDirectionPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic, assign) BOOL cumulativeOverlayEnabled;

// menu
@property (nonatomic, readonly) UIView *overlayView;

- (void)updateOverlayMenu;

@end

#pragma mark -

static char UIViewControllerOverlayControllerKey;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation UIViewController (RMOverlayControllerAdditions)

#pragma clang diagnostic pop

- (RMOverlayController *)overlayController
{
    RMOverlayController *overlayController = objc_getAssociatedObject(self, &UIViewControllerOverlayControllerKey);
    if (overlayController == nil && self.navigationController) overlayController = self.navigationController.overlayController;
    if (overlayController == nil && self.tabBarController) overlayController = self.tabBarController.overlayController;
    return overlayController;
}

- (void)setNeedsOverlayMenuUpdate
{
    RMOverlayController *overlayController = self.overlayController;
    
    if(self.overlayController == nil) return;
    
    [overlayController updateOverlayMenu];
}

- (BOOL)rm_prefersOverlayMenuDisabled
{
    if([super respondsToSelector:@selector(prefersOverlayMenuDisabled)])
    {
        BOOL prefers = (BOOL)[super performSelector:@selector(prefersOverlayMenuDisabled)];
        return prefers;
    }
    return NO;
}

@end

#pragma mark -

@implementation RMOverlayController

@synthesize overlayViewController = _overlayViewController;
@synthesize contentViewController = _contentViewController;


- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithOverlayViewController:(UIViewController *)overlayViewController contentViewController:(UIViewController *)contentViewController
{
    self = [super init];
    if(self)
    {
        [self setup];
        self.contentViewController = contentViewController;
        self.overlayViewController = overlayViewController;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _overlayWidth = 200.0f;
    _overlayEnabled = YES;
}

#pragma mark - Lifecycle

- (void)loadView
{
    [super loadView];
    
    self.fadeView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.fadeView.backgroundColor = [UIColor blackColor];
    self.fadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.fadeView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fadeTap:)]];
    
    RMDirectionPanGestureRecognizer *panGestureRecognizer = [[RMDirectionPanGestureRecognizer alloc] initWithTarget:self action:@selector(fadePan:)];
    panGestureRecognizer.direction = RMDirectionPanGestureRecognizerHorizontal;
    [self.fadeView addGestureRecognizer:panGestureRecognizer];
    
    panGestureRecognizer = [[RMDirectionPanGestureRecognizer alloc] initWithTarget:self action:@selector(fadePan:)];
    panGestureRecognizer.direction = RMDirectionPanGestureRecognizerHorizontal;
    self.panGestureRecognizer = panGestureRecognizer;
    
    UIScreenEdgePanGestureRecognizer *edgeGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(edgePan:)];
    edgeGestureRecognizer.edges = UIRectEdgeLeft;
    edgeGestureRecognizer.delegate = self;
    self.edgePanGestureRecognizer = edgeGestureRecognizer;
    
    [self.view addGestureRecognizer:edgeGestureRecognizer];
    
    [self updateCumulativeOverlayEnabled];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.overlayHidden = YES;
    
    // add controllers
    if (self.contentViewController) [self addContentViewController:self.contentViewController];
    if (self.overlayViewController) [self addOverlayViewController:self.overlayViewController];
}

#pragma mark - Accessors

- (void)setOverlayViewController:(UIViewController *)overlayViewController
{
    if (_overlayViewController) {
        objc_setAssociatedObject(_overlayViewController, &UIViewControllerOverlayControllerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    _overlayViewController = overlayViewController;
    
    if (_overlayViewController) {
        objc_setAssociatedObject(_overlayViewController, &UIViewControllerOverlayControllerKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (self.isViewLoaded) [self addOverlayViewController:_overlayViewController];
    }
}

- (void)setContentViewController:(UIViewController *)contentViewController
{
    if (_contentViewController) {
        objc_setAssociatedObject(_contentViewController, &UIViewControllerOverlayControllerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self removeContentViewController:_contentViewController];
    }
    
    _contentViewController = contentViewController;
    
    if (_contentViewController) {
        objc_setAssociatedObject(_contentViewController, &UIViewControllerOverlayControllerKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (self.isViewLoaded)
        {
            [self addContentViewController:_contentViewController];
            [self updateOverlayMenu];
        }
        
        
    }
    if (_overlayViewController) {
        [self.view bringSubviewToFront:self.overlayViewController.view];
    }
}

#pragma mark -

- (void)updateOverlayMenu
{
    [self updateCumulativeOverlayEnabled];
}


- (void)updateCumulativeOverlayEnabled
{
    BOOL prefers = [self prefersOverlayMenuDisabledByContentViewController];
    BOOL enabled = _overlayEnabled;
    
    self.cumulativeOverlayEnabled = !prefers && enabled;
    
    [self updateEdgePanGesture];
}

- (void)updateEdgePanGesture
{
    BOOL enabled = self.cumulativeOverlayEnabled && self.overlayHidden;
    self.edgePanGestureRecognizer.enabled = enabled;
    //NSLog(@"overlay enabled %d", self.cumulativeOverlayEnabled);
}

- (BOOL)prefersOverlayMenuDisabledByContentViewController
{
    BOOL prefersOverlayMenuDisabled = NO;
    if(_contentViewController)
    {
        prefersOverlayMenuDisabled = [_contentViewController rm_prefersOverlayMenuDisabled];
    }
    return prefersOverlayMenuDisabled;
    
}

#pragma mark - width

- (void)setOverlayWidth:(CGFloat)overlayWidth
{
    _overlayWidth = overlayWidth;
    
    if(self.isViewLoaded)
    {
        // hopefully works
        if(self.overlayHidden)
            [self finishHidingAnimated];
        else
            [self finishShowingAnimated];
    }
}


#pragma mark - Gesture handling

- (void)fadeTap:(UIGestureRecognizer *)tapGestureRecognizer
{
    [self hideOverlayViewControllerAnimated];
}

- (void)fadePan:(RMDirectionPanGestureRecognizer *)panGestureRecognizer
{
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        {
            CGPoint startPoint = panGestureRecognizer.globalStartPoint;
            CGPoint currentPoint = [panGestureRecognizer locationInView:nil];
            
            CGFloat offsetX = startPoint.x - currentPoint.x;
            [self updateShowingWithPercent: (1 - offsetX / self.overlayWidth)];
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        {
            BOOL shouldHideByVelocity = [panGestureRecognizer velocityInView:panGestureRecognizer.view].x < -kPanVelocityThreshold;
            BOOL shouldHideByPosition = self.overlayView.center.x < 0.0f;
            
            if (shouldHideByPosition || shouldHideByVelocity) {
                [self finishHidingAnimated];
            } else {
                [self finishShowingAnimated];
            }
        }
            break;
        default:
            break;
    }
}

- (void)edgePan:(UIScreenEdgePanGestureRecognizer *)panGestureRecognizer
{
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self startShowing];
        case UIGestureRecognizerStateChanged:
        {
            CGFloat offsetX = [panGestureRecognizer locationInView:panGestureRecognizer.view].x;
            CGFloat percent = (offsetX - kEdgePanThreshold) / self.overlayWidth;
            [self updateShowingWithPercent:percent];
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        {
            BOOL shouldShowByVelocity = [panGestureRecognizer velocityInView:panGestureRecognizer.view].x > kPanVelocityThreshold;
            BOOL shouldShowByPosition = self.overlayView.center.x > 0.0f;
            
            if (shouldShowByVelocity || shouldShowByPosition) {
                [self finishShowingAnimated];
            } else {
                [self finishHidingAnimated];
            }
        }
        default:
            break;
    }
}

#pragma mark -

- (void)setOverlayEnabled:(BOOL)overlayEnabled
{
    _overlayEnabled = overlayEnabled;
    [self updateOverlayMenu];
}

#pragma mark - Animation handling

- (void)showOverlayViewControllerAnimated
{
    if (!_overlayHidden) return;
    if (![self overlayEnabled]) return;
    
    [self startShowing];
    [self finishShowingAnimated];
}

- (void)hideOverlayViewControllerAnimated
{
    if (_overlayHidden) return;
    if (![self overlayEnabled]) return;
    
    [self finishHidingAnimated];
}

- (void)startShowing
{
    self.overlayView.hidden = NO;
    
    self.fadeView.frame = self.view.bounds;
    self.fadeView.alpha = 0.0f;
    [self.view insertSubview:self.fadeView belowSubview:self.overlayView];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)finishShowingAnimated
{
    self.overlayHidden = NO;
    self.overlayView.hidden = NO;
    
    [UIView animateWithDuration:kOverlaySpringAnimationDuration
                          delay:0.0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self updateShowingWithPercent:1.0f];
                     }
                     completion:^(BOOL finished) {
                         
                         if ([_delegate respondsToSelector:@selector(overlayControllerDidShowOverlayViewController:animated:)]) {
                             [_delegate overlayControllerDidShowOverlayViewController:self animated:YES];
                         }
                         
                     }];
}

- (void)finishHidingAnimated
{
    self.overlayHidden = YES;
    
    [UIView animateWithDuration:kOverlayAnimationDuration animations:^{
        [self updateShowingWithPercent:0.0f];
    } completion:^(BOOL finished) {
        
        [self.fadeView removeFromSuperview];
        [self setNeedsStatusBarAppearanceUpdate];
        if ([_delegate respondsToSelector:@selector(overlayControllerDidHideOverlayViewController:animated:)]) {
            [_delegate overlayControllerDidHideOverlayViewController:self animated:YES];
        }
        
        self.overlayView.hidden = YES;
        
    }];
}

- (void)updateShowingWithPercent:(CGFloat)percent
{
    percent = MIN(percent, 1.0f);
    self.overlayView.frame = CGRectMake(-self.overlayWidth * (1.0f-percent), 0, self.overlayWidth, self.view.bounds.size.height);
    self.fadeView.alpha = kFadeMaxAlpha * percent;
}

#pragma mark -

- (void)setOverlayHidden:(BOOL)overlayHidden
{
    _overlayHidden = overlayHidden;
    [self updateEdgePanGesture];
}

#pragma mark - Status bar handling

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.contentViewController) {
        return [self.contentViewController preferredStatusBarStyle];
    }
    return UIStatusBarStyleLightContent;
}
- (BOOL)prefersStatusBarHidden
{
    // TODO: more logic?
    
    //if (!_overlayHidden) return YES;
    
    if (self.contentViewController) {
        return [self.contentViewController prefersStatusBarHidden];
    }
    return NO;
}

#pragma mark - Helpers

- (void)removeContentViewController:(UIViewController *)contentViewController
{
    [contentViewController willMoveToParentViewController:nil];
    [contentViewController.view removeFromSuperview];
    [contentViewController removeFromParentViewController];
}

- (void)addContentViewController:(UIViewController *)contentViewController
{
    [self addChildViewController:contentViewController];
    contentViewController.view.frame = self.view.frame;
    if([contentViewController.view respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)])
    {
        [contentViewController.view setPreservesSuperviewLayoutMargins:YES];
    }
    contentViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:contentViewController.view];
    [contentViewController didMoveToParentViewController:self];
}

- (void)removeOverlayViewController:(UIViewController *)overlayViewController
{
    [overlayViewController willMoveToParentViewController:nil];
    [overlayViewController.view removeFromSuperview];
    [overlayViewController.view removeGestureRecognizer:_panGestureRecognizer];
}

- (void)addOverlayViewController:(UIViewController *)overlayViewController
{
    [self addChildViewController:overlayViewController];
    overlayViewController.view.frame = CGRectMake(-self.overlayWidth, 0, self.overlayWidth, self.view.bounds.size.height);
    if([overlayViewController.view respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)])
    {
        [overlayViewController.view setPreservesSuperviewLayoutMargins:YES];
    }
    
    overlayViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:overlayViewController.view];
    [overlayViewController didMoveToParentViewController:self];
    
    [self.overlayViewController.view addGestureRecognizer:self.panGestureRecognizer];
}

#pragma mark -

- (UIView *)overlayView
{
    return self.overlayViewController.view;
}

@end

