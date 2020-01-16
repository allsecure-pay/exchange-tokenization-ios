//
//  TokenizationApi.h
//

#import <Foundation/Foundation.h>
#import "CardData.h"
#import "Token.h"

typedef void (^AsxLoggerFunc) (NSString* logMsg);
typedef enum {
    AsxInvalidPublicIntegrationKey = -401,
    AsxRequestFailed = -500,
    AsxValueValidationFailed = 1002,
    AsxTokenizationNotSupported = 3002
} AsxErrorCode;

@interface TokenizationApi : NSObject

@property (strong, nonatomic) NSString* gatewayHost;
@property (strong, nonatomic) NSString* tokenizationHost;
@property (strong, nonatomic) NSString* publicIntegrationKey;
@property (strong, nonatomic) AsxLoggerFunc loggerFunc;

- (instancetype)initWithPublicIntegrationKey:(NSString *)publicIntegrationKey;
- (instancetype)initWithGatewayHost:(NSString *)gatewayHost TokenizationHost:(NSString *)tokenizationHost AndPublicIntegrationKey:(NSString *)publicIntegrationKey;

- (void)tokenizeCardData:(CardData *)cardData onComplete:(void (^)(Token *token))completeHandler onError:(void(^)(NSError *))errorHandler;

@end
