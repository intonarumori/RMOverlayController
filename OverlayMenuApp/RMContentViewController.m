//
//  RMContentViewController.m
//  OverlayMenuApp
//
//  Created by Daniel Langh on 27/01/15.
//  Copyright (c) 2015 rumori. All rights reserved.
//

#import "RMContentViewController.h"
#import "RMOverlayController.h"

@interface RMContentViewController ()

@property (nonatomic) UIStatusBarStyle statusBarStyle;
@property (nonatomic) BOOL statusBarHidden;

@end

@implementation RMContentViewController

- (IBAction)showOverlay:(id)sender
{
    [self.overlayController showOverlayViewControllerAnimated:YES];
}

- (IBAction)toggleStatusBarStyle:(id)sender
{
    self.statusBarStyle = (_statusBarStyle == UIStatusBarStyleLightContent) ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (IBAction)toggleStatusBarVisibility:(id)sender
{
    self.statusBarHidden = !_statusBarHidden;
    
    [UIView animateWithDuration:0.2 animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.statusBarStyle = UIStatusBarStyleDefault;
    self.statusBarHidden = NO;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"M" style:UIBarButtonItemStylePlain target:self action:@selector(showOverlay:)];
    
    NSLog(@"TOP %f", self.topLayoutGuide.length);

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"Content viewWillAppear");
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog(@"Content viewWillDisappear");
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"Content viewDidAppear");
}
- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog(@"Content viewDidDisappear");
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return _statusBarStyle;
}
- (BOOL)prefersStatusBarHidden
{
    return _statusBarHidden;
}

@end
