//
//  CBSAXJavaScriptParser.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/27.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXJavaScriptParser.h"
#import "CBNode.h"
#import "NSString+Tokenizer.h"
#import "NSString+JsonParser.h"


typedef enum {
    CBSAXJavaScriptTypeJSON,
    CBSAXJavaScriptTypeArray,
} CBSAXJavaScriptType;


@interface CBSAXJavaScriptParser()

- (void)parseJavaScriptInfos:(id)infos;

@end


@implementation CBSAXJavaScriptParser

- (BOOL)parse
{
    [NSThread detachNewThreadSelector:@selector(parseProc:) toTarget:self withObject:nil];
    return YES;
}

- (NSURL *)targetURL
{
    return mParentNode.URL;
}

- (CBSAXJavaScriptType)checkJavaScriptTypeForSource:(NSString *)source
{
    unsigned pos = 0;
    unsigned length = [source length];
    while (pos < length) {
        unichar c = [source characterAtIndex:pos];
        
        // Skip Line Endings or white spaces
        if (c == '\r' || c == '\n' || isspace((int)c)) {
            pos++;
            continue;
        }
        
        // Skip Comment Lines
        if (c == '/') {
            pos++;
            if (pos < length) {
                do {
                    c = [source characterAtIndex:pos];
                    pos++;
                } while (pos < length && (c != '\r' && c != '\n'));
            }
            continue;
        }

        if (c == '[' || c == '{') {
            return CBSAXJavaScriptTypeJSON;
        } else {
            return CBSAXJavaScriptTypeArray;
        }
    }
    return CBSAXJavaScriptTypeArray;
}

- (void)parseProc:(id)dummy
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if (mDelegate && [mDelegate respondsToSelector:@selector(saxParserStarted:)]) {
        [mDelegate performSelectorOnMainThread:@selector(saxParserStarted:) withObject:self waitUntilDone:NO];
    }
    
    NSData *theData = [[NSData alloc] initWithContentsOfURL:[self targetURL]];
    NSString *sourceStr = [[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding];
    
    CBSAXJavaScriptType scriptType = [self checkJavaScriptTypeForSource:sourceStr];
    
    id infos = nil;
    if (scriptType == CBSAXJavaScriptTypeJSON) {
        infos = [sourceStr jsonObject];
    } else {
        infos = [CBSAXJavaScriptParser parseJavaScriptArray:sourceStr];
    }
    [self parseJavaScriptInfos:infos];
    
    [sourceStr release];
    [theData release];
    
    if (mDelegate && [mDelegate respondsToSelector:@selector(saxParserFinished:)]) {
        [mDelegate performSelectorOnMainThread:@selector(saxParserFinished:) withObject:self waitUntilDone:NO];
    }
    
    [pool release];
}

+ (NSDictionary *)parseJavaScriptArray:(NSString *)scriptSource
{
    NSMutableDictionary *infos = [NSMutableDictionary dictionary];
    
    NSEnumerator *enums = [scriptSource tokenize:@"\n"];
    
    NSMutableArray *lines = [NSMutableArray array];
    
    NSString *indexStr = nil;
    for (NSString *aStr in enums) {
        aStr = [aStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([aStr length] == 0) {
            continue;
        }
        if ([aStr hasSuffix:@"= new Array();"]) {
            continue;
        }
        NSEnumerator *parts = [aStr tokenize:@";"];
        for (NSString *aPart in parts) {
            aPart = [aPart stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [lines addObject:aPart];
        }
    }
    
    for (NSString *aStr in lines) {
        NSEnumerator *substrs = [aStr tokenize:@"[]\"=\'"];
        NSString *header = [substrs nextObject];
        if (![header isEqualToString:@"docs"] && ![header isEqualToString:@"docElt"]) {
            continue;
        }
        NSString *key = [substrs nextObject];
        if (!key) {
            continue;
        }
        NSString *value = [substrs nextObject];
        while (value && [value length] == 1) {
            value = [substrs nextObject];
        }
        if (!value) {
            continue;
        }
        if ([key isEqualToString:@"title"]) {
            indexStr = value;
        }
        if (!indexStr) {
            continue;
        }
        NSMutableDictionary *anInfo = [infos objectForKey:indexStr];
        if (!anInfo) {
            anInfo = [NSMutableDictionary dictionary];
            [infos setObject:anInfo forKey:indexStr];
        }
        [anInfo setObject:value forKey:key];
    }
    
    return infos;
}

- (void)parseJavaScriptInfos:(id)infos
{
    // Do nothing
}

@end

