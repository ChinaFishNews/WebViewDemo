//
//  NSHTTPCookie+Utils.m
//  WebViewDemo
//
//  Created by Mac Air on 2018/9/27.
//  Copyright © 2018年 Mac Air. All rights reserved.
//

#import "NSHTTPCookie+Utils.h"

@implementation NSHTTPCookie (Utils)

- (NSString *)da_javascriptString
{
    NSString *string = [NSString stringWithFormat:@"%@=%@;domain=%@;path=%@",
                        self.name,
                        self.value,
                        self.domain,
                        self.path ?: @"/"];
    
    if (self.secure) {
        string = [string stringByAppendingString:@";secure=true"];
    }
    return string;
}
@end
