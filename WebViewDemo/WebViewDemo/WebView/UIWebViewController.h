//
//  UIWebViewViewController.h
//  WebViewDemo
//
//  Created by Mac Air on 2018/9/24.
//  Copyright © 2018年 Mac Air. All rights reserved.
//

/*
 总结：
 oc-->js
 1、通过调用- (nullable NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script;方法
 2、在页面加载完成后，获取JSContext上下文，通过JSContext的- (JSValue *)evaluateScript:(NSString *)script;方法得到JSValue对象，JSValue对象可转为Array、Number、String、对象等数据类型
 js-->oc
 1、拦截URL
 OC中，只要遵循了UIWebViewDelegate协议, 每次打开一个链接之前，都会触发方法
 - (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
 在该方法中，捕获该链接，并且返回NO（阻止本次跳转），从而执行对应的OC方法。
 2、self.jsContext[@"yourMethodName"] = your block;其中yourMethodName就是js的方法名称，赋给是一个block 里面是oc代码
 
 需求：
 若js需要oc传值，需js定义方法的参数需包含一个回调函数，oc这边通过属性获取到javascript的function后通过
 调用方法- (JSValue *)callWithArguments:(NSArray *)arguments;进行传值。
 
 
 */


#import "webBaseViewController.h"

@interface UIWebViewController : webBaseViewController

@end
