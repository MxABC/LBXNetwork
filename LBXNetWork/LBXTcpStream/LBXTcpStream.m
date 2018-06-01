//
//  LBXTcpStream.m
//  LBXNetwork
//
//  Created by lbxia on 2018/5/19.
//  Copyright © 2018年 lbx All rights reserved.
//

#import "LBXTcpStream.h"
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>


@interface LBXTcpStream()<NSStreamDelegate>

//ip+端口
@property (nonatomic, copy) NSString *ip;
@property (nonatomic, assign) NSUInteger port;

//接收数据
@property (nonatomic,strong) NSInputStream *input;

//发送数据
@property (nonatomic,strong) NSOutputStream *output;

///连接状态
@property (nonatomic, assign,getter=isConnected) BOOL connected;

///第一次收到可以发送数据事件
@property (nonatomic, assign) BOOL firstHasSpaceAvailable;

@end

@implementation LBXTcpStream


- (instancetype)initWithIp:(NSString*)ip port:(NSUInteger)port
{
    if (self = [super init]) {
        self.ip = ip;
        self.port = port;
        self.input = nil;
        self.output = nil;
        self.connectOverTime = 6;
    }
    return self;
}


- (BOOL)initStream
{
    if( _port <= 0 || _port > 65535 ) return NO;
    
    CFReadStreamRef  readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    CFStreamCreatePairWithSocketToHost(NULL,
                                       (__bridge CFStringRef) _ip,
                                       (UInt32) _port,
                                       (&_input  ? &readStream : NULL),
                                       (&_output ? &writeStream : NULL));
    
    self.input = (__bridge_transfer NSInputStream *)readStream;
    
    self.output = (__bridge_transfer NSOutputStream*)writeStream;
    
    return YES;
}


/**
 发起连接

 @return NO 表示ip和端口参数错误、或者请求已经存在
 */
- (BOOL)connect
{
    //已经存在
    if (_input) {
        return NO;
    }
    
    //初始化失败
    if (![self initStream])
    {
        return NO;
    }
    
    self.connected = NO;
    self.firstHasSpaceAvailable = YES;
    
    [self.input setDelegate:self];
    [self.output setDelegate:self];
    [self.input scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.output scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.input open];
    [self.output open];
    
    [self performSelector:@selector(onConnectOverTime) withObject:nil afterDelay:self.connectOverTime];
    
    return YES;
}

- (void)disConnect
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self]; //取消连接超时检测
  
    self.connected = NO;
    self.firstHasSpaceAvailable = NO;
    
    if (_input) {
        
        NSInputStream *input = _input;
        NSOutputStream *output = _output;
        self.input = nil;
        self.output = nil;
        
        [input removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [output removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [input close];
        [output close];
        input = nil;
        output = nil;
    }
}

#pragma mark- 网络状态检查
+ (BOOL)networkReachable
{
    // Create zero addy
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    
    if(didRetrieveFlags)
        return flags & kSCNetworkFlagsReachable;
    return NO;
}

#pragma mark- 发送数据


/**
 上传数据，一直循环上传，直到上传完毕或上传返回0为止

 @param data 上传数据
 @return 返回上传数据长度，如果返回0，有可能已经断开连接了
 */
- (NSUInteger)sendWithData:(NSData *)data {
    
    if(data == nil) return 0;
    const Byte* bytes = [data bytes];
    const NSInteger length = [data length];
    return [self sendWithBytes:bytes length:length];
}


/**
 上传数据，一直循环上传，直到上传完毕或上传返回0为止

 @param bytes 数据
 @param length 数据长度
 @return 返回上传数据长度，如果返回0，有可能已经断开连接了
 */
- (NSUInteger)sendWithBytes:(const uint8_t *)bytes length:(NSUInteger)length {
    
    if(bytes == nil || length <= 0)
        return 0;
    
    NSUInteger pos = 0;
    while ( pos < length && self.isConnected ) {
        
        if( [self.output hasSpaceAvailable] ) {
            
            NSUInteger sendLen = MIN(4096, length - pos); // 每次最多发4K
            sendLen = [self.output write:bytes+pos maxLength:sendLen];
            if(sendLen <= 0) break;
            pos += sendLen;
        } else // 如果发送缓存已满，暂停0.1秒
            [NSThread sleepForTimeInterval:0.1];
        
    }
    
    return pos;
}


/**
 上传数据，只调用发送接口一次

 @param data 上传数据
 @param pos 上传数据索引
 @return 返回上传长度，-1表示异常，一般为断开连接
 */
- (NSInteger)sendDataEx:(NSData *)data pos:(NSUInteger)pos
{
    if(data == nil)
        return 0;
    
    const Byte* bytes = [data bytes];
    const NSUInteger length = [data length];
    
    if (pos < length && _connected)
    {
        if([self.output hasSpaceAvailable])
        {
            long sendLen = MIN(4096, length - pos); // 每次最多发4K
            return [self.output write:bytes+pos maxLength:sendLen];
        }
    }
    
    //异常
    return -1;
}

#pragma mark- 连接状态事件

//连接超时
- (void)onConnectOverTime
{
    if (_input && _onConnectStatus) {
        _onConnectStatus(LBXTcpStreamStatusConnectOverTime);
    }
    
    [self disConnect];
}

//接收数据
- (void)onStreamRecv
{
    char buffer[4096];
    while ([self.input hasBytesAvailable]) {
        
        NSInteger recvLen = [self.input read:(uint8_t*)buffer maxLength:4096];
        if(recvLen <= 0) break; //没有可读数据
        
        if (_onRecvData) {
            _onRecvData(buffer,recvLen);
        }
    }
}

//连接成功
- (void)onStreamConnected
{
    if (_input && _onConnectStatus) {
        _onConnectStatus(LBXTcpStreamStatusConnected);
    }
}

//连接断开
- (void)onDisconnected
{
    if (_input && _onConnectStatus) {
        _onConnectStatus(LBXTcpStreamStatusDisconnectd);
    }
    
    [self disConnect];
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch(eventCode) {
        case NSStreamEventHasBytesAvailable:
        {
            //收到数据
            if (_input == aStream) {
                [self onStreamRecv];
            }
        }
            break;
        case NSStreamEventHasSpaceAvailable:
        {
            //可以向发送缓存发送数据
            if ( _firstHasSpaceAvailable && aStream == _output )
            {
                //取消超时检测
                [NSObject cancelPreviousPerformRequestsWithTarget:self];

                _firstHasSpaceAvailable = NO;
                [self onStreamConnected];
            }
        }
            break;
        case NSStreamEventEndEncountered:
        {
            //连接断开或结束
            NSLog(@"NSStreamEventEndEncountered %@", [[aStream streamError] localizedDescription]);
            if ( aStream.streamStatus == NSStreamStatusAtEnd )
                [self onDisconnected];
        }
            break;
        case NSStreamEventErrorOccurred:
        {
            //无法连接或断开连接
            NSLog(@"NSStreamEventErrorOccurred %@", [[aStream streamError] localizedDescription]);
            if( [[aStream streamError] code] != 0 )//确定code不是0……有时候正常使用时会跳出code为0的错误
                [self onDisconnected];
        }
            break;
        case NSStreamEventOpenCompleted://流已经打开
        case NSStreamEventNone:
        default:
            break;
    }
}

@end
