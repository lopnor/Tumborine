//
//  TumblrViewController.h
//  Tumborine
//
//  Created by Nobuo Danjou on 10/07/12.
//  Copyright 2010 株式会社ソフリット. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <libxml/tree.h>
#import "TumblrAPIOperation.h";
#import "AnimatableImage.h";
#import "AnimatableImageView.h";

@interface TumblrViewController : UIViewController {
	AnimatableImageView *imageview_;
	NSString *currentTag;
	NSMutableArray *entries_;
	NSOperationQueue *queue_;
	NSTimer *animationTimer_;
}

- (void)setimage:(AnimatableImage *)image;
- (void)startOperation;
- (void)stopOperation;

@end
