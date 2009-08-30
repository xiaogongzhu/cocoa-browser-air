//
//  MIHTMLParser.h
//
//  Created by numata on 09/03/01.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MIHTMLParser;


@protocol MIHTMLParserDelegate

@optional
- (void)htmlParserStart:(MIHTMLParser *)parser;
- (void)htmlParser:(MIHTMLParser *)parser willUseSubsetWithExternalID:(NSString *)externalID systemID:(NSString *)systemID;
- (void)htmlParserEnd:(MIHTMLParser *)parser;

- (void)htmlParser:(MIHTMLParser *)parser startTag:(NSString *)tagName attributes:(NSDictionary *)attrs;
- (void)htmlParser:(MIHTMLParser *)parser foundText:(NSString *)text;
- (void)htmlParser:(MIHTMLParser *)parser foundComment:(NSString *)comment;
- (void)htmlParser:(MIHTMLParser *)parser foundIgnorableWhitespace:(NSString *)str;
- (void)htmlParser:(MIHTMLParser *)parser endTag:(NSString *)tagName;

- (void)htmlParser:(MIHTMLParser *)parser warning:(NSString *)warning;
- (void)htmlParser:(MIHTMLParser *)parser error:(NSString *)error;
- (void)htmlParser:(MIHTMLParser *)parser fatalError:(NSString *)error;

@end


@interface MIHTMLParser : NSObject {
    NSObject<MIHTMLParserDelegate>  *mDelegate;
    NSStringEncoding                mEncoding;
}

@property(readwrite, assign) NSObject<MIHTMLParserDelegate> *delegate;
@property(readwrite, assign) NSStringEncoding               encoding;

- (BOOL)parseHTML:(NSString *)htmlStr;
- (BOOL)parseHTMLData:(NSData *)htmlData;

@end

