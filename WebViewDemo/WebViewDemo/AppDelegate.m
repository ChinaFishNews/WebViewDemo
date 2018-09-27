//
//  AppDelegate.m
//  WebViewDemo
//
//  Created by Mac Air on 2018/9/24.
//  Copyright © 2018年 Mac Air. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"

/*
 NSURLProtocol也是苹果众多黑魔法中的一种，使用它可以轻松地重定义整个URL Loading System。当你注册自定义NSURLProtocol后，就有机会对所有的请求进行统一的处理，基于这一点它可以让你
 
 ·自定义请求和响应
 
 ·提供自定义的全局缓存支持
 
 ·重定向网络请求
 
 ·提供HTTP Mocking (方便前期测试)
 
 ·其他一些全局的网络请求修改需求
 */
@interface DAURLProtocol : NSURLProtocol

@end

@implementation DAURLProtocol

//Native加载并缓存H5页面中的img
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    //处理过不再处理
    if ([NSURLProtocol propertyForKey:SHURLProtocolHandledKey inRequest:request]) {
        return NO;
    }
    //根据request header中的 accept 来判断是否加载图片
    /*
     {
     "Accept" = "image/png,image/svg+xml";
     "User-Agent" = "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Mobile/14E269 WebViewDemo/1.0.0";
     }
     */
    NSDictionary *headers = request.allHTTPHeaderFields;
    NSString *accept = headers[@"Accept"];
    if (accept.length >= @"image".length && [accept rangeOfString:@"image"].location != NSNotFound) {
        return YES;
    }
    return NO;
}

//返回规范化后的request,一般就只是返回当前request即可。
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

//用于判断你的自定义reqeust是否相同，这里返回默认实现即可。它的主要应用场景是某些直接使用缓存而非再次请求网络的地方。
+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    return [super requestIsCacheEquivalent:a toRequest:b];
}

//实现请求流程
- (void)startLoading
{
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    //这里也可以添加一些自定义的header，看具体需求
    //标记该request已经处理过
    [NSURLProtocol setProperty:@(YES) forKey:SHURLProtocolHandledKey inRequest:mutableReqeust];
    
    //NSURLProtocol拦截了图片请求
    NSLog(@"NSURLProtocol拦截了图片请求：%@", mutableReqeust);
    
    [self.client URLProtocolDidFinishLoading:self];
    //
    //    //这里NSURLProtocolClient的相关方法都要调用
    //    //比如 [self.client URLProtocol:self didLoadData:data];
    //
    //    //下面是一些伪代码
    //    //开始下载图片
    //    [ImageDownloader startLoadImage:mutableReqeust completion:^(UIImage *image, NSData *data, NSError *error){
    //        if (error) {
    //            [self.client URLProtocol:self didFailWithError:error];
    //        } else {
    //            [self.client URLProtocol:self didLoadData:data];
    //
    //        }
    //    }];
}

//实现取消流程
- (void)stopLoading
{
    //    [ImageDownloader cancel];
}

@end


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //设置自定义UserAgent
    [self setCustomUserAgent];

    return YES;
}

/*
 1、通过NSUserDefaults设置自定义UserAgent，可以同时作用于UIWebView和WKWebView。
 2、WKWebView的customUserAgent属性，优先级高于NSUserDefaults，当同时设置时，显示customUserAgent的值。
 */
- (void)setCustomUserAgent
{
    //get the original user-agent of webview
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    NSString *oldAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    //add my info to the new agent
    NSString *newAgent = [oldAgent stringByAppendingFormat:@" %@", @"WebViewDemo/1.0.0"];
    //regist the new agent
    NSDictionary *dictionnary = [[NSDictionary alloc] initWithObjectsAndKeys:newAgent, @"UserAgent", newAgent, @"User-Agent", nil];
    /*
     {
     "User-Agent" = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_2_6 like Mac OS X) AppleWebKit/604.5.6 (KHTML, like Gecko) Mobile/15D100 WebViewDemo/1.0.0";
     UserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_2_6 like Mac OS X) AppleWebKit/604.5.6 (KHTML, like Gecko) Mobile/15D100 WebViewDemo/1.0.0";
     }
     
     */
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionnary];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
