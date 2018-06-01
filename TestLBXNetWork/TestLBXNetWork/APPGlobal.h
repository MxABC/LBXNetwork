//
//  APPGlobal.h
//  TestLBXNetWork
//
//  Created by lbxia on 2018/5/29.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APPGlobal : NSObject
@property (nonatomic, copy) NSString *token;

+ (instancetype)sharedManager;

@end
