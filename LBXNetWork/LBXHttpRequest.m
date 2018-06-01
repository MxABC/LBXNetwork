//
//  LBXNetworkRequest.m
//  LBXNetwork
//
//  Created by lbx on 2018/2/25.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import "LBXHttpRequest.h"
#import "LBXDataTool.h"

@implementation LBXHttpRequest

- (instancetype)init
{
    if (self = [super init]) {
        
        self.server = nil;
        self.api = nil;
        self.requestUrl = nil;
        
        self.timeoutInterval = 10;
        self.headers = nil;
        self.requestParameters = nil;
        self.requestSerializerType = LBXHTTPSerializerTypeJSON;
        self.responseSerializerType = LBXHTTPSerializerTypeJSON;
        self.httpMethod = LBXHTTPMethodTypePOST;
        self.responseAcceptableContentTypes = [NSSet setWithObjects:@"application/json",@"application/javascript",@"text/json",@"text/javascript",@"text/html",@"text/plain",@"multipart/form-data",nil];
        
#ifdef DEBUG
        self.debugLogEnabled = YES;
#else
        self.debugLogEnabled = NO;
#endif
        
        self.cachedPrior = NO;
        self.cacheEnable = NO;
        self.errAutoHandle = NO;
    }
    return self;
}

- (NSString*)requestUrl
{
    if (_requestUrl) {
        return _requestUrl;
    }
    
    if (_server && _api) {
        return [NSString stringWithFormat:@"%@%@",_server,_api];
    }
    else if (_server)
    {
        return _server;
    }
    else if (_api)
        return _api;
    else
        return @"";
}

- (void)setRequestParameters:(id)requestParameters
{
    _requestParameters = requestParameters;
    
    if (_debugLogEnabled) {
        NSLog(@"%@",self);
    }
}

- (NSString *)description
{
    NSString *requestURL = self.requestUrl;
    NSString *reuqestPara = @"";
    
    if ([_requestParameters isKindOfClass:[NSDictionary class]]) {
        
        reuqestPara = [LBXDataTool convertToJsonStrWith:_requestParameters];
    }
    else if ([_requestParameters isKindOfClass:[NSData class]])
    {
        //NSData 转hex
        NSString *hexString = [LBXDataTool hexStringWithData:_requestParameters];
        NSString *base64 = [LBXDataTool base64StringWithData:_requestParameters];
        NSString *utf8String = [[NSString alloc]initWithData:_requestParameters encoding:NSUTF8StringEncoding];

        reuqestPara = [NSString stringWithFormat:@"requestData:\r\nHexString:%@\r\n%@\r\nutf8:%@", hexString,base64,utf8String];
    }
    return [NSString stringWithFormat:@"requestURL:%@\r\n%@",requestURL,reuqestPara];
}


@end


@implementation LBXHttpResponse
- (instancetype)init
{
    if (self = [super init]) {

        self.needHandle = YES;
        self.success = NO;
        self.error = nil;
        self.request = nil;
        self.responseObject = nil;
        self.statusCode = -1;
        self.cachedResponse = NO;
        
#ifdef DEBUG
        self.debugLogEnabled = YES;
#else
        self.debugLogEnabled = NO;
#endif
        
    }
    return self;
}


- (void)setResponseObject:(id)responseObject
{
    _responseObject = responseObject;
    if (_debugLogEnabled) {
        NSLog(@"%@",self);
    }
}


- (NSString *)description
{
    NSString *requestURL = self.request.requestUrl;
    NSString *response = @"";
    
    if ([_responseObject isKindOfClass:[NSDictionary class]]) {
        
        response = [LBXDataTool convertToJsonStrWith:_responseObject];
    }
    else if ([_responseObject isKindOfClass:[NSData class]])
    {
        //NSData 转hex
        NSString *hexString = [LBXDataTool hexStringWithData:_responseObject];
        NSString *base64 = [LBXDataTool base64StringWithData:_responseObject];
        
        NSString *dataType = @"unknown";
        NSString *utf8String = [[NSString alloc]initWithData:_responseObject encoding:NSUTF8StringEncoding];
        
        if (!utf8String) {
            utf8String = [[NSString alloc]initWithData:_responseObject encoding:NSASCIIStringEncoding];
            if (utf8String) {
                dataType = @"ASCIIString";
            }
        }
        else
        {
            dataType = @"utf8";
        }
        
        response = [NSString stringWithFormat:@"HexString:%@\r\nbase64:%@\r\n%@:%@", hexString,base64,dataType,utf8String];
    }
    return [NSString stringWithFormat:@"requestURL:%@\r\nresponse:\r\n%@",requestURL,response];
}



@end
