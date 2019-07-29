

#import <PassKit/PassKit.h>
#import "RCTConvert+RNPassKit.h"

@implementation RCTConvert (RNPassKit)

+ (PKAddPassButtonStyle)PKAddPassButtonStyle:(id)json {
  return (PKAddPassButtonStyle)json;
}

@end
