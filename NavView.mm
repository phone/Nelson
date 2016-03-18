#include <Cocoa/Cocoa.h>
#include <mach/mach_time.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include "NavView.h"

@implementation File
@end

@implementation NavView

- (void)plumb {
	if ([self selLen] == 0)
		return;
	uint32_t sz = [[self cwd] length] + [self selLen] + 2;
	NSRange rng = {[self selStart], [self selLen]};
	NSMutableString *path = [NSMutableString stringWithCapacity:sz];
	[path appendString:[self cwd]];
	[path appendString:@"/"];
	[path appendString:[[self output] substringWithRange:rng]];
	if ([path characterAtIndex:[path length] - 1] == '*') {
		[path deleteCharactersInRange:(NSRange){[path length] - 1, 1}];
	}
	char *cpath = (char *)calloc([path length], 1);
	strcpy(cpath, [path UTF8String]);
	int err = execlp("plumb", "-dedit", cpath, nil);
	if (err) {
		fprintf(stderr, "plumb -d edit %s: ", cpath);
		perror(nil);
		fprintf(stderr, "\n");
	}
}

- (void)keyDown:(NSEvent *)theEvent {
	[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

- (void)cancelOperation:(id)sender {
	exit(0);
}

- (void)insertLineBreak:(id)sender {
	[self insertNewline:sender];
}

- (void)changeDirectory:(NSString *)nwd {
	[self setCwd:nwd];
	[[self qry] deleteCharactersInRange:(NSRange){0, [[self qry] length]}];
	[self populate];
	[self query];
	[self render];
}

- (void)insertNewline:(id)sender {
	if ([[self output] characterAtIndex:[self selStart] + [self selLen] - 1] == '/') {
		uint32_t cap = [[self cwd] length] + [self selLen] + 2;
		NSMutableString * nwd = [NSMutableString stringWithCapacity:cap];
		[nwd appendString:[self cwd]];
		[nwd appendString:@"/"];
		[nwd appendString:[[self output]
			substringWithRange:(NSRange){[self selStart],[self selLen] - 1}]];
		[self changeDirectory:nwd];
	} else {
		[self plumb];
	}
}

- (void)insertTab:(id)sender {
	uint32_t i, j;
	if (![self hasEntries])
		return;
	[self unSelect];
	/* We are moving forward to the start of the next filename */
	for (i = [self selStart]; i < [[self output] length] - 1; ++i) {
		if ([[self output] characterAtIndex:i] == ' ') {
			if ([[self output] characterAtIndex:i + 1] == ' ') {
				i = i + 2;
				break;
			}
		}
	}
	/* If we're at the end, wrap back to the beginning */
	if (i == [[self output] length] - 1) {
		i = [[self cwd] length] + [[self qry] length] + 2;
		/* plus 2, one for "/" after cwd, one for "{" after qry. */
	}
	/* We are moving forward to the start of the next filename */
	for (j = i; j < [[self output] length] - 1; ++j) {
		if ([[self output] characterAtIndex:j] == ' ') {
			if ([[self output] characterAtIndex:j + 1] == ' ') {
				break;
			}
		}
	}
	/* j will be set to index of first space after selected file, so j - i gets length */
	[self setSelStart:i];
	[self setSelLen:j - i];
	[self reSelect];
}

- (void)insertBacktab:(id)sender {
	uint32_t i, j;
	if (![self hasEntries])
		return;
	//NSLog(@"BT: prevStart: %d, prevLen: %d", [self selStart], [self selLen]);
	[self unSelect];
	/* If at beginning */
	i = [self selStart];
	if (i == [[self cwd] length] + [[self qry] length] + 2) {
		//NSLog(@"BT: At Beginning Detected!");
		i = [[self output] length];
	}
	/* Move back until we see two spaces or the beginning of listing */
	for (i = i - 2; i > [[self cwd] length] + [[self qry] length] + 2; --i) {
		if ([[self output] characterAtIndex:i] == ' ') {
			if ([[self output] characterAtIndex:i - 1] == ' ') {
				i = i + 1;
				break;
			}
		}
	}

	/* We are moving forward to the start of the next filename */
	for (j = i; j < [[self output] length] - 1; ++j) {
		if ([[self output] characterAtIndex:j] == ' ') {
			if ([[self output] characterAtIndex:j + 1] == ' ') {
				break;
			}
		}
	}
	/* j will be set to index of first space after selected file, so j - i gets length */
	[self setSelStart:i];
	[self setSelLen:j - i];
	//NSLog(@"BT: newStart: %d, newLen: %d", [self selStart], [self selLen]);
	[self reSelect];
}

- (void)deleteBackward:(id)sender {
	int i;
	if ([[self qry] length] == 0) {
		NSString *cwd = [self cwd];
		if ([cwd length] == 1 && [cwd characterAtIndex:0] == '/')
			return;
		for (i = [cwd length] - 1; i >= 0; --i) {
			if ([cwd characterAtIndex:i] == '/')
				break;
		}
		NSString *up;
		if (i == 0)
			up = @"/";
		else
			up = [cwd substringToIndex:i];
		[self setCwd:up];
		[self populate];
	} else {
		NSRange del = {[[self qry] length] - 1, 1};
		[[self qry] deleteCharactersInRange:del];
	}
	[self query];
	[self render];
}

- (void)insertText:(id)string {
	//NSLog(@"Received insertText: %@", string);
	//[super insertText:string];  // have superclass insert it
	[[self qry] appendString:string];
	[self query];
	[self render];
}

-(uint8_t)hasEntries {
	return ([[self cwd] length] + [[self qry] length] + 3 < [[self output] length]);
}

-(void)populate {
	int i;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([self cwd] == nil) {
		[self setCwd:[fileManager currentDirectoryPath]];
	}
	//NSLog(@"Populating at %@", [self cwd]);
	NSURL *cwd = [NSURL fileURLWithPath:[self cwd]];
	NSArray *keys = @[
		NSURLNameKey,
		NSURLContentModificationDateKey,
		NSURLIsDirectoryKey,
		NSURLIsRegularFileKey,
		NSURLIsExecutableKey];
	NSArray *fileurls = [fileManager contentsOfDirectoryAtURL:cwd
		includingPropertiesForKeys:keys
		options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants
			| NSDirectoryEnumerationSkipsPackageDescendants)
		error: nil];
	NSMutableArray *files = [NSMutableArray arrayWithCapacity:[fileurls count]];
	for (i = 0; i < [fileurls count]; ++i) {
		NSURL *url = [fileurls objectAtIndex:i];
		NSString *name;
		NSDate *mDate;
		NSNumber *isDirectory;
		NSNumber *isRegular;
		NSNumber *isExecutable;
		NSError *error;
		//TODO: where does this shit get allocated from???
		if (![url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
			NSLog(@"isDirectory: %@", [error localizedDescription]);
			error = nil;
		}
		if (![url getResourceValue:&isRegular forKey:NSURLIsRegularFileKey error:&error]) {
			NSLog(@"isRegular: %@", [error localizedDescription]);
			error = nil;
		}
		if (![url getResourceValue:&name forKey:NSURLNameKey error:&error]) {
			NSLog(@"name: %@", [error localizedDescription]);
			error = nil;
		}
		if (![url getResourceValue:&isExecutable forKey:NSURLIsExecutableKey error:&error]) {
			NSLog(@"isExecutable: %@", [error localizedDescription]);
			error = nil;
		}
		if (![url getResourceValue:&mDate forKey:NSURLContentModificationDateKey error:&error]) {
			NSLog(@"mDate: %@", [error localizedDescription]);
			error = nil;
		}
		if (([isDirectory boolValue] == NO)
				&& ([isRegular boolValue] == NO))
			continue;
		uint64_t mTime = (uint64_t)[mDate timeIntervalSince1970];
		File *file = [File alloc];
		//TODO: leaks?
		if ([isDirectory boolValue] == YES) {
			[file setName:[name stringByAppendingString:@"/"]];
		} else if ([isExecutable boolValue] == YES) {
			[file setName:[name stringByAppendingString:@"*"]];
		} else {
			[file setName:name];
		}
		[file setMtime:mTime];
		[files addObject:file];
	}
	[self setFiles:files];
}
-(void)query {
	uint32_t selstart, sellen, i, j, found, first = 1;
	NSMutableString *output = [NSMutableString stringWithCapacity:(
		[[self cwd] length] + [[self qry] length] + 2)];
	NSMutableArray *rslt = [[NSMutableArray alloc] init];
	for (i = 0; i < [[self files] count]; ++i) {
		[rslt addObject:[[self files] objectAtIndex:i]];
	}
	NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"mtime" ascending:NO];
	NSArray *srslt = [rslt sortedArrayUsingDescriptors:@[sd]];
	[output appendString:[self cwd]];
	[output appendString:@"/"];
	[output appendString:[self qry]];
	selstart = [output length] + 1;
	sellen = 0;
	[output appendString:@"{"];
	for (i = 0; i < [srslt count]; ++i) {
		found = 0;
		File *file = [srslt objectAtIndex:i];
		for (j = 0; found < [[self qry] length] && j < [[file name] length]; ++j) {
			if ([[file name] characterAtIndex:j] == [[self qry] characterAtIndex:found]) {
				++found;
			}
			if (found == [[self qry] length]) {
				break;
			}
		}
		if (found < [[self qry] length]) {
			continue;
		}
		if (!first) {
			[output appendString:@"  "];
		}
		if (first) {
			selstart = [output length];
		}
		[output appendString:[file name]];
		if (first) {
			sellen = [output length] - selstart;
			first = 0;
		}
	}
	[output appendString:@"}"];
	[self setReplLen:[[self output] length]];
	[self setOutput:output];
	[self setSelStart:selstart];
	[self setSelLen:sellen];
}

-(void)unSelect {
	NSRange sel = {[self selStart], [self selLen]};
	[[self textStorage] applyFontTraits:NSUnboldFontMask range:sel];
}

-(void)reSelect {
	NSRange sel = {[self selStart], [self selLen]};
	[[self textStorage] applyFontTraits:NSBoldFontMask range:sel];
}

-(void)render {
	NSRange repl = {0, [self replLen]};
	NSRange ins = {[[self cwd] length] + [[self qry] length] + 1, 0};
	//NSLog(@"selstart: %d sellen: %d, repllen: %d", [self selStart], [self selLen], [self replLen]);
	[self setDrawsBackground:NO];
	[self setRichText:YES];
	[[self textStorage] replaceCharactersInRange:repl withString:[self output]];
	[self setFont:[NSFont userFontOfSize:24]];
	[self reSelect];
	[self setSelectedRange:ins];
	[self setEditable:YES];
	[self setContentHuggingPriority:NSLayoutPriorityFittingSizeCompression-1.0
		forOrientation:NSLayoutConstraintOrientationVertical];
	[self setFrame:[[[self parentWindow] contentView] bounds]];
}
@end
