//
//  ViewController.m
//  MyMarkdown
//
//  Created by Apple on 9/24/15.
//  Copyright © 2015 cnbin. All rights reserved.
//

#import "ViewController.h"
#import <MMMarkdown/MMMarkdown.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSError *error;
    
    NSString *textFileContents = [NSString stringWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"abc"ofType:@"markdown"]encoding:NSUTF8StringEncoding error: & error];
    
    NSString *htmlString = [MMMarkdown HTMLStringWithMarkdown:textFileContents error:&error];
    
    NSString * head = @"<HEAD><meta name=\"viewport\" content=\"width=device-width,initial-scale=1,maximum-scale=1\" /><meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\" /></HEAD><BODY>";
    
    
    NSString * contentString = [head stringByAppendingString:htmlString];
    
    
    NSString * finalString = [contentString stringByAppendingString:@"</Body>"];
    

//写入桌面文件
//    NSString *path = @"/Users/apple/Desktop/a.html";
//
//    [finalString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
//    if (error) {
//        NSLog(@"导出失败:%@",error);
//    }else{
//        NSLog(@"导出成功");
//    }
//    
    
    
    
    self.webView = [[WKWebView alloc]init];
    self.webView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) ;
    [self.view addSubview:self.webView];
    
    [self.webView loadHTMLString:finalString baseURL:nil];

//    
//    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"a" ofType:@"html"];
//    NSURL *bundleUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
//    
//    NSString *html = [[NSString alloc] initWithContentsOfFile:htmlPath encoding: NSUTF8StringEncoding error:&error];
//    
//    if (error == nil) {//数据加载没有错误情况下
//        [self.webView loadHTMLString:html baseURL:bundleUrl];
//    }
//
//
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
