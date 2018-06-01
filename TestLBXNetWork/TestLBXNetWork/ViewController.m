//
//  ViewController.m
//  TestLBXNetWork
//
//  Created by lbxia on 2018/5/28.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import "ViewController.h"

#import <LBXNetwork.h>
#import "LBXNetwork+TheAPP.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self testGet];
   
//    [self testChainNum];
    
//    [self testPost];

//    [self testDelete];
    
//    [self testPut];

   
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

}

- (void)testGet
{
   [LBXNetwork HttpWithRequestBlock:^(LBXHttpRequest * request) {
        
       request.responseSerializerType = LBXHTTPSerializerTypeRAW;
       request.httpMethod = LBXHTTPMethodTypeGET;
       request.responseAcceptableContentTypes = [NSSet setWithObjects:@"text/html",@"application/javascript",nil];
       
       request.server = @"https://tcc.taobao.com/";
       request.api = @"cc/json/mobile_tel_segment.htm";
       //        request.requestUrl = @"https://tcc.taobao.com/cc/json/mobile_tel_segment.htm";
       
       
        request.requestParameters = @{@"tel":@"15852509988"};
        
    } complection:^(LBXHttpResponse * _Nonnull response) {
        NSLog(@"response");
        
        if (response.success && response.responseObject) {
            
            NSString *str = [[NSString alloc]initWithData:response.responseObject encoding:NSASCIIStringEncoding];
            
            NSLog(@"%@",str);
        }
        else if (response.error)
        {
            NSLog(@"error:%@",response.error);
            //用户主动取消请求
            if (response.error.code == NSURLErrorCancelled) {
                NSLog(@"user canceled");
            }
        }
    }];
}

- (void)testCacelGet
{
    LBXHttpRequest *request = [LBXNetwork HttpWithRequestBlock:^(LBXHttpRequest * request) {
        
        request.responseSerializerType = LBXHTTPSerializerTypeRAW;
        request.httpMethod = LBXHTTPMethodTypeGET;
        request.responseAcceptableContentTypes = [NSSet setWithObjects:@"text/html",@"application/javascript",nil];
        
        request.server = @"https://tcc.taobao.com/";
        request.api = @"cc/json/mobile_tel_segment.htm";
        //        request.requestUrl = @"https://tcc.taobao.com/cc/json/mobile_tel_segment.htm";
        
        
        request.requestParameters = @{@"tel":@"15852509988"};
        
    } complection:^(LBXHttpResponse * _Nonnull response) {
        NSLog(@"response");
        
        if (response.success && response.responseObject) {
            
            NSString *str = [[NSString alloc]initWithData:response.responseObject encoding:NSASCIIStringEncoding];
            
            NSLog(@"%@",str);
        }
        else if (response.error)
        {
            NSLog(@"error:%@",response.error);
            //用户主动取消请求
            if (response.error.code == NSURLErrorCancelled) {
                NSLog(@"user canceled");
            }
        }
    }];
    
    [LBXNetwork cancelWithRequest:request];
    
}

- (void)testChainNum
{
    [LBXNetwork HttpWithBatchNum:2 batchRequestBlock:^(NSArray<LBXHttpRequest *> * _Nonnull requests) {
        
        for (int i = 0; i < requests.count; i++) {
            
            LBXHttpRequest *request = requests[i];
            request.cacheEnable = YES;
            request.responseSerializerType = LBXHTTPSerializerTypeRAW;
            request.httpMethod = LBXHTTPMethodTypeGET;
            request.responseAcceptableContentTypes = [NSSet setWithObjects:@"text/html",@"application/javascript",nil];
            
            request.requestUrl = @"https://tcc.taobao.com/cc/json/mobile_tel_segment.htm";
            if (i == 0) {
                request.requestParameters = @{@"tel":@"15852509988"};
            }
            else
            {
                request.requestParameters = @{@"tel":@"15852509986"};
            }
        }
        
    } complection:^(NSArray<LBXHttpResponse *> * _Nonnull responses) {
        
        for (int i = 0; i < responses.count; i++) {
            LBXHttpResponse *response = responses[i];
            if (response.success && response.responseObject) {
                
                NSString *str = [[NSString alloc]initWithData:response.responseObject encoding:NSASCIIStringEncoding];
                
                NSLog(@"%@",str);
            }
        }
        
    }];
 
}

- (void)testPost
{
    [LBXNetwork HttpWithRequestBlock:^(LBXHttpRequest * _Nonnull request) {
        
        request.httpMethod = LBXHTTPMethodTypePOST;
        request.responseAcceptableContentTypes = [NSSet setWithObjects:@"application/json",nil];
        request.cacheEnable = YES;
        request.requestUrl = @"...";
        
    } complection:^(LBXHttpResponse * _Nonnull response) {
        
        if (response.success && response.responseObject) {
            
            NSLog(@"%@",response.responseObject);
        }
        else if (response.error)
        {
            NSLog(@"error:%@",response.error);
        }
        
    }];
}

- (void)testDelete
{
    NSDictionary *dicPara = @{@"pId":@(1),@"token":@"123"};
    
    [LBXNetwork HttpWithRequestBlock:^(LBXHttpRequest * _Nonnull request) {
        
        request.httpMethod = LBXHTTPMethodTypeDELETE;
        request.responseAcceptableContentTypes = [NSSet setWithObjects:@"application/json",nil];
        request.requestParameters = dicPara;
        request.requestUrl = @"...";
        
    } complection:^(LBXHttpResponse * _Nonnull response) {
        
        if (response.success && response.responseObject) {
            
            NSLog(@"%@",response.responseObject);
        }
        else if (response.error)
        {
            NSLog(@"error:%@",response.error);
        }
    }];
    
}

- (void)testPut
{
    NSDictionary *dicPara = @{@"pId":@(1),@"token":@"123"};
    
    [LBXNetwork HttpWithRequestBlock:^(LBXHttpRequest * _Nonnull request) {
        
        request.httpMethod = LBXHTTPMethodTypePUT;
        request.responseAcceptableContentTypes = [NSSet setWithObjects:@"application/json",nil];
        request.requestParameters = dicPara;
        request.requestUrl = @"...";
        
    } complection:^(LBXHttpResponse * _Nonnull response) {
        
        if (response.success && response.responseObject) {
            
            NSLog(@"%@",response.responseObject);
        }
        else if (response.error)
        {
            NSLog(@"error:%@",response.error);
        }
    }];
}

- (void)testAPPNet
{
    [LBXNetwork HttpWithHud:YES token:YES requestBlock:^(LBXHttpRequest *request) {
        
        request.requestSerializerType = LBXHTTPSerializerTypeJSON;
        request.responseSerializerType = LBXHTTPSerializerTypeRAW;
        request.httpMethod = LBXHTTPMethodTypeGET;
        request.responseAcceptableContentTypes = [NSSet setWithObjects:@"text/html",@"application/javascript",nil];
        
        request.requestUrl = @"https://tcc.taobao.com/cc/json/mobile_tel_segment.htm";
        request.requestParameters = @{@"tel":@"15852509988"};
        //如果报错，直接底层弹toast
        request.errAutoHandle = YES;
    
    } complection:^(LBXHttpResponse *response) {
        
        if (!response.needHandle) {
            //对下拉刷新等类似需要处理的处理一下，对接口返回数据当作失败处理，不需要弹出提示
            return;
        }
        
        //TODO:
        if (response.success && response.responseObject) {
            
            NSString *str = [[NSString alloc]initWithData:response.responseObject encoding:NSASCIIStringEncoding];
            
            NSLog(@"%@",str);
        }
        else if (response.error)
        {
            NSLog(@"error:%@",response.error);
        }
    }];
}


@end
