//
//  CBStatusBarBackgroundView.m
//  Cocoa Browser Air
//
//  Created by numata on 08/05/05.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import "CBStatusBarBackgroundView.h"


@implementation CBStatusBarBackgroundView

- (void)drawRect:(NSRect)rect
{
    NSRect frame = [self frame];

    BOOL isWindowMain = [[self window] isMainWindow];
    
    if (isWindowMain) {
        [[NSColor colorWithCalibratedWhite:0.250980392 alpha:1.0] set];
    } else {
        [[NSColor colorWithCalibratedWhite:0.529411765 alpha:1.0] set];
    }
    NSRectFill(NSMakeRect(frame.origin.x, frame.origin.y+frame.size.height-1, frame.size.width, 1));
    
    if (isWindowMain) {
        [[NSColor colorWithCalibratedWhite:0.780392157 alpha:1.0] set];
    } else {
        [[NSColor colorWithCalibratedWhite:0.901960784 alpha:1.0] set];
    }
    NSRectFill(NSMakeRect(frame.origin.x, frame.origin.y+frame.size.height-2, frame.size.width, 1));
    
    if (isWindowMain) {
        NSGradient* grad = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.556863 green:0.560784 blue:0.560784 alpha:1.0]
                                                         endingColor:[NSColor colorWithCalibratedRed:0.745098 green:0.752941 blue:0.760784 alpha:1.0]];
        [grad drawInRect:NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height-2) angle:90.0];
    } else {
        NSGradient* grad = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.776471 green:0.776471 blue:0.780392 alpha:1.0]
                                                         endingColor:[NSColor colorWithCalibratedRed:0.870588 green:0.870588 blue:0.874510 alpha:1.0]];
        [grad drawInRect:NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height-2) angle:90.0];
    }
}

@end


