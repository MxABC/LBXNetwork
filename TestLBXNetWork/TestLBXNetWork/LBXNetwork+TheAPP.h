//
//  LBXNetwork+TheAPP.h
//  TestLBXNetWork
//
//  Created by lbxia on 2018/5/29.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import <LBXNetwork.h>


/**
 LBXNetwork 使用示例
 
 APP中业务层调用LBXNetwork库
 
 添加常用统一内部的处理内容有：
 - 添加相关业务逻辑处理
 - 添加错误统一处理
 - 添加请求等待hud
 - 接口相关配置统一处理：证书、token等
 - 保存请求的LBXHttpRequest用来取消任务
 */
@interface LBXNetwork (TheAPP)

+ (LBXHttpRequest*)HttpWithHud:(BOOL)hud
                         token:(BOOL)token
                  requestBlock:( void(^)(LBXHttpRequest *request))requestBlock
                   complection:(void(^)(LBXHttpResponse*  response))completion;

@end
