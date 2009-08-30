#import "CBOutlineViewCell.h"


static float CBOutlineViewCellIconMargin = 1.0f;


@implementation CBOutlineViewCell

@synthesize node = mTargetNode;

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
    if (!mTargetNode) {
        return;
    }
    
    // Draw Image
    NSImage *iconImage = mTargetNode.image;
    NSSize iconSize = NSZeroSize;
    if (iconImage) {
        iconSize = [iconImage size];
        NSPoint iconPos = cellFrame.origin;
        iconPos.x += CBOutlineViewCellIconMargin;
        
        if([controlView isFlipped]) {
            iconPos.y += iconSize.height;
        }
        
        [iconImage setSize:iconSize];
        [iconImage compositeToPoint:iconPos operation:NSCompositeSourceOver];
    }
    
    // Draw text
    NSString *path = [mTargetNode localizedTitle];
    NSRect	pathRect;
    pathRect.origin.x = cellFrame.origin.x + CBOutlineViewCellIconMargin;
    if (iconSize.width > 0) {
        pathRect.origin.x += iconSize.width + CBOutlineViewCellIconMargin;
    }
    pathRect.origin.y = cellFrame.origin.y;
    pathRect.size.width = cellFrame.size.width - (pathRect.origin.x - cellFrame.origin.x);
    pathRect.size.height = cellFrame.size.height;
    
    /*if (mTargetNode && mTargetNode.type == CBNodeTypeRefFrameworkFolder && [mTargetNode.title isEqualToString:NSLocalizedString(@"FL Main Frameworks", nil)]) {
        pathRect.origin.x -= 15;
    }*/
    
    if (path) {
        NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
        if ([self isHighlighted]) {
            [attrs setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
        } else if (mTargetNode.type == CBNodeTypeFrameworkFolder) {
            [attrs setObject:[NSColor darkGrayColor] forKey:NSForegroundColorAttributeName];
        }
        if (mTargetNode.isStrong) {
            [attrs setObject:[NSFont fontWithName:@"LucidaGrande-Bold" size:12.0] forKey:NSFontAttributeName];
        } else {
            [attrs setObject:[NSFont fontWithName:@"LucidaGrande" size:12.0] forKey:NSFontAttributeName];
        }
        NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        [paraStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        [attrs setObject:paraStyle forKey:NSParagraphStyleAttributeName];
        [path drawInRect:pathRect withAttributes:attrs];
        [paraStyle release];
    }
}

@end


