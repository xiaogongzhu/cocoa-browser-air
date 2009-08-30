//
//  CBBrowser.m
//  Cocoa Browser Air
//
//  Created by numata on 08/05/06.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import "CBBrowser.h"


@implementation CBBrowser

- (void)keyDown:(NSEvent *)theEvent
{
    unsigned short keyCode = [theEvent keyCode];
    unsigned modifiers = [theEvent modifierFlags];
    
    // Arrow keys should be handled by super class
    if ((modifiers & (NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask)) ||
        keyCode == 0x7e || keyCode == 0x7d || keyCode == 0x7c || keyCode == 0x7b)
    {
        // Left arrow key will activate the outline view at column 0
        if (keyCode == 0x7b) {
            if ([self selectedColumn] == 0) {
                [oDocument activateFrameworkListView];
                return;
            }
        }
        [super keyDown:theEvent];
        return;
    }
    // Esc key clears the search word
    else if (keyCode == 0x35) {
        // TODO: 検索ワードの削除？
        NSLog(@"TODO: 検索ワードの削除");
        //[oDocument clearSearchWord];
        return;
    }
    // Just ignore Return/Enter key
    else if (keyCode == 0x24 || keyCode == 0x4c) {
        [oDocument activateWebView];
        return;
    }
    //NSLog(@"-[CBBrowser keyDown:] => keyCode=0x%02x", keyCode);
    [oDocument startSearchWithStr:[theEvent characters]];
}

- (void)drawTitleOfColumn:(NSInteger)column inRect:(NSRect)aRect
{
    aRect.size.width += 2;
    aRect.size.height += 2;

    NSGradient *grad = [[NSGradient alloc] initWithStartingColor:[NSColor darkGrayColor] endingColor:[NSColor colorWithCalibratedWhite:0.95f alpha:1.0f]];
    [grad drawInRect:aRect angle:90.0f];
    [grad release];
    
    if (column == 1) {
        return;
    }
        
    NSRect roundRect = NSInsetRect(aRect, 20.0f, 4.0f);
    roundRect.origin.x -= 7;
    roundRect.origin.y -= 1;
    NSBezierPath *roundPath = [NSBezierPath bezierPathWithRoundedRect:roundRect xRadius:6.0f yRadius:6.0f];
    [[NSColor colorWithCalibratedWhite:0.2f alpha:1.0f] set];
    [roundPath fill];
}

@end


