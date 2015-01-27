//
//  AppDelegate.m
//  OverlayMenuApp
//
//  Created by Daniel Langh on 27/01/15.
//  Copyright (c) 2015 rumori. All rights reserved.
//

#import "AppDelegate.h"

#import "RMOverlayController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *menuViewController = [storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    UIViewController *contentViewController = [storyboard instantiateViewControllerWithIdentifier:@"Content"];
    
    //UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:contentViewController];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    RMOverlayController *overlayViewController = [[RMOverlayController alloc] initWithOverlayViewController:menuViewController
                                                                                      contentViewController:contentViewController];
    self.window.rootViewController = overlayViewController;
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
