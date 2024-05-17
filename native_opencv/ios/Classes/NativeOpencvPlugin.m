#import "NativeOpencvPlugin.h"
#if __has_include(<native_opencv/native_opencv-Swift.h>)
#import <native_opencv/native_opencv-Swift.h>
#else
#import "native_opencv-Swift.h"
#endif

@implementation NativeOpencvPlugin

// Register the plugin with the Flutter registrar
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftNativeOpencvPlugin registerWithRegistrar:registrar];
}

@end

