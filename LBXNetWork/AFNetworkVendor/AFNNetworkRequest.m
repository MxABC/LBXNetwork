//
//  LBXNetworkConfig.m
//  LBXNetwork
//
//  Created by lbx on 2018/2/9.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import "AFNNetworkRequest.h"
#import "AFSecurityPolicy.h"
@implementation AFNNetworkRequest

- (instancetype)init
{
    if (self = [super init]) {

        self.securityPolicy = [AFNNetworkRequest securityPolicy];
        self.sessionConfiguration = nil;
        self.task = nil;
    }
    
    return self;
}


+ (AFSecurityPolicy *)securityPolicy
{
    static AFSecurityPolicy *policy = nil;
    
    if (!policy) {
        
        //无条件的信任服务器上的证书
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
        
        // 客户端是否信任非法证书
        securityPolicy.allowInvalidCertificates = YES;
        
        // 是否在证书域字段中验证域名
        securityPolicy.validatesDomainName = NO;
        
        policy = securityPolicy;
        
    }
    
    return policy;
}

@end



