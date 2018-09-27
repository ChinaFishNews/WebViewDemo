//
//  ViewController.m
//  WebViewDemo
//
//  Created by Mac Air on 2018/9/24.
//  Copyright © 2018年 Mac Air. All rights reserved.
//

#import "ViewController.h"
#import "UIWebViewController.h"
#import "WKWebViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            switch (indexPath.row) {
                case 0:
                {
                    UIWebViewController *webVC = [[UIWebViewController alloc] init];
                    [webVC loadWebURLSring:@"https://www.baidu.com"];
                    [self.navigationController pushViewController:webVC animated:YES];
                        
                }
                    break;
                case 1:
                {
                    NSString *urlStr = @"http://www.postexample.com";
                    NSString *postData = [NSString stringWithFormat:@"arg1=%@&arg2=%@",@"val1",@"val2"];
                    
                    UIWebViewController *web = [[UIWebViewController alloc] init];
                    [web POSTWebURLSring:urlStr postData:postData];
                    [self.navigationController pushViewController:web animated:YES];

                }
                    break;
                case 2:
                {
                    UIWebViewController *webVC = [[UIWebViewController alloc] init];
                    [webVC loadWebHTMLSring:@"test"];
                    [self.navigationController pushViewController:webVC animated:YES];
                    
                }
                    break;

                    
                default:
                    break;
            }
        }
            break;
        case 1:
        {
            switch (indexPath.row) {
                case 0:
                {
                    WKWebViewController *webVC = [[WKWebViewController alloc] init];
                    [webVC loadWebURLSring:@"https://www.baidu.com"];
                    [self.navigationController pushViewController:webVC animated:YES];

                }
                    break;
                case 1:
                {
                    NSString *postData = @"\"username\":\"aaa\",\"password\":\"123\"";
                    NSString *urlStr = @"http://www.postexample.com";
                    WKWebViewController *web = [[WKWebViewController alloc] init];
                    [web POSTWebURLSring:urlStr postData:postData];
                    [self.navigationController pushViewController:web animated:YES];

                }
                    break;
                case 2:
                {
                    WKWebViewController *webVC = [[WKWebViewController alloc] init];
                    [webVC loadWebHTMLSring:@"test"];
                    [self.navigationController pushViewController:webVC animated:YES];

                }
                    break;
                default:
                    break;
            }

        }
            break;
        default:
            break;
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
