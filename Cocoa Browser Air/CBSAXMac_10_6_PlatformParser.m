//
//  CBSAXMac_10_6_PlatformParser.m
//  Cocoa Browser Air
//
//  Created by numata on 09/09/04.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXMac_10_6_PlatformParser.h"
#import "CBNode+MacPlatformSort.h"


@implementation CBSAXMac_10_6_PlatformParser

- (NSURL *)targetURL
{
    NSString *theURLStr = [mParentNode.URL absoluteString];
    theURLStr = [theURLStr stringByAppendingPathComponent:@"Contents/Resources/Documents/navigation/library.js"];
    return [NSURL URLWithString:theURLStr];;
}

- (void)parseJavaScriptInfos:(NSDictionary *)infos
{
#ifdef __DEBUG__
    NSLog(@"JS Infos: %@", infos);
#endif

    mParentNode.isLoaded = YES;
}

@end
