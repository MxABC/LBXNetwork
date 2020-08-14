//
//  LBXNetwork.m
//  LBXNetwork
//
//  Created by lbx on 2018/2/25.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import "AFNNetworkVendor.h"

@implementation AFNNetworkVendor


#pragma mark-
#pragma mark- AFN HTTP请求入口
+ (nullable NSURLSessionDataTask*)AFNRequest:(LBXHttpRequest* _Nonnull)request
                                     success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
                                        fail:(nullable void (^)(NSURLSessionDataTask * _Nullable task,NSError * _Nonnull error))fail
{
    if (!request.securityPolicy) {
        
        request.securityPolicy = [AFSecurityPolicy defaultPolicy];
    }
    
    switch (request.httpMethod) {
        case LBXHTTPMethodTypeGET:
        {
            return  [self getWithRequest:request success:success fail:fail];
        }
            break;
        case LBXHTTPMethodTypePOST:
        {
            return [self postWithRequest:request success:success fail:fail];
        }
            break;
        case LBXHTTPMethodTypeDELETE:
        {
            return [self deleteWithRequest:request success:success fail:fail];
        }
            break;
        case LBXHTTPMethodTypePUT:
        {
            return [self putWithRequest:request success:success fail:fail];
        }
            
        default:
            break;
    }
}


#pragma mark-
#pragma mark- GET方法
+ (nullable NSURLSessionDataTask*)getWithRequest:(LBXHttpRequest* _Nonnull)request
                                         success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
                                            fail:(nullable void (^)(NSURLSessionDataTask * _Nullable task,NSError * _Nonnull error))fail
{
    AFHTTPSessionManager *manager = nil;
    
    if (request.sessionConfiguration) {
        manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:request.sessionConfiguration];
    }else
    {
        manager = [AFHTTPSessionManager manager];
    }
    //设置安全策略
    manager.securityPolicy = request.securityPolicy;
    
    ///请求相关配置
#ifdef DEBUG
    manager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
#else
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
#endif
    //超时时间设置
    manager.requestSerializer.timeoutInterval = request.timeoutInterval;
    //设置http请求信息头
    [self requestHttpHeader:request.headers requestSerializer:manager.requestSerializer];
    
    
    //响应相关配置
    if (request.responseSerializerType == LBXHTTPSerializerTypeRAW) {
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    manager.responseSerializer.acceptableContentTypes = request.responseAcceptableContentTypes;
    
    NSURLSessionDataTask *task  = [manager GET:request.requestUrl parameters:request.requestParameters headers:request.headers progress:nil success:success failure:fail];
    
    //开始请求
//    NSURLSessionDataTask *task = [manager GET:request.requestUrl
//                                   parameters:request.requestParameters
//                                     progress:nil success:success failure:fail];
    
    return task;
}

#pragma mark-
#pragma mark- POST方法
+ (nullable NSURLSessionDataTask*)postWithRequest:(LBXHttpRequest* _Nonnull)request
                                          success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
                                             fail:(nullable void (^)(NSURLSessionDataTask * _Nullable task,NSError * _Nonnull error))fail
{
    
    //http请求manger
    AFHTTPSessionManager *manager = nil;
    if (request.sessionConfiguration) {
        manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:request.sessionConfiguration];
    }else{
       manager = [AFHTTPSessionManager manager];
    }
   
    //设置安全策略
    manager.securityPolicy = request.securityPolicy;
    
    //请求相关配置
    if (request.requestSerializerType == LBXHTTPSerializerTypeJSON) {
#ifdef DEBUG
        manager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
#else
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
#endif
    }
    else if (request.requestSerializerType == LBXHTTPSerializerTypeRAW)
    {
        //上传NSData数据
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        [manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    }
    manager.requestSerializer.timeoutInterval = request.timeoutInterval;
    //设置http请求信息头
    [self requestHttpHeader:request.headers requestSerializer:manager.requestSerializer];


    //响应配置
    if (request.responseSerializerType == LBXHTTPSerializerTypeRAW) {
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    manager.responseSerializer.acceptableContentTypes = request.responseAcceptableContentTypes;
   
    
    //请求路径url
    NSString *requestUrl = request.requestUrl;
    NSDictionary *requestParas = request.requestParameters;
    //请求
//    NSURLSessionDataTask *task = [manager POST:requestUrl
//                                    parameters:requestParas
//                                      progress:nil success:success failure:fail];
    
    
    NSURLSessionDataTask *task = [manager POST:requestUrl parameters:requestParas headers:request.headers progress:nil success:success failure:fail];
    
    return task;
}




#pragma mark-
#pragma mark- Delete方法
+ (nullable NSURLSessionDataTask*)deleteWithRequest:(LBXHttpRequest* _Nonnull)request
                                         success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
                                            fail:(nullable void (^)(NSURLSessionDataTask * _Nullable task,NSError * _Nonnull error))fail
{
    
    AFHTTPSessionManager *manager = nil;
    
    if (request.sessionConfiguration) {
        manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:request.sessionConfiguration];
    }else
    {
        manager = [AFHTTPSessionManager manager];
    }

    //设置安全策略
    manager.securityPolicy = request.securityPolicy;
    
    //请求相关配置
    if (request.requestSerializerType == LBXHTTPSerializerTypeJSON) {
#ifdef DEBUG
        manager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
#else
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
#endif
    }
    else if (request.requestSerializerType == LBXHTTPSerializerTypeRAW)
    {
        //上传NSData数据
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        [manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    }
    manager.requestSerializer.timeoutInterval = request.timeoutInterval;
    manager.requestSerializer.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"GET", @"HEAD", nil ];
    //设置http请求信息头
    [self requestHttpHeader:request.headers requestSerializer:manager.requestSerializer];
    
    //响应相关配置
    if (request.responseSerializerType == LBXHTTPSerializerTypeRAW) {
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    manager.responseSerializer.acceptableContentTypes = request.responseAcceptableContentTypes;
    
    //开始请求
//    NSURLSessionDataTask *task = [manager DELETE:request.requestUrl parameters:request.requestParameters success:success failure:fail];
    
    
    NSURLSessionDataTask *task = [manager DELETE:request.requestUrl parameters:request.requestParameters headers:request.headers success:success failure:fail];
    
    return task;
}

#pragma mark-
#pragma mark- PUT方法
+ (nullable NSURLSessionDataTask*)putWithRequest:(LBXHttpRequest* _Nonnull)request
                                            success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
                                               fail:(nullable void (^)(NSURLSessionDataTask * _Nullable task,NSError * _Nonnull error))fail
{
    AFHTTPSessionManager *manager = nil;
    
    if (request.sessionConfiguration) {
        manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:request.sessionConfiguration];
    }else
    {
        manager = [AFHTTPSessionManager manager];
    }

    //设置安全策略
    manager.securityPolicy = request.securityPolicy;
    
    //请求相关配置
    if (request.requestSerializerType == LBXHTTPSerializerTypeJSON) {
#ifdef DEBUG
        manager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
#else
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
#endif
    }
    else if (request.requestSerializerType == LBXHTTPSerializerTypeRAW)
    {
        //上传NSData数据
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        [manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    }
    manager.requestSerializer.timeoutInterval = request.timeoutInterval;
     //设置http请求信息头
    [self requestHttpHeader:request.headers requestSerializer:manager.requestSerializer];

    //响应配置
    if (request.responseSerializerType == LBXHTTPSerializerTypeRAW) {
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    manager.responseSerializer.acceptableContentTypes = request.responseAcceptableContentTypes;


    //开始请求
//    NSURLSessionDataTask *task = [manager PUT:request.requestUrl parameters:request.requestParameters success:success failure:fail];
    
    NSURLSessionDataTask *task = [manager PUT:request.requestUrl parameters:request.requestParameters headers:request.headers success:success failure:fail];

    return task;
}


#pragma mark-
#pragma mark- 设置http信息头

+ (void)requestHttpHeader:(NSDictionary*)header
        requestSerializer:(AFHTTPRequestSerializer <AFURLRequestSerialization> * )requestSerializer
{
    if (header) {
        [header enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
            [requestSerializer setValue:value forHTTPHeaderField:field];
        }];
    }
}

#pragma mark - 开始监听网络
+ (void)networkStatusWithBlock:(void(^)(NSInteger status))completion
{
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:completion];
}

@end
