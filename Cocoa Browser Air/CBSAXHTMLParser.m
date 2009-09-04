//
//  CBSAXHTMLParser.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXHTMLParser.h"
#import "CBNode.h"


@implementation CBSAXHTMLParser

- (BOOL)parse
{
    [NSThread detachNewThreadSelector:@selector(parseProc:) toTarget:self withObject:nil];
    return YES;
}

- (void)parseProc:(id)dummy
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if (mDelegate && [mDelegate respondsToSelector:@selector(saxParserStarted:)]) {
        [mDelegate performSelectorOnMainThread:@selector(saxParserStarted:) withObject:self waitUntilDone:NO];
    }
    
    mHTMLParser = [[MIHTMLParser alloc] init];
    mHTMLParser.delegate = self;
    mHTMLParser.encoding = NSUTF8StringEncoding;

    NSData *htmlData = [[NSData alloc] initWithContentsOfURL:mParentNode.URL];
    [mHTMLParser parseHTMLData:htmlData];
    [htmlData release];
    [mHTMLParser release];
    
    if (mDelegate && [mDelegate respondsToSelector:@selector(saxParserFinished:)]) {
        [mDelegate performSelectorOnMainThread:@selector(saxParserFinished:) withObject:self waitUntilDone:NO];
    }
    
    [pool release];
}

- (void)htmlParserStart:(MIHTMLParser *)parser
{
    // Do nothing
}

- (void)htmlParser:(MIHTMLParser *)parser foundComment:(NSString *)comment
{
    // Do nothing
}

- (void)htmlParser:(MIHTMLParser *)parser startTag:(NSString *)tagName attributes:(NSDictionary *)attrs
{
    // Do nothing
}

- (void)htmlParser:(MIHTMLParser *)parser foundText:(NSString *)text
{
    // Do nothing
}

- (void)htmlParser:(MIHTMLParser *)parser endTag:(NSString *)tagName
{
    // Do nothing
}

- (void)htmlParserEnd:(MIHTMLParser *)parser
{
    // Do nothing
}

- (void)htmlParser:(MIHTMLParser *)parser willUseSubsetWithExternalID:(NSString *)externalID systemID:(NSString *)systemID
{
    // Do nothing
}

- (void)htmlParser:(MIHTMLParser *)parser warning:(NSString *)warning
{
    if (mDelegate && [mDelegate respondsToSelector:@selector(saxParserFacedWarning:)]) {
        [mDelegate performSelectorOnMainThread:@selector(saxParserFacedWarning:) withObject:warning waitUntilDone:NO];
    }
}

- (void)htmlParser:(MIHTMLParser *)parser error:(NSString *)error
{
    if (mDelegate && [mDelegate respondsToSelector:@selector(saxParserFacedError:)]) {
        [mDelegate performSelectorOnMainThread:@selector(saxParserFacedError:) withObject:error waitUntilDone:NO];
    }
}

- (void)htmlParser:(MIHTMLParser *)parser fatalError:(NSString *)error
{
    if (mDelegate && [mDelegate respondsToSelector:@selector(saxParserFacedFatalError:)]) {
        [mDelegate performSelectorOnMainThread:@selector(saxParserFacedFatalError:) withObject:error waitUntilDone:NO];
    }
}

@end

