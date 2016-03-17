#pragma once
#include <Cocoa/Cocoa.h>
#include <stdint.h>

@interface File : NSObject
@property (retain, readwrite) NSString *name;
@property (assign, readwrite) uint64_t mtime;
@end

@interface NavView : NSTextView
//@property float width;
//@property float height;
@property (assign, readwrite) uint32_t replLen;
@property (retain, readwrite) NSString *output;
@property (retain, readwrite) NSString *cwd;
@property (retain, readwrite) NSMutableString *qry;
@property (assign, readwrite) uint32_t selStart;
@property (assign, readwrite) uint32_t selLen;
@property (retain, readwrite) NSMutableArray *files;
-(void)populate;
-(void)query;
-(void)render;
-(void)renderToWindow:(NSWindow *)window;
-(void)reSelect;
@end
