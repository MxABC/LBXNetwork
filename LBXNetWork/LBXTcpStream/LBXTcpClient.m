//
//  LBXTcpClient.m
//
//
//  Created by lbx on 2021/4/25.
//  Copyright © 2021 lbx. All rights reserved.
//

#import "LBXTcpClient.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import <netdb.h>
#import <SystemConfiguration/SystemConfiguration.h>


@interface LBXTcpClient()<NSStreamDelegate>
{
    BOOL bActive;//当前处于活跃状态，关闭连接则为NO
    BOOL bConnectSuccess;      //是否连接成功
    BOOL bPostDisconnectError; //是否需要回调断开事件，比如自己主动断开的，则不需要回调了
    BOOL bFirstHasSpaceToSend; //第一次收到可以向缓存发送数据事件
}

@property(nonatomic,strong) NSInputStream *input;
@property(nonatomic,strong) NSOutputStream *output;

@property (nonatomic, strong) NSRunLoop *runLoop;
@property (strong, nonatomic) NSPort *emptyPort;
@property (strong, nonatomic) NSThread *thread;

@property (nonatomic, strong) NSCondition *condition;

//定时检测接收数据情况
@property (nonatomic, assign) BOOL needcheckRecv; //是否需要检查接收数据情况
@property (nonatomic, assign) BOOL recvOverTime;//接收数据超时
@property (nonatomic, strong) NSDate *preRecvDate;//上一次接收数据的时间
@property (nonatomic, strong) NSTimer* timerCheck;//定时检测

@end

@implementation LBXTcpClient


#pragma mark ---- ----- ----
#pragma mark ---- RunLoop ----

- (void)StartRunLoop
{
    if (!_emptyPort) {
        self.emptyPort = [NSMachPort port];
    }
    
    [self stopRunLoop];
    
    self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(runLoopThread) object:nil];
    
    
//    [self.thread runAtDealloc:^{
//        NSLog(@"thread dealloc");
//    }];
    
    //最高优先级，音频下载播放效果仍然不可以
    self.thread.qualityOfService = NSQualityOfServiceUserInteractive;
    
    [self.thread start];
}

- (void)stopRunLoop
{
    if (_thread) {
        
        [self performSelector:@selector(stopRunLoopInThread) onThread:self.thread withObject:nil waitUntilDone:YES];
    }
}

//请勿直接调用
- (void)stopRunLoopInThread
{
    if (self.runLoop) {
        
        CFRunLoopStop(CFRunLoopGetCurrent());
        
        self.thread = nil;
        self.runLoop = nil;
    }
}

- (void)runLoopThread
{
    @autoreleasepool {
//      NSLog(@"first time current thread = %@", [NSThread currentThread]);
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        self.runLoop = runLoop;
//        [runLoop runAtDealloc:^{
//            NSLog(@"runLoop dealloc");
//        }];
        
//        https://bestswifter.com/runloop-and-thread/
        //NSPort不释放，内存占用很少，是否可以创建一个单例NSPort，重复使用？？？
//      self.emptyPort = [NSMachPort port];
       
        [runLoop addPort:self.emptyPort forMode:NSDefaultRunLoopMode];
                
        CFRunLoopRun();
        
        NSLog(@" RunLoop Stop");
    }
}


#pragma mark - 静态方法


+ (BOOL)CreateStreamsToHost:(NSString *)hostName
                       port:(NSInteger)port
                      input:(NSInputStream **)inputPtr
                     output:(NSOutputStream **)outputPtr
{
    if( port < 0 || port > 65535 ) return NO;
    if( inputPtr == nil && outputPtr == nil ) return NO;
    if( hostName == nil || [hostName isEqualToString:@""]) return NO;
    
    
    if (@available(iOS 8.0,macOS 10.10, *)) {

        [NSStream getStreamsToHostWithName:hostName port:port inputStream:inputPtr outputStream:outputPtr];
    }
    else
    {
        CFReadStreamRef  readStream = NULL;
        CFWriteStreamRef writeStream = NULL;
       
        //The hostname to which the socket streams should connect. The host can be specified using an IPv4 or IPv6 address or a fully qualified DNS hostname.  支持域名，也支持IP
        CFStreamCreatePairWithSocketToHost(NULL,
                                           (__bridge CFStringRef) hostName,
                                           (UInt32) port,
                                           (inputPtr ? &readStream : NULL),
                                           (outputPtr ? &writeStream : NULL));
        
        //MRC
        //    if (inputPtr) *inputPtr = [NSMakeCollectable(readStream) autorelease];
        //    if (outputPtr) *outputPtr = [NSMakeCollectable(writeStream) autorelease];
        
        //ARC
        if (inputPtr) {
            //Moves a non-Objective-C pointer to Objective-C and also transfers ownership to ARC.
            *inputPtr = CFBridgingRelease(readStream);
        }
        if (outputPtr) {
            *outputPtr = CFBridgingRelease(writeStream);
        }
    }
    return YES;
}

+ (BOOL)IsNetworkReachable {
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

#pragma mark - methods

- (id)init {
    if(self = [super init]) {
        self.outTime = 10;
        self.mainRunLoop = NO;
        self.netService = nil;
        self.overRecvDataTime = 10;
               
    } return self;
}

- (NSCondition*)condition
{
    if (!_condition) {
        _condition = [[NSCondition alloc]init];
    }
    return _condition;
}


- (BOOL)isConnected {
    return bConnectSuccess;
}

- (BOOL)hasSpaceToSend {
    if(self.output == nil) return NO;
    return [self.output hasSpaceAvailable];
}

- (BOOL)connectToHost:(NSString *)hostname port:(uint16_t)port {
    if (bActive) {
        [self callBackError:HKTCE_Another];
        return NO;
    }
    
//    if (![LBXTcpClient IsNetworkReachable]) {
//       
//        [self callBackError:HKTCE_NoNetwork];
//        return NO;
//    }
    
    NSInputStream* input = nil;
    NSOutputStream* output = nil;
    if (![LBXTcpClient CreateStreamsToHost:hostname port:port input:&input output:&output]) {
        [self callBackError:HKTCE_IPPortInvalid];
        return NO;
    }

    bActive = YES;
    self.input = input;
    self.output = output;
    bFirstHasSpaceToSend = YES;
    bPostDisconnectError = YES;
    
    
    //ssl
    /*
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:1];
    [settings setObject:(NSString *)NSStreamSocketSecurityLevelTLSv1 forKey:(NSString *)kCFStreamSSLLevel];
    //不检查证书有效性 kCFStreamSSLAllowsAnyRoot DEPRECATED
//   [settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
    
    //不检查证书有效性
    [settings setObject:[NSNumber numberWithBool:NO] forKey:(NSString *)kCFStreamSSLValidatesCertificateChain];

    
    [settings setObject:hostname forKey:(NSString *)kCFStreamSSLPeerName];
    [settings setObject:NSStreamSocketSecurityLevelTLSv1 forKey:NSStreamSocketSecurityLevelKey];
    CFReadStreamSetProperty((CFReadStreamRef)input, kCFStreamPropertySSLSettings, (CFTypeRef)settings);
    CFWriteStreamSetProperty((CFWriteStreamRef)output, kCFStreamPropertySSLSettings, (CFTypeRef)settings);
    */
    
    
    if (_hostProxy && _portProxy > 0) {
        
        //设置代理服务器
        [self.output setProperty:_hostProxy forKey:NSStreamSOCKSProxyHostKey];
        [self.output setProperty:[NSNumber numberWithInteger:_portProxy]  forKey:NSStreamSOCKSProxyPortKey];
    }
    
    [self.input setDelegate:self];
    [self.output setDelegate:self];
    
    if (_netService)
    {
        [self.input setProperty:_netService forKey:NSStreamNetworkServiceType];
        [self.output setProperty:_netService forKey:NSStreamNetworkServiceType];
    }
    
    if (_mainRunLoop)
    {
        [self.input scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [self.output scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [self.input open];
        [self.output open];
    }
    else
    {
        [self StartRunLoop];
        
        NSInteger nums = 0;
        while (YES) {
            
            if (self.runLoop) {
                
                [self.input scheduleInRunLoop:self.runLoop forMode:NSDefaultRunLoopMode];
                [self.output scheduleInRunLoop:self.runLoop forMode:NSDefaultRunLoopMode];
                
                                NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:1];
                                                  [settings setObject:(NSString *)NSStreamSocketSecurityLevelTLSv1 forKey:(NSString *)kCFStreamSSLLevel];
                                                  [settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
                                                  [settings setObject:hostname forKey:(NSString *)kCFStreamSSLPeerName];
                                                  [settings setObject:NSStreamSocketSecurityLevelTLSv1 forKey:NSStreamSocketSecurityLevelKey];
                //
                //
                //
                //                                  CFReadStreamSetProperty((CFReadStreamRef)_input, kCFStreamPropertySSLSettings, (CFTypeRef)settings);
                //                                  CFWriteStreamSetProperty((CFWriteStreamRef)_output, kCFStreamPropertySSLSettings, (CFTypeRef)settings);
                
                [self.input open];
                [self.output open];
                break;
            }
            [NSThread sleepForTimeInterval:0.1];
            nums++;
            
            if (nums > 15)
            {
                return NO;
            }
        }
    }
    
    [self delayCheckOverTime];
    
    return YES;
}

- (void)disconnectFromHost
{
    bConnectSuccess = NO;
    bPostDisconnectError = NO;
    
    if(bActive == NO)
        return;
    
    bActive = NO;

    [self cancelDelay];
    [self stopCheckRecv];
   
    bConnectSuccess = NO;
    bPostDisconnectError = NO;
    
    if (_runLoop) {
        [self.input removeFromRunLoop:self.runLoop forMode:NSDefaultRunLoopMode];
        [self.output removeFromRunLoop:self.runLoop forMode:NSDefaultRunLoopMode];
    }else{
        [self.input removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [self.output removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
    
    [self.input close];
    [self.output close];
    self.input = nil;
    self.output = nil;
    
    [self stopRunLoop];
}

#pragma mark- ---连接超时处理---

//备注：如果是主线程中延迟函数，子线程调用取消延迟，不起作用，需要保持统一，都在同一个子线程中执行(应该主要不在同一个RunLoop导致的问题)
//这样将调用和取消都保持到主线程，防止线程不统一问题不起作用
- (void)delayCheckOverTime
{
    if ([NSThread isMainThread]) {
        
        [self performSelector:@selector(onConnectTimeover) withObject:nil afterDelay:self.outTime];
    }
    else
    {
        [self performSelectorOnMainThread:@selector(delayCheckOverTime) withObject:nil waitUntilDone:YES];
    }
}

- (void)cancelDelay
{
    if ([NSThread isMainThread]) {
         [NSObject cancelPreviousPerformRequestsWithTarget:self]; //取消连接超时检测
    }
    else
    {
        [self performSelectorOnMainThread:@selector(cancelDelay) withObject:nil waitUntilDone:NO];
    }
}

- (void)onConnectTimeover {
    
    [self disconnectFromHost];
    
    [self callBackError:HKTCE_ConnectTimeout];
}

#pragma mark- - --数据发送----

- (long)sendData:(NSData *)data
{
    if(data == nil) return 0;
    const Byte* bytes = [data bytes];
    const long length = [data length];
    return [self sendBytes:bytes length:length];
}

- (long)sendDataSafe:(NSData *)data
{
    if(data == nil) return 0;
    const Byte* bytes = [data bytes];
    const long length = [data length];
    return [self sendBytesSafe:bytes length:length];
}

- (long)sendBytes:(const uint8_t *)bytes length:(long)length
{
    if(bytes == nil) return 0;
    long pos = 0;
    while (pos < length && bConnectSuccess) {
        if(bActive && [self.output hasSpaceAvailable]) {
            long sendLen = MIN(4096, length - pos); // 每次最多发4K
            sendLen = [self.output write:bytes+pos maxLength:sendLen];
            if(sendLen <= 0) break;
            pos += sendLen;
        } else // 如果发送缓存已满，暂停0.1秒
            [NSThread sleepForTimeInterval:0.1]; 
    } return pos;
}

- (long)sendBytesSafe:(const uint8_t *)bytes length:(long)length
{
    if(bytes == nil) return 0;
    long pos = 0;
    [self.condition lock];
    while (pos < length && bConnectSuccess)
    {
        if(bActive && [self.output hasSpaceAvailable]) {
            long sendLen = MIN(4096, length - pos); // 每次最多发4K
            sendLen = [self.output write:bytes+pos maxLength:sendLen];
            if(sendLen <= 0) break;
            pos += sendLen;
        }
        else // 如果发送缓存已满，暂停0.1秒
            [NSThread sleepForTimeInterval:0.1];
    }
    [self.condition unlock];
    return pos;
}

- (long)sendDataEx:(NSData *)data pos:(long)pos
{
    if(data == nil) return 0;
    const Byte* bytes = [data bytes];
    const long length = [data length];
    if (pos < length && bConnectSuccess) {
        if( bActive && [self.output hasSpaceAvailable]) {
            long sendLen = MIN(4096, length - pos); // 每次最多发4K
            return [self.output write:bytes+pos maxLength:sendLen];
        } return 0;
    } return -1;
}

- (long)sendDataExSafe:(NSData *)data pos:(long)pos
{
    if(data == nil)
        return 0;
    const Byte* bytes = [data bytes];
    const long length = [data length];
    
    if (pos < length && bConnectSuccess)
    {
        long retLong = 0;
        
        [self.condition lock];
        if( bActive && [self.output hasSpaceAvailable])
        {
            long sendLen = MIN(4096, length - pos); // 每次最多发4K
            retLong = [self.output write:bytes+pos maxLength:sendLen];
        }
        [self.condition unlock];
        
        return retLong;
    }
    return -1;
}


#pragma mark - ---回调处理

- (void)callBackError:(enum LBXTcpClientError) error
{
    if (_delegate && [_delegate respondsToSelector:@selector(onError:errMsg:client:)])
    {
        [_delegate onError:error  client:self];
    }
}

- (void)onRecvWithData:(const uint8_t*)data len:(NSUInteger)datLen
{
    if (_delegate && [_delegate respondsToSelector:@selector(onRecv:len:client:)])
    {
        [_delegate onRecv:data len:datLen client:self];
    }
    
    
    if (_needcheckRecv) {
        self.preRecvDate = [NSDate date];
    }
}


- (void)onConnected
{
    if (_delegate && [_delegate respondsToSelector:@selector(onConnected:)])
    {
        [_delegate onConnected:self];
    }
}

#pragma mark - NSStreamDelegate 网络事件
- (void)onReadyRead
{
    uint8_t buffer[5120];
//    NSLog(@"onReadyRead");
    
    if ( bActive && [self.input hasBytesAvailable] )
    {
        NSInteger readLen = [self.input read:(uint8_t*)buffer maxLength:5120];
        if(readLen <= 0)
            return;//没有可读数据，
        
        [self onRecvWithData:buffer len:readLen];
    }
}

- (void)onReadyRead_old
{
    char buffer[5120];
    
    while ( bActive && [self.input hasBytesAvailable]) {
        long readLen = [self.input read:(uint8_t*)buffer maxLength:5120];
        if(readLen <= 0)
            break; //没有可读数据，不进入回调
        
        [self onRecvWithData:buffer len:readLen];
        
        //如果不加下面代码，偶尔出现崩溃情况
        if (readLen < 5120) {
            break;
        }
    }
}

- (void)onReadyWrite
{
    bConnectSuccess = YES; //必须置YES才能发送数据
    [self cancelDelay];
    [self startCheckRecv];
    
    [self onConnected];
}

- (void)onDisconnected
{
    BOOL postErr = bPostDisconnectError;
    
    //先调用disconnect，再调用回调
    //不然容易导致崩溃问题，原因还不知道，错误-[LBXTcpClient stream:handleEvent:]信号错误，不好定位
    [self disconnectFromHost];
    
    if (postErr)
    {
        [self callBackError:HKTCE_Disconnected];
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    
    if (!bActive) {
        return;
    }
    
    switch(eventCode) {
        case NSStreamEventHasBytesAvailable:
            if( aStream == self.input )
                [self onReadyRead];
            break;
        case NSStreamEventHasSpaceAvailable://可以向发送缓存发送数据
            if ( bFirstHasSpaceToSend && aStream == self.output )
            {
                bFirstHasSpaceToSend = NO;
                [self onReadyWrite];
            }
            break;
        case NSStreamEventEndEncountered://连接断开或结束
//            Log_Detail(@"%@ NSStreamEventEndEncountered %@", self.loggerName, [[aStream streamError] localizedDescription]);
            if ( aStream.streamStatus == NSStreamStatusAtEnd )
                [self onDisconnected];
            break;
        case NSStreamEventErrorOccurred://无法连接或断开连接
//            Log_Detail(@"%@ NSStreamEventErrorOccurred %@", self.loggerName, [[aStream streamError] localizedDescription]);
            if( [[aStream streamError] code] != 0 )//确定code不是0……有时候正常使用时会跳出code为0的错误
                [self onDisconnected];
            break;
        case NSStreamEventOpenCompleted://流已经打开
        {
            NSLog(@"NSStreamEventOpenCompleted");
        }
            break;
        case NSStreamEventNone:
        default:
            break;
    }
}


#pragma mark- - 域名判断---

+ (NSString*)getIpByHostName:(NSString*)strHostName {
    struct hostent* phot = nil;
    @try {
        phot = gethostbyname(strHostName.UTF8String);
        if(phot == nil)
            NSLog(@"getIpByHostName %@ = nil", strHostName);
    }
    @catch (NSException *exception) {
//        NSArray *stack = [exception callStackSymbols]; // 异常的堆栈信息
//        NSString *reason = [exception reason]; // 出现异常的原因
//        NSString *name = [exception name]; // 异常名称
        //        Log_Error(@"getIpByHostName %@\n异常:%@\n原因：%@\n信息：%@", strHostName, name, reason, stack);
        return nil;
    }
    if(phot == nil) return nil;
    struct in_addr ip_addr;
    memcpy(&ip_addr, phot->h_addr_list[0], 4);
    char ip[20] = {0};
    inet_ntop(AF_INET, &ip_addr, ip, sizeof(ip));
    
    return [NSString stringWithUTF8String:ip];
}

+ (BOOL)isPureInt:(NSString*)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return [scan scanInt:&val] && [scan isAtEnd];
}

/*
 ipv4 127.0.0.1
 ipv6: 2405:3140:3A:5102::0A70:296F  (其中一种IPVv形式,IPv6还有其他形式，如Ipv6格式中 有包含ipv4格式的形式)
 */
+ (NSString*)digitalIpWithHostName:(NSString*)hostName
{
    NSArray *array = [hostName componentsSeparatedByString:@"."];
    
    NSArray *arrayIPV6 = [hostName componentsSeparatedByString:@":"];
    
    if (array.count == 3 && arrayIPV6.count == 0) {
        
        //ipv4
        NSString *domain = nil;
        for (NSString* str in array) {
            
            if (![self isPureInt:str]) {
                
                //域名解析成ip
                domain = [self getIpByHostName:hostName];
                break;
            }
        }
        return domain ? domain : hostName;
    }
    
    if (arrayIPV6.count >= 3) {
        
        //判断为Ipv6，直接返回
       return hostName;
    }
   
    NSString *domain = [self getIpByHostName:hostName];
    
    return domain ? domain : hostName;
}


#pragma mark-  定时检测数据接收情况

- (void)startCheckRecv
{
    if ( (_delegate && [_delegate respondsToSelector:@selector(onRecvOverRecvTime:client:)]) )
    {
        self.needcheckRecv = YES;
        self.recvOverTime = NO;
        [self startCheckRecvTimer];
        [self registerApplication];
        self.preRecvDate = [NSDate date];
    }
}

- (void)stopCheckRecv
{
    [self stopCheckRecvTimer];
    [self removeNotification];
    self.preRecvDate = nil;
    self.needcheckRecv = NO;
}

/*
 及时检测视频下载数据，防止对方不在线，虽然保持连接，但是么有数据，及时提示连接情况
*/
- (void)registerApplication
{
    if ( !_netService )
    {
#if  TARGET_OS_OSX
        
#else
        //后台进前台通知 UIApplicationDidBecomeActiveNotification
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
//        
//        //进入后台UIApplicationDidEnterBackgroundNotification
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
#endif
    }
}

//进入后台方法
- (void)didEnterBackground
{
    [self stopCheckRecvTimer];
}

//每次后台进前台都会执行这个方法
- (void)didBecomeActive
{
    if (!_recvOverTime) {
        self.preRecvDate = [NSDate date];
    }
    if (_needcheckRecv) {
        [self startCheckRecvTimer];
    }
}

- (void)removeNotification
{
    [[NSNotificationCenter defaultCenter]removeObserver:self]; //移除通知
}

- (void)startCheckRecvTimer
{
    if (![NSThread isMainThread]) {
        
        [self performSelectorOnMainThread:@selector(startCheckRecvTimer) withObject:nil waitUntilDone:YES];
        return;
    }
    
    [self stopCheckRecvTimer];
    
    if (_overRecvDataTime < 2 ) {
        _overRecvDataTime = 10;
    }
    
    self.timerCheck = [NSTimer scheduledTimerWithTimeInterval:_overRecvDataTime target:self selector:@selector(recvDataCheckStatus) userInfo:nil repeats:YES];
}

- (void)stopCheckRecvTimer
{
    if (!_timerCheck)
        return;

    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(stopCheckRecvTimer) withObject:nil waitUntilDone:YES];
        return;
    }
    if (_timerCheck) {
        [_timerCheck invalidate];
        self.timerCheck = nil;
    }
}

- (void)recvDataCheckStatus
{
    if (!bConnectSuccess|| !_preRecvDate ) {
        return;
    }
    
    NSDate *nowDate = [NSDate date];
    NSTimeInterval diffSeconds = [nowDate timeIntervalSinceDate:self.preRecvDate];
    if (diffSeconds > _overRecvDataTime)
    {
        if (!_recvOverTime) {
            _recvOverTime = YES;
            [self callBackRecvDataTime];
        }
    }
    else if (_recvOverTime)
    {
        _recvOverTime = NO;
        [self callBackRecvDataTime];
    }
}

- (void)callBackRecvDataTime
{
    if (_delegate && [_delegate respondsToSelector:@selector(onRecvOverRecvTime:client:)]) {
        [_delegate onRecvOverRecvTime:_recvOverTime client:self];
    }
}

@end
