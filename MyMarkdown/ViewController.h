//
//  ViewController.h
//  MyMarkdown
//
//  Created by Apple on 9/24/15.
//  Copyright © 2015 cnbin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface ViewController :UIViewController<WKUIDelegate>

@property (nonatomic,strong) WKWebView * webView;

@end

