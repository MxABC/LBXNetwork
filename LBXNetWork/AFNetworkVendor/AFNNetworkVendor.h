//
//  LBXNetwork.h
//  LBXNetwork
//  https://github.com/MxABC/LBXNetwork
//  Created by lbx on 2018/2/25.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LBXHttpRequest.h"
#import "AFNetworking/AFNetworking.h"

@interface AFNNetworkVendor : NSObject


#pragma mark-
#pragma mark- AFN HTTP请求入口
+ (nullable NSURLSessionDataTask*)AFNRequest:(LBXHttpRequest* _Nonnull)request
                                     success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
                                        fail:(nullable void (^)(NSURLSessionDataTask * _Nullable task,NSError * _Nonnull error))fail;

#pragma mark - 开始监听网络
+ (void)networkStatusWithBlock:(void(^)(NSInteger status))completion;

@end
