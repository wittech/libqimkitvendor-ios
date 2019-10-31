//
//  QIMHttpSerializer.m
//  QIMKitVendor
//
//  Created by qitmac000645 on 2019/6/25.
//

#import "QIMHttpSerializer.h"

@interface QIMHttpSerializer()
@property (nonatomic, strong) AFJSONRequestSerializer * jsonRequestSerializer;
@property (nonatomic, strong) AFHTTPRequestSerializer * httpRequsetSerializer;
@property (nonatomic, strong) AFPropertyListRequestSerializer * afPlistRequestSerializer;

@property (nonatomic, strong) AFJSONResponseSerializer * jsonResponseSerializer;
@property (nonatomic, strong) AFHTTPResponseSerializer * httpResponseSerializer;
@property (nonatomic, strong) AFXMLParserResponseSerializer * afXMLParserResponseSerializer;
@property (nonatomic, strong) AFPropertyListResponseSerializer * afPlistResponseSerializer;
@end

@implementation QIMHttpSerializer

-(id<AFURLRequestSerialization>)requestSeialization:(QIMHttpRequestSerializer)requestSerializer{
    switch (requestSerializer) {
        case QIMHttpRequestSerializerHTTP:
            return self.httpRequsetSerializer;
            break;
            case QIMHttpRequestSerializerJSON:
            return self.jsonRequestSerializer;
            break;
            case QIMHttpRequestSerializerPLIST:
            return self.afPlistRequestSerializer;
        default:
            return nil;
            break;
    }
}

-(id<AFURLResponseSerialization>)responseSeialization:(QIMHttpResponseSerializer)responseSerializer{
    switch (responseSerializer) {
        case QIMHttpResponseSerializerHTTP:
            return self.httpResponseSerializer;
            break;
            case QIMHttpResponseSerializerJSON:
            return self.jsonResponseSerializer;
            break;
            case QIMHttpResponseSerializerXML:
            return self.afXMLParserResponseSerializer;
            break;
            case QIMHttpResponseSerializerPLIST:
            return self.afPlistResponseSerializer;
            break;
        default:
            break;
    }
}

-(AFHTTPRequestSerializer *)httpRequsetSerializer{
    if (!_httpRequsetSerializer) {
        _httpRequsetSerializer = [AFHTTPRequestSerializer serializer];
    }
    return _httpRequsetSerializer;
}

-(AFJSONRequestSerializer *)jsonRequestSerializer{
    if (!_jsonRequestSerializer) {
        _jsonRequestSerializer = [AFJSONRequestSerializer serializer];
    }
    return _jsonRequestSerializer;
}

-(AFPropertyListRequestSerializer *)afPlistRequestSerializer{
    if (!_afPlistRequestSerializer) {
        _afPlistRequestSerializer = [AFPropertyListRequestSerializer serializer];
    }
    return _afPlistRequestSerializer;
}

-(AFHTTPResponseSerializer *)httpResponseSerializer{
    if (!_httpResponseSerializer) {
        _httpResponseSerializer = [AFHTTPResponseSerializer serializer];
        _httpResponseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/plain", nil];
    }
    return _httpResponseSerializer;
}

-(AFJSONResponseSerializer *)jsonResponseSerializer{
    if (!_jsonResponseSerializer) {
        _jsonResponseSerializer = [AFJSONResponseSerializer serializer];
        _jsonResponseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/plain", nil];
    }
    return _jsonResponseSerializer;
}

-(AFXMLParserResponseSerializer *)afXMLParserResponseSerializer
{
    if (!_afXMLParserResponseSerializer) {
        _afXMLParserResponseSerializer = [AFXMLParserResponseSerializer serializer];
        _afXMLParserResponseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/plain", nil];
    }
    return _afXMLParserResponseSerializer;
}

-(AFPropertyListResponseSerializer *)afPlistResponseSerializer{
    if (!_afPlistResponseSerializer) {
        _afPlistResponseSerializer = [AFPropertyListResponseSerializer serializer];
        _afPlistResponseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/plain", nil];
    }
    return _afPlistResponseSerializer;
}
@end
