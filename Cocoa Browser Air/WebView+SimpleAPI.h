//
//  WebView+SimpleAPI.h
//  Cocoa Browser Air
//
//  Created by numata on 08/04/29.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface WebView (SimpleAPI)

- (void)loadURL:(NSURL *)URL;
- (void)loadURLString:(NSString *)URLString;
- (void)loadHTMLString:(NSString *)string;

@end
