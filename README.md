# gpc-tokenization-ios

This SDK enables you to tokenize card data natively from your iOS application to our PCI-certified servers.

## Preparation of Repository

Replace identifiers `gatewayHost` and `tokenizationHost` in `Info.plist` file with your dedicated host names


## Usage

Build a `CardData` object with card number ("pan"), CVV/CVC code ("cvv"), card holder, exipiration month and year.
Instantiate the `TokenizationApi` class with your public integration key (and optionally hostname, if different than production environment) and call
`tokenizeCardData` on that.

```objective-c

#import <GpcTokenizationSdk.h>

...


// Preprate cardData
CardData *cardData = [[CardData alloc] init];
cardData.pan = @"CARD NUMBER";
cardData.cvv = @"CVV";
cardData.cardHolder = @"CARD HOLDER";
cardData.expirationMonth = [NSNumber numberWithInt:4];
cardData.expirationYear = [NSNumber numberWithInt:2025];

// Initialize API object
TokenizationApi *api = [[TokenizationApi alloc] initWithPublicIntegrationKey:@"PUBLIC_INTEGRATION_KEY"];

// Tokenize cardData
[api tokenizeCardData:cardData onComplete:^(Token *token) {
	// Tokenization successful
    NSLog(@"Success, token is: %@ ; fingerprint: %@", 
		token.token, 
		token.fingerprint);
    
} onError:^(NSError *error) {
	// Errors occurred
    NSLog(@"Error occurred: Code %d", error.code);

    [error.userInfo enumerateKeysAndObjectsUsingBlock:^(NSErrorUserInfoKey  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSLog(@"Field %@, Message: %@", key, obj);
    }];

}];


```


## Development

### Requirements
- iOS 9.0 or higher
- Xcode 8.0 or higher (to build source)

### Dependencies
- none

## License

[LICENSE](LICENSE)

## Changelog

[CHANGELOG.md](CHANGELOG.md)
