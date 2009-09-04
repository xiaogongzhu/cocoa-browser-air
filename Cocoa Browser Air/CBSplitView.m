#import "CBSplitView.h"


@implementation CBSplitView

- (CGFloat)dividerThickness
{
    return 1.0f;
}

- (void)drawDividerInRect:(NSRect)rect
{
    [[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] set];
    NSRectFill(rect);
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
    NSRect newFrame = [self frame];
    
    NSView *firstView = [[self subviews] objectAtIndex:0];
    NSView *secondView = [[self subviews] objectAtIndex:1];
    
    NSRect firstFrame = [firstView frame];
    NSRect secondFrame = [secondView frame];
    float dividerThickness = [self dividerThickness];
    
    if ([self isVertical]) {
        firstFrame.size.height = newFrame.size.height;
        secondFrame.size.height = newFrame.size.height;

        secondFrame.origin.x = firstFrame.origin.x + firstFrame.size.width + dividerThickness;
        secondFrame.size.width = newFrame.size.width - firstFrame.size.width - dividerThickness;
    } else {
        firstFrame.size.width = newFrame.size.width;
        secondFrame.size.width = newFrame.size.width;

        secondFrame.origin.y = firstFrame.origin.y + firstFrame.size.height + dividerThickness;
        secondFrame.size.height = newFrame.size.height - firstFrame.size.height - dividerThickness;
    }
    
    [firstView setFrame:firstFrame];
    [secondView setFrame:secondFrame];
    
    [self setNeedsDisplay:YES];
}

@end


