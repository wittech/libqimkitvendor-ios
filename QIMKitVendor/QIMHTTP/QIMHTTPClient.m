//
//  QIMHTTPClient.m
//  QIMKitVendor
//
//  Created by 李露 on 2018/8/2.
//  Copyright © 2018年 QIM. All rights reserved.
//

#import "QIMHTTPClient.h"
#import "QIMHTTPResponse.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "QIMJSONSerializer.h"
#import "QIMWatchDog.h"
#import "QIMPublicRedefineHeader.h"
#import "QIMHttpRequestManager.h"
#import "QIMHttpRequestConfig.h"
static NSString *baseUrl = nil;

@implementation QIMHTTPClient

+ (NSString *)baseUrl {
    return baseUrl;
}

+ (void)configBaseUrl:(NSString *)httpBaseurl {
    if (httpBaseurl.length > 0) {
        baseUrl = httpBaseurl;
    }
}

+ (void)sendRequestWithUrl:(NSString * _Nonnull)url requesetMethod:(QIMHTTPMethod)method requestBody:(id)httpBody requestHeaders:(NSDictionary <NSString *, NSString *> *)httpHeaders complete:(QIMCompleteHandler)completeHandler failure:(QIMFailureHandler)failureHandler {
    
}

+ (void)sendRequest:(QIMHTTPRequest *)request complete:(QIMCompleteHandler)completeHandler failure:(QIMFailureHandler)failureHandler {
    if (request.uploadComponents.count > 0 || request.postParams || request.HTTPBody) {
        request.HTTPMethod = QIMHTTPMethodPOST;
    }
    if (request.HTTPMethod == QIMHTTPMethodGET) {
        [QIMHTTPClient getMethodRequest:request complete:completeHandler failure:failureHandler];
//        [QIMHTTPClient postAFMethodRequest:request complete:completeHandler failure:failureHandler];
    } else if (request.HTTPMethod == QIMHTTPMethodPOST) {
//         [QIMHTTPClient postAFMethodRequest:request complete:completeHandler failure:failureHandler];
        [QIMHTTPClient postMethodRequest:request complete:completeHandler failure:failureHandler];
    } else {
        
    }
}

+ (void)getMethodRequest:(QIMHTTPRequest *)request
           progressBlock:(QIMProgressHandler)progreeBlock
                complete:(QIMCompleteHandler)completeHandler
                 failure:(QIMFailureHandler)failureHandler {
    ASIHTTPRequest *asiRequest = [ASIHTTPRequest requestWithURL:request.url];
    [asiRequest setRequestMethod:@"GET"];
    [self configureASIRequest:asiRequest QIMHTTPRequest:request progressBlock:progreeBlock complete:completeHandler failure:failureHandler];
    if (request.shouldASynchronous) {
        [asiRequest startAsynchronous];
    } else {
        [asiRequest startSynchronous];
    }
}

+ (void)postMethodRequest:(QIMHTTPRequest *)request
            progressBlock:(QIMProgressHandler)progreeBlock
                 complete:(QIMCompleteHandler)completeHandler
                  failure:(QIMFailureHandler)failureHandler {
    ASIFormDataRequest *asiRequest = [ASIFormDataRequest requestWithURL:request.url];
    [asiRequest setRequestMethod:@"POST"];
    if (request.postParams) {
        for (id key in request.postParams) {
            [asiRequest setPostValue:request.postParams[key] forKey:key];
        }
    } else {
        if (request.HTTPBody) {
            id bodyStr = [[QIMJSONSerializer sharedInstance] deserializeObject:request.HTTPBody error:nil];
            QIMVerboseLog(@"QIMHTTPRequest请求Url : %@, Body :%@,", request.url, bodyStr);
            [asiRequest setPostBody:[NSMutableData dataWithData:request.HTTPBody]];
        }
    }
    if (request.uploadComponents) {
        for (NSInteger i = 0; i < request.uploadComponents.count; i++) {
            QIMHTTPUploadComponent *component = request.uploadComponents[i];
            if (component.filePath) {
                [asiRequest addFile:component.filePath withFileName:component.fileName andContentType:component.mimeType forKey:component.dataKey];
            } else if (component.fileData) {
                [asiRequest addData:component.fileData withFileName:component.fileName andContentType:component.mimeType forKey:component.dataKey];
            }
            NSDictionary *uploadBodyDic = component.bodyDic;
            for (NSString *uploadBodyKey in component.bodyDic.allKeys) {
                [asiRequest addPostValue:[uploadBodyDic objectForKey:uploadBodyKey] forKey:uploadBodyKey];
            }
        }
    }
    [self configureASIRequest:asiRequest QIMHTTPRequest:request progressBlock:progreeBlock complete:completeHandler failure:failureHandler];
    QIMVerboseLog(@"startSynchronous获取当前线程1 :%@, %@",dispatch_get_current_queue(),  request.url);
    CFAbsoluteTime startTime = [[QIMWatchDog sharedInstance] startTime];
    if (request.shouldASynchronous) {
        [asiRequest startAsynchronous];
    } else {
        [asiRequest startSynchronous];
    }
    QIMVerboseLog(@"startSynchronous获取当前线程2 :%@,  %@, %lf", dispatch_get_current_queue(), request.url, [[QIMWatchDog sharedInstance] escapedTimewithStartTime:startTime]);
}

+ (void)configureASIRequest:(ASIHTTPRequest *)asiRequest
              QIMHTTPRequest:(QIMHTTPRequest *)request
              progressBlock:(QIMProgressHandler)progreeBlock
                   complete:(QIMCompleteHandler)completeHandler
                    failure:(QIMFailureHandler)failureHandler {
    [asiRequest setNumberOfTimesToRetryOnTimeout:2];
    [asiRequest setValidatesSecureCertificate:asiRequest.validatesSecureCertificate];
    [asiRequest setTimeOutSeconds:request.timeoutInterval];
    [asiRequest setAllowResumeForFileDownloads:YES];
    if (request.HTTPRequestHeaders) {
        [asiRequest setUseCookiePersistence:NO];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:request.HTTPRequestHeaders];
        [asiRequest setRequestHeaders:dict];
    } else {
        //默认加载Cookie
        [asiRequest setUseCookiePersistence:YES];
    }
    if (request.downloadDestinationPath) { //有下载路径时，认为是下载
        [asiRequest setDownloadDestinationPath:request.downloadDestinationPath];
        [asiRequest setTemporaryFileDownloadPath:request.downloadTemporaryPath];
    }
    __weak typeof(asiRequest) weakAsiRequest = asiRequest;
    asiRequest.completionBlock = ^{
        __strong typeof(weakAsiRequest) strongAsiRequest = weakAsiRequest;
        QIMHTTPResponse *response = [QIMHTTPResponse new];
        response.code = strongAsiRequest.responseStatusCode;
        response.data = strongAsiRequest.responseData;
        response.responseString = strongAsiRequest.responseString;
        QIMVerboseLog(@"【RequestUrl : %@\n RequestHeader : %@\n Response : %@\n", weakAsiRequest.url, weakAsiRequest.requestHeaders, response);
        if (completeHandler) {
            completeHandler(response);
        }
    };
    [asiRequest setFailedBlock:^{
        __strong typeof(weakAsiRequest) strongAsiRequest = weakAsiRequest;
        if (failureHandler) {
            QIMVerboseLog(@"Error : %@", strongAsiRequest.error);
            failureHandler(strongAsiRequest.error);
        }
    }];
    __block long long receiveSize = 0;
    [asiRequest setBytesSentBlock:^(unsigned long long size, unsigned long long total) {
        receiveSize += size;
        float progress = (float)receiveSize/total;
        QIMVerboseLog(@"sent progressValue22 : %lf", progress);
        if (progreeBlock) {
            progreeBlock(progress);
        }
    }];
    [asiRequest setBytesReceivedBlock:^(unsigned long long size, unsigned long long total) {
        receiveSize += size;
        float progress = (float)receiveSize/total;
        QIMVerboseLog(@"download progressValue : %lf", progress);
        if (progreeBlock) {
            progreeBlock(progress);
        }
    }];
}


+ (void)postAFMethodRequest:(QIMHTTPRequest *)request
                         complete:(QIMCompleteHandler)completeHandler
                          failure:(QIMFailureHandler)failureHandler
{

    [[QIMHttpRequestManager sharedManger] sendRequest:^(QIMHTTPRequest * _Nonnull qtRequest) {
        qtRequest.url = request.url;
        qtRequest.httpRequestType = request.httpRequestType;
        qtRequest.HTTPMethod = request.HTTPMethod;
        qtRequest.timeoutInterval = 60;
        qtRequest.downloadDestinationPath = request.downloadDestinationPath;
        qtRequest.HTTPRequestHeaders = request.HTTPRequestHeaders;
        qtRequest.uploadComponents = request.uploadComponents;
        qtRequest.retryCount = request.retryCount;
        qtRequest.userInfo = request.userInfo;
        qtRequest.uploadComponents = request.uploadComponents;
        qtRequest.requestSerializer = request.requestSerializer;
        qtRequest.responseSerializer = request.responseSerializer;
        if (request.HTTPBody) {
            qtRequest.postParams = [[QIMJSONSerializer sharedInstance] deserializeObject:request.HTTPBody error:nil];
        }
        else{
            qtRequest.postParams = request.postParams;
        }
    } successBlock:^(id  _Nullable responseObjcet) {
        NSLog(@"AFNetWorkingRebuid:%@",responseObjcet);
        QIMHTTPResponse * response = [[QIMHTTPResponse alloc]init];
        if ([responseObjcet isKindOfClass:[NSDictionary class]]) {
            NSDictionary * dic = [responseObjcet copy];
            if ([dic objectForKey:@"StatusCode"]) {
                NSNumber * statusCode = dic[@"StatusCode"];
                response.code = statusCode.integerValue;
            }
        }
        NSData * data = [[QIMJSONSerializer sharedInstance] serializeObject:responseObjcet error:nil];
        response.data = data;
        response.responseString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
        QIMVerboseLog(@"【RequestUrl : %@\n RequestHeader : %@\n Response : %@\n", request.url.absoluteString, request.HTTPRequestHeaders, response);
        if (completeHandler) {
            completeHandler(response);
        }
    } failureBlock:^(NSError *error) {
        if (failureHandler) {
            NSLog(@"AFNetWorkingError:%@",error);
            QIMVerboseLog(@"Error : %@",error);
            failureHandler(error);
        }
    }];
}

+ (void)sendRequest:(QIMHTTPRequest *)request success:(QIMSuccessHandler)successHandler failure:(QIMFailureHandler)failureHandler{

    [[QIMHttpRequestManager sharedManger] sendRequest:^(QIMHTTPRequest * _Nonnull qtRequest) {
        qtRequest.url = request.url;
        qtRequest.httpRequestType = request.httpRequestType;
        qtRequest.HTTPMethod = request.HTTPMethod;
        qtRequest.timeoutInterval = 60;
        qtRequest.downloadDestinationPath = request.downloadDestinationPath;
        qtRequest.HTTPRequestHeaders = request.HTTPRequestHeaders;
        qtRequest.uploadComponents = request.uploadComponents;
        qtRequest.retryCount = request.retryCount;
        qtRequest.userInfo = request.userInfo;
        qtRequest.uploadComponents = request.uploadComponents;
        qtRequest.requestSerializer = request.requestSerializer;
        qtRequest.responseSerializer = request.responseSerializer;
    } successBlock:^(id  _Nullable responseObjcet) {
        QIMVerboseLog(@"【RequestUrl : %@\n RequestHeader : %@\n Response : %@\n", request.url.absoluteString, request.HTTPRequestHeaders, responseObjcet);
        if (successHandler) {
            successHandler(responseObjcet);
        }
    } failureBlock:^(NSError *error) {
        if (failureHandler) {
            NSLog(@"AFNetWorkingError:%@",error);
            QIMVerboseLog(@"Error : %@",error);
            failureHandler(error);
        }
    }];
}


+ (void)setCommonRequestConfig:(void (^)(QIMHttpRequestConfig *))configBlock{
    [[QIMHttpRequestManager sharedManger] setQIMHttpRequestConfig:configBlock];
}

//+(void)load{
//    //for test
//    QIMHTTPRequest * request = [[QIMHTTPRequest alloc]init];
//    request.url = [NSURL URLWithString:@"http://www.baidu.com"];
//    request.httpRequestType = QIMHTTPRequestTypeNormal;
//    request.requestSerializer = QIMHttpRequestSerializerHTTP;
//    request.responseSerializer = QIMHttpResponseSerializerHTTP;
//    request.HTTPMethod = QIMHTTPMethodGET;
//    request.timeoutInterval = 10;
//    [QIMHTTPClient postAFMethodRequest:request complete:^(QIMHTTPResponse * _Nullable response) {
//
//    } failure:^(NSError *error) {
//
//    }];
//}
@end
