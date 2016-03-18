#include <Cocoa/Cocoa.h>
#include <mach/mach_time.h>
#include <stdio.h>
#include <string.h>
//#include "Navigator.h"
#include "NavWindow.h"
#include "NavView.h"

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

int main(int argc, const char* argv[])
{
	#pragma unused(argc)
	#pragma unused(argv)

	@autoreleasepool
	{
		NSApplication* app = [NSApplication sharedApplication];
		[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
		OSXCreateMainMenu();
		[app setDelegate:[[NavAppDelegate alloc] init]];

		NSRect screenRect = [[NSScreen mainScreen] frame];
		float w = screenRect.size.width / 2;
		float h = screenRect.size.height / 3;
		NSRect frame = NSMakeRect((screenRect.size.width - w) * 0.5,
			(screenRect.size.height - h) * 0.5, w, h);

		NavWindow* window = [[NavWindow alloc] initWithContentRect:frame
			styleMask: NSResizableWindowMask
			backing:NSBackingStoreBuffered
			defer:NO];
		NavView* view = [[NavView alloc] init];
		[view setParentWindow:window];
		[view populate];
		[view setQry:[NSMutableString stringWithCapacity:256]];
		[view query];
		[view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

		[[window contentView] addSubview:view];
		[window setMinSize:NSMakeSize(20, 20)];
		[window makeKeyAndOrderFront:nil];
		[view render];
		[NSApp activateIgnoringOtherApps:YES];

		[NSApp run];
	}
}
