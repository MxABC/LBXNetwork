//
//  LBXNetwork.h
//  LBXNetwork
//  https://github.com/MxABC/LBXNetwork
//  Created by lbx, on 2018/2/25.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LBXHttpRequest.h"


NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, LBXNetworkStatus) {
    LBXNetworkStatusUnknown          = -1,
    LBXNetworkStatusNotReachable     = 0,
    LBXNetworkStatusReachableViaWWAN = 1,
    LBXNetworkStatusReachableViaWiFi = 2,
};

/**
 - 封装AFN3.x
 - 支持get,post,delete，put请求
 - 支持批量请求,统一返回
 - 支持缓存(通过YYCache实现)
 */
@interface LBXNetwork : NSObject


#pragma mark-
#pragma mark- 开始监听网络
+ (void)networkStatusWithBlock:(void(^)(LBXNetworkStatus status))completion;


#pragma mark-
#pragma mark- http请求
/**
 http接口请求

 @param requestBlock 请求参数填充,内部创建LBXNetworkRequest对象
 @param completion 调用结束回调
 @return 返回请求相关参数，可用于取消接口任务
 */
+ (LBXHttpRequest*)HttpWithRequestBlock:(void(^)(LBXHttpRequest *request))requestBlock
                            complection:(void(^)(LBXHttpResponse *response))completion;





#pragma mark-
#pragma mark- http批量接口请求
/**
 批量http接口请求，都调用结束统一返回给调用者

 @param batchNum 接口数量
 @param requestsBlock 请求参数回调，填充
 @param completion 请求结束回调，对应的结果数组顺序与请求数组顺序一致
 @return 返回请求参数对象，可用于取消接口任务
 */
+ (NSArray<LBXHttpRequest*>*)HttpWithBatchNum:(NSUInteger)batchNum
                            batchRequestBlock:(void(^)(NSArray<LBXHttpRequest*> *request) )requestsBlock
                                  complection:(void(^)(NSArray<LBXHttpResponse*> *responses))completion;



#pragma mark- 取消任务

///取消指定任务
+ (void)cancelWithRequest:(LBXHttpRequest*)request;

///取消指定接口地址的任务
+ (void)cancelWithURL:(NSString*)requestUrl;

///取消所有任务
+ (void)cancelAllRequests;

@end

NS_ASSUME_NONNULL_END
