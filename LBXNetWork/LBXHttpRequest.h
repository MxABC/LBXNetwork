//
//  LBXNetworkRequest.h
//  LBXNetwork
//  https://github.com/MxABC/LBXNetwork
//  Created by lbx on 2018/2/25.
//  Copyright © 2018年 lbx. All rights reserved.
//

#import "AFNNetworkRequest.h"

///请求或返回数据形式
typedef NS_ENUM(NSInteger, LBXHTTPSerializerType) {
    LBXHTTPSerializerTypeJSON = 0,      /// JSON object
    LBXHTTPSerializerTypeRAW = 1 //NSData object,二进制数据,内部已经默认设置 Content-Type  application/x-www-form-urlencoded
};

/**
 HTTP methods 请求方法.
 */
typedef NS_ENUM(NSInteger, LBXHTTPMethodType) {
    LBXHTTPMethodTypeGET    = 0,
    LBXHTTPMethodTypePOST   = 1,
    LBXHTTPMethodTypeDELETE = 2,
    LBXHTTPMethodTypePUT    = 3
};


@interface LBXHttpRequest : AFNNetworkRequest

/**
 The server address for request, eg. "http://example.com/v1/"
 */
@property (nonatomic, copy, nullable) NSString *server;

/**
 The API interface path for request, eg. "foo/bar", `nil` by default.
 */
@property (nonatomic, copy, nullable) NSString *api;

/**
 The final URL of request, which is combined by `server` and `api` properties, eg. "http://example.com/v1/foo/bar", `nil` by default.
 NOTE: when you manually set the value for `requestUrl`, the `server` and `api` properties will be ignored.
 */
@property (nonatomic, copy, nullable) NSString *requestUrl;

///上传参数形式，默认值 LBXHTTPSerializerTypeJSON
@property (nonatomic, assign) LBXHTTPSerializerType requestSerializerType;

///返回数据类型,默认值 LBXHTTPSerializerTypeJSON
@property (nonatomic, assign) LBXHTTPSerializerType responseSerializerType;

//请求方法,GET,POST,DELETE,PUT，默认POST
@property (nonatomic, assign) LBXHTTPMethodType httpMethod;

///请求超时时间,默认10s
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

///设置http请求信息头(HTTPHeaderField)，默认为nil
@property (nonatomic, strong,nullable) NSDictionary<NSString*,NSString*> *headers;

///上传参数，类型为NSDictionary或NSData,默认nil
@property (nonatomic, strong,nullable) id requestParameters;

//其他参数，如表单使用到的文件参数
@property (nonatomic, strong,nullable) id requestElseParameters;


/**
 接收http响应数据ContentTypes
 默认值:
 [NSSet setWithObjects:@"application/json",@"text/json",@"text/javascript",@"application/javascript",@"text/html",@"text/plain",@"multipart/form-data",nil];
 */
@property (nonatomic, copy, nullable) NSSet <NSString *> *responseAcceptableContentTypes;

/**
 如果设置YES，在requestParameters赋值的时候，会打印请求数据的日志
 默认值策略：
 - debug环境：YES
 - release环境：NO
 */
@property (nonatomic) BOOL debugLogEnabled;

/**
 支持缓存，调用成功后缓存到本地，调用失败，读取缓存,默认值NO
 */
@property (nonatomic, assign) BOOL cacheEnable;

/**
 先读取缓存，不调用接口，如果没有缓存则调用接口，默认值NO
 */
@property (nonatomic, assign) BOOL cachedPrior;


/**
 报错统一处理，供上层使用，LBXNetwork没有使用该参数
 默认值NO
 
 如业务层可以添加一层，报错自动弹出toast提示错误,
 如果有报错信息，且errAutoHandle为YES，则响应返回needHandle值为NO
 */
@property (nonatomic, assign) BOOL errAutoHandle;

@end


@interface LBXHttpResponse : NSObject

/**
 LBXNetwork层没有使用该参数，上层封装时可以参考以下建议使用
 
 - 上层是否需要处理，部分业务可能底层统一处理了，如用户取消请求，业务上统一报错的toast提示等
 - 接口返回返回的地方，先判断值是否为YES，为NO一般不需要处理，其他情况：如果是下拉刷新则结束下拉刷新即可
 - 如果业务上不需要该参数，也可以忽略参数
 */
@property (nonatomic, assign,getter=isNeedHandle) BOOL needHandle;

/**
 接口是否调用成功,下面2种情况下值为YES
 - 接口调用成功，不是网络连接失败
 - 网络连接失败，但是读取缓存数据成功，cachedResponse设置为YES
 */
@property (nonatomic, assign) BOOL success;

///接口返回失败后的错误信息，如果成功则为nil,有错误信息，responseObject数据也可能读取了缓存的数据
@property (nonatomic, strong,nullable) NSError *error;

///保存的请求信息
@property (nonatomic, strong,nullable) LBXHttpRequest *request;


///返回的headers
@property (nonatomic, strong,nullable) NSDictionary *headers;

/**
 如果设置YES，在responseObject赋值的时候，会打印返回的数据的日志
 默认值策略：
 - debug环境：YES
 - release环境：NO
 */
@property (nonatomic) BOOL debugLogEnabled;

/**
 调用成功后的返回数据，接口返回或读取缓存的数据，类型为NSDictionary或NSData
 */
@property (nonatomic, strong,nullable) id responseObject;

///返回的数据是否是缓存的
@property (nonatomic, assign,getter=isCachedResponse) BOOL cachedResponse;

///返回参数，初始化默认值-1,成功请求后的值为http statuscode的值,如200,301,404,500等

/**
 http statusCode
 默认值为-1
 接口调用成功后，一般值为2xx,3xx,4xx,5xx
 */
@property (nonatomic, assign) NSInteger statusCode;

@end

