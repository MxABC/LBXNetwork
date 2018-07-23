//
//  AppDelegate.m
//  TestLBXNetWork
//
//  Created by lbxia on 2018/5/28.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import "AppDelegate.h"
//包含头文件
#import <netdb.h>
#import <sys/socket.h>
#import <arpa/inet.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
//    [[self class]getIpByHostName:@"www.baidu.com"];
    
//    [[self class]getIpByHostName:@"https://tcc.taobao.com/"];
    
//    [[self class]getIpByHostName:@"www.taobao.com"];
    
    
//     [[self class]getIpByHostName:@"www.handkoo.com"];
    
    
    union {
        char str[4];
        uint32_t num;
    }un;
    
    uint32_t num = 42;
    num = htonl(num);
    
    un.num = num;

    num = ntohl(num);
    
    
    union {
        char str[4];
        uint32_t num;
    }un1;
    
    memset(un1.str, 0, 4);
    memcpy(un1.str + 1, un.str+1, 3);
    
    num = ntohl(un1.num);
    
//    uint32_t numNew = 0;
//    memcpy(&numNew, un.str+1, 3);
    
//    numNew = ntohl(numNew);
    
    NSLog(@"");
    
    NSInteger i = pow(2, 24);
    
//    {
//        union {
//            char str[4];
//            uint32_t num;
//        }un;
//            un.num = htonl(data.length);
//        fwrite(un.str, 3, 1, recordFile);
//    }

    
    return YES;
}

+(NSString*)getIpByHostName:(NSString*)strHostName {
    struct hostent* phot = nil;
    @try {
        phot = gethostbyname(strHostName.UTF8String);
        if(phot == nil)
            NSLog(@"getIpByHostName %@ = nil", strHostName);
    }
    @catch (NSException *exception) {
        NSArray *stack = [exception callStackSymbols]; // 异常的堆栈信息
        NSString *reason = [exception reason]; // 出现异常的原因
        NSString *name = [exception name]; // 异常名称
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


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
