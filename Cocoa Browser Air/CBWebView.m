//
//  CBWebView.m
//  Cocoa Browser Air
//
//  Created by numata on 08/05/07.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CBWebView.h"


@implementation CBWebView

- (void)keyDown:(NSEvent *)theEvent
{
    unsigned short keyCode = [theEvent keyCode];
    
    // Esc key activate the browser
    if (keyCode == 0x35) {
        [oDocument activateBrowser];
        return;
    }
    
    // Otherwise pass it to the super class
    [super keyDown:theEvent];
}

@end


