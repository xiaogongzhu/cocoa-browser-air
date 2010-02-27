//
//  WebView+SimpleAPI.m
//  Cocoa Browser Air
//
//  Created by numata on 08/04/29.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import "WebView+SimpleAPI.h"


@implementation WebView (SimpleAPI)

- (void)loadURL:(NSURL *)URL
{
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    WebFrame *frame = [self mainFrame];
    [frame loadRequest:request];
}

- (void)loadURLString:(NSString *)URLString
{
    NSURL *URL = [NSURL URLWithString:URLString];
    [self loadURL:URL];
}

- (void)loadHTMLString:(NSString *)string
{
    WebFrame *frame = [self mainFrame];
    [frame loadHTMLString:string baseURL:nil];
}

@end
