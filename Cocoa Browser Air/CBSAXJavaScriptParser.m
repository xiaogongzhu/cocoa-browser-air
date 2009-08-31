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


@interface CBSAXJavaScriptParser()

- (void)parseJavaScriptInfos:(NSDictionary *)infos;

@end


@implementation CBSAXJavaScriptParser

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
    
    NSData *theData = [[NSData alloc] initWithContentsOfURL:mParentNode.URL];
    NSString *sourceStr = [[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding];
    
    NSDictionary *infos = nil;
    if ([sourceStr hasPrefix:@"["]) {
        infos = [CBSAXJavaScriptParser parseJavaScriptJSON:sourceStr];
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

+ (NSDictionary *)parseJavaScriptJSON:(NSString *)scriptSource
{
    NSMutableDictionary *infos = [NSMutableDictionary dictionary];

    unsigned pos = 0;
    unsigned length = [scriptSource length];
    
    NSMutableDictionary *currentInfo = [NSMutableDictionary dictionary];
    
    while (pos < length) {
        // シングルクォーテーション(')を探す
        NSUInteger keyStartPos = NSNotFound;
        while (pos < length) {
            unichar c = [scriptSource characterAtIndex:pos];
            pos++;
            if (c == '}') {
                NSString *title = [currentInfo objectForKey:@"title"];
                if (title) {
                    [infos setObject:currentInfo forKey:title];
                }
                currentInfo = [NSMutableDictionary dictionary];
            }
            if (c == '\'') {
                keyStartPos = pos;
                break;
            }
        }
        if (keyStartPos == NSNotFound) {
            break;
        }
        
        // シングルクォーテーション(')を探す
        NSUInteger keyEndPos = NSNotFound;
        while (pos < length) {
            unichar c = [scriptSource characterAtIndex:pos];
            pos++;
            if (c == '\'') {
                keyEndPos = pos;
                break;
            }
            else if (c == '\\') {
                pos++;
            }
        }
        if (keyEndPos == NSNotFound) {
            break;
        }
        
        // シングルクォーテーション(')を探す
        NSUInteger valueStartPos = NSNotFound;
        while (pos < length) {
            unichar c = [scriptSource characterAtIndex:pos];
            pos++;
            if (c == '\'') {
                valueStartPos = pos;
                break;
            }
        }
        if (valueStartPos == NSNotFound) {
            break;
        }
        
        // シングルクォーテーション(')を探す
        NSUInteger valueEndPos = NSNotFound;
        while (pos < length) {
            unichar c = [scriptSource characterAtIndex:pos];
            pos++;
            if (c == '\'') {
                valueEndPos = pos;
                break;
            }
            else if (c == '\\') {
                pos++;
            }
        }
        if (keyEndPos == NSNotFound) {
            break;
        }
        
        NSString *keyStr = [scriptSource substringWithRange:NSMakeRange(keyStartPos, keyEndPos - keyStartPos - 1)];
        NSString *valueStr = [scriptSource substringWithRange:NSMakeRange(valueStartPos, valueEndPos - valueStartPos - 1)];
        
        [currentInfo setObject:valueStr forKey:keyStr];
    }

    NSString *title = [currentInfo objectForKey:@"title"];
    if (title) {
        [infos setObject:currentInfo forKey:title];
    }
    
    return infos;
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

- (void)parseJavaScriptInfos:(NSDictionary *)infos
{
    // Do nothing
}

@end

