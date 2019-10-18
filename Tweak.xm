#define CHECK_TARGET
#import <UIKit/UIKBTree.h>
#import <UIKit/UIKBShape.h>
#import <UIKit/UIKBKeyView.h>
#import <UIKit/UIKeyboardImpl.h>
#import <UIKit/UIKeyboardLayoutStar.h>
#import "../PS.h"

// Uncomment if non iOS 13 keyboard layout file used
/*%hook TUIKBGraphSerialization

- (CGRect)CGRectForOffset:(int *)offset {
	CGRect orig = %orig;
	if (orig.size.width == 768)
		orig.size.width = 834;
	else if (orig.size.width == 1024 || orig.size.width == 1112)
		orig.size.width = 1194;
	if (orig.size.height == 768)
		orig.size.height = 834;
	else if (orig.size.height == 1024 || orig.size.height == 1112)
		orig.size.height = 1194;
	if (orig.origin.x > 1194)
		orig.origin.x -= 1194;
	return orig;
}

%end

%hook UIKeyboardEmojiSplitCharacterPicker

- (void)setFrame:(CGRect)frame {
	if (frame.origin.x == 512)
		frame.origin.x = 834 - frame.size.width - 56;
	else if (frame.origin.x == 767)
		frame.origin.x = 1194 - frame.size.width - 56;
	%orig(frame);
}

%end*/

%hook TUIKeyboardLayoutFactory

+ (NSString *)layoutsFileName {
	return @"KBLayouts_iPad2.dat";
}

%end

BOOL override = NO;

BOOL isTargetKey(UIKBTree *keyplane, UIKBTree *key) {
	return [keyplane.name containsString:@"Wildcat-Emoji-Keyboard"] && [keyplane.name hasSuffix:@"-split"] && key.frame.size.width == 56;
}

CGRect modifyKeyFrame(CGRect frame) {
	CGRect mframe = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
	BOOL set = mframe.origin.x == 716 || mframe.origin.x == 968;
	set = set && mframe.size.width != 0;
	if (set) {
		CGFloat base = mframe.origin.x == 716 ? 834 : 1194;
		mframe.origin.x = base - mframe.size.width;
	}
	return mframe;
}

%hook UIKBKeyView

- (void)layoutSubviews {
	%orig;
	if (isTargetKey(self.keyplane, self.key)) {
		CGRect frame = self.frame;
		CGRect mframe = modifyKeyFrame(frame);
		self.drawFrame = mframe;
		self.key.frame = mframe;
		self.key.shape.frame = mframe;
		self.key.shape.paddedFrame = mframe;
		self.key.shape = self.key.shape;
	}
}

%end

%hook UIKBScreenTraits

- (CGFloat)keyboardWidth {
	CGFloat orig = %orig;
	return override ? orig > 1112.0 ? 1112.0 : orig : orig;
}

%end

%hook UIKBInputBackdropView

- (id)initWithFrame:(CGRect)frame {
	override = YES;
	self = %orig;
	override = NO;
	return self;
}

%end

%hook UIInputViewSet

- (bool)_inputViewSupportsSplit {
	override = YES;
	bool orig = %orig;
	override = NO;
	return orig;
}

%end

%hook UIKeyboardImpl

+ (bool)supportsSplit {
	override = YES;
	bool orig = %orig;
	override = NO;
	return orig;
}

+ (void)refreshRivenStateWithTraits:(id)trats isKeyboard:(bool)isKeyboard {
	override = YES;
	%orig;
	override = NO;
}

%end

%hook UIKeyboardLayoutStar

- (void)setFrame:(CGRect)frame {
	if ([self.keyplane isSplit] && frame.size.height > 216) {
		if (frame.size.height - 17 > 200)
			frame.size.height -= 17;
	}
	%orig(frame);
}

- (bool)_shouldAttemptToAddSupplementaryControlKeys {
	override = [self.keyplane isSplit];
	bool orig = %orig;
	override = NO;
	return orig;
}

- (void)_swapGlobeAndMoreKeysIfNecessary {
	override = [self.keyplane isSplit];
	%orig;
	override = NO;
}

%end

%group Bundle

%hook KeyboardController

- (void)loadPreferenceForInputModeIdentifier:(void *)arg2 keyboardInputMode:(void *)arg3 addNewPreferencesToArray:(void *)arg4 defaultPreferenceIdentifiers:(void *)arg5 additionalPreferenceIdentifiers:(void *)arg6 mapPreferenceToInputMode:(void *)arg7 {
	override = YES;
	%orig;
	override = NO;
}

%end

%end

int (*UIKeyboardComputeKeyboardIdiomFromScreenTraits)(void *, int, int);
%hookf(int, UIKeyboardComputeKeyboardIdiomFromScreenTraits, void *screenTraits, int idiom, int arg3) {
	return override ? 0 : %orig(screenTraits, idiom, arg3);
}

%ctor {
	if (isTarget(TargetTypeApps)) {
		dlopen(realPath2(@"/System/Library/PrivateFrameworks/TextInputUI.framework/TextInputUI"), RTLD_LAZY);
		MSImageRef ref = MSGetImageByName(realPath2(@"/System/Library/PrivateFrameworks/UIKitCore.framework/UIKitCore"));
		if ([@"com.apple.Preferences" isEqualToString:NSBundle.mainBundle.bundleIdentifier]) {
			dlopen("/System/Library/PreferenceBundles/KeyboardSettings.bundle/KeyboardSettings", RTLD_NOW | RTLD_GLOBAL);
			%init(Bundle);
		}
		UIKeyboardComputeKeyboardIdiomFromScreenTraits = (int (*)(void *, int, int))_PSFindSymbolCallable(ref, "_UIKeyboardComputeKeyboardIdiomFromScreenTraits");
		%init;
	}
}