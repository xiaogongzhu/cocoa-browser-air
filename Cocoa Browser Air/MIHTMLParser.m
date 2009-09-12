//
//  MIHTMLParser.m
//
//  Created by numata on 09/03/01.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "MIHTMLParser.h"
#import <libxml/HTMLParser.h>


static void SAXStartDocument(void *ctx);
static void SAXInternalSubset(void *ctx, const xmlChar *name, const xmlChar *externalID, const xmlChar *systemID);
static void SAXExternalSubset(void *ctx, const xmlChar *name, const xmlChar *externalID, const xmlChar *systemID);
static void SAXEndDocument(void *ctx);

static void SAXStartElement(void *ctx, const xmlChar *name, const xmlChar **atts);
static void SAXEndElement(void *ctx, const xmlChar *name);

static void SAXNotationDeclaration(void *ctx, const xmlChar *name, const xmlChar *publicID, const xmlChar *systemID);
static void SAXAttributeDeclaration(void *ctx, const xmlChar *elem, const xmlChar *fullname, int type, int def, const xmlChar *defaultValue, xmlEnumerationPtr tree);
static void SAXElementDeclaration(void *ctx, const xmlChar *name, int type, xmlElementContentPtr content);

static void SAXCharacters(void *ctx, const xmlChar *ch, int len);
static void SAXComment(void *ctx, const xmlChar *value);
static void SAXIgnorableWhitespace(void *ctx, const xmlChar *ch, int len);

static void SAXEntityDeclaration(void *ctx, const xmlChar *name, int type, const xmlChar *publicID, const xmlChar *systemID, xmlChar *content);
static void SAXSetDocumentLocator(void *ctx, xmlSAXLocatorPtr loc);
static void SAXCDATABlock(void *ctx, const xmlChar *value, int len);
static void SAXUnparsedEntityDeclSAXFunc(void *ctx, const xmlChar *name, const xmlChar *publicID, const xmlChar *systemID, const xmlChar *notationName);
static void SAXReference(void *ctx, const xmlChar *name);

static void SAXProcessingInstruction(void *ctx, const xmlChar *target, const xmlChar *data);

static void SAXWarning(void *ctx, const char *msg, ...);
static void SAXError(void *ctx, const char *msg, ...);
static void SAXFatalError(void *ctx, const char *msg, ...);

static int SAXIsStandalone(void *ctx);
static int SAXHasInternalSubset(void *ctx);
static int SAXHasExternalSubset(void *ctx);

static xmlEntityPtr SAXGetEntity(void *ctx, const xmlChar *name);
static xmlEntityPtr SAXGetParameterEntity(void *ctx, const xmlChar *name);
static xmlParserInputPtr SAXResolveEntity(void *ctx, const xmlChar *publicId, const xmlChar *systemId);



@implementation MIHTMLParser

@synthesize delegate = mDelegate;
@synthesize encoding = mEncoding;

- (id)init
{
    self = [super init];
    if (self) {
        self.encoding = NSUTF8StringEncoding;
    }
    return self;
}

- (BOOL)parseHTML:(NSString *)htmlStr
{
    self.encoding = NSUTF8StringEncoding;
    return [self parseHTMLData:[htmlStr dataUsingEncoding:NSUTF8StringEncoding]];
}

- (BOOL)parseHTMLData:(NSData *)htmlData
{
    if (!htmlData) {
        return NO;
    }
    
    htmlParserCtxtPtr context = htmlCreateMemoryParserCtxt([htmlData bytes], [htmlData length]);
    
    context->userData = self;

    context->sax->startDocument = SAXStartDocument;
    context->sax->internalSubset = SAXInternalSubset;
    context->sax->externalSubset = SAXExternalSubset;
    context->sax->endDocument = SAXEndDocument;

    context->sax->startElement = SAXStartElement;
    context->sax->endElement = SAXEndElement;
    
    context->sax->notationDecl = SAXNotationDeclaration;
    context->sax->attributeDecl = SAXAttributeDeclaration;
    context->sax->elementDecl = SAXElementDeclaration;
    
    context->sax->characters = SAXCharacters;
    context->sax->comment = SAXComment;
    context->sax->ignorableWhitespace = SAXIgnorableWhitespace;

    context->sax->entityDecl = SAXEntityDeclaration;
    context->sax->setDocumentLocator = SAXSetDocumentLocator;
    context->sax->cdataBlock = SAXCDATABlock;
    context->sax->unparsedEntityDecl = SAXUnparsedEntityDeclSAXFunc;
    context->sax->reference = SAXReference;    
    
    context->sax->processingInstruction = SAXProcessingInstruction;
    
    context->sax->warning = SAXWarning;
    context->sax->error = SAXError;
    context->sax->fatalError = SAXFatalError;
    
    context->sax->isStandalone = SAXIsStandalone;
    context->sax->hasInternalSubset = SAXHasInternalSubset;
    context->sax->hasExternalSubset = SAXHasExternalSubset;
    
    context->sax->getEntity = SAXGetEntity;
    context->sax->getParameterEntity = SAXGetParameterEntity;
    context->sax->resolveEntity = SAXResolveEntity;
    
    htmlParseDocument(context);

    htmlFreeParserCtxt(context);
    
    return YES;
}

static void SAXStartDocument(void *ctx)
{
    MIHTMLParser *parser = (MIHTMLParser *)ctx;
    NSObject<MIHTMLParserDelegate> *delegate = parser.delegate;
    if (delegate && [delegate respondsToSelector:@selector(htmlParserStart:)]) {
        [delegate htmlParserStart:parser];
    }
}

static void SAXInternalSubset(void *ctx, const xmlChar *name, const xmlChar *externalID, const xmlChar *systemID)
{
    //NSLog(@"[MIHTMLParser] SAXInternalSubset is not handled: name=%s, external_id=%s, system_id=%s", name, externalID, systemID);
}

static void SAXExternalSubset(void *ctx, const xmlChar *name, const xmlChar *externalID, const xmlChar *systemID)
{
    //NSLog(@"[MIHTMLParser] SAXExternalSubset is not handled: name=%s, external_id=%s, system_id=%s", name, externalID, systemID);
}

static void SAXEndDocument(void *ctx)
{
    MIHTMLParser *parser = (MIHTMLParser *)ctx;
    NSObject<MIHTMLParserDelegate> *delegate = parser.delegate;
    if (delegate && [delegate respondsToSelector:@selector(htmlParserEnd:)]) {
        [delegate htmlParserEnd:parser];
    }
}

static NSDictionary *SAXCreateElementAttributes(const xmlChar **attrs, NSStringEncoding encoding)
{
    if (attrs == NULL) {
        return nil;
    }
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (int i = 0; attrs[i] != NULL; i++) {
        const char *keyBytes = (const char *)attrs[i++];
        const char *valueBytes = (const char *)attrs[i];
        if (valueBytes != NULL) {
            NSString *key = [[NSString alloc] initWithCString:keyBytes encoding:encoding];
            NSString *value = [[NSString alloc] initWithCString:valueBytes encoding:encoding];
            [dict setObject:value forKey:key];
            [value release];
            [key release];
        }
    } 
    return dict;
}

static void SAXStartElement(void *ctx, const xmlChar *name, const xmlChar **attrs)
{
    MIHTMLParser *parser = (MIHTMLParser *)ctx;
    NSObject<MIHTMLParserDelegate> *delegate = parser.delegate;
    if (delegate && [delegate respondsToSelector:@selector(htmlParser:startTag:attributes:)]) {
        NSDictionary *attrDict = SAXCreateElementAttributes(attrs, parser.encoding);
        NSString *tag = [[NSString alloc] initWithCString:(const char *)name encoding:parser.encoding];
        [delegate htmlParser:parser startTag:tag attributes:attrDict];
        [tag release];
        [attrDict release];
    }
}

static void SAXEndElement(void *ctx, const xmlChar *name)
{
    MIHTMLParser *parser = (MIHTMLParser *)ctx;
    NSObject<MIHTMLParserDelegate> *delegate = parser.delegate;
    if (delegate && [delegate respondsToSelector:@selector(htmlParser:endTag:)]) {
        NSString *tag = [[NSString alloc] initWithCString:(const char *)name encoding:parser.encoding];
        [delegate htmlParser:parser endTag:tag];
        [tag release];
    }
}

static void SAXNotationDeclaration(void *ctx, const xmlChar *name, const xmlChar *publicID, const xmlChar *systemID)
{
    NSLog(@"[MIHTMLParser] SAXNotationDeclaration is not handled: name=%s, public_id=%s, system_id=%s", name, publicID, systemID);
}

static void SAXAttributeDeclaration(void *ctx, const xmlChar *elem, const xmlChar *fullname, int type, int def, const xmlChar *defaultValue, xmlEnumerationPtr tree)
{
    NSLog(@"[MIHTMLParser] SAXAttributeDeclaration is not handled: elem=%s, fullname=%s, type=%d, def=%d, default=%s", elem, fullname, type, def, defaultValue);
}

static void SAXElementDeclaration(void *ctx, const xmlChar *name, int type, xmlElementContentPtr content)
{
    NSLog(@"[MIHTMLParser] SAXElementDeclaration is not handled: name=%s, type=%d", name, type);
}

static void SAXCharacters(void *ctx, const xmlChar *ch, int len)
{
    MIHTMLParser *parser = (MIHTMLParser *)ctx;
    NSObject<MIHTMLParserDelegate> *delegate = parser.delegate;
    if (delegate && [delegate respondsToSelector:@selector(htmlParser:foundText:)]) {
        //NSString *str = [[NSString alloc] initWithBytes:ch length:len encoding:parser.encoding];
        NSString *str = [[NSString alloc] initWithBytesNoCopy:(void *)ch length:len encoding:parser.encoding freeWhenDone:NO];
        [delegate htmlParser:parser foundText:str];
        [str release];
    }
}

static void SAXComment(void *ctx, const xmlChar *value)
{
    MIHTMLParser *parser = (MIHTMLParser *)ctx;
    NSObject<MIHTMLParserDelegate> *delegate = parser.delegate;
    if (delegate && [delegate respondsToSelector:@selector(htmlParser:foundComment:)]) {
        NSString *str = [[NSString alloc] initWithCString:(const char *)value encoding:parser.encoding];
        [delegate htmlParser:parser foundComment:str];
        [str release];
    }
}

static void SAXIgnorableWhitespace(void *ctx, const xmlChar *ch, int len)
{
    MIHTMLParser *parser = (MIHTMLParser *)ctx;
    NSObject<MIHTMLParserDelegate> *delegate = parser.delegate;
    if (delegate && [delegate respondsToSelector:@selector(htmlParser:foundIgnorableWhitespace:)]) {
        NSString *str = [[NSString alloc] initWithBytes:ch length:len encoding:NSUTF8StringEncoding];
        [delegate htmlParser:parser foundIgnorableWhitespace:str];
        [str release];
    }    
}

static void SAXEntityDeclaration(void *ctx, const xmlChar *name, int type, const xmlChar *publicID, const xmlChar *systemID, xmlChar *content)
{
    //NSLog(@"[MIHTMLParser] SAXEntityDeclaration is not handled: name=%s, type=%d, public_id=%s, system_id=%s, content=%s", name, type, publicID, systemID, content);
}

static void SAXSetDocumentLocator(void *ctx, xmlSAXLocatorPtr loc)
{
    //NSLog(@"[MIHTMLParser] SAXSetDocumentLocator is not handled.");
}

static void SAXCDATABlock(void *ctx, const xmlChar *value, int len)
{
    //MIHTMLParser *parser = (MIHTMLParser *)ctx;
    //NSLog(@"[MIHTMLParser] SAXCDATABlock is not handled: %s", [[[NSString alloc] initWithBytes:value length:len encoding:parser.encoding] autorelease]);
}

static void SAXUnparsedEntityDeclSAXFunc(void *ctx, const xmlChar *name, const xmlChar *publicID, const xmlChar *systemID, const xmlChar *notationName)
{
    //NSLog(@"[MIHTMLParser] SAXUnparsedEntityDeclSAXFunc is not handled: name=%s, public_id=%s, system_id=%s, notation_name=%s", name, publicID, systemID, notationName);
}

static void SAXReference(void *ctx, const xmlChar *name)
{
    //NSLog(@"[MIHTMLParser] SAXReference is not handled: name=%s", name);
}

static void SAXProcessingInstruction(void *ctx, const xmlChar *target, const xmlChar *data)
{
    //NSLog(@"[MIHTMLParser] SAXProcessingInstruction is not handled: target=%s, data=%s", target, data);
}

static void SAXWarning(void *ctx, const char *msg, ...)
{
    MIHTMLParser *parser = (MIHTMLParser *)ctx;
    NSObject<MIHTMLParserDelegate> *delegate = parser.delegate;
    if (delegate && [delegate respondsToSelector:@selector(htmlParser:warning:)]) {
        va_list argList;
        va_start(argList, msg);
        
        NSString *format = [[NSString alloc] initWithCString:msg encoding:parser.encoding];
        NSString *error = [[NSString alloc] initWithFormat:format arguments:argList];
        [delegate htmlParser:parser warning:error];
        [error release];
        [format release];
        
        va_end(argList);
    }
}

static void SAXError(void *ctx, const char *msg, ...)
{
    MIHTMLParser *parser = (MIHTMLParser *)ctx;
    NSObject<MIHTMLParserDelegate> *delegate = parser.delegate;
    if (delegate && [delegate respondsToSelector:@selector(htmlParser:error:)]) {
        va_list argList;
        va_start(argList, msg);
	
        NSString *format = [[NSString alloc] initWithCString:msg encoding:parser.encoding];
        NSString *error = [[NSString alloc] initWithFormat:format arguments:argList];
        [delegate htmlParser:parser error:error];
        [error release];
        [format release];
	
        va_end(argList);
    }
}

static void SAXFatalError(void *ctx, const char *msg, ...)
{
    MIHTMLParser *parser = (MIHTMLParser *)ctx;
    NSObject<MIHTMLParserDelegate> *delegate = parser.delegate;
    if (delegate && [delegate respondsToSelector:@selector(htmlParser:fatalError:)]) {
        va_list argList;
        va_start(argList, msg);
        
        NSString *format = [[NSString alloc] initWithCString:msg encoding:parser.encoding];
        NSString *error = [[NSString alloc] initWithFormat:format arguments:argList];
        [delegate htmlParser:parser fatalError:error];
        [error release];
        [format release];
        
        va_end(argList);
    }
}

static int SAXIsStandalone(void *ctx)
{
    NSLog(@"SAXIsStandalone");

    return 1;
}

static int SAXHasInternalSubset(void *ctx)
{
    NSLog(@"SAXHasInternalSubset");

    return 0;
}

static int SAXHasExternalSubset(void *ctx)
{
    NSLog(@"SAXHasExternalSubset");

    return 0;
}

static xmlEntityPtr SAXGetEntity(void *ctx, const xmlChar *name)
{
    NSLog(@"SAXGetEntity: %s", name);
    return NULL;
}

static xmlEntityPtr SAXGetParameterEntity(void *ctx, const xmlChar *name)
{
    NSLog(@"SAXGetParameterEntity: %s", name);
    return NULL;
}

static xmlParserInputPtr SAXResolveEntity(void *ctx, const xmlChar *publicId, const xmlChar *systemId)
{
    NSLog(@"SAXResolveEntity: public_id=%s, system_id=%s", publicId, systemId);
    return NULL;
}

@end

