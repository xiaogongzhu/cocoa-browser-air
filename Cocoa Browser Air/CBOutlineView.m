//
//  CBOutlineView.m
//  Cocoa Browser Air
//
//  Created by numata on 08/05/05.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import "CBOutlineView.h"
#import "CBNode.h"


@implementation CBOutlineView

- (void)keyDown:(NSEvent *)theEvent
{
    unsigned short keyCode = [theEvent keyCode];
    unsigned modifiers = [theEvent modifierFlags];
    
    if ((modifiers & (NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask)) ||
        keyCode == 0x7e || keyCode == 0x7d || keyCode == 0x7c || keyCode == 0x7b)
    {
        // Right arrow key will activate the browser view at leaf nodes
        if (keyCode == 0x7c) {
            NSInteger selectedRow = [self selectedRow];
            if (selectedRow >= 0) {
                CBNode *selectedItem = [self itemAtRow:selectedRow];
                if (selectedItem.type == CBNodeTypeReferences || selectedItem.type == CBNodeTypeDocument) {
                    if ([selectedItem childNodeCount] > 0) {
                        [oDocument showNode:[selectedItem childNodeAtIndex:0]];
                        [oDocument activateBrowser];
                        return;
                    }
                }
            }
        }
        [super keyDown:theEvent];
        return;
    }
    
    [oDocument startSearchWithStr:[theEvent characters]];
}

/*
- (void)mouseDown:(NSEvent *)theEvent
{
    [oDocument clearSearchWord];
    [super mouseDown:theEvent];
}
 */

- (NSMenu *)menuForEvent:(NSEvent *)event
{
    NSPoint pos = [self convertPoint:[event locationInWindow] fromView:nil];
    NSInteger row = [self rowAtPoint:pos];
    
    if (row < 0) {
        return nil;
    }
    
    CBNode *targetNode = [self itemAtRow:row];
    
    NSMenu *menu = [super menuForEvent:event];
    for (NSMenuItem *anItem in [menu itemArray]) {
        [anItem setRepresentedObject:targetNode];
    }
    
    return menu;
}

@end


