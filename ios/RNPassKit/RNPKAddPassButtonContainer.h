
#import <PassKit/PassKit.h>
#import <React/RCTComponent.h>

@interface RNPKAddPassButtonContainer : UIView

- (instancetype)initWithAddPassButtonStyle:(PKAddPassButtonStyle)style;

@property (nonatomic, retain) PKAddPassButton *addPassButton;
@property (nonatomic, assign) PKAddPassButtonStyle addPassButtonStyle;
@property (nonatomic, copy) RCTBubblingEventBlock onPress;

@end
