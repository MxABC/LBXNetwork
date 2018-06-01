//
//  LBXDataTool.m
//  LBXNetwork
//
//  Created by lbxia on 2018/5/29.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import "LBXDataTool.h"

@implementation LBXDataTool

/**
 * 数组转换成十六进制字符串
 */
+ (NSString*)hexStringWithData:(NSData*)data
{
    NSMutableString *arrayString = [[NSMutableString alloc]initWithCapacity:data.length * 2];
    int len = (int)data.length;
    unsigned char* bytes = (unsigned char*)data.bytes;
    
    for (int i = 0; i < len; i++)
    {
        unsigned char cValue = bytes[i];
        
        //        int iValue = cValue;
        //        iValue = iValue & 0x000000FF;
        
        NSString *str = [NSString stringWithFormat:@"%02x",cValue];
        
        [arrayString appendString:str];
    }
    
    return arrayString.uppercaseString;
}

+ (NSString*)base64StringWithData:(NSData*)data
{
    NSString *base64 = [data base64EncodedStringWithOptions:0];
    return base64;
}

+ (NSString *)convertToJsonStrWith:(NSDictionary *)dic
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString=@"";
    if (!jsonData) {
        NSLog(@"%@",error);
    }else{
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
//    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
//    NSRange range = {0,jsonString.length};
//    //去掉字符串中的空格
//    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
//    NSRange range2 = {0,mutStr.length};
//    //去掉字符串中的换行符
//    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    
    return jsonString;
}


@end
