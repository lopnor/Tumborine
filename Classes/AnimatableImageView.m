//
//  AnimatableImageView.m
//  Tumborine
//
//  Created by Nobuo Danjou on 10/08/07.
//  Copyright 2010 株式会社ソフリット. All rights reserved.
//

#import "AnimatableImageView.h"


@implementation AnimatableImageView

- (void)animateGIF89a {
	animationIndex_ = 0;
	timer_ = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerEvent:) userInfo:nil repeats:YES];
}

- (BOOL)isAnimatingGIF89a {
	return [timer_ isValid];
}

- (void)stopAnimatingGIF89a {
	[timer_ invalidate];
	timer_ = nil;
}

- (void)timerEvent:(NSTimer *)sender {

	UIGraphicsBeginImageContext(self.bounds.size);
	UIImage *i = [self.animationImages objectAtIndex:animationIndex_];
	if (self.image) {
		[self.image drawInRect:self.bounds];
	}
	[i drawInRect:self.bounds blendMode:kCGBlendModeNormal alpha:1];
	self.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	if (animationIndex_ + 1 == [self.animationImages count]) {
		animationIndex_ = 0;
	} else {
		animationIndex_++;
	}

}

@end
