#import <substrate.h>
#import <UIKit/UIKBTree.h>
#import "../PS.h"

%config(generator=MobileSubstrate)

typedef struct { double x1; int x2; } UIKBValue;

int (*UIKeyboardDeviceSupportsSplit)(void);

%hookf(int, UIKeyboardDeviceSupportsSplit) {
	return 1;
}

void logUIKBTree(int level, id tree) {
	id object = [tree respondsToSelector:@selector(properties)] ? ((UIKBTree *)tree).properties : tree;
	HBLogDebug([NSString stringWithFormat:@"%%%dsproperties %@ : ", level + 1, object], " ");
	if ([tree respondsToSelector:@selector(subtrees)]) {
		for (id subtree in ((UIKBTree *)tree).subtrees) {
			HBLogDebug([NSString stringWithFormat:@"%%%ds%@ : ", level + 3, subtree], " ");
			logUIKBTree(level + 1, subtree);
		}
	}
}

%hook TUIKeyboardLayoutFactory

- (id)keyboardPrefixForWidth:(CGFloat)width andEdge:(bool)edge {
	return %orig(width >= 1194.0 ? 1112.0 : width, edge);
}

/*- (UIKBTree *)keyboardWithName:(NSString *)name inCache:(NSMutableDictionary *)cache {
	UIKBTree *x = %orig;
	logUIKBTree(0, x);
	return x;
}*/

%end

%hook UIKeyboardCache

+ (BOOL)enabled {
    return NO;
}

%end

%hook UIKBTree

- (CGRect)frameForKeylayoutName:(NSString *)key {
	CGRect rect = %orig;
	if ([key hasPrefix:@"split-"]) {
		CGFloat width = MAX(rect.size.width, rect.size.height);
		if ([key isEqualToString:@"split-left"]) {
			rect.size.width = width >= 1194 ? 570 : 285;
		}
		else if ([key isEqualToString:@"split-right"]) {
			rect.size.width = width >= 1194 ? 570 : 285;
			rect.origin.x = width - (width >= 1194 ? 570 : 285);
		}
	}
	return rect;
}

%end

%hook TUIKBGraphSerialization

- (CGRect)CGRectForOffset:(int *)offset {
	CGRect orig = %orig;
	if (orig.size.width == 768)
		orig.size.width = 834;
	else if (orig.size.width == 1024)
		orig.size.width = 1194;
	if (orig.size.height == 768)
		orig.size.height = 834;
	else if (orig.size.height == 1024)
		orig.size.height = 1194;
	return orig;
}

%end

/*%hook UIKBScreenTraits

- (CGFloat)keyboardWidth {
	CGFloat width = %orig;
	return width >= 1194.0 ? 1112.0 : width;
}

- (void)setKeyboardWidth:(CGFloat)width {
	%orig(width >= 1194.0 ? 1112.0 : width);
}

%end*/

%ctor {
	const char *UIKitCorePath = realPath2(@"/System/Library/PrivateFrameworks/UIKitCore.framework/UIKitCore");
	dlopen(realPath2(@"/System/Library/PrivateFrameworks/TextInputUI.framework/TextInputUI"), RTLD_LAZY);
	dlopen(UIKitCorePath, RTLD_LAZY);
	MSImageRef ref = MSGetImageByName(UIKitCorePath);
	UIKeyboardDeviceSupportsSplit = (int (*)(void))MSFindSymbol(ref, "_UIKeyboardDeviceSupportsSplit");
	%init;
}