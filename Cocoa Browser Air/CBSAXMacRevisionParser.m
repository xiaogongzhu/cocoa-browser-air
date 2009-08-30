//
//  CBSAXMacRevisionParser.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/09.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXMacRevisionParser.h"
#import "CBNode.h"
#import "NSURL+RelativeAddress.h"


@implementation CBSAXMacRevisionParser

- (void)htmlParserStart:(MIHTMLParser *)parser
{
    mHasStarted = NO;
    mHTMLSource = [[NSMutableString alloc] init];
}

- (void)htmlParser:(MIHTMLParser *)parser foundComment:(NSString *)comment
{
    // Do nothing
}

- (void)htmlParser:(MIHTMLParser *)parser startTag:(NSString *)tagName attributes:(NSDictionary *)attrs
{
    if ([tagName isEqualToString:@"h1"]) {
        mHasStarted = YES;
    }
    if (mHasStarted) {
        if ([tagName isEqualToString:@"hr"] ||
            [tagName isEqualToString:@"div"] && [[attrs objectForKey:@"class"] isEqualToString:@"mini_nav_text"])
        {
            mHasStarted = NO;
            return;
        }
        
        [mHTMLSource appendString:@"<"];
        [mHTMLSource appendString:tagName];
        for (NSString *key in attrs) {
            NSString *value = [attrs objectForKey:key];
            [mHTMLSource appendString:@" "];
            [mHTMLSource appendString:key];
            [mHTMLSource appendString:@"=\""];
            if ([tagName isEqualToString:@"a"] && [key isEqualToString:@"href"]) {
                NSURL *theURL = [NSURL numataURLWithString:value relativeToURL:mParentNode.URL];
                [mHTMLSource appendString:[theURL absoluteString]];
            } else if ([tagName isEqualToString:@"img"] && [key isEqualToString:@"src"]) {
                NSURL *theURL = [NSURL numataURLWithString:value relativeToURL:mParentNode.URL];
                [mHTMLSource appendString:[theURL absoluteString]];
            } else {
                [mHTMLSource appendString:value];
            }
            [mHTMLSource appendString:@"\""];
        }
        [mHTMLSource appendString:@">"];
    }
}

- (void)htmlParser:(MIHTMLParser *)parser foundText:(NSString *)text
{
    if (mHasStarted) {
        [mHTMLSource appendString:text];
    }
}

- (void)htmlParser:(MIHTMLParser *)parser endTag:(NSString *)tagName
{
    if (mHasStarted) {
        if (![tagName isEqualToString:@"br"]) {
            [mHTMLSource appendString:@"</"];
            [mHTMLSource appendString:tagName];
            [mHTMLSource appendString:@">"];
        }
    }
}

- (void)htmlParserEnd:(MIHTMLParser *)parser
{
    if (mHTMLSource) {
        NSString *source = mHTMLSource;
        int loopCount = 100;
        while (loopCount > 0) {
            source = [source stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([source hasSuffix:@"<br>"]) {
                source = [source substringToIndex:[source length]-4];
            } else if ([source hasSuffix:@"<br/>"]) {
                source = [source substringToIndex:[source length]-5];
            } else {
                break;
            }
            loopCount--;
        }
        mParentNode.contentHTMLSource = source;
        [mHTMLSource release];
        mHTMLSource = nil;
    }
    mParentNode.isLoaded = YES;
}

- (void)htmlParser:(MIHTMLParser *)parser willUseSubsetWithExternalID:(NSString *)externalID systemID:(NSString *)systemID
{
    // Do nothing
}

@end

