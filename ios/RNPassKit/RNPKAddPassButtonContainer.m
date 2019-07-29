
#import "RNPKAddPassButtonContainer.h"

@implementation RNPKAddPassButtonContainer

- (instancetype)initWithAddPassButtonStyle:(PKAddPassButtonStyle)style {
  if (self = [super init]) {
    NSLog(@" ------------- initWithAddPassButtonStyle ---------------");
    self.addPassButton = [[PKAddPassButton alloc] initWithAddPassButtonStyle:style];
    self.addPassButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.addPassButton addTarget:self
                           action:@selector(addPassButtonDidTouchUpInside:)
                 forControlEvents:UIControlEventTouchUpInside];
    [super setFrame:self.addPassButton.frame];
    [self addSubview:self.addPassButton];
  }
  
  return self;
}

- (PKAddPassButtonStyle)addPassButtonStyle {
  if (self.addPassButton != nil) {
    return self.addPassButton.addPassButtonStyle;
  }
  return PKAddPassButtonStyleBlack;
}

- (void)setAddPassButtonStyle:(PKAddPassButtonStyle)addPassButtonStyle {
  if (self.addPassButton != nil) {
    self.addPassButton.addPassButtonStyle = addPassButtonStyle;
  }
}

- (void)addPassButtonDidTouchUpInside:(id)sender {
   if (self.onPress) {
     self.onPress(@{});
   }
}


@end
