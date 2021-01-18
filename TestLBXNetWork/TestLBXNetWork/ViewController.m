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

- (NSString*)documentDir
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths lastObject];
    return docDir;
}

- (void)testFormData
{
    UIImage *image = [UIImage imageNamed:@"guide1"];
    NSData *imageData =  UIImageJPEGRepresentation(image, 0.3);
    
    NSString* filePath = [[self documentDir]stringByAppendingPathComponent:@"1.jpg"];
    [imageData writeToFile:filePath atomically:YES];
    
    LBXHttpRequest *request = [[LBXHttpRequest alloc]init];
    request.requestUrl = @"http://192.168.1.195:8080/api/medicalaid/business/image/uploadImageData";
    
    //除文件外的参数
    NSDictionary *dic = @{@"injuryNo":@"ios112",@"userCode":@"iosUserCode1"
                          ,@"loanApplyNo":@"iosLoanAppNo",@"policyNo":@"ios",
                          @"picType":@"12"
    };
    request.requestParameters = dic;
    
    
//    NSArray* array = @[@{@"fileData":imageData,@"name":@"file",@"fileName":@"1.jpg",@"mimeType":@"image/jpeg"}];
    
    NSArray* array = @[@{@"filePath":filePath,@"name":@"file",@"fileName":@"1.jpg",@"mimeType":@"image/jpeg"}];

    
    request.requestElseParameters = array;
    
    request.responseAcceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"text/html",@"application/json", @"text/json" ,@"text/javascript", nil];
    
    [LBXNetwork PostFormWithRequest:request progress:nil complection:^(LBXHttpResponse * _Nonnull response) {
        
        if (response.success) {
         
            
            NSDictionary *dictFromData = [NSJSONSerialization JSONObjectWithData:response.responseObject
                                                                       options:NSJSONReadingAllowFragments
                                                                           error:nil];
            
            NSLog(@"%@",dictFromData);
            
        }
        else if(response.error)
        {
            NSLog(@"error:%@",response.error);
        }
        
      
    }];
}

- (void)testFormData2
{
    UIImage *image = [UIImage imageNamed:@"guide1"];
    NSData *imageData =  UIImageJPEGRepresentation(image, 0.3);
    
    NSString* filePath = [[self documentDir]stringByAppendingPathComponent:@"1.jpg"];
    [imageData writeToFile:filePath atomically:YES];
    

    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = 100;
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"text/html",@"application/json", @"text/json" ,@"text/javascript", nil];
    
    //除文件外的参数
    NSDictionary *dic = @{@"injuryNo":@"ios11",@"userCode":@"iosUserCode"
                          ,@"loanApplyNo":@"iosLoanAppNo",@"policyNo":@"ios",
                          @"picType":@"11"
    };
    
    [manager POST:@"http://192.168.1.195:8080/api/medicalaid/business/image/uploadImageData" parameters:dic headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        [formData appendPartWithFileData:imageData
                                    name:@"file"
                                fileName:@"1.jpg"
                                mimeType:@"image/jpeg"];
//
        
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:filePath] name:@"file" fileName:@"1.jpg" mimeType:@"image/jpeg" error:nil];
        
        
//        - (BOOL)appendPartWithFileURL:(NSURL *)fileURL
//                                 name:(NSString *)name
//                             fileName:(NSString *)fileName
//                             mimeType:(NSString *)mimeType
//                                error:(NSError * _Nullable __autoreleasing *)error;
        
//        [formData appendPartWithFormData:imageData name:@"file"];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
     
        NSLog(@"progress：%f,finish:%d",uploadProgress.fractionCompleted,uploadProgress.isFinished);
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSLog(@"success:%@",responseObject);
        
        NSDictionary *dictFromData = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                   options:NSJSONReadingAllowFragments
                                                                       error:nil];
        
        NSLog(@"%@",dictFromData);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"%@",error);
    }];

}





/// 表单上传文件
/// @param URLString 接口地址
/// @param parameters 参数
/// @param headers headers
/// @param fileParameters 文件参数
/// @param uploadProgress 上传进度
/// @param success 接口调用成功结果返回
/// @param failure 接口调用失败
- (NSURLSessionDataTask*)PostFormData:(NSString *)URLString
          parameters:(nullable id)parameters
             headers:(nullable NSDictionary<NSString *,NSString *> *)headers
      fileParameters:(NSArray<NSDictionary*>*)fileParameters
            progress:(nullable void (^)(double progress))uploadProgress
             success:(nullable void (^)(id _Nullable))success
             failure:(void (^)(NSError * _Nonnull))failure
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = 100;
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"text/html",@"application/json", @"text/json" ,@"text/javascript", nil];
    

    void (^onProgress)(NSProgress * _Nonnull uploadProgress) = nil;
    
    if (uploadProgress) {
        
        onProgress = ^(NSProgress * _Nonnull progress)
        {
            uploadProgress(progress.fractionCompleted);
        };
    }
    
    return [manager POST:URLString parameters:parameters headers:headers constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {

        for (int i = 0; i < fileParameters.count; i++) {
            NSDictionary *dic = fileParameters[i];
            //下面2个参数有一个即可
            NSData *fileData = dic[@"fileData"];
            NSString *filePath = dic[@"filePath"];
            
            NSString *name = dic[@"name"];
            NSString *fileName = dic[@"fileName"];
            NSString * mimeType = dic[@"mimeType"];
            
            if (fileData) {
                [formData appendPartWithFileData:fileData
                                            name:name
                                        fileName:fileName
                                        mimeType:mimeType];
            }
            else if(filePath)
            {
                NSError *error = nil;
                [formData appendPartWithFileURL:[NSURL fileURLWithPath:filePath] name:name fileName:fileName mimeType:mimeType error:&error];
                
                if (error && failure) {
                    failure(error);
                }
            }
        }
        
    } progress:onProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (success) {
            success(responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (failure) {
            failure(error);
        }
    }];
    
}

- (void)testFormData1
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
