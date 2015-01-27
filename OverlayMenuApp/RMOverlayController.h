//
//  RMOverlayViewController.h
//  OverlayMenuApp
//
//  Created by Daniel Langh on 27/01/15.
//  Copyright (c) 2015 rumori. All rights reserved.
//

#import <UIKit/UIKit.h>


@class RMOverlayController;

#pragma mark -

@interface UIViewController (RMOverlayControllerAdditions)

- (RMOverlayController *)overlayController;

@end

#pragma mark -

@protocol RMOverlayControllerDelegate <NSObject>

@optional
- (void)overlayControllerWillShowOverlayViewController:(RMOverlayController *)overlayController animated:(BOOL)animated;
- (void)overlayControllerWillHideOverlayViewController:(RMOverlayController *)overlayController animated:(BOOL)animated;

@end

#pragma mark -

@interface RMOverlayController : UIViewController

@property (nonatomic, strong) UIViewController *overlayViewController;
@property (nonatomic, strong) UIViewController *contentViewController;

@property (nonatomic, getter=isOverlayHidden) BOOL overlayHidden;

@property (nonatomic, weak) id<RMOverlayControllerDelegate> delegate;

- (instancetype)initWithOverlayViewController:(UIViewController *)overlayViewController
                        contentViewController:(UIViewController *)contentViewController;

- (void)showOverlayViewControllerAnimated:(BOOL)animated;
- (void)hideOverlayViewControllerAnimated:(BOOL)animated;

@end
