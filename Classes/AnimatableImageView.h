//
//  AnimatableImageView.h
//  Tumborine
//
//  Created by Nobuo Danjou on 10/08/07.
//  Copyright 2010 株式会社ソフリット. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AnimatableImageView : UIImageView {
	NSTimer *timer_;
	int animationIndex_;
}

- (void)animateGIF89a;
- (BOOL)isAnimatingGIF89a;
- (void)stopAnimatingGIF89a;
- (void)timerEvent:(NSTimer *)sender;

@end
