/*
 * Version for React Native
 * © 2020 YANDEX
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * https://yandex.com/legal/appmetrica_sdk_agreement/
 */

#import "AppMetrica.h"
#import "AppMetricaUtils.h"


static NSString *const kYMMReactNativeExceptionName = @"ReactNativeException";

static YMMECommerceScreen* getECommerceScreen (NSDictionary *options) {
    NSString *screenName = options[@"screenName"];
    if(screenName==NULL) screenName=@"CreateOrderScreen";
    YMMECommerceScreen *screen = [[YMMECommerceScreen alloc] initWithName:screenName];
    return screen;
}

static YMMECommercePrice* getECommercePrice (NSDictionary* options){
    
    NSNumber *price = options[@"price"];
    
    NSString *type = options[@"typeOfCurrency"];
    
    NSDecimalNumber *priceDecimal = [NSDecimalNumber decimalNumberWithDecimal:[price decimalValue]];
    
    YMMECommerceAmount *amount =  [[YMMECommerceAmount alloc] initWithUnit:type value:priceDecimal];
    
    YMMECommercePrice *actualPrice = [[YMMECommercePrice alloc] initWithFiat:amount];
    
    return actualPrice;
    
}

static YMMECommerceProduct* getECommerceProduct(YMMECommercePrice* price, NSDictionary* options){
    NSString *productId = options[@"article"];
    NSString *name = options[@"name"];
    NSString *categoryName = options[@"categoryName"];
    
    YMMECommerceProduct *product = [[YMMECommerceProduct alloc] initWithSKU:productId
                                                                       name:name
                                                         categoryComponents:@[categoryName]
                                                                    payload:@{}
                                                                actualPrice:price
                                                              originalPrice:price
                                                                 promoCodes:@[]];
    
    return product;
}

static YMMECommerceCartItem* getECommerceCartItem(YMMECommerceReferrer* refferer, NSDictionary* options){
    
    NSDictionary *priceInfo = options[@"price"];
    YMMECommercePrice *price = getECommercePrice(priceInfo);
    
    
    
    NSDictionary *productInfo = options[@"product"];
    YMMECommerceProduct *product = getECommerceProduct(price,productInfo);
    
    
    
    NSNumber *quan = options[@"quantity"];
    NSDecimalNumber *quantity = [NSDecimalNumber decimalNumberWithDecimal:[quan decimalValue]];
    
    YMMECommerceCartItem *addedItems = [[YMMECommerceCartItem alloc] initWithProduct:product
                                                                            quantity:quantity
                                                                             revenue:price
                                                                            referrer:refferer];
    
    [YMMYandexMetrica reportECommerce:[YMMECommerce addCartItemEventWithItem:addedItems] onFailure:nil];
    
    return addedItems;
}

static NSMutableArray<YMMECommerceCartItem*>* getCartItemsList(YMMECommerceReferrer* refferer,NSArray* array){
    
    NSMutableArray<YMMECommerceCartItem*> *list = [NSMutableArray new];
    
    for (NSDictionary *item in array) {
        YMMECommerceCartItem *it = getECommerceCartItem(refferer,item);
        [list addObject:it];
    }
    
    return list;
}





static void reportCheckout(NSDictionary *options){
    
    NSDictionary *screenNameObj = options[@"screen"];
    
    
    if (screenNameObj == NULL) return;
    
    
    YMMECommerceScreen *screen = getECommerceScreen(screenNameObj);
    
    YMMECommerceReferrer *referrer = [[YMMECommerceReferrer alloc] initWithType:@"button"
                                                                     identifier:@"createOrder"
                                                                         screen:screen];

    NSArray *productsArray = options[@"productsInfo"];
    if (productsArray == NULL) return;
    
    
    NSMutableArray<YMMECommerceCartItem *> *cartItems = getCartItemsList(referrer,productsArray);
    
    NSString *orderId = options[@"orderId"];
    if(orderId == nil) orderId = @"123456";
    
    YMMECommerceOrder *order = [[YMMECommerceOrder alloc] initWithIdentifier:orderId
                                                                   cartItems:cartItems];
    
    [YMMYandexMetrica reportECommerce:[YMMECommerce beginCheckoutEventWithOrder:order] onFailure:nil];
    
    [YMMYandexMetrica reportECommerce:[YMMECommerce purchaseEventWithOrder:order] onFailure:nil];

}







@implementation AppMetrica

@synthesize methodQueue = _methodQueue;

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(activate:(NSDictionary *)configDict)
{
    [YMMYandexMetrica activateWithConfiguration:[AppMetricaUtils configurationForDictionary:configDict]];
}

RCT_EXPORT_METHOD(reportECommerce:(NSString *)eventName:(NSDictionary *)attributes)
{
    NSString * const checkout = @"checkout";
    if([eventName isEqualToString:checkout]){
        reportCheckout(attributes);
    }
}

RCT_EXPORT_METHOD(getLibraryApiLevel)
{
    // It does nothing for iOS
}

RCT_EXPORT_METHOD(getLibraryVersion:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    resolve([YMMYandexMetrica libraryVersion]);
}

RCT_EXPORT_METHOD(pauseSession)
{
    [YMMYandexMetrica pauseSession];
}

RCT_EXPORT_METHOD(reportAppOpen:(NSString *)deeplink)
{
    [YMMYandexMetrica handleOpenURL:[NSURL URLWithString:deeplink]];
}

RCT_EXPORT_METHOD(reportError:(NSString *)message) {
    NSException *exception = [[NSException alloc] initWithName:message reason:nil userInfo:nil];
    [YMMYandexMetrica reportError:message exception:exception onFailure:NULL];
}

RCT_EXPORT_METHOD(reportEvent:(NSString *)eventName:(NSDictionary *)attributes)
{
    if (attributes == nil) {
        [YMMYandexMetrica reportEvent:eventName onFailure:^(NSError *error) {
            NSLog(@"error: %@", [error localizedDescription]);
        }];
    } else {
        [YMMYandexMetrica reportEvent:eventName parameters:attributes onFailure:^(NSError *error) {
            NSLog(@"error: %@", [error localizedDescription]);
        }];
    }
}





RCT_EXPORT_METHOD(reportReferralUrl:(NSString *)referralUrl)
{
    [YMMYandexMetrica reportReferralUrl:[NSURL URLWithString:referralUrl]];
}

RCT_EXPORT_METHOD(requestAppMetricaDeviceID:(RCTResponseSenderBlock)listener)
{
    YMMAppMetricaDeviceIDRetrievingBlock completionBlock = ^(NSString *_Nullable appMetricaDeviceID, NSError *_Nullable error) {
        listener(@[[self wrap:appMetricaDeviceID], [self wrap:[AppMetricaUtils stringFromRequestDeviceIDError:error]]]);
    };
    [YMMYandexMetrica requestAppMetricaDeviceIDWithCompletionQueue:nil completionBlock:completionBlock];
}

RCT_EXPORT_METHOD(resumeSession)
{
    [YMMYandexMetrica resumeSession];
}

RCT_EXPORT_METHOD(sendEventsBuffer)
{
    [YMMYandexMetrica sendEventsBuffer];
}

RCT_EXPORT_METHOD(setLocation:(NSDictionary *)locationDict)
{
    [YMMYandexMetrica setLocation:[AppMetricaUtils locationForDictionary:locationDict]];
}

RCT_EXPORT_METHOD(setLocationTracking:(BOOL)enabled)
{
    [YMMYandexMetrica setLocationTracking:enabled];
}

RCT_EXPORT_METHOD(setStatisticsSending:(BOOL)enabled)
{
    [YMMYandexMetrica setStatisticsSending:enabled];
}

RCT_EXPORT_METHOD(setUserProfileID:(NSString *)userProfileID)
{
    [YMMYandexMetrica setUserProfileID:userProfileID];
}

- (NSObject *)wrap:(NSObject *)value
{
    if (value == nil) {
        return [NSNull null];
    }
    return value;
}

@end