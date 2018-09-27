//
//  WKWebViewController.m
//  WebViewDemo
//
//  Created by Mac Air on 2018/9/24.
//  Copyright © 2018年 Mac Air. All rights reserved.
//

#import "WKWebViewController.h"
#import <WebKit/WebKit.h>
#import "NSHTTPCookie+Utils.h"
#import "NSHTTPCookieStorage+Utils.h"

static void *WkwebBrowserContext = &WkwebBrowserContext;

/*
 WKUIDelegate, 主要是一些alert、打开新窗口之类的
 WKNavigationDelegate,类似于UIWebView的加载成功、失败、是否允许跳转等
 将UIWebView的代理协议拆成了一个跳转的协议和一个关于UI的协议。
 */

@interface WKWebViewController ()<WKNavigationDelegate,WKUIDelegate,WKScriptMessageHandler>

@property (strong, nonatomic) WKWebView *webView;
//仅当第一次的时候加载本地JS
@property(nonatomic,assign) BOOL needLoadJSPOST;


//返回按钮
@property (nonatomic)UIBarButtonItem* customBackBarItem;
//关闭按钮
@property (nonatomic)UIBarButtonItem* closeButtonItem;
//设置加载进度条
@property (nonatomic,strong) UIProgressView *progressView;



@end

@implementation WKWebViewController

#pragma mark - Life Cycle
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (_isNavHidden == YES) {
        self.navigationController.navigationBarHidden = YES;
        //创建一个高20的假状态栏
        UIView *statusBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 20)];
        //设置成绿色
        statusBarView.backgroundColor=[UIColor whiteColor];
        // 添加到 navigationBar 上
        [self.view addSubview:statusBarView];
    }else{
        self.navigationController.navigationBarHidden = NO;
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];

    //添加到主控制器上
    [self.view addSubview:self.webView];
    //添加进度条
    [self.view addSubview:self.progressView];
    //更新webView的cookie
    [self updateWebViewCookie];
    //图片添加点击事件
    [self imgAddClickEvent];
    //添加NativeApi
    [self addNativeApiToJS];
    
    //添加右边刷新按钮
    UIBarButtonItem *roadLoad = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(roadLoadClicked)];
    UIBarButtonItem *cookie =[[UIBarButtonItem alloc] initWithTitle:@"获取cookie" style:UIBarButtonItemStylePlain target:self action:@selector(testEvaluateJavaScript)];
    
    self.navigationItem.rightBarButtonItems = @[roadLoad,cookie];


    
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        //比如我在这个时候保存了Cookie
        [self saveCookie];
    }
    return self;
}

- (void)dealloc
{
    //记得移除
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"share"];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"imageDidClick"];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"shareNew"];
    
    //NativeApi相关
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"nativeChoosePhoneContact"];

}
#pragma mark - WKNavigationDelegate 方法按调用前后顺序排序
//针对一次action来决定是否允许跳转，允许与否都需要调用decisionHandler，比如decisionHandler(WKNavigationActionPolicyCancel);
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    //可以通过navigationAction.navigationType获取跳转类型，如新链接、后退等
    NSURL *URL = navigationAction.request.URL;
    //判断URL是否符合自定义的URL Scheme
    if([URL.scheme isEqualToString:SHWebViewDemoScheme]){
        //根据不同的业务，来执行对应的操作，且获取参数
        if([URL.host isEqualToString:SHWebViewDemoHostSmsLogin]){
            NSString *param = URL.query;
            NSLog(@"短信验证码登录, 参数为%@", param);//短信验证码登录, 参数为username=12323123&code=892845
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    
#warning important 这里很重要
    //解决Cookie丢失问题
    NSURLRequest *originalRequest = navigationAction.request;
    [self fixRequest:originalRequest];
    
    //判断自定义按钮
    [self updateNavigationItems];
    
    //如果originalRequest就是NSMutableURLRequest, originalRequest中已添加必要的Cookie，可以跳转
    //允许跳转
    decisionHandler(WKNavigationActionPolicyAllow);
    //可能有小伙伴，会说如果originalRequest是NSURLRequest，不可变，那不就添加不了Cookie了，是的，我们不能因为这个问题，不允许跳转，也不能在不允许跳转之后用loadRequest加载fixedRequest，否则会出现死循环，具体的，小伙伴们可以用本地的html测试下。
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

//根据response来决定，是否允许跳转，允许与否都需要调用decisionHandler，如decisionHandler(WKNavigationResponsePolicyAllow);
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    decisionHandler(WKNavigationResponsePolicyAllow);
}

//提交了一个跳转，早于 didStartProvisionalNavigation
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

//开始加载，对应UIWebView的- (void)webViewDidStartLoad:(UIWebView *)webView;
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    //开始加载的时候，让加载进度条显示
    self.progressView.hidden = NO;
    NSLog(@"%@", NSStringFromSelector(_cmd));
}


//加载成功，对应UIWebView的- (void)webViewDidFinishLoad:(UIWebView *)webView; 网页加载完成，导航的变化
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    /*
     主意：这个方法是当网页的内容全部显示（网页内的所有图片必须都正常显示）的时候调用（不是出现的时候就调用），，否则不显示，或则部分显示时这个方法就不调用。
     */
    // 判断是否需要加载（仅在第一次加载）
    if (self.needLoadJSPOST) {
        // 调用使用JS发送POST请求的方法
        [self postRequestWithJS];
        // 将Flag置为NO（后面就不需要加载了）
        self.needLoadJSPOST = NO;
    }

    
    self.title = self.webView.title; //其实可以kvo来实现动态切换title
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    //    self.webView.scrollView.frame = CGRectMake(0, 64, self.webView.scrollView.frame.size.width, self.webView.scrollView.frame.size.height);
    //    self.webView.scrollView.contentOffset = CGPointMake(0, -64);

    
    
    //@property (strong, nonatomic) WKWebView *webView;
//    [self.webView evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable title, NSError * _Nullable error) {
//        self.title = title;
//    }];
    
    [self updateNavigationItems];
    
    NSLog(@"%@", NSStringFromSelector(_cmd));

}

//页面加载失败或者跳转失败，对应UIWebView的- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSLog(@"%@\nerror：%@", NSStringFromSelector(_cmd), error);
}

/*
 比如，最近遇到在一个高内存消耗的H5页面上 present 系统相机，拍照完毕后返回原来页面的时候出现白屏现象（拍照过程消耗了大量内存，导致内存紧张，WebContent Process 被系统挂起），但上面的回调函数并没有被调用。在WKWebView白屏的时候，另一种现象是 webView.titile 会被置空, 因此，可以在 viewWillAppear 的时候检测 webView.title 是否为空来 reload 页面。
 */

//当WKWebView加载的网页占用内存过大时，会出现白屏现象
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
    [webView reload];//刷新就好了
}


//页面加载数据时报错
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSLog(@"%@\nerror：%@", NSStringFromSelector(_cmd), error);
}


#pragma mark - WKUIDelegate

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
#warning important 这里也很重要
    //这里不打开新窗口
    [self.webView loadRequest:[self fixRequest:navigationAction.request]];
    return nil;
}

// 获取js 里面的提示
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(nonnull void (^)(void))completionHandler
{
    //js 里面的alert实现，如果不实现，网页的alert函数无效
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    [self presentViewController:alertController animated:YES completion:^{}];
}

// js 信息的交流
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    //  js 里面的alert实现，如果不实现，网页的alert函数无效  ,
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
        completionHandler(NO);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        completionHandler(YES);
    }]];
    [self presentViewController:alertController animated:YES completion:^{}];
}

// 交互。可输入的文本。
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *))completionHandler
{
    //用于和JS交互，弹出输入框
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
        completionHandler(nil);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = alertController.textFields.firstObject;
        completionHandler(textField.text);
    }]];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [self presentViewController:alertController animated:YES completion:NULL];
}


#pragma mark - WKScriptMessageHandler  js -> oc
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.name isEqualToString:@"share"]) {
        id body = message.body;
        NSLog(@"share分享的内容为：%@", body);
        /**
         share分享的内容为：{
         imgUrl = "http://cc.cocimg.com/api/uploads/170425/b2d6e7ea5b3172e6c39120b7bfd662fb.jpg";
         link = "file:///Users/macair/Library/Developer/CoreSimulator/Devices/04C1A1B2-EBF1-4C3A-BC06-6664428718F6/data/Containers/Bundle/Application/C009579D-10B9-49D2-A3A4-4D409157C158/WebViewDemo.app/test.html";
         title = "\U5206\U4eab\U6807\U9898";
         }
         */
    }else if ([message.name isEqualToString:@"imageDidClick"]) {
        //点击了html上的图片， Native预览H5页面中的image
        NSLog(@"点击了html上的图片，参数为%@", message.body);
        /**
         点击了html上的图片，参数为{
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

         注意这里的x，y是不包含自定义scrollView的contentInset的，如果要获取图片在屏幕上的位置：
         x = x + self.webView.scrollView.contentInset.left;
         y = y + self.webView.scrollView.contentInset.top;
         */
        
        NSDictionary *dict = message.body;
        NSString *selectedImageUrl = dict[@"imgUrl"];
        CGFloat x = [dict[@"x"] floatValue] + + self.webView.scrollView.contentInset.left;
        CGFloat y = [dict[@"y"] floatValue] + self.webView.scrollView.contentInset.top;
        CGFloat width = [dict[@"width"] floatValue];
        CGFloat height = [dict[@"height"] floatValue];
        CGRect frame = CGRectMake(x, y, width, height);
        NSUInteger index = [dict[@"index"] integerValue];
        NSLog(@"点击了第%@个图片，\n链接为%@，\n在Screen中的绝对frame为%@，\n所有的图片数组为%@", @(index), selectedImageUrl, NSStringFromCGRect(frame), dict[@"imgUrls"]);
        /*
         点击了第0个图片，
         链接为http://cc.cocimg.com/api/uploads/170425/b2d6e7ea5b3172e6c39120b7bfd662fb.jpg，
         在Screen中的绝对frame为{{8, 72}, {252, 168}}，
         所有的图片数组为(
         "http://cc.cocimg.com/api/uploads/170425/b2d6e7ea5b3172e6c39120b7bfd662fb.jpg"
         )
         */

    }else if ([message.name isEqualToString:@"shareNew"]) {
        NSDictionary *shareData = message.body;
        NSLog(@"%@分享的数据为： %@", message.name, shareData);
        /**
         shareNew分享的数据为： {
         imgUrl = "http://img.dd.com/xxx.png";
         link = "file:///Users/macair/Library/Developer/CoreSimulator/Devices/04C1A1B2-EBF1-4C3A-BC06-6664428718F6/data/Containers/Bundle/Application/9DE46251-970B-460B-AB13-86629C09C279/WebViewDemo.app/test.html";
         result = "function (res) {\n                            //\U8fd9\U91ccshareResult \U7b49\U540c\U4e8e document.getElementById(\"shareResult\")\n                            shareResult.innerHTML = res ? \"success\" : \"failure\";\n\n                         }";
         title = title;
         }
         */
        
        //模拟异步回调
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //读取js function的字符串
            NSString *jsFunctionString = shareData[@"result"];
            /*
             function (res) {
             //这里shareResult 等同于 document.getElementById("shareResult")
             shareResult.innerHTML = res ? "success" : "failure";
             
             }
             */
            //拼接调用该方法的js字符串
            NSString *callbackJs = [NSString stringWithFormat:@"(%@)(%d);", jsFunctionString, NO];    //后面的参数NO为模拟分享失败
            //执行回调
            [self.webView evaluateJavaScript:callbackJs completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                if (!error) {
                    NSLog(@"模拟回调，分享失败");
                }
            }];
        });
    }else if ([message.name isEqualToString:@"nativeChoosePhoneContact"]) {
        NSLog(@"正在选择联系人");

        [self selectContactCompletion:^(NSString *name, NSString *phone) {
            NSLog(@"选择完成");
            //读取js function的字符串
            NSString *jsFunctionString = message.body[@"completion"];
            //拼接调用该方法的js字符串
            NSString *callbackJs = [NSString stringWithFormat:@"(%@)({name: '%@', mobile: '%@'});", jsFunctionString, name, phone];
            //执行回调
            [self.webView evaluateJavaScript:callbackJs completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                
            }];
        }];
    }
    
}


#pragma mark - Events
/**
 Native预览H5页面中的image,
 页面中的所有img标签添加点击事件
 */
- (void)imgAddClickEvent
{
    //防止频繁IO操作，造成性能影响
    static NSString *jsSource;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        jsSource = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ImgAddClickEvent" ofType:@"js"] encoding:NSUTF8StringEncoding error:nil];
    });
    /*
     注入的js source可以是任何js字符串，也可以js文件。比如你有很多提供给h5使用的js方法，那么你本地可能就会有一个ImgAddClickEvent.js
     */
    //添加自定义的脚本
    WKUserScript *js = [[WKUserScript alloc] initWithSource:jsSource injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
    [self.webView.configuration.userContentController addUserScript:js];
    //注册回调
    [self.webView.configuration.userContentController addScriptMessageHandler:self name:@"imageDidClick"];

}

/**
 添加native端的api
 */
- (void)addNativeApiToJS
{
    //防止频繁IO操作，造成性能影响
    static NSString *nativejsSource;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nativejsSource = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"NativeApi" ofType:@"js"] encoding:NSUTF8StringEncoding error:nil];
    });
    //添加自定义的脚本
    WKUserScript *js = [[WKUserScript alloc] initWithSource:nativejsSource injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [self.webView.configuration.userContentController addUserScript:js];
    //注册回调
    [self.webView.configuration.userContentController addScriptMessageHandler:self name:@"nativeChoosePhoneContact"];
}

- (void)roadLoadClicked{
    //刷新
    [self.webView reload];
    /*
     //等同于
     [self.webView evaluateJavaScript:@"location.reload()" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
     
     }];
     */
}

/**
 测试evaluateJavaScript方法
 */

- (void)testEvaluateJavaScript {
    
    [self.webView evaluateJavaScript:@"document.cookie" completionHandler:^(id _Nullable cookies, NSError * _Nullable error) {
        NSLog(@"调用evaluateJavaScript异步获取cookie：%@", cookies);
    }];
    
    // do not use dispatch_semaphore_t
    /*
     __block id cookies;
     dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
     [self.webView evaluateJavaScript:@"document.cookie" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
     cookies = result;
     dispatch_semaphore_signal(semaphore);
     }];
     //等待三秒，接收参数
     dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC));
     //打印cookie，肯定为空，因为足足等了3s，dispatch_semaphore_signal没有起作用
     NSLog(@"cookie的值为：%@", cookies);
     
     //还是老实的接受异步回调吧，不要用信号来搞成同步，会卡死的，不信可以试试
     */
}
#pragma mark - JSPOST
// 调用JS发送POST请求
- (void)postRequestWithJS
{
    // 拼装成调用JavaScript的字符串
    NSString *jscript = [NSString stringWithFormat:@"post('%@',{%@})",self.URLString,self.postData];
    NSLog(@"Javascript: %@", jscript);
    //post('http://www.postexample.com',{"username":"aaa","password":"123"})
    // 调用JS代码
    [self.webView evaluateJavaScript:jscript completionHandler:^(id object, NSError * _Nullable error) {
        NSLog(@"%@",error);
    }];
}



#pragma mark - 加载方式
- (void)webviewLoadURLType
{
    switch (self.loadType) {
        case WebLoadTypeURLString:
        {
            
//            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.URLString]];
//            NSArray *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
//            NSDictionary *requestHeaderFields = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
//            request.allHTTPHeaderFields = requestHeaderFields;
//            [self.webView loadRequest:request];
            
            [self loadUrl:self.URLString];
        }
            break;
        case WebLoadTypeHTMLString:
        {
            [self loadRequestPathHtmlURL:self.URLString];
            //            [self loadHostPathURL:self.URLString];
        }
            break;
        case WebLoadTypePOSTUrlString:
        {
            // JS发送POST的Flag，为真的时候会调用JS的POST方法
            self.needLoadJSPOST = YES;
            //POST使用预先加载本地JS方法的html实现，请确认WKJSPOST存在
            [self loadHostPathURL:@"WKJSPOST"];
        }
            break;
            
            
        default:
            break;
    }
}

/**
 解决首次加载页面Cookie带不上问题
 @param url 链接
 */
- (void)loadUrl:(NSString *)url
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
//    [self.webView loadRequest:request];
    [self.webView loadRequest:[self fixRequest:request]];
}

- (void)loadRequestPathHtmlURL:(NSString *)url
{
    NSString *path = [[NSBundle mainBundle] pathForResource:url ofType:@"html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]];
    [self.webView loadRequest:request];
}


- (void)loadHostPathURL:(NSString *)url
{
    //获取JS所在的路径
    NSString *path = [[NSBundle mainBundle] pathForResource:url ofType:@"html"];
    //获得html内容
    NSString *html = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    //加载js
    [self.webView loadHTMLString:html baseURL:[[NSBundle mainBundle] bundleURL]];
}



#pragma mark - cookie相关
/**
 修复打开链接Cookie丢失问题
 
 @param request 请求
 @return 一个fixedRequest
 */
- (NSURLRequest *)fixRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *fixedRequest;
    if ([request isKindOfClass:[NSMutableURLRequest class]]) {
        fixedRequest = (NSMutableURLRequest *)request;
    }else {
        fixedRequest = request.mutableCopy;
    }
    //防止Cookie丢失，Cookies数组转换为requestHeaderFields
    NSDictionary *dict = [NSHTTPCookie requestHeaderFieldsWithCookies:[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies];
    if (dict.count) {
        NSMutableDictionary *mDict = request.allHTTPHeaderFields.mutableCopy;
        [mDict setValuesForKeysWithDictionary:dict];
        //设置请求头
        fixedRequest.allHTTPHeaderFields = mDict;
    }
    return fixedRequest;
}

//比如你在登录成功时，保存Cookie
- (void)saveCookie
{
    /*
     //如果从已有的地方保存Cookie，比如登录成功
    NSArray *allCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie *cookie in allCookies) {
        if ([cookie.name isEqualToString:SHServerSessionCookieName]) {
            NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SHUserDefaultsCookieStorageKey];
            if (dict) {
                NSHTTPCookie *localCookie = [NSHTTPCookie cookieWithProperties:dict];
                if (![cookie.value isEqual:localCookie.value]) {
                    NSLog(@"本地Cookie有更新");
                }
            }
            [[NSUserDefaults standardUserDefaults] setObject:cookie.properties forKey:SHUserDefaultsCookieStorageKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            break;
        }
    }
    */
    
    
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:@{
                                                                NSHTTPCookieName: SHServerSessionCookieName,
                                                                NSHTTPCookieValue: @"1314521",
                                                                NSHTTPCookieDomain: @".baidu.com",
                                                                NSHTTPCookiePath: @"/"
                                                                }];
    [[NSUserDefaults standardUserDefaults] setObject:cookie.properties forKey:SHUserDefaultsCookieStorageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    
    
}

/*!
 *  更新webView的cookie
 */
- (void)updateWebViewCookie
{
    WKUserScript *cookieScript = [[WKUserScript alloc] initWithSource:@"" injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    //添加Cookie
    [self.webView.configuration.userContentController addUserScript:cookieScript];
}

- (NSString *)cookieString
{
    NSMutableString *script = [NSMutableString string];
    for (NSHTTPCookie *cookie in [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies) {
        if ([cookie.value rangeOfString:@"'"].location != NSNotFound) {
            continue;
        }
        
        // Create a line that appends this cookie to the web view's document's cookies
        [script appendFormat:@"document.cookie='%@'; \n", cookie.da_javascriptString];

    }
    return script;
}


#pragma mark - 自定义返回/关闭按钮

- (void)updateNavigationItems
{
    if (self.webView.canGoBack) {
        UIBarButtonItem *spaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        spaceButtonItem.width = -6.5;
        [self.navigationItem setLeftBarButtonItems:@[spaceButtonItem,self.customBackBarItem,self.closeButtonItem] animated:NO];
    }else {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        [self.navigationItem setLeftBarButtonItems:@[self.customBackBarItem]];
    }
}

-(UIBarButtonItem*)customBackBarItem{
    if (!_customBackBarItem) {
        UIImage* backItemImage = [[UIImage imageNamed:@"backItemImage"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImage* backItemHlImage = [[UIImage imageNamed:@"backItemImage-hl"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        UIButton* backButton = [[UIButton alloc] init];
        [backButton setTitle:@"返回" forState:UIControlStateNormal];
        [backButton setTitleColor:self.navigationController.navigationBar.tintColor forState:UIControlStateNormal];
        [backButton setTitleColor:[self.navigationController.navigationBar.tintColor colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        [backButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        [backButton setImage:backItemImage forState:UIControlStateNormal];
        [backButton setImage:backItemHlImage forState:UIControlStateHighlighted];
        [backButton sizeToFit];
        
        [backButton addTarget:self action:@selector(customBackItemClicked) forControlEvents:UIControlEventTouchUpInside];
        _customBackBarItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    }
    return _customBackBarItem;
}

-(void)customBackItemClicked{
    if (self.webView.goBack) {
        [self.webView goBack];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(UIBarButtonItem*)closeButtonItem{
    if (!_closeButtonItem) {
        _closeButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeItemClicked)];
    }
    return _closeButtonItem;
}

-(void)closeItemClicked{
    [self.navigationController popViewControllerAnimated:YES];
}



#pragma mark - 进度条
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.webView) {
        self.progressView.alpha = 1.0f;
        BOOL animated = self.webView.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:self.webView.estimatedProgress animated:animated];
        // Once complete, fade out UIProgressView
        if (self.webView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.progressView.alpha = 0.0f;
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
            }];
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (UIProgressView *)progressView{
    if (!_progressView) {
        _progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
        if (_isNavHidden == YES) {
            _progressView.frame = CGRectMake(0, 20, self.view.bounds.size.width, 3);
        }else{
            _progressView.frame = CGRectMake(0, 64, self.view.bounds.size.width, 3);
        }
        // 设置进度条的色彩
        [_progressView setTrackTintColor:[UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1.0]];
        _progressView.progressTintColor = [UIColor greenColor];
    }
    return _progressView;
}


#pragma mark - Setters and Getters
//
- (WKWebView *)webView {
    if (_webView == nil) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        
        WKUserContentController *UserContentController = [[WKUserContentController alloc] init];
        
        //页面加载完成立刻回调，获取页面上的所有Cookie
//        WKUserScript *cookieScript = [[WKUserScript alloc] initWithSource:@"                window.webkit.messageHandlers.currentCookies.postMessage(document.cookie);" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];

        /*
         - (instancetype)initWithSource:(NSString *)source
         injectionTime:(WKUserScriptInjectionTime)injectionTime
         forMainFrameOnly:(BOOL)forMainFrame
         返回可以添加到用户内容控制器的初始化用户脚本
         source：脚本的源代码。
         injectionTime：脚本应该注入网页的时间。该值必须是枚举类型的常量之一。WKUserScriptInjectionTime
         forMainFrameOnly：一个布尔值，指示脚本是仅应注入主框架（YES）还是注入所有框架（NO）。
         */

        //添加自定义的cookie
        WKUserScript *newCookieScript = [[WKUserScript alloc] initWithSource:@"document.cookie = 'SyhCookie=Syh;'" injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];

        //添加脚本
//        [UserContentController addUserScript:cookieScript];
        [UserContentController addUserScript:newCookieScript];
        
        
        
        //注册回调
        [UserContentController addScriptMessageHandler:self name:@"share"];
        [UserContentController addScriptMessageHandler:self name:@"shareNew"];
        configuration.userContentController = UserContentController;
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
        _webView.navigationDelegate = self;
        _webView.UIDelegate = self;
        
        //加入此行代码后，加载的地址会有变化
        // _webView.customUserAgent = @"WebViewDemo/1.0.0";    //自定义UA，只支持WKWebView，UA最常用来判断在哪个App内，常见的微信、支付宝App等，都有自己的UserAgent
        /*
         自定义contentInset刷新时页面跳动的bug,通过KVC设置私有变量的值
         */
        //        self.webView.scrollView.contentInset = UIEdgeInsetsMake(64, 0, 49, 0);
        //史诗级神坑，为何如此写呢？参考https://opensource.apple.com/source/WebKit2/WebKit2-7600.1.4.11.10/ChangeLog   以及我博客中的介绍
        //        [self.webView setValue:[NSValue valueWithUIEdgeInsets:self.webView.scrollView.contentInset] forKey:@"_obscuredInsets"];
        
        //kvo 添加进度监控
        [_webView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:0 context:WkwebBrowserContext];
        //适应你设定的尺寸
        [_webView sizeToFit];

        
        
        
    }
    return _webView;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
