//
//  webBaseViewController.m
//  WebViewDemo
//
//  Created by Mac Air on 2018/9/24.
//  Copyright © 2018年 Mac Air. All rights reserved.
//

#import "webBaseViewController.h"

@implementation webBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //加载web页面
    [self webviewLoadURLType];

}

#pragma mark - 加载方式
- (void)webviewLoadURLType
{
   
}

#pragma mark 选择联系人
- (void)selectContactCompletion:(void(^)(NSString *name, NSString *phone))completion
{
    self.completion = completion;
    CNContactPickerViewController *picker = [[CNContactPickerViewController alloc] init];
    picker.delegate = self;
    picker.displayedPropertyKeys = @[CNContactPhoneNumbersKey];
    [self presentViewController:picker animated:YES completion:^{
        
    }];
}

#pragma mark - CNContactPickerDelegate
- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContactProperty:(CNContactProperty *)contactProperty
{
    if (![contactProperty.key isEqualToString:CNContactPhoneNumbersKey]) {
        return;
    }
    
    CNContact *contact = contactProperty.contact;
    NSString *name = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];
    
    CNPhoneNumber *phoneNumber = contactProperty.value;
    NSString *phone = phoneNumber.stringValue.length ? phoneNumber.stringValue : @"";
    
    //可以把-、+86、空格这些过滤掉
    NSString *phoneStr = [phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
    phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"+86" withString:@""];
    phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    phoneStr = [[phoneStr componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet]] componentsJoinedByString:@""];
    
    //回调
    if (self.completion) {
        self.completion(name, phoneStr);
    }
    
    //dissMiss
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)contactPickerDidCancel:(CNContactPickerViewController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - 公共方法
- (void)loadWebURLSring:(NSString *)string
{
    self.URLString = string;
    self.loadType = WebLoadTypeURLString;
}

- (void)loadWebHTMLSring:(NSString *)string
{
    self.URLString = string;
    self.loadType = WebLoadTypeHTMLString;
}

- (void)POSTWebURLSring:(NSString *)string postData:(NSString *)postData
{
    self.URLString = string;
    self.postData = postData;
    self.loadType = WebLoadTypePOSTUrlString;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
