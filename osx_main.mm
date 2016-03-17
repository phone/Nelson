#include <Cocoa/Cocoa.h>
#include <mach/mach_time.h>
#include <stdio.h>
#include <string.h>
//#include "Navigator.h"
#include "NavWindow.h"
#include "NavView.h"

static uint8_t Alive;

@interface NavAppDelegate : NSObject<NSApplicationDelegate>
@end

@implementation NavAppDelegate

- (void)applicationDidFinishLaunching:(id)sender {
	#pragma unused(sender)
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender {
	#pragma unused(sender)
	return YES;
}

- (void)applicationWillTerminate:(NSApplication*)sender {
	#pragma unused(sender)
	printf("applicationWillTerminate\n");
}

@end


void OSXCreateMainMenu() {
	NSMenu* menubar = [NSMenu new]; 

	NSMenuItem* appMenuItem = [NSMenuItem new];
	[menubar addItem:appMenuItem];

	[NSApp setMainMenu:menubar];

	NSMenu* appMenu = [NSMenu new];

	//NSString* appName = [[NSProcessInfo processInfo] processName];
	NSString* appName = @"Nelson";

	NSString* quitTitle = [@"Quit " stringByAppendingString:appName];
	NSMenuItem* quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitTitle
		action:@selector(terminate:)
		keyEquivalent:@"q"];
	[appMenu addItem:quitMenuItem];
	[appMenuItem setSubmenu:appMenu];
}

char *query;
char *queryend;
char *selection = nil;
int IsDown = 0;

int main(int argc, const char* argv[])
{
	#pragma unused(argc)
	#pragma unused(argv)

	//return NSApplicationMain(argc, argv);
	@autoreleasepool
	{
		NSApplication* app = [NSApplication sharedApplication];
		[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
	/*
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *dir = [fileManager currentDirectoryPath];
		NSLog(@"working directory: %@", dir);
		NSArray *contents = [fileManager contentsOfDirectoryAtPath:dir error:nil];
		NSString *fullresult = [dir stringByAppendingString:@"/{"];
		uint32_t selstart = 0, sellen = 0;
		if (contents) {
			for (i = 0; i < [contents count]; ++i) {
				if (i == 0) {
					selstart = [fullresult length];
				}
				fullresult = [fullresult stringByAppendingString:[contents objectAtIndex:i]];
				if (i == 0) {
					sellen = [fullresult length] - selstart;
				}
				if (i != [contents count] - 1) {
					fullresult = [fullresult stringByAppendingString:@"  "];
				}
			}
		}
		fullresult = [fullresult stringByAppendingString:@"}"];
*/
		OSXCreateMainMenu();

		[app setDelegate:[[NavAppDelegate alloc] init]];

		// Create the main window and the content view
		NSRect screenRect = [[NSScreen mainScreen] frame];
		//float w = 960.0; // 1920.0;
		//float h = 540.0; // 1080.0;
		float w = 960.0;
		float h = 540.0;
		NSRect frame = NSMakeRect((screenRect.size.width - w) * 0.5,
			(screenRect.size.height - h) * 0.5, w, h);
	
		NavWindow* window = [[NavWindow alloc] initWithContentRect:frame
			styleMask: NSResizableWindowMask
			backing:NSBackingStoreBuffered
			defer:NO];
		NavView* view = [[NavView alloc] init];
		[view populate];
		[view setQry:[NSMutableString stringWithCapacity:256]];
		[view query];
		[view renderToWindow:window];
/*		
		[view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		NSRange rng = {0, 0};
		NSRange selrng = {selstart, sellen};
		NSRange insrng = {selstart - 1, 0};
		[view setRichText:YES];
		[[view textStorage] replaceCharactersInRange:rng withString:fullresult];
		[view setFont:[NSFont userFontOfSize:28]];
		//[view setSelectedRange:selrng];
		[[view textStorage] applyFontTraits:NSBoldFontMask range:selrng];
		//[view setTextColor:[NSColor redColor] range:selrng];
		[view setSelectedRange:insrng];
		[view setEditable:YES];
		[view setFrame:[[window contentView] bounds]];
*/
		[[window contentView] addSubview:view];
		[window setMinSize:NSMakeSize(100, 100)];
		[window makeKeyAndOrderFront:nil];
		[window setFrame:frame display:YES];

		Alive = true;
		[NSApp run];
	}
}
