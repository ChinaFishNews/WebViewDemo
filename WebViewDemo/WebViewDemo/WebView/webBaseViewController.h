//
//  webBaseViewController.h
//  WebViewDemo
//
//  Created by Mac Air on 2018/9/24.
//  Copyright © 2018年 Mac Air. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import <ContactsUI/ContactsUI.h>


typedef enum : NSUInteger {
    WebLoadTypeURLString,
    WebLoadTypeHTMLString,
    WebLoadTypePOSTUrlString,
} WebLoadType;

@interface webBaseViewController : UIViewController<CNContactPickerDelegate>

@property (nonatomic, copy) NSString * URLString;// 保存的网址链接
@property (nonatomic, copy) NSString * postData;// 保存POST请求体
@property (nonatomic, assign) WebLoadType loadType;// 网页加载的类型
@property (nonatomic, copy) void(^completion)(NSString *name, NSString *phone);

- (void)selectContactCompletion:(void(^)(NSString *name, NSString *phone))completion;

/**
 加载纯外部链接网页
 
 @param string URL地址
 */
- (void)loadWebURLSring:(NSString *)string;

/**
 加载本地网页
 
 @param string 本地HTML文件名
 */
- (void)loadWebHTMLSring:(NSString *)string;

/**
 加载外部链接POST请求(注意检查 XFWKJSPOST.html 文件是否存在 )
 postData请求块 注意格式：@"\"username\":\"xxxx\",\"password\":\"xxxx\""
 
 @param string 需要POST的URL地址
 @param postData post请求块
 */
- (void)POSTWebURLSring:(NSString *)string postData:(NSString *)postData;

@end
