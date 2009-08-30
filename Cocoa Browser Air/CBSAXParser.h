//
//  CBSAXParser.h
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class CBNode;
@class CBSAXParser;


@protocol CBSAXParserDelegate
@optional
- (void)saxParserStarted:(CBSAXParser *)parser;

// どんなエラーが起こった場合でも saxParserFinished: が最後に呼ばれます。
- (void)saxParserFinished:(CBSAXParser *)parser;

- (void)saxParserFacedWarning:(NSString *)warning;
- (void)saxParserFacedError:(NSString *)error;
- (void)saxParserFacedFatalError:(NSString *)error;

@end


@interface CBSAXParser : NSObject {
    CBNode  *mParentNode;
    NSObject<CBSAXParserDelegate>   *mDelegate;
}

@property(readwrite, assign) NSObject<CBSAXParserDelegate> *delegate;

+ (CBSAXParser *)createParserForNode:(CBNode *)aNode;

- (id)initWithParentNode:(CBNode *)parentNode;

- (BOOL)parse;

@end

