
#import <PassKit/PassKit.h>
#import "RNPassKit.h"
#import "RNPasskitAddToWalletDefinitions.h"

@implementation RNPassKit

static char NSData_BytesConversionString[512] = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff";

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(canAddPasses:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject) {
  resolve(@([PKAddPassesViewController canAddPasses]));
}

RCT_EXPORT_METHOD(addPass:(NSString *)base64Encoded
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject) {
  NSData *data = [[NSData alloc] initWithBase64EncodedString:base64Encoded options:NSUTF8StringEncoding];
  NSError *error;
  PKPass *pass = [[PKPass alloc] initWithData:data error:&error];

  if (error) {
    reject(@"", @"Failed to create pass.", error);
    return;
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    UIApplication *sharedApplication = RCTSharedApplication();
    UIWindow *window = sharedApplication.keyWindow;
    if (window) {
      UIViewController *rootViewController = window.rootViewController;
      if (rootViewController) {
        PKAddPassesViewController *addPassesViewController = [[PKAddPassesViewController alloc] initWithPass:pass];
        addPassesViewController.delegate = self;
        [rootViewController presentViewController:addPassesViewController animated:YES completion:^{
          // Succeeded
          resolve(nil);
        }];
        return;
      }
    }
    
    reject(@"", @"Failed to present PKAddPassesViewController.", nil);
  });
}

- (NSDictionary *)constantsToExport {
  PKAddPassButton *addPassButton = [[PKAddPassButton alloc] initWithAddPassButtonStyle:PKAddPassButtonStyleBlack];
  [addPassButton layoutIfNeeded];
  
  return @{
           @"AddPassButtonStyle": @{
               @"black": @(PKAddPassButtonStyleBlack),
               @"blackOutline": @(PKAddPassButtonStyleBlackOutline),
               },
           @"AddPassButtonWidth": @(CGRectGetWidth(addPassButton.frame)),
           @"AddPassButtonHeight": @(CGRectGetHeight(addPassButton.frame)),
           };
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

#pragma mark - PKAddPassesViewControllerDelegate

- (void)addPassesViewControllerDidFinish:(PKAddPassesViewController *)controller {
  [controller dismissViewControllerAnimated:YES completion:^{
    [self sendEventWithName:@"addPassesViewControllerDidFinish" body:nil];
  }];
}

#pragma mark - RCTEventEmitter implementation

- (NSArray<NSString *> *)supportedEvents {
  return @[@"addPassesViewControllerDidFinish", @"addingPassSucceeded", @"addingPassFailed", @"addToWalletViewCreationError", @"addToWalletViewShown", @"addToWalletViewHidden"];
}


RCT_EXPORT_METHOD(isAvailable:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject) {
  resolve(@([PKAddPaymentPassViewController canAddPaymentPass]));
}

RCT_EXPORT_METHOD(canAddCard:(NSString *)card
    reolver:(RCTPromiseResolveBlock)resolve
    rejector:(RCTPromiseRejectBlock)reject) {

    PKPassLibrary *library = [[PKPassLibrary alloc] init];
    resolve(@([library canAddPaymentPassWithPrimaryAccountIdentifier:card]));  
}

RCT_EXPORT_METHOD(getUUID:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject) {

    NSString *uuid = [[NSUUID UUID] UUIDString];
    
    NSDictionary *keychainItem = @{
                                   (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                   (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                   (__bridge id)kSecAttrAccount : @"RNPassKitModule",
                                   (__bridge id)kSecValueData : [uuid dataUsingEncoding:NSUTF8StringEncoding],
                                   (__bridge id)kSecReturnData : (__bridge id)kCFBooleanTrue,
                                   };
    
    CFDataRef result = nil;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, (CFTypeRef *)&result) == noErr) {
        NSData *uuidData = (__bridge NSData *)result;
        uuid = [[NSString alloc] initWithData:uuidData encoding:NSUTF8StringEncoding];
        
        CFRelease(result);
    } else {
        OSStatus status = SecItemAdd((__bridge CFDictionaryRef)keychainItem, NULL);
    }
    
    resolve(uuid);
}

RCT_EXPORT_METHOD(presentAddPaymentPassViewController: (NSDictionary *)args 
    resolver:(RCTPromiseResolveBlock)resolve 
    rejecter:(RCTPromiseRejectBlock)reject) {

    PKAddPaymentPassRequestConfiguration *configuration = [[PKAddPaymentPassRequestConfiguration alloc] initWithEncryptionScheme:PKEncryptionSchemeECC_V2];
    
    self.cardholderName = args[@"cardholderName"];
    self.localizedDescription = args[@"localizedDescription"];
    switch ([args[@"paymentNetwork"] intValue]) {
        case kPKPaymentNetworkAmex:
            self.paymentNetwork = PKPaymentNetworkAmex;
            break;
        case kPKPaymentNetworkDiscover:
            self.paymentNetwork = PKPaymentNetworkDiscover;
            break;
        case kPKPaymentNetworkMasterCard:
            self.paymentNetwork = PKPaymentNetworkMasterCard;
            break;
        case kPKPaymentNetworkPrivateLabel:
            self.paymentNetwork = PKPaymentNetworkPrivateLabel;
            break;
        case kPKPaymentNetworkVisa:
            self.paymentNetwork = PKPaymentNetworkVisa;
            break;
        default:
            self.paymentNetwork = nil;
            break;
    }    
    self.primaryAccountSuffix = args[@"primaryAccountSuffix"];
    self.primaryAccountIdentifier = args[@"primaryAccountIdentifier"];
    self.apiEndpoint = args[@"apiEndpoint"];
    self.authorization = args[@"authorization"];
    self.userName = args[@"userName"];

    configuration.cardholderName = self.cardholderName;
    configuration.localizedDescription = self.localizedDescription;
    configuration.paymentNetwork = self.paymentNetwork;
    configuration.primaryAccountSuffix = self.primaryAccountSuffix;
    configuration.primaryAccountIdentifier = self.primaryAccountIdentifier;

    PKAddPaymentPassViewController *passView = [[PKAddPaymentPassViewController alloc] initWithRequestConfiguration:configuration
                                                                                                           delegate:self];
    if (passView != nil) {
      dispatch_async(dispatch_get_main_queue(), ^{
        UIApplication *sharedApplication = RCTSharedApplication();
        UIWindow *window = sharedApplication.keyWindow;
        if (window) {
          UIViewController *rootViewController = window.rootViewController;
          if (rootViewController) {
           
            [rootViewController presentViewController:passView animated:YES completion:^{
              // Succeeded
                [self sendEventWithName:@"addToWalletViewShown" body:@{
                    @"args" : args
                    }];

                resolve(nil);
                return;
            }];            

          }
        }
      });

        
    } else {

        [self sendEventWithName:@"addToWalletViewCreationError" body:nil];
        resolve(nil);
        return;
    }
}

#pragma mark PKAddPaymentPassViewControllerDelegate Methods

-(void)addPaymentPassViewController:(PKAddPaymentPassViewController *)controller
generateRequestWithCertificateChain:(NSArray<NSData *> *)certificates
                              nonce:(NSData *)nonce
                     nonceSignature:(NSData *)nonceSignature
                  completionHandler:(void (^)(PKAddPaymentPassRequest *request))handler
{
    NSLog(@"[INFO] addPaymentPassViewController 1");

    NSURL *apiEndpointURL = [NSURL URLWithString:self.apiEndpoint];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiEndpointURL];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 19.0;
    [request setAllHTTPHeaderFields:@{
                                      @"content-type" : @"application/x-www-form-urlencoded",
                                      @"authorization" : self.authorization,
                                      }];

    
    NSData *noncePrefix = [@"&Nonce=" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *nonceHex = [self dataToHexData:nonce];
    
    NSData *nonceSignaturePrefix = [@"&NonceSignature=" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *nonceSignatureHex = [self dataToHexData:nonceSignature];

    NSData *leafCertificatePrefix = [@"&LeafCertificate=" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *leafCertificateHex = [self dataToHexData:certificates[0]];

    NSData *subCACertificatePrefix = [@"&SubCACertificate=" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *subCACertificateHex = [self dataToHexData:certificates[1]];

    NSData *userNamePrefix;
    NSData *userNameHex;

    if(![self.userName isEqual:[NSNull null]]) {      
        userNamePrefix = [@"&Username=" dataUsingEncoding:NSUTF8StringEncoding];
        userNameHex = [self.userName dataUsingEncoding:NSUTF8StringEncoding];
    }
        
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);

    dispatch_data_t dispatch_data_noncePrefix = dispatch_data_create(noncePrefix.bytes, noncePrefix.length, queue, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    dispatch_data_t dispatch_data_nonce = dispatch_data_create(nonceHex.bytes, nonceHex.length, queue, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    
    dispatch_data_t dispatch_data_nonceSignaturePrefix = dispatch_data_create(nonceSignaturePrefix.bytes, nonceSignaturePrefix.length, queue, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    dispatch_data_t dispatch_data_nonceSignature = dispatch_data_create(nonceSignatureHex.bytes, nonceSignatureHex.length, queue, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    
    dispatch_data_t dispatch_data_leafCertificatePrefix = dispatch_data_create(leafCertificatePrefix.bytes, leafCertificatePrefix.length, queue, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    dispatch_data_t dispatch_data_leafCertificate = dispatch_data_create(leafCertificateHex.bytes, leafCertificateHex.length, queue, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    
    dispatch_data_t dispatch_data_subCACertificatePrefix = dispatch_data_create(subCACertificatePrefix.bytes, subCACertificatePrefix.length, queue, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    dispatch_data_t dispatch_data_subCACertificate = dispatch_data_create(subCACertificateHex.bytes, subCACertificateHex.length, queue, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    
    dispatch_data_t dispatch_data_userNamePrefix;
    dispatch_data_t dispatch_data_userName;
    
    if (self.userName != nil) {
        dispatch_data_userNamePrefix = dispatch_data_create(userNamePrefix.bytes, userNamePrefix.length, queue, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
        dispatch_data_userName = dispatch_data_create(userNameHex.bytes, userNameHex.length, queue, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    }

    noncePrefix = nil;
    nonce = nil;
    nonceHex = nil;
    
    nonceSignaturePrefix = nil;
    nonceSignature = nil;
    nonceSignatureHex = nil;
    
    leafCertificatePrefix = nil;
    leafCertificateHex = nil;
    subCACertificatePrefix = nil;
    subCACertificateHex = nil;
    certificates = nil;
    
    userNamePrefix = nil;
    userNameHex = nil;
    
    dispatch_data_t dispatch_data_concat = dispatch_data_create_concat(dispatch_data_noncePrefix, dispatch_data_nonce);
    
    dispatch_data_concat = dispatch_data_create_concat(dispatch_data_concat, dispatch_data_nonceSignaturePrefix);
    dispatch_data_concat = dispatch_data_create_concat(dispatch_data_concat, dispatch_data_nonceSignature);
    
    dispatch_data_concat = dispatch_data_create_concat(dispatch_data_concat, dispatch_data_leafCertificatePrefix);
    dispatch_data_concat = dispatch_data_create_concat(dispatch_data_concat, dispatch_data_leafCertificate);
    
    dispatch_data_concat = dispatch_data_create_concat(dispatch_data_concat, dispatch_data_subCACertificatePrefix);
    dispatch_data_concat = dispatch_data_create_concat(dispatch_data_concat, dispatch_data_subCACertificate);
    
    if (self.userName != nil) {
        dispatch_data_concat = dispatch_data_create_concat(dispatch_data_concat, dispatch_data_userNamePrefix);
        dispatch_data_concat = dispatch_data_create_concat(dispatch_data_concat, dispatch_data_userName);
    }
    
    
    NSMutableData *postData = [NSMutableData dataWithCapacity: dispatch_data_get_size(dispatch_data_concat)];
    dispatch_data_apply(dispatch_data_concat, ^(dispatch_data_t region, size_t offset, const void *buffer, size_t size) {
        [postData appendBytes:buffer length:size];
        return (_Bool)true;
    });

    [request setHTTPBody:postData];
    

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

            NSLog(@"[INFO] addPaymentPassViewController 3");
            NSLog(@"error: %@", error);
            NSLog(@"data: %@", data);
            NSLog(@"response: %@", response);

            NSError *processError = error;
            
            if (processError == nil && data != nil) {
                id response = [NSJSONSerialization JSONObjectWithData:data
                                                                  options:0
                                                                    error:&processError];

                if (processError == nil && [response isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *json = response;
                    id dataElm = json[@"Data"];
                    
                    if ([dataElm isKindOfClass:[NSDictionary class]]) {
                        NSString *encryptedPassData = dataElm[@"CipherText"];
                        //NSLog(@"[INFO] In module - EncryptedPassData (CipherText): %@\n__________________________________To data: %@", encryptedPassData, [self hexStringToData:encryptedPassData]);
                        NSString *activationData = dataElm[@"TokenizationAuthenticationValue"];
                        //NSLog(@"[INFO] In module - ActivationData (TokenizationAuthenticationValue): %@\n____________________________________________________To data: %@", activationData, [self hexStringToData:activationData]);
                        NSString *ephemeralPublicKey = dataElm[@"EphemeralPublicKey"];
                        //NSLog(@"[INFO] In module - EphemeralPublicKey (EphemeralPublicKey): %@\n___________________________________________To data: %@", ephemeralPublicKey, [self hexStringToData:ephemeralPublicKey]);
                        
                        if (encryptedPassData != nil && activationData != nil && ephemeralPublicKey != nil) {
                            PKAddPaymentPassRequest *paymentPassRequest = [[PKAddPaymentPassRequest alloc] init];
                            
                            if (paymentPassRequest != nil) {
                                paymentPassRequest.activationData = [self hexStringToData:activationData];
                                paymentPassRequest.encryptedPassData = [self hexStringToData:encryptedPassData];
                                paymentPassRequest.ephemeralPublicKey = [self hexStringToData:ephemeralPublicKey];
                            }
                            NSLog(@"in module paymentPassRequest: %@", paymentPassRequest); 
                            handler(paymentPassRequest);
                            return;
                        }
                    }
                }
            }
            
            // This will only be reached if no return above. This means an error occured.
            handler(nil);
            if (processError != nil) {
                [self sendEventWithName:@"addingPassFailed" body:@{
                                        @"code" : @([processError code]),
                                        @"message" : [processError localizedDescription],
                                        }];
                
            } else {
                
                [self sendEventWithName:@"addingPassFailed" body:nil];
            }
        }];
    
    [dataTask resume];
    
}

-(void)addPaymentPassViewController:(PKAddPaymentPassViewController *)controller
         didFinishAddingPaymentPass:(PKPaymentPass *)pass
                              error:(NSError *)error
{

    NSLog(@"addPaymentPassViewController handler 1");
    NSLog(@"pass: %@", pass);
    NSLog(@"error: %@", error);

    if (pass != nil) {
        
        [self sendEventWithName:@"addingPassSucceeded" body:nil];
    } else {

        if (error != nil) {
          [self sendEventWithName:@"addingPassFailed" body:@{
                                       @"code" : @([error code]),
                                    @"message" : [error localizedDescription],
                                    }];
            
        } else {
            [self sendEventWithName:@"addingPassFailed" body:nil];
        }
    }
    
    
    [controller dismissViewControllerAnimated:YES
                                   completion:^() {
                                       //[controller release];
                                       [self sendEventWithName:@"addToWalletViewHidden" body:nil];
                                   }];
}

#pragma mark PKAddPaymentPassViewControllerDelegate Helper Method

-(NSData *)dataToHexData:(NSData *)data
{
    const UInt16 *mapping = (UInt16 *)NSData_BytesConversionString;
    register NSUInteger length = data.length;
    char *hexChars = malloc(sizeof(char) * length * 2);
    register UInt16 *destination = ((UInt16 *)hexChars) + length - 1;
    register const unsigned char *source = (const unsigned char *)data.bytes + length - 1;
    
    while (length-- != 0) {
        *destination-- = mapping[*source--];
    }
    
    NSData *hexData = [[NSData alloc] initWithBytesNoCopy:hexChars
                                                   length:(data.length * 2)
                                             freeWhenDone:YES];
#if (!__has_feature(objc_arc))
    return [hexData autorelease];
#else
    return hexData;
#endif
}

-(NSData *)hexStringToData:(NSString *)hexString
{
    const char *hexChars = hexString.UTF8String;
    register NSUInteger length = hexString.length;
    char *dataBytes = malloc(sizeof(char) * length / 2);
    register char *destination = dataBytes + (length / 2) - 1;
    register const char *source = hexChars + length - 1;
    
    length /= 2;
    while (length-- != 0) {
        *destination = *source > '9' ? (*source & 0x0F) + 9 : *source & 0x0F;
        source--;
        *destination-- |= *source > '9' ? (*source + 9) << 4 : *source << 4;
        source--;
    }
    
    NSData *data = [[NSData alloc] initWithBytesNoCopy:dataBytes
                                                length:(hexString.length / 2)
                                          freeWhenDone:YES];
#if (!__has_feature(objc_arc))
    return [data autorelease];
#else
    return data;
#endif
}

@end
