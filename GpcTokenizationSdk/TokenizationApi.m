//
//  TokenizationApi.m
//

#import "TokenizationApi.h"
#import "Token.h"

@interface TokenizationApi ()

@property (strong, nonatomic) NSString *tokenizationKey;

@end

@implementation TokenizationApi

- (instancetype)init {
    self = [super init];
    self.gatewayHost = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"gatewayHost"];
    self.tokenizationHost = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"tokenizationHost"];
    return self;
}

/**
  publicIntegrationKey as defined in the Gateway (or given by your integration engineer)
 */
- (instancetype)initWithPublicIntegrationKey:(NSString *)publicIntegrationKey {
    self = [self init];
    self.publicIntegrationKey = publicIntegrationKey;
    return self;
}


/**
 host format: @"https://sub.domain.com"
 */
- (instancetype)initWithGatewayHost:(NSString *)gatewayHost TokenizationHost:(NSString *)tokenizationHost AndPublicIntegrationKey:(NSString *)publicIntegrationKey {
    self = [super init];
    
    //prepend https if not defined
    if (![[gatewayHost substringToIndex:4] isEqualToString:@"http"])  {
        gatewayHost = [@"https://" stringByAppendingString:gatewayHost];
    }
    if (![[tokenizationHost substringToIndex:4] isEqualToString:@"http"])  {
        tokenizationHost = [@"https://" stringByAppendingString:tokenizationHost];
    }
    
    self.gatewayHost = gatewayHost;
    self.tokenizationHost = tokenizationHost;
    self.publicIntegrationKey = publicIntegrationKey;
    
    return self;
}

- (void)setPublicIntegrationKey:(NSString *)publicIntegrationKey {
    //reset tokenization key
    _publicIntegrationKey = publicIntegrationKey;
    _tokenizationKey = nil;
}

- (void)setGatewayHost:(NSString *)gatewayHost {
    //reset tokenization key
    _gatewayHost = gatewayHost;
    _tokenizationKey = nil;
}

- (void)setTokenizationHost:(NSString *)tokenizationHost {
    //reset tokenization key
    _tokenizationHost = tokenizationHost;
    _tokenizationKey = nil;
}

- (void)tokenizeCardData:(CardData *)cardData onComplete:(void (^)(Token *token))completeHandler onError:(void(^)(NSError* error))errorHandler {
    if (self.tokenizationKey != nil) {
        [self callTokenizationEndpoint:cardData tokenizationKey:self.tokenizationKey onComplete:completeHandler onError:errorHandler];
    } else {
        //Get tokenization key
        [self getTokenizationKey:^(NSString *tokenizationKey) {
            [self callTokenizationEndpoint:cardData tokenizationKey:tokenizationKey onComplete:completeHandler onError:errorHandler];
        } onError:errorHandler];
    }
}

- (void)callTokenizationEndpoint:(CardData *)cardData tokenizationKey:(NSString *)tokenizationKey onComplete:(void (^)(Token *token))completeHandler onError:(void(^)(NSError*))errorHandler {
 
    //Build URL
    NSString *tokenizeUrl = [NSString stringWithFormat:@"%@/v1/%@/tokenize/creditcard", self.tokenizationHost, tokenizationKey];
    
    //Build Request Data
    NSMutableString *reqData = [[NSMutableString alloc] initWithFormat:@"cardHolder=%@&month=%@&year=%@", cardData.cardHolder, cardData.expirationMonth.stringValue, cardData.expirationYear.stringValue];

    if (cardData.cvv && ![cardData.cvv isEqualToString:@""]) {
        [reqData appendFormat:@"&pan=%@&cvv=%@", cardData.pan, cardData.cvv];
    } else {
        [reqData appendFormat:@"&panonly=%@", cardData.pan];
    }

    [self logMsg:[NSString stringWithFormat:@"Sending Request to %@", tokenizeUrl]];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[[NSURL alloc] initWithString:tokenizeUrl]];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:[reqData dataUsingEncoding:NSUTF8StringEncoding]];
    
    //Send Request
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error) {
            [self logMsg:@"Request #2 failed"];
            dispatch_async(dispatch_get_main_queue(), ^{
                errorHandler(error);
            });
            return;
        }
        
        [self logMsg:[NSString stringWithFormat:@"Tokenization response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]]];
        
        //Error handling first
        NSError *e = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
        
        if (!result) {
            [self logMsg:@"Tokenization returned unexpected response"];
            NSError *error = [NSError errorWithDomain:@"cloud.paymentgateway.PgcTokenizationSdk" code:GpcRequestFailed userInfo:[NSDictionary dictionaryWithObject:@"Unexpected response" forKey:@"request"]];
            dispatch_async(dispatch_get_main_queue(), ^{
                errorHandler(error);
            });
            return;
        }
        
        if (![[result objectForKey:@"success"] isKindOfClass:[NSNumber class]]) {
            [self logMsg:@"Tokenization returned unexpected response"];
            NSError *error = [NSError errorWithDomain:@"cloud.paymentgateway.PgcTokenizationSdk" code:GpcRequestFailed userInfo:[NSDictionary dictionaryWithObject:@"Unexpected response" forKey:@"request"]];
            dispatch_async(dispatch_get_main_queue(), ^{
                errorHandler(error);
            });
            return;
        }
        NSNumber *status = [result objectForKey:@"success"];
        if ([status boolValue] == false) {
            [self logMsg:@"Tokenization returned errors"];
            NSDictionary *jsonErrors = [result objectForKey:@"errors"];
            
            NSMutableDictionary *userData = [NSMutableDictionary dictionary];
            [jsonErrors enumerateKeysAndObjectsWithOptions:0 usingBlock:^(NSString*  _Nonnull field, NSArray*  _Nonnull fieldErrors, BOOL * _Nonnull stop) {
                [fieldErrors enumerateObjectsUsingBlock:^(NSString*  _Nonnull fieldError, NSUInteger idx, BOOL * _Nonnull stop) {
                    //currently there is always only 1 error code per field
                    [userData setObject:fieldError forKey:field];
                }];
            }];
            NSError *error = [NSError errorWithDomain:@"cloud.paymentgateway.PgcTokenizationSdk" code:GpcValueValidationFailed userInfo:userData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                errorHandler(error);
            });
            return;
        }
        
        //All good, build token object
        Token *token = [[Token alloc] init];
        
        token.token = [result objectForKey:@"token"];
        token.fingerprint = [result objectForKey:@"fingerprint"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completeHandler(token);
        });
        
        return;
    }] resume];
    
}

- (void)getTokenizationKey:(void (^)(NSString *tokenizationKey))completeHandler onError:(void(^)(NSError *))errorHandler {

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/integrated/getTokenizationKey/%@", self.gatewayHost, self.publicIntegrationKey]];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    
    [self logMsg:[NSString stringWithFormat:@"Sending Request to %@", url.absoluteString]];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    
        if (error) {
            [self logMsg:@"Request #1 failed"];
            dispatch_async(dispatch_get_main_queue(), ^{
                errorHandler(error);
            });
            return;
        }
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            
            //Check for error HTTP status codes
            if (statusCode == 401) {
                NSError *error = [NSError errorWithDomain:@"cloud.paymentgateway.PgcTokenizationSdk" code:GpcInvalidPublicIntegrationKey userInfo:[NSDictionary dictionaryWithObject:@"Invalid public integration key" forKey:@"request"]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorHandler(error);
                });
                return;
            } else if (statusCode != 200) {
                NSError *error = [NSError errorWithDomain:@"cloud.paymentgateway.PgcTokenizationSdk" code:GpcRequestFailed userInfo:[NSDictionary dictionaryWithObject:@"Request failed" forKey:@"request"]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorHandler(error);
                });
                return;
            }
        }
        
        NSError *e = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
        
        //Check for valid json
        if (!json) {
            [self logMsg:@"Response has unexpected content"];
            NSError *error = [NSError errorWithDomain:@"cloud.paymentgateway.PgcTokenizationSdk" code:GpcRequestFailed userInfo:[NSDictionary dictionaryWithObject:@"Unexpected response" forKey:@"request"]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                errorHandler(error);
            });
            return;
        }
        
        //Check success indicator
        if (![[json objectForKey:@"success"] isKindOfClass:[NSNumber class]]) {
            [self logMsg:@"Response has unexpected content"];
            NSError *error = [NSError errorWithDomain:@"cloud.paymentgateway.PgcTokenizationSdk" code:GpcRequestFailed userInfo:[NSDictionary dictionaryWithObject:@"Unexpected response" forKey:@"request"]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                errorHandler(error);
            });
            return;
        }
        
        NSNumber *status = [json objectForKey:@"success"];
        if ([status boolValue] == false) {
            [self logMsg:@"Response status = false"];
            NSNumber *errorCode = [json objectForKey:@"error_code"];
            NSError *error = [NSError errorWithDomain:@"cloud.paymentgateway.PgcTokenizationSdk" code:errorCode.integerValue userInfo:[NSDictionary dictionaryWithObject:[json objectForKey:@"error_message"] forKey:([json objectForKey:@"field"] != nil ? [json objectForKey:@"field"] : @"request")]];

            dispatch_async(dispatch_get_main_queue(), ^{
                errorHandler(error);
            });
            return;
        }
        
        [self logMsg:@"Response OK"];
        
        //finally extract tokenization key
        NSString *tokenizationKey = [json objectForKey:@"tokenizationKey"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completeHandler(tokenizationKey);
        });
        
        return;
    }] resume];
}

- (void)logMsg:(NSString*)msg {
    if (self.loggerFunc != nil) {
        self.loggerFunc(msg);
    }
}


@end
