//
//  LBXNetwork.m
//  LBXNetwork
//
//  Created by lbx on 2018/2/25.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import "LBXNetwork.h"
#import "AFNNetworkVendor.h"
#import "LBXHttpCache.h"


@interface LBXNetwork()
@property (nonatomic, strong) NSHashTable *tasks;
@end

@implementation LBXNetwork

+ (instancetype)sharedManager
{
    static LBXNetwork* _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[LBXNetwork alloc] init];
    });
    return _sharedInstance;
}

#pragma mark-
#pragma mark- 开始监听网络
+ (void)networkStatusWithBlock:(void(^)(LBXNetworkStatus status))completion
{
    [AFNNetworkVendor networkStatusWithBlock:completion];
}


#pragma mark-
#pragma mark- http请求
+ (LBXHttpRequest*)HttpWithRequestBlock:(void(^)(LBXHttpRequest *request))requestBlock
                            complection:(void(^)(LBXHttpResponse *response))completion
{
    //获取参数
    LBXHttpRequest *request = [[LBXHttpRequest alloc]init];
    requestBlock(request);
    
   return  [self HttpWithRequest:request complection:completion];
}

+ (LBXHttpRequest*)HttpWithRequest:(LBXHttpRequest *)request
                       complection:(void(^)(LBXHttpResponse *response))completion
{
    if (request.cachedPrior) {
        //读取缓存，如果读取成功，则不实际调用网络接口,直接读取缓存返回
        
        id responseObject = [LBXHttpCache cachedWithRequest:request];
        
        if (responseObject) {
            
            LBXHttpResponse *response = [[LBXHttpResponse alloc]init];
            response.success = YES;
            response.request = request;
            response.responseObject = responseObject;
            response.cachedResponse = YES;
            response.statusCode = 200;
            completion(response);
            return request;
        }
    }
    
    request.task = [AFNNetworkVendor AFNRequest:request success:^(NSURLSessionDataTask * task, id  _Nullable responseObject) {
        
        if (completion) {
            
            LBXHttpResponse *response = [[LBXHttpResponse alloc]init];
            response.success = YES;
            response.request = request;
            response.responseObject = responseObject;
            
            if (task && [task.response isKindOfClass:[NSHTTPURLResponse class]])
            {
                NSHTTPURLResponse *res = (NSHTTPURLResponse*)task.response;
                response.statusCode = res.statusCode;
                response.headers = res.allHeaderFields;
            }
            completion(response);
            
            if (request.cacheEnable) {
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    //存储缓存
                    [LBXHttpCache storeCacheWithResponse:response];
                });
            }
        }
        
    } fail:^(NSURLSessionDataTask * _Nullable task, NSError *  error) {
        
        if (completion)
        {
            LBXHttpResponse *response = [[LBXHttpResponse alloc]init];
            response.success = NO;
            response.request = request;
            response.error = error;
            id responseObject = nil;
            if (request.cacheEnable) {
                //读取缓存
                responseObject = [LBXHttpCache cachedWithRequest:response.request];
            }
            if (responseObject) {
                response.responseObject = responseObject;
                response.cachedResponse = YES;
                response.success = YES;
            }
            
            if (task && [task.response isKindOfClass:[NSHTTPURLResponse class]])
            {
                NSHTTPURLResponse *res = (NSHTTPURLResponse*)task.response;
                response.statusCode = res.statusCode;
            }
            
            completion(response);
        }
    }];
        
    [[LBXNetwork sharedManager].tasks addObject:request];
    
    return request;
}

#pragma mark-
#pragma mark- http多个请求
///ChainRequest
///测试取消请求，是否会进入fail回调，如果不进入，会有问题
+ (NSArray<LBXHttpRequest*>*)HttpWithBatchNum:(NSUInteger)batchNum
                            batchRequestBlock:(void(^)(NSArray<LBXHttpRequest*> *request) )requestsBlock
                                  complection:(void(^)(NSArray<LBXHttpResponse*> *responses))completion
{
    NSMutableArray<LBXHttpRequest*> *requests = [NSMutableArray arrayWithCapacity:batchNum];
    for (int i = 0; i < batchNum; i++) {
        LBXHttpRequest *request = [[LBXHttpRequest alloc]init];
        [requests addObject:request];
    }
    
    requestsBlock(requests);
    
    return [self HttpWithBatchNum:batchNum batchRequest:requests complection:completion];
}

///ChainRequest
///测试取消请求，是否会进入fail回调，如果不进入，会有问题
+ (NSArray<LBXHttpRequest*>*)HttpWithBatchNum:(NSUInteger)batchNum
                                 batchRequest:(NSArray<LBXHttpRequest *>*)requests
                                  complection:(void(^)(NSArray<LBXHttpResponse*> *responses))completion
{

    NSMutableArray<LBXHttpResponse*> *responses = [NSMutableArray arrayWithCapacity:batchNum];
    
    dispatch_group_t group = dispatch_group_create();
    for (NSUInteger i = 0; i < batchNum; i++ )
    {
        //占位置
        LBXHttpResponse *res = [[LBXHttpResponse alloc]init];
        [responses addObject:res];
        
        dispatch_group_enter(group);
        
        [self HttpWithRequest:requests[i] complection:^(LBXHttpResponse *  response) {
            
            [responses replaceObjectAtIndex:i withObject:response];
            
            dispatch_group_leave(group);
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        
        //任务完成
        completion(responses);
    });
    
    return requests;
}

#pragma mark- 取消任务
- (NSHashTable*)tasks
{
    if (!_tasks) {
        
        _tasks = [[NSHashTable alloc]initWithOptions:NSHashTableWeakMemory capacity:5];
    }
    return _tasks;
}

+ (void)cancelWithRequest:(LBXHttpRequest*)request
{
    if (request && request.task )
    {
        if (request.task.state == NSURLSessionTaskStateRunning || request.task.state == NSURLSessionTaskStateSuspended) {
            [request.task cancel];
        }
    }
}

+ (void)cancelWithURL:(NSString*)requestUrl
{
    if (!requestUrl) {
        return;
    }
    
    for (LBXHttpRequest *request in [LBXNetwork sharedManager].tasks) {
        
        if (request.api && [request.api isEqualToString:requestUrl] ) {
            
            [self cancelWithRequest:request];
            break;
        }
        else if (request.requestUrl && [request.requestUrl isEqualToString:requestUrl] )
        {
            [self cancelWithRequest:request];
            break;
        }
    }
}

+ (void)cancelAllRequests
{
    for (LBXHttpRequest *request in [LBXNetwork sharedManager].tasks) {
        
        [self cancelWithRequest:request];
    }
}


@end
