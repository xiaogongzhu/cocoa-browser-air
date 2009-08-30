#import <Cocoa/Cocoa.h>
#import "CBNode.h"


@interface CBOutlineViewCell : NSCell {
    CBNode  *mTargetNode;
}

@property(assign, readwrite) CBNode *node;

@end


