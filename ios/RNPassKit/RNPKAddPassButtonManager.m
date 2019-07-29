
#import <PassKit/Passkit.h>
#import "RNPKAddPassButtonManager.h"
#import "RNPKAddPassButtonContainer.h"
#import "RCTConvert+RNPassKit.h"

@implementation RNPKAddPassButtonManager

RCT_EXPORT_MODULE()

RCT_CUSTOM_VIEW_PROPERTY(addPassButtonStyle, PKAddPassButtonStyle, RNPKAddPassButtonContainer) {
  view.addPassButtonStyle = json ? [RCTConvert PKAddPassButtonStyle:json] : defaultView.addPassButtonStyle;
}

RCT_EXPORT_VIEW_PROPERTY(onPress, RCTBubblingEventBlock)


- (UIView *)view {
  RNPKAddPassButtonContainer *addPassButtonContainer = [[RNPKAddPassButtonContainer alloc] initWithAddPassButtonStyle:PKAddPassButtonStyleBlack];
  return addPassButtonContainer;
}

@end
