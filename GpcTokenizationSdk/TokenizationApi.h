//
//  TokenizationApi.h
//

#import <Foundation/Foundation.h>
#import "CardData.h"
#import "Token.h"

typedef void (^GpcLoggerFunc) (NSString* logMsg);
typedef enum {
    GpcInvalidPublicIntegrationKey = -401,
    GpcRequestFailed = -500,
    GpcValueValidationFailed = 1002,
    GpcTokenizationNotSupported = 3002
} GpcErrorCode;

@interface TokenizationApi : NSObject

@property (strong, nonatomic) NSString* gatewayHost;
@property (strong, nonatomic) NSString* tokenizationHost;
@property (strong, nonatomic) NSString* publicIntegrationKey;
@property (strong, nonatomic) GpcLoggerFunc loggerFunc;

- (instancetype)initWithPublicIntegrationKey:(NSString *)publicIntegrationKey;
- (instancetype)initWithGatewayHost:(NSString *)gatewayHost TokenizationHost:(NSString *)tokenizationHost AndPublicIntegrationKey:(NSString *)publicIntegrationKey;

- (void)tokenizeCardData:(CardData *)cardData onComplete:(void (^)(Token *token))completeHandler onError:(void(^)(NSError *))errorHandler;

@end
