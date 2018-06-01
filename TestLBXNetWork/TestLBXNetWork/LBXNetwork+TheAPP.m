//
//  LBXNetwork+TheAPP.m
//  TestLBXNetWork
//
//  Created by lbxia on 2018/5/29.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import "LBXNetwork+TheAPP.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <LBXAlertAction.h>
#import "APPGlobal.h"
#import <AFSecurityPolicy.h>
#import <UIView+Toast.h>

@implementation LBXNetwork (TheAPP)

+ (LBXHttpRequest*)HttpWithHud:(BOOL)hud
                         token:(BOOL)token
                  requestBlock:(void(^)(LBXHttpRequest *request))requestBlock
                   complection:(void(^)(LBXHttpResponse*  response))completion
{
    __weak UIView *hudView = nil;
    if (hud) {
        //显示网络请求hud，也可以自定义请求hud
        hudView = [self showhud];
    }
    
    LBXHttpRequest *request = [LBXNetwork HttpWithRequestBlock:^(LBXHttpRequest * _Nonnull request) {
        
        //block回调，让调用者填充相关请求信息，block内不需要使用weakSelf,这里是使用完block马上就释放了
        
        //设置当前APP常用参数
        request.cacheEnable = YES;
        request.timeoutInterval = 6;
        
        //回调给具体业务，再进一步设置相关参数
        requestBlock(request);
        
        //假设这里上传参数都是JSON形式
        if (token)
        {
            //上传参数需要http连接token认证
            NSMutableDictionary *muDic = request.requestParameters ?  [NSMutableDictionary dictionaryWithDictionary:request.requestParameters] : [NSMutableDictionary dictionary];
            
            [muDic  setObject:[APPGlobal sharedManager].token forKey:@"token"];
            
            request.requestParameters = muDic;
        }
        
        //设置当前APP 安全策略
        //request.securityPolicy = [self securityPolicy];

        
    } complection:^(LBXHttpResponse * _Nonnull response) {
        
        if (hudView) {
            [self hiddHudWithView:hudView];
        }
        
        response.needHandle = YES;
        
        if (response.success) {
            
            //解析返回的数据,200为成功，否则表示请求失败
            NSInteger respCode = 200;
            //返回状态信息
            NSString *respMessage = @"respMessage";
            
            //业务上失败，或者其他具体处理方式，如需要判断未登录或账号其他设备登录具体业务状态
            if (respCode != 200 && response.request.errAutoHandle) {
                
                response.needHandle = NO;
                //弹出toast提示
                [self showToastWithMessage:respMessage];
            }
        }
        else
        {
            //用户主动取消请求
            if (response.error.code == NSURLErrorCancelled) {
                NSLog(@"user canceled");
                
                response.needHandle = NO;
            }
            //请求接口失败，未连接上，或网络库底层解析出现问题
            else if (response.request.errAutoHandle)
            {
                response.needHandle = NO;
                
                if (response.error.code == NSURLErrorTimedOut)
                {
                    [self showToastWithMessage:@"接口连接超时"];
                }
                else
                {
                    [self showToastWithMessage:@"网络连接失败"];
                }
            }
        }
        
        if (completion) {
            completion(response);
        }
    }];
    
    return request;
}

#pragma mark- 加载证书
+ (AFSecurityPolicy *)securityPolicy
{
    static AFSecurityPolicy *policy = nil;
    
    if (!policy) {
        //加载证书
        NSString * cerPath = [[NSBundle mainBundle] pathForResource:@"app" ofType:@"cer"];
        NSData * cerData = [NSData dataWithContentsOfFile:cerPath];
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:[[NSSet alloc] initWithObjects:cerData, nil]];
        securityPolicy.allowInvalidCertificates = YES;
        [securityPolicy setValidatesDomainName:NO];

        policy = securityPolicy;
    }
    
    return policy;
}

#pragma mark- toast
+ (void)showToastWithMessage:(NSString*)message
{
    if (message == nil) {
        message = @"";
    }
    //tip
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    [window makeToast:message
             duration:2
             position:CSToastPositionCenter];
}

+ (void)showErrorToast:(NSError*)err
{
    if (err && err.userInfo && err.userInfo[@"respMsg"] ) {
        
        [self showToastWithMessage:err.userInfo[@"respMsg"]];
    }
}

#pragma mark- hud

+ (UIView*)showhud
{
    UIView *hudView = nil;
    UIViewController *vc = [self currentTopViewController];
    if (vc) {
        hudView = vc.view;
        [MBProgressHUD hideHUDForView:hudView animated:NO];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:hudView animated:YES];
        hud.label.text = @"loading";
        hud.animationType=MBProgressHUDAnimationFade;
        
        
        [hud showAnimated:YES];
        
        hud.bezelView.backgroundColor = [UIColor blackColor];
        
        hud.label.textColor = [UIColor whiteColor];
        
        hud.activityIndicatorColor = [UIColor whiteColor];

    }
    return hudView;
}

+ (void)hiddHudWithView:(UIView*)view
{
    if (view){
        [MBProgressHUD hideHUDForView:view animated:YES];
    }
}


+ (UIViewController*)topRootController
{
    UIViewController *topController = [[UIApplication sharedApplication].delegate.window rootViewController];
    
    //  Getting topMost ViewController
    while ([topController presentedViewController])
        topController = [topController presentedViewController];
    
    //  Returning topMost ViewController
    return topController;
}

+ (UIViewController*)presentedWithController:(UIViewController*)vc
{
    while ([vc presentedViewController])
        vc = vc.presentedViewController;
    return vc;
}


+ (UIViewController*)currentTopViewController
{
    UIViewController *currentViewController = [self topRootController];
    
    if ([currentViewController isKindOfClass:[UITabBarController class]]
        && ((UITabBarController*)currentViewController).selectedViewController != nil )
    {
        currentViewController = ((UITabBarController*)currentViewController).selectedViewController;
    }
    
    currentViewController = [self presentedWithController:currentViewController];
    
    while ([currentViewController isKindOfClass:[UINavigationController class]]
           && [(UINavigationController*)currentViewController topViewController])
    {
        currentViewController = [(UINavigationController*)currentViewController topViewController];
        currentViewController = [self presentedWithController:currentViewController];
        
    }
    
    
    currentViewController = [self presentedWithController:currentViewController];
    
    
    return currentViewController;
}

@end
