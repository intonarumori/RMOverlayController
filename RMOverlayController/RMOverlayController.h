//
//  RMOverlayViewController.h
//  OverlayMenuApp
//
//  Created by Daniel Langh on 27/01/15.
//  Copyright (c) 2015 rumori. All rights reserved.
//

#import <UIKit/UIKit.h>


@class RMOverlayController;

@interface UIViewController (RMOverlayControllerAdditions)

- (RMOverlayController *)overlayController;
- (void)setNeedsOverlayMenuUpdate;
- (BOOL)prefersOverlayMenuDisabled;

@end

#pragma mark -

@protocol RMOverlayControllerDelegate <NSObject>

@optional
- (void)overlayControllerDidShowOverlayViewController:(RMOverlayController *)overlayController animated:(BOOL)animated;
- (void)overlayControllerDidHideOverlayViewController:(RMOverlayController *)overlayController animated:(BOOL)animated;

@end

#pragma mark -

@interface RMOverlayController : UIViewController

@property (nonatomic, strong) UIViewController *overlayViewController;
@property (nonatomic, strong) UIViewController *contentViewController;

@property (nonatomic, assign) CGFloat overlayWidth;

@property (nonatomic, getter=isOverlayHidden) BOOL overlayHidden;
@property (nonatomic, assign) BOOL overlayEnabled;

@property (nonatomic, weak) id<RMOverlayControllerDelegate> delegate;

- (instancetype)initWithOverlayViewController:(UIViewController *)overlayViewController
                        contentViewController:(UIViewController *)contentViewController;

- (void)showOverlayViewControllerAnimated;
- (void)hideOverlayViewControllerAnimated;
- (void)setup NS_REQUIRES_SUPER;

@end

// UIGestureRecognizerDelegate




