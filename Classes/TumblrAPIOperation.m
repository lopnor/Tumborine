//
//  TumblrAPIOperation.m
//  Tumborine
//
//  Created by Nobuo Danjou on 10/07/24.
//  Copyright 2010 株式会社ソフリット. All rights reserved.
//

#import "TumblrAPIOperation.h"
#import "AnimatableImage.h"
#import <libxml/tree.h>

static xmlSAXHandler mySAXHandlerStruct;

@implementation TumblrAPIOperation

@synthesize entries = entries_;


- (id)init {
	self = [super init];
	if (self != nil) {
		finished_ = NO;
		executing_ = NO;
	}
	return self;
}

- (void)dealloc {
	[entries_ release];
	[super dealloc];
}

- (BOOL)isConcurrent { 
	return YES; 
}

- (BOOL)isFinished {
	return finished_;
}

- (BOOL)isExecuting {
	return executing_;
}

- (void)start {
	NSLog(@"Operation start");
	if ([self isCancelled]) {
		return;
	}
	UIApplication *app = [UIApplication sharedApplication];
	app.networkActivityIndicatorVisible = YES;

	[NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
	[self willChangeValueForKey:@"isExecuting"];
	executing_ = YES;
	[self didChangeValueForKey:@"isExecuting"];
}

- (void)main {
	NSLog(@"thread main");
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	
	NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://www.tumblr.com/api/dashboard"]];
	[req setHTTPMethod:@"POST"];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *email = [defaults stringForKey:@"email"];
	NSString *password = [defaults stringForKey:@"password"];
	
	NSString *body = [NSString stringWithFormat:@"email=%@&password=%@&type=photo&num=3",
					  [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
					  [password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
					  ];
	[req setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
	NSLog(@"request start");
	[[NSURLConnection alloc] initWithRequest:req delegate:self];
	NSLog(@"request sent");

	do {
		[[NSRunLoop currentRunLoop]
		 runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]
		 ];
	} while (![self isFinished]);
	[pool release];
		
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSLog(@"didReceiveResponse");
	parser_ = xmlCreatePushParserCtxt(&mySAXHandlerStruct, self, NULL, 0, NULL);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	NSLog(@"didReceiveData");
	xmlParseChunk(parser_, (const char *)[data bytes], [data length], 0);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSLog(@"connectionDidFinishLoading");
	xmlParseChunk(parser_, NULL, 0, 1);
}

- (void)putChars:(NSString *)chars {
	if ([entries_ count] > 0 && currentTag_ != nil) {
		NSMutableDictionary *dict = [entries_ objectAtIndex:[entries_ count] - 1];
		NSString *value = [dict valueForKey:currentTag_];
		[dict setValue:[value stringByAppendingString:chars] forKey:currentTag_];
	}
}

- (void)startElem:(NSString *)name withAttr:(NSMutableDictionary *)attr {
	currentTag_ = name;
	if ([name isEqualToString:@"posts"]) {
		entries_ = [[NSMutableArray alloc] init];
	} else if ([name isEqualToString:@"post"]) {
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		[entries_ addObject:dict];
	} else {
		if ([name isEqualToString:@"photo-url"]){
			if ([[attr valueForKey:@"max-width"] intValue] != 500) {
				currentTag_ = nil;
				return;
			}
		}
		NSMutableDictionary *dict =[entries_ objectAtIndex:[entries_ count] - 1];
		[dict setValue:@"" forKey:name];
	}
}

- (void)endElem:(NSString *)name {
	if ([currentTag_ isEqualToString:@"photo-url"]) {
		NSMutableDictionary *dict = [entries_ objectAtIndex:[entries_ count] - 1];
		NSURL *url = [NSURL URLWithString:[dict valueForKey:@"photo-url"]];
		NSLog(@"%@", url);
		[dict setObject:[[AnimatableImage alloc] initWithData:[NSData dataWithContentsOfURL:url]]
				 forKey:@"photo-url"];
	}
	if ([name isEqualToString:@"posts"]) {
		[self willChangeValueForKey:@"isFinished"];
		finished_ = YES;
		[self didChangeValueForKey:@"isFinished"];
		
		[self willChangeValueForKey:@"isExecuting"];
		executing_ = NO;
		[self didChangeValueForKey:@"isExecuting"];
		UIApplication *app = [UIApplication sharedApplication];
		app.networkActivityIndicatorVisible = NO;
	}
	currentTag_ = nil;
}

@end

static void charactersFoundSAX(void *ctx, const xmlChar *ch, int len) {
	TumblrAPIOperation *controller = (TumblrAPIOperation *)ctx;
	NSString *chars = [[NSString alloc] initWithBytes:ch length:len encoding:NSUTF8StringEncoding];
	[controller putChars:chars];
}


static void startElementSAX(void *ctx, 
							const xmlChar *localname,
							const xmlChar *prefix,
							const xmlChar *URI,
							int nb_namespaces,
							const xmlChar **namespaces,
							int nb_attributes,
							int nb_defaulted,
							const xmlChar **attributes) {
	TumblrAPIOperation *controller = (TumblrAPIOperation *)ctx;
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	for (int i = 0; nb_attributes > i; i++) {
		NSString *localname_attr = [[NSString alloc] initWithCString:(const char *)attributes[i * 5]];
		const xmlChar *valueBegin = attributes[i*5 + 3];
		const xmlChar *valueEnd = attributes[i*5 + 4];
		NSString *value = [[NSString alloc] initWithBytes:valueBegin length:(valueEnd - valueBegin) encoding:NSUTF8StringEncoding];
		[dict setValue:value forKey:localname_attr];
	}
	NSString *l = [[NSString alloc] initWithCString:(const char *)localname];
	[controller startElem:l withAttr:dict];
}

static void endElementSAX(void *ctx,
						  const xmlChar *localname,
						  const xmlChar *prefix,
						  const xmlChar *URI) {
	TumblrAPIOperation *controller = (TumblrAPIOperation *)ctx;
	NSString *n = [[NSString alloc] initWithCString:(const char *)localname];
	[controller endElem:n];
}

static xmlSAXHandler mySAXHandlerStruct = {
    NULL,                       /* internalSubset */
    NULL,                       /* isStandalone   */
    NULL,                       /* hasInternalSubset */
    NULL,                       /* hasExternalSubset */
    NULL,                       /* resolveEntity */
    NULL,                       /* getEntity */
    NULL,                       /* entityDecl */
    NULL,                       /* notationDecl */
    NULL,                       /* attributeDecl */
    NULL,                       /* elementDecl */
    NULL,                       /* unparsedEntityDecl */
    NULL,                       /* setDocumentLocator */
    NULL,                       /* startDocument */
    NULL,                       /* endDocument */
    NULL,                       /* startElement*/
    NULL,                       /* endElement */
    NULL,                       /* reference */
    charactersFoundSAX,         /* characters */
    NULL,                       /* ignorableWhitespace */
    NULL,                       /* processingInstruction */
    NULL,                       /* comment */
    NULL,                       /* warning */
    NULL, /*errorEncounteredSAX,        /* error */
    NULL,                       /* fatalError //: unused error() get all the errors */
    NULL,                       /* getParameterEntity */
    NULL,                       /* cdataBlock */
    NULL,                       /* externalSubset */
    XML_SAX2_MAGIC,             //
    NULL,
    startElementSAX,            /* startElementNs */
    endElementSAX,              /* endElementNs */
    NULL,                       /* serror */	
};