//
//  LBXNetworkConfig.h
//  LBXNetwork
//  https://github.com/MxABC/LBXNetwork
//  Created by lbx on 2018/2/9.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AFSecurityPolicy;



/**
 接口配置参数
 */
@interface AFNNetworkRequest : NSObject

///  Security policy will be used by AFNetworking. See also `AFSecurityPolicy`. 
@property (nonatomic, strong,nullable) AFSecurityPolicy *securityPolicy;


///  SessionConfiguration will be used to initialize AFHTTPSessionManager. Default is nil.
@property (nonatomic, strong,nullable) NSURLSessionConfiguration* sessionConfiguration;


///任务，调用接口后，存储task,用于取消任务等
@property (nonatomic, strong,nullable) NSURLSessionDataTask *task;

@end
