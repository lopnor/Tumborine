    //
//  TumblrViewController.m
//  Tumborine
//
//  Created by Nobuo Danjou on 10/07/12.
//  Copyright 2010 株式会社ソフリット. All rights reserved.
//

#import "TumblrViewController.h"
#import <libxml/tree.h>

@implementation TumblrViewController

- (id)init {
	self = [super init];
	if (self != nil) {
		queue_ = [[NSOperationQueue alloc] init];
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	imageview_ = [[AnimatableImageView alloc] initWithFrame:self.view.bounds];
	[self.view addSubview:imageview_];
	
	[self startOperation];
}

- (void)startOperation {
	entries_ = [[NSMutableArray alloc] init];
	TumblrAPIOperation *op = [[[TumblrAPIOperation alloc] init] autorelease];
	[op addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
	[queue_ addOperation:op];
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"cat2" ofType:@"gif"];
	AnimatableImage* image = [[AnimatableImage alloc] initWithData:[NSData dataWithContentsOfFile:path]];
	
	[self setimage:image];	
}

- (void)stopOperation {
	imageview_.backgroundColor = [UIColor blackColor];
	imageview_.image = nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([entries_ count] > 0) {
		NSMutableDictionary *dict = [entries_ objectAtIndex:0];
		AnimatableImage *image = [dict objectForKey:@"photo-url"];
		[self setimage:image];
		[entries_ removeObjectAtIndex:0];	
	}
}

- (void)setimage:(AnimatableImage *)image {
	
	CGSize size = image.size;
	
	if (size.height < size.width) {
		imageview_.bounds = CGRectMake(0,0,self.view.bounds.size.height, self.view.bounds.size.width);
		imageview_.transform = CGAffineTransformMakeRotation(90 * (M_PI / 180.0));
	} else {
		imageview_.bounds = self.view.bounds;
		imageview_.transform = CGAffineTransformMakeRotation(0);
	}
	imageview_.center = self.view.center;
	imageview_.contentMode = UIViewContentModeScaleAspectFit;
	imageview_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;	
	if (image.has_animation) {
		imageview_.image = nil;
		imageview_.animationImages = [image images];
		[imageview_ animateGIF89a];
	} else {
		if ([imageview_ isAnimatingGIF89a]) {
			[imageview_ stopAnimatingGIF89a];
			imageview_.animationImages = nil;
		}
		imageview_.image = image;
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSLog(@"key changed");
	TumblrAPIOperation *op = (TumblrAPIOperation *)object;
	[entries_ addObjectsFromArray:[op.entries copy]];	
	[object removeObserver:self forKeyPath:keyPath];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc {
	[queue_ release];
	[imageview_ release];
	[entries_ release];
    [super dealloc];
}

@end
