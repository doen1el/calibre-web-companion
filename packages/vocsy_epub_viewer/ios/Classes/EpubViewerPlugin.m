#import "EpubViewerPlugin.h"
#import <vocsy_epub_viewer/vocsy_epub_viewer-Swift.h>

@implementation EpubViewerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftEpubViewerPlugin registerWithRegistrar:registrar];
}
@end
