//
//  APPGlobal.m
//  TestLBXNetWork
//
//  Created by lbxia on 2018/5/29.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import "APPGlobal.h"

@implementation APPGlobal

+ (instancetype)sharedManager
{
    static APPGlobal* _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[APPGlobal alloc] init];
        _sharedInstance.token = @"123";
        
    });
    
    return _sharedInstance;
}

@end
