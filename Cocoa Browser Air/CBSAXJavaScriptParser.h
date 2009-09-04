//
//  CBSAXJavaScriptParser.h
//  Cocoa Browser Air
//
//  Created by numata on 09/03/27.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXParser.h"


@interface CBSAXJavaScriptParser : CBSAXParser {
}

+ (NSDictionary *)parseJavaScriptArray:(NSString *)scriptSource;

@end

