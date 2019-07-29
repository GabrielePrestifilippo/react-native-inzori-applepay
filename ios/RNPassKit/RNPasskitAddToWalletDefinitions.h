

#ifndef RNPasskitAddToWalletDefinitions_h
#define RNPasskitAddToWalletDefinitions_h

typedef enum {
    kPKEncryptionSchemeECC_V2 = 0,
} EncryptionScheme;

typedef enum {
    kPKPaymentNetworkAmex = 0,
    kPKPaymentNetworkDiscover,
    kPKPaymentNetworkMasterCard,
    kPKPaymentNetworkPrivateLabel,
    kPKPaymentNetworkVisa,
} PaymentNetwork;

#endif 
