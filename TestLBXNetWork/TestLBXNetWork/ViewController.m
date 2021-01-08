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
#import <AFNetworking.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

//    [self testGet];
   
//    [self testChainNum];
    
//    [self testPost];

//    [self testDelete];
    
//    [self testPut];
    
    [self testFormData];

   
}

- (void)testFormData
{
    UIImage *image = [UIImage imageNamed:@"guide1"];
    NSData *imageData =  UIImageJPEGRepresentation(image, 0.3);

    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = 100;
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"text/html",@"application/json", @"text/json" ,@"text/javascript", nil];
    
    //除文件外的参数
    NSDictionary *dic = @{@"key1":@"val1",@"key2":@"val2"};
    
    [manager POST:@"http://192.168.0.102:8092/req/upImg" parameters:dic headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        
        /*
         appendPartWithFileData  设置文件参数，其中name字段某个文件组，例如下面调用的2次，name参数一致，服务器收到内容是这样的
         keyName1: [
            {
              fieldName: 'keyName1',
              originalFilename: '1.jpg',
              path: 'public/images/53-JLQAozSBwdeKBunp6nZoA.jpg',//这个服务器自己生成的存储路径
              headers: [Object],
              size: 81900
            },
            {
              fieldName: 'keyName1',
              originalFilename: '2.jpg',
              path: 'public/images/5MBaa9kWuvBLJ7X_pnuAm0xw.jpg',
              headers: [Object],
              size: 81900
            }

         */
        [formData appendPartWithFileData:imageData
                                    name:@"keyName1"
                                fileName:@"1.jpg"
                                mimeType:@"image/jpeg"];
        
        [formData appendPartWithFileData:imageData
                                    name:@"keyName1"
                                fileName:@"2.jpg"
                                mimeType:@"image/jpeg"];
        
        
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSLog(@"success:%@",responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"%@",error);
    }];

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
            NSLog(@"headers:%@",response.headers);
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
