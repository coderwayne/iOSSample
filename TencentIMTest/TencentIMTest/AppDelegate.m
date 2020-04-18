//
//  AppDelegate.m
//  OFweekPhone
//
//  Created by 胡晓伟 on 16/3/10.
//  Copyright © 2016年 ofweek. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    if (@available(iOS 13.0, *)) {
        self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        [[UITabBar appearance] setUnselectedItemTintColor:[UIColor lightGrayColor]];
    }


    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

//获取Window当前显示的ViewController
- (UIViewController*)currentViewController{
    
    UIViewController* vc = [self rootViewController];
    
    while (1) {
        if ([vc isKindOfClass:[UITabBarController class]]) {
            vc = ((UITabBarController*)vc).selectedViewController;
        }
        
        if ([vc isKindOfClass:[UINavigationController class]]) {
            vc = ((UINavigationController*)vc).visibleViewController;
        }
        
        if (vc.presentedViewController) {
            vc = vc.presentedViewController;
        }else{
            break;
        }
        
    }
    
    return vc;
}

- (UIViewController *)rootViewController{
    UIWindow* window = [UIApplication sharedApplication].keyWindow;
    return window.rootViewController;
}


@end
