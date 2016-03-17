#include <Cocoa/Cocoa.h>
#include "NavWindow.h"
@implementation NavWindow
- (BOOL)canBecomeKeyWindow {
	return YES;
}
- (BOOL)canBecomeMainWindow {
	return YES;
}
@end
