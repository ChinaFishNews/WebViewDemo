//
//  UIWebViewViewController.m
//  WebViewDemo
//
//  Created by Mac Air on 2018/9/24.
//  Copyright © 2018年 Mac Air. All rights reserved.
//

#import "UIWebViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface UIWebViewController ()<UIWebViewDelegate>

@property (nonatomic, strong) UIWebView * webView;
@property (nonatomic, strong) JSContext * jsContext;

@end

@implementation UIWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.webView];
}

#pragma mark - 加载方式
- (void)webviewLoadURLType
{
    switch (self.loadType) {
        case WebLoadTypeURLString:
        {
            //自定义cookie
            //[self UIWebViewCustomCookie];
            
            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.URLString]]];
        }
            break;
        case WebLoadTypeHTMLString:
        {
            NSString *path = [[NSBundle mainBundle] pathForResource:self.URLString ofType:@"html"];
            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
        }
            break;
        case WebLoadTypePOSTUrlString:
        {
            NSMutableURLRequest *request=[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.URLString]];
            [request setHTTPMethod:@"POST"];
            [request setHTTPBody:[self.postData dataUsingEncoding:NSUTF8StringEncoding]];
            [self.webView loadRequest:request];

        }
            break;
        default:
            break;
    }
}

#pragma mark - UIWebViewDelegate
/*
 JS调用OC
 1. Custom URL Scheme（拦截URL）
 只要遵循了UIWebViewDelegate协议，每次打开一个链接之前，都会触发方法
 - (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
 在该方法中，捕获该链接，并且返回NO（阻止本次跳转），从而执行对应的OC方法。
 
 
 优点：泛用性强，可以配合h5实现页面动态化。比如页面中一个活动链接到活动详情页，当native尚未开发完毕时，链接可以是一个h5链接，等到native开发完毕时，可以通过该方法跳转到native页面，实现页面动态化。且该方案适用于Android和iOS，泛用性很强。
 
 缺点：无法直接获取本次交互的返回值，比较适合单向传参，且不关心回调的情景，比如h5页面跳转到native页面等。
 
 
 
 */

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    //标准的URL包含scheme、host、port、path、query、fragment等
    NSURL *URL = request.URL;
    if ([URL.scheme isEqualToString:SHWebViewDemoScheme]) {
        if ([URL.host isEqualToString:SHWebViewDemoHostSmsLogin]) {
            NSLog(@"短信验证码登录，参数为 %@", URL.query); //短信验证码登录，参数为 username=syh&code=776632
            return NO;
        }
    }
    
    NSLog(@"%s, line = %d",__FUNCTION__,__LINE__);
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
     NSLog(@"%s, line = %d",__FUNCTION__,__LINE__);
   
    /*
     oc调用js：
     方法一：
     //@property (nonatomic, strong) UIWebView * webView;
     self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
     解析：
     - (nullable NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script;
     1、该方法不能判断调用了一个js方法之后，是否发生了错误。当错误发生时，返回值为nil，而当调用一个方法本身没有返回值时，返回值也为nil，所以无法判断是否调用成功了。
     2、返回值类型为nullable NSString *，就意味着当调用的js方法有返回值时，都以字符串返回，不够灵活。当返回值是一个js的Array时，还需要解析字符串，比较麻烦
     */
    
    self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    [self convertJSFunctionsToOCMethods];
}


#pragma mark - 将JS的函数转换成OC的方法
- (void)convertJSFunctionsToOCMethods
{
    /**
     oc调用js：
     方法二：
    //@property (nonatomic, strong) UIWebView * webView;
    //@property (nonatomic, strong) JSContext * jsContext;
    //获取该UIWebview的javascript上下文
    self.jsContext = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    //JSContext oc调用js
    JSValue *value = [self.jsContext evaluateScript:@"document.title"];
    self.title = value.toString;
     
     解析：
     其实WebKit都有一个内嵌的js环境，一般我们在页面加载完成之后，获取js上下文，然后通过JSContext的evaluateScript:方法来获取返回值。因为该方法得到的是一个JSValue对象，所以支持JavaScript的Array、Number、String、对象等数据类型。该方法解决了stringByEvaluatingJavaScriptFromString:返回值只是NSString的问题
     
     [self.jsContext evaluateScript:@"document.titlexxxx"];那么必然会报错，报错了，可以通过
     @property (copy) void(^exceptionHandler)(JSContext *context, JSValue *exception);，
     设置该block来获取异常。
     
     //在调用前，设置异常回调
     [self.jsContext setExceptionHandler:^(JSContext *context, JSValue *exception){
     NSLog(@"%@", exception);
     }];
     //执行方法
     JSValue *value = [self.jsContext evaluateScript:@"document.titlexxxx"];
     
     该方法，也很好的解决了stringByEvaluatingJavaScriptFromString:调用js方法后，出现错误却捕获不到的缺点。
     
     
     */
    //获取该UIWebview的javascript上下文
    self.jsContext = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
//    //JSContext oc调用js
//    JSValue *value = [self.jsContext evaluateScript:@"document.title"];
//    self.title = value.toString;
    
    
    
    /*
     Native预览H5页面中的image
     */
    //防止频繁IO操作，造成性能影响
    static NSString *jsSource;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        jsSource = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ImgAddClickEvent" ofType:@"js"] encoding:NSUTF8StringEncoding error:nil];
    });
    //先注入给图片添加点击事件的js
    [self.jsContext evaluateScript:jsSource];
    self.jsContext[@"h5ImageDidClick"] = ^(NSDictionary *imgInfo){
        NSLog(@"UIWebView点击了html上的图片，信息是：%@", imgInfo);
    };
    /**
     UIWebView点击了html上的图片，信息是：{
     height = 168;
     imgUrl = "http://cc.cocimg.com/api/uploads/170425/b2d6e7ea5b3172e6c39120b7bfd662fb.jpg";
     imgUrls =     (
     "http://cc.cocimg.com/api/uploads/170425/b2d6e7ea5b3172e6c39120b7bfd662fb.jpg"
     );
     index = 0;
     width = 252;
     x = 8;
     y = 8;
     }
     */
    
    //js调用OC
    //其中share就是js的方法名称，赋给是一个block 里面是iOS代码
    //此方法最终将打印出所有接收到的参数，js参数是不固定的
    /*
     self.jsContext[@"yourMethodName"] = your block;这样写不仅可以在有yourMethodName方法时替换该JS方法为OC实现，还会在该方法没有时，添加方法。简而言之，有则替换，无则添加。
     */
    
    self.jsContext[@"share"] = ^(){
        NSArray *args = [JSContext currentArguments];//获取到share里的所有参数
        //args中的元素是JSValue，需要转成OC的对象
        NSMutableArray *messages = [NSMutableArray array];
        for (JSValue *obj in args) {
            [messages addObject:[obj toObject]];
        }
        NSLog(@"点击分享js传回的参数：\n%@", messages);
        /**
         点击分享js传回的参数：
         (
         "\U5206\U4eab\U6807\U9898",
         "http://cc.cocimg.com/api/uploads/170425/b2d6e7ea5b3172e6c39120b7bfd662fb.jpg",
         "file:///Users/macair/Library/Developer/CoreSimulator/Devices/04C1A1B2-EBF1-4C3A-BC06-6664428718F6/data/Containers/Bundle/Application/2684F36D-58CB-4A37-96AB-334D21098682/WebViewDemo.app/test.html"
         )
         */
    };
    
    //两数相加、相乘
    /*
    self.jsContext[@"testAddMethod"] = ^NSInteger(NSInteger a, NSInteger b){
        return a + b;
//        return a * b;
    };
    */
    //调用方法的本来实现，给原结果乘以10
    JSValue *value = self.jsContext[@"testAddMethod"];
    self.jsContext[@"testAddMethod"] = ^NSInteger(NSInteger a, NSInteger b){
        JSValue *resultValue = [value callWithArguments:[JSContext currentArguments]];
        return resultValue.toInt32 * 10;
    };
    
    /*
     需求：
     h5中有一个分享按钮，用户点击之后，调用native分享（微信分享、微博分享等），在native分享成功或者失败时，回调h5页面，告诉其分享结果，h5页面刷新对应的UI，显示分享成功或者失败。
     */
    //异步回调
    self.jsContext[@"shareNew"] = ^(JSValue *shareData){//首先这里要注意，回调的参数不能直接写NSDictionary类型，为何呢？
        //仔细看，打印出的确实是一个NSDictionary，但是result字段对应的不是block而是一个NSDictionary
        NSLog(@"%@", [shareData toObject]);
        /**
         {
         imgUrl = "http://img.dd.com/xxx.png";
         link = "file:///Users/macair/Library/Developer/CoreSimulator/Devices/04C1A1B2-EBF1-4C3A-BC06-6664428718F6/data/Containers/Bundle/Application/F0F701AB-D134-4596-8104-16EDD27CDBCD/WebViewDemo.app/test.html";
         result =     {
         };
         title = title;
         }
         */
        //获取shareData对象的result属性，这个JSValue对应的其实是一个javascript的function。
        JSValue *resultFunction = [shareData valueForProperty:@"result"];
        //回调block，将js的function转换为OC的block
        void (^result)(BOOL) = ^(BOOL isSuccess) {
            [resultFunction callWithArguments:@[@(isSuccess)]];
        };
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            result(NO);
            
        });
    };
}

#pragma mark - 自定义cookie

- (void)UIWebViewCustomCookie
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.URLString]];
    //主动操作NSHTTPCookieStorage，添加一个自定义Cookie
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:@{
                                                                NSHTTPCookieName: @"customCookieName",
                                                                NSHTTPCookieValue: @"heiheihei",
                                                                NSHTTPCookieDomain: @".baidu.com",
                                                                NSHTTPCookiePath: @"/"
                                                                
                                                                }];
    //Cookie存在则覆盖，不存在添加
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    //读取所有Cookie
    NSArray *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
    //Cookies数组转换为requestHeaderFields
    NSDictionary *requestHeaderFields = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    //设置请求头
    request.allHTTPHeaderFields = requestHeaderFields;
    [self.webView loadRequest:request];

}

#pragma mark - Setter & Getter

- (UIWebView *)webView {
    if (_webView == nil) {
        _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        _webView.backgroundColor = [UIColor blueColor];
        _webView.delegate = self;
    }
    return _webView;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
