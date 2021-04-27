//
// LBXNetWorkMonitor.h
// LBXNetWork
//
// Created by lbxia on 2021/4/27
//
//
    

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, LBXNetWorkStatus) {
    LBXNetWorkStatusNotReachable = 0,
    LBXNetWorkStatusUnknown      = 1,
    LBXNetWorkStatusWWAN2G       = 2,
    LBXNetWorkStatusWWAN3G       = 3,
    LBXNetWorkStatusWWAN4G       = 4,
    LBXNetWorkStatusWWAN5G       = 5,
    LBXNetWorkStatusWiFi         = 10,
};


@interface LBXNetWorkMonitor : NSObject

@property (nonatomic, assign) LBXNetWorkStatus status;
@property (nonatomic,readonly,class) NSString *netWorkChangeNotification;

+ (instancetype)sharedManager;
/// 获取本机IP
/// @param preferIPv4 preferIPv4 YES 优先返回IPv4
+ (NSString *)iPAddress:(BOOL)preferIPv4;
//本机IP相关信息
+ (NSDictionary *)iPAddresses;

- (LBXNetWorkStatus)currentReachabilityStatus;


/// 开始监听
/// @param hostName hostName 尝试连接的host 常用 @"www.baidu.com"
- (BOOL)startNotifierWithHostName:(NSString*)hostName;
//默认 www.baidu.com
- (BOOL)startNotifier;
- (void)stopNotifier;
@end


