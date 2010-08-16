//
//  AnimatableImage.h
//  Tumborine
//
//  Created by Nobuo Danjou on 10/07/25.
//  Copyright 2010 株式会社ソフリット. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnimatableImage : UIImage {
@private
	int position_;
	NSData *data_;
	NSData *gif89a_header_;
	NSData *global_color_table_;
	NSMutableArray *imagedata_;
	NSArray *images;
@public
	BOOL has_animation_;
}

@property (readonly) BOOL has_animation;
@property (readonly) NSArray *images;

- (BOOL) parseData:(NSData *)data;
- (BOOL) parseHeader;
- (NSData *) read:(int)length;
- (NSNumber *) readint;
- (BOOL) readdata;
- (void) readdataseq;
- (NSMutableDictionary *) parseBlock;
- (NSArray *) getImageArray;

@end
