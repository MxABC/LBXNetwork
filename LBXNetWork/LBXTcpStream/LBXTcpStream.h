//
//  LBXTcpStream.h
//  LBXNetwork
//  https://github.com/MxABC/LBXNetwork
//  Created by lbxia on 2018/5/19.
//  Copyright © 2018年 lbx All rights reserved.
//

#import <Foundation/Foundation.h>


//TCP连接状态
typedef NS_ENUM(NSInteger,LBXTcpStreamStatus)
{
    LBXTcpStreamStatusConnected,
    LBXTcpStreamStatusDisconnectd,
    LBXTcpStreamStatusConnectOverTime
};


/**
 封装NSStream,TCP功能
 */
@interface LBXTcpStream : NSObject

//连接超时时间，单位:秒,默认:6秒
@property (nonatomic, assign) NSInteger connectOverTime;

//连接状态
@property (nonatomic,readonly,getter=isConnected) BOOL connected;

//回调连接状态,主线程
@property (nonatomic, copy) void (^onConnectStatus)(LBXTcpStreamStatus status);

//回调接收到的数据，主线程
@property (nonatomic, copy) void (^onRecvData)(const char* data,NSInteger datalen);


#pragma mark- 网络状态检查
+ (BOOL)networkReachable;

/**
 初始化对象

 @param ip ip
 @param port 端口
 @return 对象
 */
- (instancetype)initWithIp:(NSString*)ip port:(NSUInteger)port;


/**
 发起连接
 
 @return NO 表示ip和端口参数错误、或者请求已经存在
 */
- (BOOL)connect;


/**
 断开连接
 */
- (void)disConnect;


#pragma mark- 发送数据


/**
 上传数据，一直循环上传，直到上传完毕或上传返回0为止,建议在子线程中调用
 
 @param data 上传数据
 @return 返回上传数据长度，如果返回0，有可能已经断开连接了
 */
- (NSUInteger)sendWithData:(NSData *)data;

/**
 上传数据，一直循环上传，直到上传完毕或上传返回0为止,建议在子线程中调用
 
 @param bytes 数据
 @param length 数据长度
 @return 返回上传数据长度，如果返回0，有可能已经断开连接了
 */
- (NSUInteger)sendWithBytes:(const uint8_t *)bytes length:(NSUInteger)length;

/**
 上传数据，只调用发送接口一次
 
 @param data 上传数据
 @param pos 上传数据索引
 @return 返回上传长度，-1表示异常，一般为断开连接
 */
- (NSInteger)sendDataEx:(NSData *)data pos:(NSUInteger)pos;

@end
