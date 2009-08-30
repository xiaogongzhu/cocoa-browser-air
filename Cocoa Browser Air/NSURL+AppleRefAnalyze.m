//
//  NSURL+AppleRefAnalyze.m
//  Cocoa Browser Air
//
//  Created by numata on 08/05/04.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import "NSURL+AppleRefAnalyze.h"
#import "CBNavigationInfo.h"


static NSString *sCBMacOSXDocumentLocalHeader = @"file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation";
static NSString *sCBMacOSXDocumentRemoteHeader = @"http://developer.apple.com/documentation";

static NSString *sCBMacOSXDocumentLocalHeaderForPlatformCheck = @"file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/";

static NSMutableArray   *sCBIPhoneDocumentLocalHeaders = nil;
static NSMutableArray   *sCBIPhoneDocumentLocalHeadersForPlatformCheck = nil;


@implementation NSURL (AppleRefAnalyze)

+ (void)initialize
{
    [super initialize];
    
    if (sCBIPhoneDocumentLocalHeaders) {
        return;
    }
    sCBIPhoneDocumentLocalHeaders = [[NSMutableArray alloc] init];
    [sCBIPhoneDocumentLocalHeaders addObject:@"file:///Library/Developer/Shared/Documentation/DocSets/com.apple.adc.documentation.AppleiPhone2_0.iPhoneLibrary.docset/Contents/Resources/Documents/documentation"];
    [sCBIPhoneDocumentLocalHeaders addObject:@"file:///Library/Developer/Shared/Documentation/DocSets/com.apple.adc.documentation.AppleiPhone2_1.iPhoneLibrary.docset/Contents/Resources/Documents/documentation"];
    [sCBIPhoneDocumentLocalHeaders addObject:@"file:///Library/Developer/Shared/Documentation/DocSets/com.apple.adc.documentation.AppleiPhone2_2.iPhoneLibrary.docset/Contents/Resources/Documents/documentation"];
    [sCBIPhoneDocumentLocalHeaders addObject:@"file:///Library/Developer/Shared/Documentation/DocSets/com.apple.adc.documentation.AppleiPhone3_0.iPhoneLibrary.docset/Contents/Resources/Documents/documentation"];
    [sCBIPhoneDocumentLocalHeaders addObject:@"file:///Developer/Platforms/iPhoneOS.platform/Developer/Documentation/DocSets/com.apple.adc.documentation.AppleiPhone2_0.iPhoneLibrary.docset/Contents/Resources/Documents/documentation"];
    [sCBIPhoneDocumentLocalHeaders addObject:@"file:///Developer/Platforms/iPhoneOS.platform/Developer/Documentation/DocSets/com.apple.adc.documentation.AppleiPhone2_1.iPhoneLibrary.docset/Contents/Resources/Documents/documentation"];
    [sCBIPhoneDocumentLocalHeaders addObject:@"file:///Developer/Platforms/iPhoneOS.platform/Developer/Documentation/DocSets/com.apple.adc.documentation.AppleiPhone2_2.iPhoneLibrary.docset/Contents/Resources/Documents/documentation"];
    [sCBIPhoneDocumentLocalHeaders addObject:@"file:///Developer/Platforms/iPhoneOS.platform/Developer/Documentation/DocSets/com.apple.adc.documentation.AppleiPhone3_0.iPhoneLibrary.docset/Contents/Resources/Documents/documentation"];
    
    sCBIPhoneDocumentLocalHeadersForPlatformCheck = [[NSMutableArray alloc] init];
    [sCBIPhoneDocumentLocalHeadersForPlatformCheck addObject:@"file:///Library/Developer/Shared/Documentation/DocSets/com.apple.adc.documentation.AppleiPhone"];
    [sCBIPhoneDocumentLocalHeadersForPlatformCheck addObject:@"file:///Developer/Platforms/iPhoneOS.platform"];
}

- (NSString *)checkClassName
{
    NSString *urlStr = [self absoluteString];
    NSEnumerator *enumerator = [urlStr tokenize:@"/#"];
    NSString *aToken;
    while (aToken = [enumerator nextObject]) {
        if ([aToken isEqualToString:@"Classes"] || [aToken isEqualToString:@"Reference"]) {
            aToken = [enumerator nextObject];
            if (aToken && [aToken hasSuffix:@"_Class"] || [aToken hasSuffix:@"_class"]) {
                return [aToken substringWithRange:NSMakeRange(0, [aToken length]-6)];
            }
        }
    }
    return nil;
}

/*!
    // doc
    CBReferenceShowInfo *ret = nil;
    if ([domain isEqualToString:@"doc"]) {
        // Framework (and maybe Others)
        else if ([target isEqualToString:@"uid"]) {
            ret = [[CBReferenceShowInfo new] autorelease];
            ret.frameworkName = frameworkName;
            ret.type = CBReferenceTypeFramework;
        }
        // Constant group
        else if ([target isEqualToString:@"constant_group"]) {
            NSString *groupName = [refs nextObject];
            groupName = [groupName stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            NSString *className = [self findCocoaClassName];
            NSLog(@"Constant group {%@} in class={%@}", groupName, className);
            if (className) {
                ret = [[CBReferenceShowInfo new] autorelease];
                ret.frameworkName = frameworkName;
                ret.className = className;
                ret.constantName = groupName;
                ret.type = CBReferenceTypeConstantInClass;
            }
        }
        // Otherwise
        else {
            NSLog(@"Unknown target(doc): {%@}", target);
        }
    }
    // occ
    else if ([domain isEqualToString:@"occ"]) {
        // Property
        else if ([target isEqualToString:@"instp"]) {
            NSString *className = [refs nextObject];
            NSString *propertyName = [refs nextObject];
            if (propertyName) {
                ret = [[CBReferenceShowInfo new] autorelease];
                ret.frameworkName = frameworkName;
                ret.className = className;
                ret.propertyName = propertyName;
                ret.type = CBReferenceTypeProperty;
            }
        }
}*/

- (NSString *)checkPlatformName
{
    NSString *absoluteStr = [self absoluteString];
    if ([absoluteStr hasPrefix:sCBMacOSXDocumentLocalHeaderForPlatformCheck]) {
        return @"Mac OS X";
    } else {
        for (NSString *aHeader in sCBIPhoneDocumentLocalHeadersForPlatformCheck) {
            if ([absoluteStr hasPrefix:aHeader]) {
                return @"iPhone";
            }
        }
    }
    return nil;
}

- (NSString *)checkFrameworkNameForMacOSX
{
    NSString *urlStr = [self absoluteString];
    
    if ([urlStr hasPrefix:sCBMacOSXDocumentLocalHeader]) {
        urlStr = [urlStr substringFromIndex:[sCBMacOSXDocumentLocalHeader length]];
    } else if ([urlStr hasPrefix:sCBMacOSXDocumentRemoteHeader]) {
        urlStr = [urlStr substringFromIndex:[sCBMacOSXDocumentRemoteHeader length]];
    } else {
        NSLog(@"[checkFrameworkNameForMacOSX] No header for URL: url={%@}", urlStr);
        return nil;
    }
    
    NSString *ret = nil;
    // Foundation stuffs
    if ([urlStr hasPrefix:@"/Cocoa/Reference/Foundation/"] ||
        [urlStr hasPrefix:@"/Cocoa/Reference/NSCondition_class/"] ||
        [urlStr hasPrefix:@"/Cocoa/Reference/NSFastEnumeration_protocol/"] ||
        [urlStr hasPrefix:@"/Cocoa/Reference/NSGarbageCollector_class/"] ||
        [urlStr hasPrefix:@"/Cocoa/Reference/NSHashTable_class/"] ||
        [urlStr hasPrefix:@"/Cocoa/Reference/NSInvocationOperation_Class/"] ||
        [urlStr hasPrefix:@"/Cocoa/Reference/NSMapTable_class/"] ||
        [urlStr hasPrefix:@"/Cocoa/Reference/NSOperation_class/"] ||
        [urlStr hasPrefix:@"/Cocoa/Reference/NSOperationQueue_class/"])
    {
        ret = @"Foundation";
    }
    // Application Kit stuffs
    // (not only /Cocoa/Reference/ApplicationKit but also /Cocoa/Reference itself contains some of AppKit classes and of others)
    else if ([urlStr hasPrefix:@"/Cocoa/Reference/ApplicationKit/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSAnimationContext_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSAnimatablePropertyContainer_protocol/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSCollectionView_Class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSCollectionViewItem_Class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSDictionaryController_Class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSDictionaryControllerKeyValuePair_Protocol/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSDockTile_Class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSGradient_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSPathCell_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSPathCellDelegate_protocol/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSPathControl_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSPathControlDelegate_protocol/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSPredicateEditor_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSPredicateEditorRowTemplate_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSPrintPanelAccessorizing_Protocol/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSRuleEditor_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSToolbarItemGroup_Class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSTrackingArea_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSTreeNode_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSViewController_Class/"])
    {
        ret = @"Application Kit";
    }
    // Core Data stuffs
    else if ([urlStr hasPrefix:@"/Cocoa/Reference/CoreData_ObjC/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/CoreDataFramework/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSAtomicStore_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSAtomicStoreCacheNode_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSAtomicStoreCacheNode_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSEntityMapping_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSEntityMigrationPolicy_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSFetchRequestExpression_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSMappingModel_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSMigrationManager_class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSPersistentStore_Class/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSPersistentStoreCoordinator_SyncServicesAdditions/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSPersistentStoreCoordinatorSyncing_Protocol/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/NSPropertyMapping_class/"])
    {
        ret = @"Core Data";
    }
    // Address Book
    else if ([urlStr hasPrefix:@"/UserExperience/Reference/AddressBook/"]) {
        ret = @"Address Book";
    }
    // Automator
    else if ([urlStr hasPrefix:@"/AppleApplications/Reference/AutomatorFramework/"] ||
             [urlStr hasPrefix:@"/AppleApplications/Reference/AM"])
    {
        ret = @"Automator";
    }
    // Calendar Store
    else if ([urlStr hasPrefix:@"/AppleApplications/Reference/CalendarStoreFramework/"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/Cal"])
    {
        ret = @"Calendar Store";
    }
    // Collaboration
    else if ([urlStr hasPrefix:@"/Networking/Reference/CB"]) {
        ret = @"Collaboration";
    }
    // Core Animation (Quartz Core) stuffs
    else if ([urlStr hasPrefix:@"/GraphicsImaging/Reference/CA"] ||
             [urlStr hasPrefix:@"/GraphicsImaging/Reference/QuartzCoreFramework/"] ||
             [urlStr hasPrefix:@"/GraphicsImaging/QC"])
    {
        ret = @"Core Animation";
    }
    // Web Services Core（Core Foundation の前に処理しなければならない）
    else if ([urlStr hasPrefix:@"/CoreFoundation/Reference/WebServicesReference/"]) {
        ret = @"Web Services Core";
    }
    // Core Foundation
    else if ([urlStr hasPrefix:@"/CoreFoundation/"]) {
        ret = @"Core Foundation";
    }
    // Core Graphics stuffs
    else if ([urlStr hasPrefix:@"/GraphicsImaging/Reference/CG"] ||
             [urlStr hasPrefix:@"/GraphicsImaging/Reference/Quartz_Services_Ref/"])
    {
        ret = @"Core Graphics";
    }
    // Core Image stuffs
    else if ([urlStr hasPrefix:@"/GraphicsImaging/Reference/QuartzCoreFramework/Classes/CI"]) {
        ret = @"Core Image";
    }
    // Core Text
    else if ([urlStr hasPrefix:@"/Carbon/Reference/CT"]) {
        ret = @"Core Text";
    }
    // Instant Message
    else if ([urlStr hasPrefix:@"/Cocoa/Reference/IM"]) {
        ret = @"Instant Message";
    }
    // Message
    else if ([urlStr hasPrefix:@"/AppleApplications/Reference/MessageFrameworkReference/"]) {
        ret = @"Message";
    }
    // PDF Kit
    else if ([urlStr hasPrefix:@"/GraphicsImaging/Reference/PDF"] ||
             [urlStr hasPrefix:@"/GraphicsImaging/Reference/QuartzFramework/Classes/PDF"])
    {
        ret = @"PDF Kit";
    }
    // Quartz Composer stuffs
    else if ([urlStr hasPrefix:@"/Cocoa/Reference/QC"] ||
             [urlStr hasPrefix:@"/GraphicsImaging/Reference/QuartzFramework/Classes/QC"] ||
             [urlStr hasPrefix:@"/GraphicsImaging/Reference/QC"])
    {
        ret = @"Quartz Composer";
    }
    // QuickTime stuffs
    else if ([urlStr hasPrefix:@"/QuickTime/Reference/"]) {
        ret = @"QuickTime Kit";
    }
    // Screen Saver
    else if ([urlStr hasPrefix:@"/UserExperience/Reference/ScreenSaver/"]) {
        ret = @"Screen Saver";
    }
    // Scripting Bridge stuffs
    else if ([urlStr hasPrefix:@"/Cocoa/Reference/SB"]) {
        ret = @"Scripting Bridge";
    }
    // Security Foundation
    else if ([urlStr hasPrefix:@"/Security/Reference/SecurityFoundationFramework/"]) {
        ret = @"Security Foundation";
    }
    // Security Interface
    else if ([urlStr hasPrefix:@"/Security/Reference/SecurityInterfaceFramework/"]) {
        ret = @"Security Interface";
    }
    // Sync Services
    else if ([urlStr hasPrefix:@"/Cocoa/Reference/SyncServicesFramework/"]) {
        ret = @"Sync Services";
    }
    // WebKit stuffs
    else if ([urlStr hasPrefix:@"/Cocoa/Reference/WebKit/"]) {
        ret = @"Web Kit Objective-C";
    }
    // Objective-C 2.0 References
    else if ([urlStr hasPrefix:@"/Cocoa/Reference/ObjCRuntimeRef/"]) {
        ret = @"Objective-C 2.0";
    }
    // Otherwise
    else {
        NSLog(@"Unknown framework [%@]", urlStr);
    }    
    
    return ret;
}

- (NSString *)checkFrameworkNameForIPhone
{
    NSString *ret = nil;
    
    NSString *urlStr = [self absoluteString];
    BOOL foundHeader = NO;
    for (NSString *aHeader in sCBIPhoneDocumentLocalHeaders) {
        if ([urlStr hasPrefix:aHeader]) {
            urlStr = [urlStr substringFromIndex:[aHeader length]];
            foundHeader = YES;
            break;
        }
    }

    if (!foundHeader) {
        NSLog(@"- [NSURL checkFrameworkNameForIPhone] No header for URL={%@}", urlStr);
        return nil;
    }
    
    // Foundation stuffs
    if ([urlStr hasPrefix:@"/Cocoa/Reference/Foundation/"]) {
        ret = @"Foundation";
    }
    // UIKit stuffs
    else if ([urlStr hasPrefix:@"/UIKit/"]) {
        ret = @"UIKit";
    }
    // Core Animation (Quartz Core) stuffs
    else if ([urlStr hasPrefix:@"/GraphicsImaging/Reference/CA"] ||
             [urlStr hasPrefix:@"/Cocoa/Reference/CoreAnimation_"])
    {
        ret = @"Core Animation";
    }
    // Core Foundation
    else if ([urlStr hasPrefix:@"/CoreFoundation/"]) {
        ret = @"Core Foundation";
    }
    // Core Graphics
    else if ([urlStr hasPrefix:@"/GraphicsImaging/"]) {
        ret = @"Core Graphics";
    }
    // Address Book
    else if ([urlStr hasPrefix:@"/AddressBook/"]) {
        ret = @"Address Book";
    }
    // Address Book UI
    else if ([urlStr hasPrefix:@"/AddressBookUI/"]) {
        ret = @"Address Book UI";
    }
    // Audio Toolbox
    else if ([urlStr hasPrefix:@"/AudioToolbox/"] || [urlStr hasPrefix:@"/MusicAudio/"]) {
        ret = @"Audio Toolbox";
    }
    // Audio Unit
    else if ([urlStr hasPrefix:@"/AudioUnit/"]) {
        ret = @"Audio Unit";
    }
    // Core Location
    else if ([urlStr hasPrefix:@"/CoreLocation/"]) {
        ret = @"Core Location";
    }
    // External Accessory
    else if ([urlStr hasPrefix:@"/ExternalAccessory/"]) {
        ret = @"External Accessory";
    }
    // Game Kit
    else if ([urlStr hasPrefix:@"/GameKit/"]) {
        ret = @"Game Kit";
    }
    // Map Kit
    else if ([urlStr hasPrefix:@"/MapKit/"]) {
        ret = @"Map Kit";
    }
    // Media Player
    else if ([urlStr hasPrefix:@"/MediaPlayer/"]) {
        ret = @"Media Player";
    }
    // Message UI
    else if ([urlStr hasPrefix:@"/MessageUI/"]) {
        ret = @"Message UI";
    }
    // OpenGL ES
    else if ([urlStr hasPrefix:@"/OpenGLES/"]) {
        ret = @"OpenGL ES";
    }
    // QuartzCore
    else if ([urlStr hasPrefix:@"/QuartzCore/"]) {
        ret = @"Core Animation";
    }
    // Objective-C 2.0 Reference
    else if ([urlStr hasPrefix:@"/Cocoa/Reference/ObjCRuntimeRef/"]) {
        ret = @"Objective-C 2.0";
    }
    // Security
    else if ([urlStr hasPrefix:@"/Security/"]) {
        ret = @"Security";
    }
    // Otherwise
    else {
        NSLog(@"unknown_framework={%@}", urlStr);
    }

    return ret;
}

- (NSString *)checkFrameworkNameForPlatform:(NSString *)platformName
{
    if ([platformName isEqualToString:@"Mac OS X"]) {
        return [self checkFrameworkNameForMacOSX];
    } else if ([platformName isEqualToString:@"iPhone"]) {
        return [self checkFrameworkNameForIPhone];
    }
    return nil;
}

- (CBReferenceInfo *)makeReferenceInfo
{
    //NSLog(@"-[NSURL makeReferenceInfo] url={%@}", self);
    // Platform name
    NSString *platformName = [self checkPlatformName];
    if (!platformName) {
        return nil;
    }
    //NSLog(@"  => platform={%@}", platformName);
    
    // Prepare to analyze the "#//apple_ref"
    NSString *referenceStr = [self fragment];
    if (!referenceStr) {
        return nil;
    }
    
    NSString *frameworkName = [self checkFrameworkNameForPlatform:platformName];
    if (!frameworkName) {
        return nil;
    }
    //NSLog(@"  => framework={%@}", frameworkName);
    
    NSString *urlStr = [self absoluteString];
    BOOL foundHeader = NO;
    
    if ([urlStr hasPrefix:sCBMacOSXDocumentLocalHeader]) {
        urlStr = [urlStr substringFromIndex:[sCBMacOSXDocumentLocalHeader length]];
        foundHeader = YES;
    } else if ([urlStr hasPrefix:sCBMacOSXDocumentRemoteHeader]) {
        urlStr = [urlStr substringFromIndex:[sCBMacOSXDocumentRemoteHeader length]];
        foundHeader = YES;
    } else {
        for (NSString *aHeader in sCBIPhoneDocumentLocalHeaders) {
            if ([urlStr hasPrefix:aHeader]) {
                urlStr = [urlStr substringFromIndex:[aHeader length]];
                foundHeader = YES;
                break;
            }
        }
    }
    
    if (!foundHeader) {
        NSLog(@"No header for URL: url={%@}", urlStr);
        return nil;
    }
    NSRange underbarRange = [urlStr rangeOfString:@"_"];
    if (underbarRange.location == NSNotFound) {
        return nil;
    }
    
    NSRange slashRange = [urlStr rangeOfString:@"/" options:NSBackwardsSearch range:NSMakeRange(0, underbarRange.location)];
    if (slashRange.location == NSNotFound) {
        return nil;
    }
    NSString *subjectName = [urlStr substringWithRange:NSMakeRange(slashRange.location+1, underbarRange.location-slashRange.location-1)];
    
    NSEnumerator *refs = [referenceStr tokenize:@"/"];
    NSString *header = [refs nextObject];
    if (![header isEqualToString:@"apple_ref"]) {
        return nil;
    }
    
    /*NSString *domain =*/ [refs nextObject];   // Skip the domain part
    //NSLog(@"domain=%@", domain);
    NSString *target = [refs nextObject];
    
    //NSLog(@"  => subject={%@}, domain={%@}, target={%@}", subjectName, domain, target);
    
    NSString *restURLStr = [[urlStr substringFromIndex:underbarRange.location+1] lowercaseString];
    //NSLog(@"restURLStr: %@", restURLStr);
    // Class related
    if ([restURLStr hasPrefix:@"class/"] || [restURLStr hasPrefix:@"appkitadditions/"] || [restURLStr hasPrefix:@"classref/"]) {
        // Class
        if ([target isEqualToString:@"cl"]) {
            NSString *className = [refs nextObject];
            if (className) {
                CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
                ret.type = CBReferenceTypeClass;
                ret.platformName = platformName;
                ret.frameworkName = frameworkName;
                ret.className = subjectName;
                return ret;
            }
        }
        // Class method
        else if ([target isEqualToString:@"clm"]) {
            NSString *className = [refs nextObject];
            NSString *methodName = [refs nextObject];
            if (className && methodName) {
                CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
                ret.type = CBReferenceTypeClassMethod;
                ret.platformName = platformName;
                ret.frameworkName = frameworkName;
                ret.className = subjectName;
                ret.methodName = methodName;
                return ret;
            }
        }
        // Instant method
        else if ([target isEqualToString:@"instm"]) {
            NSString *className = [refs nextObject];
            NSString *methodName = [refs nextObject];
            if (className && methodName) {
                CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
                ret.type = CBReferenceTypeInstanceMethod;
                ret.platformName = platformName;
                ret.frameworkName = frameworkName;
                ret.className = subjectName;
                ret.methodName = methodName;
                return ret;
            }
        }
        // Property
        else if ([target isEqualToString:@"instp"]) {
            NSString *className = [refs nextObject];
            NSString *propertyName = [refs nextObject];
            if (className && propertyName) {
                CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
                ret.type = CBReferenceTypeProperty;
                ret.platformName = platformName;
                ret.frameworkName = frameworkName;
                ret.className = subjectName;
                ret.propertyName = propertyName;
                return ret;
            }
        }
        // Constant in Class / Class
        else if ([target isEqualToString:@"c_ref"] || [target isEqualToString:@"constant_group"] || [target isEqualToString:@"econst"]) {
            NSString *constantName = [refs nextObject];
            if (constantName) {
                // Class
                if ([constantName isEqualToString:subjectName]) {
                    CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
                    ret.type = CBReferenceTypeClass;
                    ret.platformName = platformName;
                    ret.frameworkName = frameworkName;
                    ret.className = subjectName;
                    return ret;
                }
                // Constant in Class
                else {
                    CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
                    ret.type = CBReferenceTypeConstantInClass;
                    ret.platformName = platformName;
                    ret.frameworkName = frameworkName;
                    ret.className = subjectName;
                    constantName = [constantName stringByReplacingOccurrencesOfString:@"_" withString:@" "];
                    ret.constantName = constantName;
                    return ret;
                }
            }
        }
        // Otherwise
        else {
            NSLog(@"  => unknown class target: %@", target);
        }
    }
    // Protocol related
    else if ([restURLStr hasPrefix:@"protocol/"]) {
        // Class
        if ([target isEqualToString:@"intf"]) {
            NSString *protocolName = [refs nextObject];
            if (protocolName) {
                CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
                ret.type = CBReferenceTypeProtocol;
                ret.platformName = platformName;
                ret.frameworkName = frameworkName;
                ret.protocolName = protocolName;
                return ret;
            }
        }
        // Class Method in Protocol
        else if ([target isEqualToString:@"clm"]) {
            NSString *protocolName = [refs nextObject];
            NSString *methodName = [refs nextObject];
            if (protocolName && methodName) {
                CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
                ret.type = CBReferenceTypeProtocolClassMethod;
                ret.platformName = platformName;
                ret.frameworkName = frameworkName;
                ret.protocolName = subjectName;
                ret.methodName = methodName;
                return ret;
            }
        }
        // Instance Method in Protocol
        else if ([target isEqualToString:@"instm"] || [target isEqualToString:@"intfm"]) {
            NSString *protocolName = [refs nextObject];
            NSString *methodName = [refs nextObject];
            if (protocolName && methodName) {
                CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
                ret.type = CBReferenceTypeProtocolInstanceMethod;
                ret.platformName = platformName;
                ret.frameworkName = frameworkName;
                ret.protocolName = subjectName;
                ret.methodName = methodName;
                return ret;
            }
        }
        // Property in Protocol
        else if ([target isEqualToString:@"intfp"]) {
            NSString *protocolName = [refs nextObject];
            NSString *propertyName = [refs nextObject];
            if (protocolName && propertyName) {
                CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
                ret.type = CBReferenceTypePropertyInProtocol;
                ret.platformName = platformName;
                ret.frameworkName = frameworkName;
                ret.protocolName = subjectName;
                ret.propertyName = propertyName;
                return ret;
            }
        }
        // Constant in Protocol / Protocol
        else if ([target isEqualToString:@"c_ref"] || [target isEqualToString:@"constant_group"]) {
            NSString *constantName = [refs nextObject];
            if (constantName) {
                // Protocol
                if ([constantName isEqualToString:subjectName]) {
                    CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
                    ret.type = CBReferenceTypeProtocol;
                    ret.platformName = platformName;
                    ret.frameworkName = frameworkName;
                    ret.protocolName = subjectName;
                    return ret;
                }
                // Constant in Protocol
                CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
                ret.type = CBReferenceTypeConstantInProtocol;
                ret.platformName = platformName;
                ret.frameworkName = frameworkName;
                ret.protocolName = subjectName;
                constantName = [constantName stringByReplacingOccurrencesOfString:@"_" withString:@" "];
                ret.constantName = constantName;
                return ret;
            }
        }
        // Otherwise
        else {
            NSLog(@"  => unknown protocol target: %@", target);
        }
    }
    // Functions
    else if ([restURLStr hasPrefix:@"functions/"] || [restURLStr hasPrefix:@"ref/c/func/"]) {
        NSString *functionName = [refs nextObject];
        CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
        ret.type = CBReferenceTypeFunction;
        ret.platformName = platformName;
        ret.frameworkName = frameworkName;
        ret.methodName = functionName;
        return ret;
    }
    // Data Types
    else if ([restURLStr hasPrefix:@"datatypes/"]) {
        NSString *dataTypeName = [refs nextObject];
        CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
        ret.type = CBReferenceTypeDataType;
        ret.platformName = platformName;
        ret.frameworkName = frameworkName;
        ret.dataTypeName = dataTypeName;
        return ret;
    }
    // Global Constant
    else if ([restURLStr hasPrefix:@"constants/"]) {
        NSString *constantName = [refs nextObject];
        CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
        ret.type = CBReferenceTypeConstant;
        ret.platformName = platformName;
        ret.frameworkName = frameworkName;
        constantName = [constantName stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        ret.constantName = constantName;
        return ret;
    }
    // Objective-C 2.0
    else if ([urlStr hasPrefix:@"/Cocoa/Reference/ObjCRuntimeRef/"]) {
        NSString *targetName = [refs nextObject];

        if ([restURLStr hasPrefix:@"ref/doc/constant_group/"] || [targetName isEqualToString:@"YES"] || [targetName isEqualToString:@"NO"] || [targetName isEqualToString:@"nil"] || [targetName isEqualToString:@"Nil"]) {
            CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
            ret.type = CBReferenceTypeConstantInClass;
            ret.platformName = platformName;
            ret.frameworkName = @"Objective-C 2.0";
            ret.className = @"Objective-C 2.0";
            ret.constantName = targetName;
            return ret;
        } else if ([restURLStr hasPrefix:@"ref/doc/c_ref/"] || [restURLStr hasPrefix:@"ref/c/tdef/"] || [restURLStr hasPrefix:@"ref/c/tag/"]) {
            CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
            ret.type = CBReferenceTypeDataType;
            ret.platformName = platformName;
            ret.frameworkName = @"Objective-C 2.0";
            ret.className = @"Objective-C 2.0";
            ret.dataTypeName = targetName;
            return ret;
        }
    }
    // Core Graphics のデータ型
    else if ([urlStr hasPrefix:@"/GraphicsImaging/Reference/CGGeometry/"]) {
        if ([target isEqualToString:@"c_ref"] || [target isEqualToString:@"tdef"]) {
            NSString *dataTypeName = [refs nextObject];
            CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
            ret.type = CBReferenceTypeCategorizedDataType;
            ret.platformName = platformName;
            ret.frameworkName = frameworkName;
            ret.className = @"CGGeometry Reference";
            ret.dataTypeName = dataTypeName;
            return ret;
        }
    }
    // Core Foundation のデータ型
    else if ([urlStr hasPrefix:@"/CoreFoundation/Reference/"] && ![urlStr hasPrefix:@"/CoreFoundation/Reference/WebServicesReference/"]) {
        if ([target isEqualToString:@"c_ref"]) {
            NSString *dataTypeName = [refs nextObject];
            CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
            ret.type = CBReferenceTypeCategorizedDataType;
            ret.platformName = platformName;
            ret.frameworkName = frameworkName;
            if ([dataTypeName hasSuffix:@"Ref"]) {
                ret.className = [dataTypeName substringToIndex:[dataTypeName length]-3];
            }
            ret.dataTypeName = dataTypeName;
            return ret;
        }
    }
    // Otherwise
    else {
        NSLog(@"Unrecognizable URL: restURLStr=%@, urlStr=%@, platformName=%@, frameworkName=%@", restURLStr, urlStr, platformName, frameworkName);
    }

    return nil;
}

- (NSArray *)makeNavigationInfos
{
    CBReferenceInfo *refInfo = [self makeReferenceInfo];
    if (refInfo) {
        return [refInfo convertToNavigationInfos];
    }
    return nil;
}

@end


