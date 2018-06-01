//
//  LBXDataTool.h
//  LBXNetwork
//  https://github.com/MxABC/LBXNetwork
//  Created by lbxia on 2018/5/29.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 数据调试工具代码
 */
@interface LBXDataTool : NSObject

/**
 NSData成十六进制字符串,方便打印日志，查看数据，调试使用

 @param data NSData数据
 @return hex字符串
 */
+ (NSString*)hexStringWithData:(NSData*)data;



/**
 NSData转换 base64字符串，方便打印日志，查看数据，调试使用

 @param data NSData
 @return base64字符串
 */
+ (NSString*)base64StringWithData:(NSData*)data;


/**
 字典转字符串，仅供打印日志使用，

 @param dic 字典
 @return 字符串
 */
+ (NSString *)convertToJsonStrWith:(NSDictionary *)dic;

@end
