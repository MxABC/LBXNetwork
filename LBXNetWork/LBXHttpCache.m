//
//  LBXNetworkCache.m
//  LBXNetwork
//
//  Created by lbx on 2018/2/9.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import "LBXHttpCache.h"
#import <YYCache.h>
#import <CommonCrypto/CommonDigest.h>

#define LBXNetworkCacheName @"LBXNetworkCacheName"

static YYCache *gCache = nil;

@implementation LBXHttpCache

#pragma mark- YYCache读取缓存

+ (void)storeCacheWithResponse:(LBXHttpResponse*)response
{
    if (response && response.request  && response.responseObject) {
        
        NSString *key = [self cacheKeyWithRequest:response.request];
        [self storeCacheWithKey:key response:response.responseObject];
    }
}

+ (id)cachedWithRequest:(LBXHttpRequest*)request
{
    NSString *key = [self cacheKeyWithRequest:request];
    
    return [self readCacheWithKey:key];
}


/**
 Returns the total cost (in bytes)
 */
+ (NSInteger)allCacheSize
{
    YYCache *cache = [self cache];

    return [cache.diskCache totalCost];
}

+ (void)clearAllCache
{
    YYCache *cache = [self cache];

    [cache removeAllObjects];
}

+ (void)clearWithRequest:(LBXHttpRequest*)request
{
    NSString *key = [self cacheKeyWithRequest:request];
    if (key) {
        YYCache *cache = [self cache];
        [cache removeObjectForKey:key];
    }
}
/**
 存储缓存
 
 @param key 存储缓存key
 @param response 返回值，NSDictionary或NSData
 */
+ (void)storeCacheWithKey:(NSString*)key response:(id)response
{
    if (key && response) {
        
        YYCache *cache = [self cache];
        [cache setObject:response forKey:key];
    }
}

+ (id)readCacheWithKey:(NSString*)key
{
    if (key) {
        
        YYCache *cache = [self cache];
        return [cache objectForKey:key];
    }
    return nil;
}

+ (YYCache*)cache
{
    if (!gCache) {
        gCache = [YYCache cacheWithName:LBXNetworkCacheName];
    }
    return gCache;
}

#pragma mark- 计算YYCache存储key

//计算接口存储key
+ (NSString *)cacheKeyWithRequest:(LBXHttpRequest*)request
{
    if (!request || !request.requestUrl) {
        return nil;
    }

    ///地址与请求类型组合，计算md5
    NSString *stringURL = [NSString stringWithFormat:@"%@%ld%ld",request.requestUrl,request.httpMethod,request.requestSerializerType];
    NSString *urlMD5 = [self md5WithData:[stringURL dataUsingEncoding:NSUTF8StringEncoding]];
    
    ///请求参数计算md5
    NSString *stringMD5 = @"";
    NSData *paraData = nil;
    if ( request.requestParameters )
    {
        if ([request.requestParameters isKindOfClass:[NSDictionary class]]) {
            paraData = [NSJSONSerialization dataWithJSONObject:request.requestParameters options:0 error:nil];
            if (!paraData) {
                NSLog(@"\r\n\r\n\r\n LBXNetworkCache -NSDictionary convert NSData fail \r\n\r\n\r\n");
            }
        }
        else if ([request.requestParameters isKindOfClass:[NSData class]])
        {
            paraData = request.requestParameters;
        }
        if (paraData) {
            stringMD5 = [self md5WithData:paraData];
        }
    }
    
    //md组合
    NSString *md5lastString = [NSString stringWithFormat:@"%@%@",urlMD5,stringMD5];
    
    return md5lastString;
}

#pragma mark-
#pragma mark- MD5
+ (NSString*)md5WithData:(NSData*)data
{
    if (!data) {
        return @"";
    }
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( data.bytes, (CC_LONG)data.length, result ); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end
