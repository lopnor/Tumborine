//
//  TumborineAppDelegate.h
//  Tumborine
//
//  Created by Nobuo Danjou on 10/07/12.
//  Copyright 株式会社ソフリット 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TumblrViewController.h";

@interface TumborineAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	TumblrViewController *tumblr;
}

@property (nonatomic, retain) UIWindow *window;

@end

