//
//  TumblrAPIOperation.h
//  Tumborine
//
//  Created by Nobuo Danjou on 10/07/24.
//  Copyright 2010 株式会社ソフリット. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>

@interface TumblrAPIOperation : NSOperation {
	xmlParserCtxtPtr parser_;
	NSString *currentTag_;
	NSMutableArray *entries_;
	BOOL executing_, finished_;
}

@property (readonly) NSMutableArray *entries;
@end
