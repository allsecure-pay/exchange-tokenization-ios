//
//  GpcTokenizationSdkTests.m
//  GpcTokenizationSdkTests
//

#import <XCTest/XCTest.h>
#import "../GpcTokenizationSdk/Token.h"
#import "../GpcTokenizationSdk/CardData.h"
#import "../GpcTokenizationSdk/TokenizationApi.h"

@interface GpcTokenizationSdkTests : XCTestCase

@end

@implementation GpcTokenizationSdkTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTokenObject {
    Token *token = [[Token alloc] init];
    token.token = @"12341234";
    token.fingerprint = @"Fingerprint1";
    
    XCTAssertEqual(token.token, @"12341234");
    XCTAssertEqual(token.fingerprint, @"Fingerprint1");
    
}

- (void)testCardDataObject {
    CardData *cardData = [[CardData alloc] init];
    cardData.cardHolder = @"Yes No";
    cardData.pan = @"4111111111111111";
    cardData.cvv = @"123";
    cardData.expirationYear = [NSNumber numberWithInt:2063];
    cardData.expirationMonth = [NSNumber numberWithInt:5];
    
    XCTAssertEqual(cardData.cardHolder, @"Yes No");
    XCTAssertEqual(cardData.pan, @"4111111111111111");
    XCTAssertEqual(cardData.cvv, @"123");
    XCTAssertEqual(cardData.expirationYear, [NSNumber numberWithInt:2063]);
    XCTAssertEqual(cardData.expirationMonth, [NSNumber numberWithInt:5]);
    
}

/*- (void)testTokenization {

    CardData *cardData = [[CardData alloc] init];
    cardData.cardHolder = @"Yes No";
    cardData.pan = @"4111111111111111";
    cardData.cvv = @"123";
    cardData.expirationYear = [NSNumber numberWithInt:2063];
    cardData.expirationMonth = [NSNumber numberWithInt:5];
    
    NSString *publicIntegrationKey = @"INPUT_HERE";
    
    TokenizationApi *tokenizationApi = [[TokenizationApi alloc] initWithGatewayHost:@"https://gateway.HOSTNAME.com" TokenizationHost:@"https://secure.HOSTNAME.com" AndPublicIntegrationKey:publicIntegrationKey];

    [tokenizationApi tokenizeCardData:cardData onComplete:^(Token *token) {
        NSLog(@"Success, token is: %@ ; fingerprint: %@", token.token, token.fingerprint);
    } onError:^(NSError *error) {
        NSLog(@"Error occurred: Code %d", error.code);
        [error.userInfo enumerateKeysAndObjectsUsingBlock:^(NSErrorUserInfoKey  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSLog(@"Key %@, Message: ", key, obj);
        }];
    }];
}*/

@end
