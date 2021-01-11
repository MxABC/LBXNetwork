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


#pragma mark- 表单上传文件接口

/// 表单上传文件
/// @param request 请求参数，文件参数通过requestElseParameters来赋值
///  requestElseParameters参数格式为NSArray<NSDictionary*>*
///  NSDictionary包含字段 name,fileName,mimeType以及文件数据fileData(NSData)(或者filePath表示文件路径)
/// @param uploadProgress 上传进度
/// @param completion 调用完成
+ (LBXHttpRequest*)PostFormWithRequest:(LBXHttpRequest *)request
                              progress:(nullable void (^)(double progress))uploadProgress
                           complection:(void(^)(LBXHttpResponse *response))completion
{
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = request.timeoutInterval;
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"text/html",@"application/json", @"text/json" ,@"text/javascript", nil];
    

    void (^onProgress)(NSProgress * _Nonnull uploadProgress) = nil;
    
    if (uploadProgress) {
        
        onProgress = ^(NSProgress * _Nonnull progress)
        {
            uploadProgress(progress.fractionCompleted);
        };
    }
    
    
    return [manager POST:request.requestUrl parameters:request.requestParameters headers:request.headers constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {

        NSArray* fileParameters = request.requestElseParameters;
        for (int i = 0; i < fileParameters.count; i++) {
            NSDictionary *dic = fileParameters[i];
            //下面2个参数有一个即可
            NSData *fileData = dic[@"fileData"];
            NSString *filePath = dic[@"filePath"];
            
            NSString *name = dic[@"name"];
            NSString *fileName = dic[@"fileName"];
            NSString * mimeType = dic[@"mimeType"];
            
            if (fileData) {
                [formData appendPartWithFileData:fileData
                                            name:name
                                        fileName:fileName
                                        mimeType:mimeType];
            }
            else if(filePath)
            {
                NSError *error = nil;
                [formData appendPartWithFileURL:[NSURL fileURLWithPath:filePath] name:name fileName:fileName mimeType:mimeType error:&error];
                
                if (error) {
                    NSLog(@"表单上传文件 添加文件参数错误: %@",error);

                }

            }
        }
        
    } progress:onProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
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
           
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (completion)
        {
            LBXHttpResponse *response = [[LBXHttpResponse alloc]init];
            response.success = NO;
            response.request = request;
            response.error = error;
            
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
