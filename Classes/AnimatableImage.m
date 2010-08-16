//
//  AnimatableImage.m
//  Tumborine
//
//  Created by Nobuo Danjou on 10/07/25.
//  Copyright 2010 株式会社ソフリット. All rights reserved.
//

#import "AnimatableImage.h"
#define UNKNOWN_BLOCK 0x00
#define PLAIN_TEXT_EXTENSION 0x01
#define GRAPHIC_CONTROL_EXTENSION 0xf9
#define COMMENT_EXTENSION 0xfe
#define APPLICATION_EXTENSION 0xff
#define EXTENSION_BLOCK 0x21
#define IMAGE_DATA_BLOCK 0x2C
#define TRAILER_BLOCK 0x3b

@implementation AnimatableImage

@synthesize has_animation = has_animation_;
@synthesize images;

- (id) initWithData:(NSData *)data {
	self = [super initWithData:data];
	if ([self parseData:data]) {
		has_animation_ = YES;
		images = [self getImageArray];
	} else {
		has_animation_ = NO;
	}
	return self;
}

- (NSArray *) getImageArray {
	if (!has_animation_) {
		return nil;
	}
	NSMutableArray *ret = [[NSMutableArray alloc] init];
	for (int i = 0; i < [imagedata_ count]; i++) {
		NSDictionary *dict = [imagedata_ objectAtIndex:i];
		NSData *body = [data_ subdataWithRange:NSMakeRange([[dict valueForKey:@"start"] intValue],[[dict valueForKey:@"length"] intValue])];
		NSMutableData *img = [[NSMutableData alloc] init];
		[img setData:[gif89a_header_ copy]];
		[img appendData:[global_color_table_ copy]];
		[img appendData:body];
		[img appendData:[[[NSNumber numberWithUnsignedChar:TRAILER_BLOCK] stringValue] dataUsingEncoding:NSUTF8StringEncoding]];
		[ret addObject:[[UIImage alloc] initWithData:img]];
	}
	return ret;
}

- (BOOL) parseData:(NSData *)data {
	if (data == nil) {
		return NO;
	}
	data_ = data;
	position_ = 0;
	if (![self parseHeader]) {
		return NO;
	}
	imagedata_ = [[NSMutableArray alloc] init];
	NSMutableDictionary *block;
	BOOL found_application_extension;
	NSDictionary *img;
	NSNumber *length;
	while (block = [self parseBlock]) {
		unsigned char key = [[block valueForKey:@"type"] unsignedCharValue];
		if (key == TRAILER_BLOCK) {
			break;
		}
		switch (key) {
			case APPLICATION_EXTENSION:
				found_application_extension = YES;
				break;
			case GRAPHIC_CONTROL_EXTENSION:
				[block removeObjectForKey:@"key"];
				[imagedata_ addObject:block];
				break;
			case IMAGE_DATA_BLOCK:
				img = [imagedata_ lastObject];
				length = [NSNumber numberWithInt:[[img valueForKey:@"length"] intValue] + [[block valueForKey:@"length"] intValue]];
				[img setValue:length forKey:@"length"];
				break;
			default:
				break;
		}
	}
	return found_application_extension;
}

- (BOOL) parseHeader {
	gif89a_header_ = [self read:13];
	NSString *sign = [[NSString alloc] initWithData:[gif89a_header_ subdataWithRange:NSMakeRange(0, 6)] encoding:NSUTF8StringEncoding];
	if (! [sign isEqualToString:@"GIF89a"]) {
		return NO;
	}
	unsigned char packed[1];
	[gif89a_header_ getBytes:packed range:NSMakeRange(10, 1)];
	int global_color_table_length = (2 << (packed[0] & 0x07)) * 3;
	global_color_table_ = [self read:global_color_table_length];
	return YES;
}

- (NSData *) read:(int)length {
	NSData *ret = [data_ subdataWithRange:NSMakeRange(position_, length)];
	position_ += length;
	return ret;
}

- (NSNumber *) readint {
	unsigned char aBuffer[1];
	[[self read:1] getBytes:aBuffer length:1];
	return [NSNumber numberWithUnsignedChar: aBuffer[0]];
}

- (BOOL) readdata {
	NSNumber *length = [self readint];
	if ([length isEqualToNumber:[NSNumber numberWithInt:0]]) {
		return NO;
	}
	[self read:[length intValue]];
	return YES;
}

- (void) readdataseq {
	BOOL b = YES;
	while (b) {
		b = [self readdata];
	}
}

- (NSMutableDictionary *) parseBlock {
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	int pos = position_;
	[dict setValue:[NSNumber numberWithUnsignedChar:UNKNOWN_BLOCK] forKey:@"type"];
	[dict setValue:[NSNumber numberWithInt:pos] forKey:@"start"];
	NSNumber *intro = [self readint];
	switch ([intro unsignedCharValue]) {
		case EXTENSION_BLOCK:
			[dict setValue:[self readint] forKey:@"type"];
			[self readdataseq];
			break;
		case IMAGE_DATA_BLOCK:
			[dict setValue:intro forKey:@"type"];
			NSData *header = [self read:9];
			unsigned char packed;
			[header getBytes:&packed range:NSMakeRange(8, 1)];
			if (packed & 0x80) {
				int local_color_table_length = (2 << (packed & 0x07)) * 3;
				[self read:local_color_table_length];
			}
			[self read:1];
			[self readdataseq];
			break;
		case TRAILER_BLOCK:
			[dict setValue:intro forKey:@"type"];
			break;
		default:
			break;
	}
	[dict setValue:[NSNumber numberWithInt:(position_ - pos)] forKey:@"length"];
	if ([[dict valueForKey:@"type"] isEqualToValue:[NSNumber numberWithUnsignedChar:UNKNOWN_BLOCK]]) {
		return nil;
	} else {
		return dict;
	}

}

@end
