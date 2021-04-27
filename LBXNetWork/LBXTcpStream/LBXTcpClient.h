//
//  LBXTcpClient.h
//
//
//  Created by lbxia on 2020/4/25.
//  Copyright © 2020 lbx. All rights reserved.
//

#import <Foundation/Foundation.h>


enum LBXTcpClientError {
    HKTCE_Another,//当前client已经在连接
    HKTCE_NoNetwork, //没有网络
    HKTCE_IPPortInvalid,//ip与端口错误
    HKTCE_ConnectTimeout, //连接超时
    HKTCE_Disconnected //连接断开
};

@class LBXTcpClient;

@protocol LBXTcpClientProtocol <NSObject>

@required

- (void)onError:(enum LBXTcpClientError) error client:(LBXTcpClient*)client;

//接收到数据
- (void)onRecv:(const uint8_t*)data len:(NSUInteger)datLen client:(LBXTcpClient*)client;

//已连接，可以发送数据了
- (void)onConnected:(LBXTcpClient*)client;

@optional
- (void)onRecvOverRecvTime:(BOOL)overRecvTime client:(LBXTcpClient*)client;

@end

#pragma mark - LBXTcpClient


/*
 基于NSStream的TCP客户端，通过子线程获取RunLoop，实现网络事件在子线程中执行
 支持IPV6,支持后台运行(需要设置netService对应模式)
*/
@interface LBXTcpClient : NSObject

//委托形式回调
@property (nonatomic, weak) id<LBXTcpClientProtocol> delegate;

// Supported network service types:
//NSStreamNetworkServiceTypeVoIP
//NSStreamNetworkServiceTypeVideo
//NSStreamNetworkServiceTypeBackground
//NSStreamNetworkServiceTypeVoice
//NSStreamNetworkServiceTypeCallSignaling  ios10
//根据需要设置对应的后台执行方式,模拟 nil
@property (nonatomic, copy) NSStreamNetworkServiceTypeValue netService;

//代理服务器设置,iOS一般使用不到，mac osx 使用代理网络可以使用
@property (nonatomic, copy) NSString *hostProxy;
@property (nonatomic, assign) NSInteger portProxy;

// 连接超时时间,默认10s
@property (nonatomic,assign) NSInteger outTime;


//超过多少秒(默认10s)没有接收到数据，回调状态，如果没有实现onRecvOverRecvTime方法，不会计算超时时间
@property (nonatomic, assign) NSInteger overRecvDataTime;

/// 是否需要主线程支持 默认值NO:子线程模式
@property (nonatomic, assign) BOOL mainRunLoop;



//是否有网络，判断不准确
+ (BOOL)IsNetworkReachable;


#pragma mark - methods

- (BOOL)isConnected;
- (BOOL)hasSpaceToSend;

- (BOOL)connectToHost:(NSString*)hostname port:(uint16_t)port;
- (void)disconnectFromHost;



#pragma mark - 数据上传

/*
 如果有多线程同时调用上传方法
 */

/// 循环发送全部数据直至失败，返回发送字节数
/// @param data 发送数据
- (long)sendData:(NSData*)data;

/// 循环发送全部数据直至失败，返回发送字节数
/// @param bytes 数据
/// @param length 数据长度
- (long)sendBytes:(const uint8_t*)bytes length:(long)length;

/// 上传数据，返回当前发送成功字节数,如果没有一次性上传完，调用者处理
/// @param data 上传数据
/// @param pos 上传数据开始坐标
- (long)sendDataEx:(NSData*)data pos:(long)pos;


#pragma mark - 数据安全上传,函数内加锁，防止多线程同时上传数据问题


/// 循环发送全部数据直至发完或失败，返回发送字节数
/// @param data 发送数据
- (long)sendDataSafe:(NSData*)data;

/// 循环发送全部数据直至失败，返回发送字节数
/// @param bytes 数据
/// @param length 数据长度
- (long)sendBytesSafe:(const uint8_t*)bytes length:(long)length;

/// 上传数据，返回当前发送成功字节数,如果没有一次性上传完，调用者处理
/// @param data 上传数据
/// @param pos 上传数据开始坐标
- (long)sendDataExSafe:(NSData*)data pos:(long)pos;



@end
