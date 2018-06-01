//
//  LBXNetworkCache.h
//  LBXNetwork
//  https://github.com/MxABC/LBXNetwork
//  Created by lbx on 2018/2/9.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LBXHttpRequest.h"


/**
 - 根据接口地址,接口请求类型、请求参数计算MD5作为缓存key
 */
@interface LBXHttpCache : NSObject

/**
 存储缓存

 @param response 返回数据
 */
+ (void)storeCacheWithResponse:(LBXHttpResponse*)response;

/**
 读取缓存,返回nil表示没有缓存信息

 @param request 请求信息
 @return 返回缓存信息
 */
+ (id)cachedWithRequest:(LBXHttpRequest*)request;

/**
 清除缓存

 @param request 请求信息
 */
+ (void)clearWithRequest:(LBXHttpRequest*)request;

/**
 获取缓存大小
 Returns the total cost (in bytes)
 */
+ (NSInteger)allCacheSize;
/**
 清除所有接口缓存
 */
+ (void)clearAllCache;


@end
