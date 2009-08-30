//
//  CBSAXHTMLParser.h
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXParser.h"
#import "MIHTMLParser.h"


@interface CBSAXHTMLParser : CBSAXParser<MIHTMLParserDelegate> {
    MIHTMLParser    *mHTMLParser;
}

@end

