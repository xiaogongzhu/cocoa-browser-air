//
//  CBSearchBarBackgroundView.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/29.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSearchBarBackgroundView.h"


@implementation CBSearchBarBackgroundView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.mainColor1 = [NSColor whiteColor];
        self.mainColor2 = [NSColor grayColor];

        self.subColor1 = [NSColor whiteColor];
        self.subColor2 = [NSColor colorWithCalibratedWhite:0.75f alpha:1.0];

        self.hasBottomLine = YES;
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];

    NSRect frame = [self frame];
    frame.origin = NSZeroPoint;
    
    int oneWidth = (int)(frame.size.width / 3/* + 0.5*/);

    [[NSGraphicsContext currentContext] saveGraphicsState];
    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
    
    [[NSColor colorWithCalibratedWhite:0.0f alpha:0.3] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(oneWidth, 0) toPoint:NSMakePoint(oneWidth, frame.size.height)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(oneWidth*2, 0) toPoint:NSMakePoint(oneWidth*2, frame.size.height)];

    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

@end
