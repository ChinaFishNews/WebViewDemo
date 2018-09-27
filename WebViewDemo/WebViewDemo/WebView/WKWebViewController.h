//
//  WKWebViewController.h
//  WebViewDemo
//
//  Created by Mac Air on 2018/9/24.
//  Copyright © 2018年 Mac Air. All rights reserved.
//


/*
 总结：
 oc --> js
 通过调用方法：- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^ _Nullable)(_Nullable id result, NSError * _Nullable error))completionHandler;
 js --> oc
 1、URL拦截
 - (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;
 2、WKUserContentController中新增方法
 2.1、注册回调 - (void)addScriptMessageHandler:(id <WKScriptMessageHandler>)scriptMessageHandler name:(NSString *)name;
 2.2、js中调用方法 window.webkit.messageHandlers.<name>.postMessage(<messageBody>)
 2.3、oc中将会收到WKScriptMessageHandler的回调
 - (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;
 2.4、移除
 - (void)removeScriptMessageHandlerForName:(NSString *)name;
 
 
 新分享调用流程分析：
 点击之后，触发了test()函数，test()中封装了对share()函数的调用，且传了一个对象作为参数，对象中result字段对应的是个匿名函数，紧接着share()函数调用，其中的实现是2s过后，result(true);模拟js异步实现异步回调结果，分享成功。同时share()函数中，因为通过scriptMessageHandler无法传递function，所以先把shareData对象中的result这个匿名function转成String，然后替换shareData对象的result属性为这个String，并回传给OC，OC这边对应JS对象的数据类型是NSDictionary，我们打印并得到了所有参数，同时，把result字段对应的js function String取出来。这里我们延迟4s回调，模拟Native分享的异步过程，在4s后，也就是js中显示success的2s过后，调用js的匿名function，并传递参数（分享结果）。调用一个js function的方法是 functionName(argument); ，这里由于这个js的function已经是一个String了，所以我们调用时，需要加上()，如 (functionString)(argument);因此，最终我们通过OC -> JS 的evaluateJavaScript:completionHandler:方法，成功完成了异步回调，并传递给js一个分享失败的结果。
 
 上面的描述看起来很复杂，其实就是先执行了JS的默认实现，后执行了OC的实现。上面的代码展示了如何解决scriptMessageHandler的两个问题，并且实现了一个 JS -> OC、OC -> JS 完整的交互流程。
 
 
 */


#import "webBaseViewController.h"

@interface WKWebViewController : webBaseViewController

/** 是否显示Nav */
@property (nonatomic,assign) BOOL isNavHidden;


@end
