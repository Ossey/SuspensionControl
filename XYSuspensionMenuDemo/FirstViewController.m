//
//  FirstViewController.m
//  SuspensionView
//
//  Created by xiaoyuan on 2017/5/21.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import "FirstViewController.h"
#import "XYSuspensionMenu.h"
#import "XYConsoleView.h"
#import "XYSuspensionWebView.h"
#import "XYSuspensionQuestionAnswerMatchView.h"
#import "XYHTTPRequest.h"

#pragma mark *** Sample ***

@interface FirstViewController () <SuspensionMenuViewDelegate>

@end

@implementation FirstViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    DLog(@"111");
    
    // 显示多级菜单的suspensionMenu
    [self sample];
    // 打印log测试
    [self testLog];
    
    // 显示控制台
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] xy_toggleConsoleWithCompletion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self testWebView];
            });
        }];
    });
    
    
}

static NSString * const wd = @"中国哪位诗人的作品最多";


- (void)testWebView {
    /// 显示webView
    [[UIApplication sharedApplication] xy_toggleConsoleWithCompletion:^(BOOL finished) {
        [[UIApplication sharedApplication] xy_toggleWebViewWithCompletion:^(BOOL finished) {
            NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:wd] invertedSet];
            NSString *wdr = [wd stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
            
            NSString *urlString = [NSString stringWithFormat:@"https://m.baidu.com/s?ie=utf-8&f=8&rsv_bp=0&rsv_idx=1&tn=baidu&wd=%@&inputT=1696&rsv_sug4=1697", wdr];
            [UIApplication sharedApplication].xy_suspensionWebView.urlString = urlString;
        }];
    }];
}



- (void)testQuestionAnswerView {

    [[UIApplication sharedApplication] xy_toggleSuspensionQuestionAnswerMatchViewWithCompletion:^(BOOL finished) {
        
        [self.class request:@"孟姜女是哪个朝代的人" ansOps:@[@"唐朝", @"宋代", @"秦朝"] completion:^(NSDictionary *responseDict, NSError *error) {
           
            if (!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    int bestIndex = [responseDict[@"best_answer_index"] intValue];
                    if (bestIndex == -1) {
                        [[UIApplication sharedApplication].xy_suspensionQuestionAnsweView setAttributedText:[[NSAttributedString alloc] initWithString:@"未返回结果"]];
                    }
                    NSString *bestAnswer = [NSString stringWithFormat:@"建议答案：\n第%d个\n%@", bestIndex+1, responseDict[@"best_answer"]];
                    NSLog(@"%@", bestAnswer);
                    [[UIApplication sharedApplication].xy_suspensionQuestionAnsweView setAttributedText:[[NSAttributedString alloc] initWithString:bestAnswer]];
                });
            }
        }];
    }];
}

+ (NSURLSessionDataTask *)request:(NSString *)quesText
                           ansOps:(NSArray <NSString *> *)ansOps
                       completion:(void (^)(NSDictionary *responseDict, NSError *error))completion {
    NSURLSessionDataTask * (^ searchOnAlpface)(NSString *qeustion, NSArray<NSString *> *quesOps, void (^ completion)(NSDictionary *responseDict, NSError *error)) = ^NSURLSessionDataTask *(NSString *qeustion, NSArray<NSString *> *quesOps, void (^ completion)(id responseDict, NSError *error)) {
        if (qeustion.length == 0) {
            return nil;
        }
        NSURLSession *session=[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        
        NSString *urlString=@"http://www.alpface.com/question/answer/";
        /**
         NSString *urlString=@"http://10.211.55.3:8000/question/answer/";
         测试数据
         NSString *qeustion = @"孟姜女是哪个朝代的人";
         NSArray<NSString *> *quesOps = @[@"宋代", @"唐朝", @"秦朝"];
         */
        
        NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        [request setTimeoutInterval:20];
        request.HTTPMethod=@"POST";
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"csrftoken=MKIxe7TiEwjVdITrEHfgd9qqeFjKEkqvHMPmNfSuJDIYfMJVBBsMOHJqq5S7rWcS" forHTTPHeaderField:@"Cookie"];
        [request setValue:@"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" forHTTPHeaderField:@"Accept"];
        [request setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
        
        
        NSMutableDictionary *paramer = @{@"csrfmiddlewaretoken":@"w2N7qYoxz8fHoWRmzUjNrFkyzkB7jCRor4UWZ6nJEfEKq0HQwOwj2dDyLKau6eDL",@"question_text": qeustion}.mutableCopy;
        [quesOps enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [paramer setObject:obj forKey:[NSString stringWithFormat:@"answeroptions%ld", idx+1]];
        }];
        NSMutableString *paramerStr = @"".mutableCopy;
        [paramer enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [paramerStr appendFormat:@"&%@=%@", key, obj];
        }];
        
        request.HTTPBody=[paramerStr dataUsingEncoding:NSUTF8StringEncoding];
        
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                if (completion) {
                    completion(nil, error);
                }
            }
            else {
                NSDictionary *responseDict = @{};
                if (data) {
                    NSError *er = nil;
                    responseDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&er];
                    if (er) {
                        responseDict = @{};
                    }
                    if (completion) {
                        completion(responseDict, er);
                    }
                }
                else {
                    if (completion) {
                        completion(responseDict, nil);
                    }
                }
                
            }
            
        }];
        
        [task resume];
        return task;
    };
    
    
    return searchOnAlpface(quesText, ansOps, completion);
}



- (void)testRepeatInit {
    /// 测试重复创建
    [self oneLevelMenuSample];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sample];
        DLog(@"666");
    });
}

- (void)testLog {
    if (@available(iOS 10.0, *)) {
        [[NSThread currentThread] setName:@"main"];
        // 主线程执行
        NSTimer *timer = [NSTimer timerWithTimeInterval:3.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            static NSInteger i = 0;
            DLog(@"%li, current thread:%@", (long)i++, [NSThread currentThread].name);
            NSLog(@"Hello NSLog");
        }];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        
        // 子线程执行, 开启多条线程打印log 测试并发
        for (NSInteger i = 1; i<4; i++) {
            dispatch_async(dispatch_queue_create("testLog", DISPATCH_QUEUE_CONCURRENT), ^{
                NSString *seleString = [NSString stringWithFormat:@"myLog%ld", (long)i];
                [self.class addTask:NSSelectorFromString(seleString) identifier:seleString];
            });
            
        }
    }
}

+ (void)addTask:(SEL)selector identifier:(NSString *)identifier { @autoreleasepool {
        [[NSThread currentThread] setName:identifier];
        [NSTimer scheduledTimerWithTimeInterval:2
                                         target:self
                                       selector:selector
                                       userInfo:nil
                                        repeats:YES];
        
        NSThread *currentThread = [NSThread currentThread];
        NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
        
        BOOL isCancelled = [currentThread isCancelled];
        while (!isCancelled && [currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
            isCancelled = [currentThread isCancelled];
        }
        
        NSAssert(NO, @"thread is die");
    }}

+ (void)myLog1 {
    static NSInteger i = 0;
    // 模拟耗时
    [NSThread sleepForTimeInterval:arc4random_uniform(8)];
    i++;
    DLog(@"i:%ld current thread:%@", i, [NSThread currentThread].name);
}

+ (void)myLog2 {
    static NSInteger i = 0;
    [NSThread sleepForTimeInterval:arc4random_uniform(5)];
    i++;
    DLog(@"i:%ld current thread:%@", i, [NSThread currentThread].name);
}


+ (void)myLog3 {
    static NSInteger i = 0;
    [NSThread sleepForTimeInterval:arc4random_uniform(3)];
    i++;
    DLog(@"i:%ld current thread:%@", i, [NSThread currentThread].name);
}

/// 一级菜单使用
- (void)oneLevelMenuSample {
    DLog(@"111");
    XYSuspensionMenu *menuView = [XYSuspensionMenu menuWindowWithFrame:CGRectMake(0, 0, 300, 300) itemSize:CGSizeMake(50, 50)];
    [menuView.centerButton setImage:[UIImage imageNamed:@"aws-icon"] forState:UIControlStateNormal];
    menuView.shouldOpenWhenViewWillAppear = NO;
    menuView.shouldHiddenCenterButtonWhenOpen = YES;
    menuView.shouldCloseWhenDeviceOrientationDidChange = YES;
    UIImage *image = [UIImage imageNamed:@"mm.jpg"];
    menuView.backgroundImageView.image = image;
    menuView.delegate = self;
    HypotenuseAction *item = nil;
    {
        item = [HypotenuseAction actionWithType:UIButtonTypeCustom handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
            DLog(@"222");
        }];
        [menuView addAction:item];
        [item.hypotenuseButton setImage:[UIImage imageNamed:@"apple-icon"] forState:UIControlStateNormal];
            [item.hypotenuseButton setTitle:@"Apple" forState:UIControlStateNormal];
    }
    
    {
        item = [HypotenuseAction actionWithType:UIButtonTypeCustom handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
            
        }];
        [menuView addAction:item];
        [item.hypotenuseButton setTitle:@"Google" forState:UIControlStateNormal];
        item.hypotenuseButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    }

    
    
    [menuView showWithCompetion:NULL];
    
}



/// 多级菜单使用
- (void)sample {
    
    XYSuspensionMenu *menuView = [XYSuspensionMenu menuWindowWithFrame:CGRectMake(0, 0, 300, 300) itemSize:CGSizeMake(50, 50)];
    [menuView.centerButton setImage:[UIImage imageNamed:@"aws-icon"] forState:UIControlStateNormal];
    
    menuView.shouldOpenWhenViewWillAppear = NO;
    menuView.shouldHiddenCenterButtonWhenOpen = YES;
    menuView.shouldCloseWhenDeviceOrientationDidChange = YES;
    UIImage *image = [UIImage imageNamed:@"mm.jpg"];
    menuView.backgroundImageView.image = image;
    
    NSMutableArray *types = [NSMutableArray array];
    NSMutableArray *images = [NSMutableArray array];
    int i = 0;
    while (i <= 7) {
        UIButtonType type = UIButtonTypeCustom;
        NSString *imageNamed = @"aws-icon";
        if (i == 1) {
            type = UIButtonTypeCustom;
            imageNamed = @"apple-icon";
        }
        if (i == 2) {
            type = UIButtonTypeSystem;
            imageNamed = @"blip-icon";
        }
        if (i == 4) {
            type = UIButtonTypeSystem;
            imageNamed = @"dropbox-icon";
        }
        [types addObject:@(type)];
        [images addObject:imageNamed];
        i++;
    }
    i--;
    HypotenuseAction *item = nil;
    {
        item = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
            [[UIApplication sharedApplication] xy_toggleConsoleWithCompletion:^(BOOL finished) {
                [menuView close];
            }];
        }];
        [menuView addAction:item];
        item.hypotenuseButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        [item.hypotenuseButton setBackgroundColor:[UIColor blackColor]];
        [item.hypotenuseButton setTitle:@"Console" forState:UIControlStateNormal];
        i--;
    }
    
    {
        item = [HypotenuseAction actionWithType:UIButtonTypeSystem handler:NULL];
        [menuView addAction:item];
        [item.hypotenuseButton setTitle:@"more" forState:UIControlStateNormal];
        {
            HypotenuseAction *itemM = nil;
            {
                itemM  = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                    [menuView showViewController:getViewController() animated:YES];
                }];
                [itemM.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
                [item addMoreAction:itemM];
            }
            
            {
                itemM  = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                    [menuView showViewController:getViewController() animated:YES];
                }];
                [itemM.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
                [item addMoreAction:itemM];
            }
            
            {
                itemM  = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                    [menuView showViewController:getViewController() animated:YES];
                }];
                [itemM.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
                [item addMoreAction:itemM];
            }
            
        }
        i--;
    }
    
    
    {
        item = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
            [[UIApplication sharedApplication] xy_toggleWebViewWithCompletion:^(BOOL finished) {
                NSString *wd = @"天气如何";
                NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:wd] invertedSet];
                wd = [wd stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
                
                NSString *urlString = [NSString stringWithFormat:@"https://m.baidu.com/s?ie=utf-8&f=8&rsv_bp=0&rsv_idx=1&tn=baidu&wd=%@&inputT=1696&rsv_sug4=1697", wd];
                [UIApplication sharedApplication].xy_suspensionWebView.urlString = urlString;
            }];
            [menuView close];
        }];
        [menuView addAction:item];
        [item.hypotenuseButton setTitle:@"Test WebView" forState:UIControlStateNormal];
        i--;
    }
    
    {
        item = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
            [self testQuestionAnswerView];
            [menuView close];
        }];
        [menuView addAction:item];
        [item.hypotenuseButton setTitle:@"Question view" forState:UIControlStateNormal];
        i--;
    }
    {
        item = [HypotenuseAction actionWithType:UIButtonTypeSystem handler:NULL];
        [menuView addAction:item];
        [item.hypotenuseButton setTitle:@"more" forState:UIControlStateNormal];
        
        {
            HypotenuseAction *itemM = nil;
            {
                itemM  = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                    [menuView showViewController:getViewController() animated:YES];
                }];
                [itemM.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
                [item addMoreAction:itemM];
            }
            
            {
                itemM  = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                    [menuView showViewController:getViewController() animated:YES];
                }];
                [itemM.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
                [item addMoreAction:itemM];
            }
            
            {
                itemM  = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                    [menuView showViewController:getViewController() animated:YES];
                }];
                [itemM.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
                [item addMoreAction:itemM];
            }
            
            {
                itemM  = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                    [menuView showViewController:getViewController() animated:YES];
                }];
                [itemM.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
                [item addMoreAction:itemM];
            }
            
            {
                itemM  = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                    [menuView showViewController:getViewController() animated:YES];
                }];
                [itemM.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
                [item addMoreAction:itemM];
            }
            
            {
                itemM  = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                    [menuView showViewController:getViewController() animated:YES];
                }];
                [itemM.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
                [item addMoreAction:itemM];
            }
            
        }
        i--;
    }

    
    {
        item = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
            [menuView showViewController:getViewController() animated:YES];
        }];
        [menuView addAction:item];
        [item.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
        if ([types[i] integerValue] == UIButtonTypeSystem) {
            [item.hypotenuseButton setTitle:@"Apple" forState:UIControlStateNormal];
        }
        
        {
            HypotenuseAction *itemM = nil;
            {
                itemM  = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                    [menuView showViewController:getViewController() animated:YES];
                }];
                [itemM.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
                [item addMoreAction:itemM];
            }
            
            {
                itemM  = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                    [menuView showViewController:getViewController() animated:YES];
                }];
                [itemM.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
                [item addMoreAction:itemM];
            }
            
            {
                itemM  = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                    [menuView showViewController:getViewController() animated:YES];
                }];
                [itemM.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
                [item addMoreAction:itemM];
            }
            
            {
                itemM  = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                    [menuView showViewController:getViewController() animated:YES];
                }];
                [itemM.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
                [item addMoreAction:itemM];
            }
            
            {
                itemM  = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                    [menuView showViewController:getViewController() animated:YES];
                }];
                [itemM.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
                [item addMoreAction:itemM];
            }
            
            {
                itemM  = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                    [menuView showViewController:getViewController() animated:YES];
                }];
                [itemM.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
                [item addMoreAction:itemM];
            }
        }
        
        i--;
    }
    
    {
        item = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
            [menuView showViewController:getViewController() animated:YES];
        }];
        [menuView addAction:item];
        [item.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
        if ([types[i] integerValue] == UIButtonTypeSystem) {
            [item.hypotenuseButton setTitle:@"Apple" forState:UIControlStateNormal];
        }
        i--;
    }
    
    {
        item = [HypotenuseAction actionWithType:[types[i] integerValue] handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
            [menuView showViewController:getViewController() animated:YES];
        }];
        [menuView addAction:item];
        [item.hypotenuseButton setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
        if ([types[i] integerValue] == UIButtonTypeCustom) {
            [item.hypotenuseButton setTitle:@"Apple" forState:UIControlStateNormal];
        }
        i--;
    }
    
    
    [menuView showWithCompetion:NULL];

}

NS_INLINE UIViewController *getViewController() {
    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1.0];
    return vc;
}


////////////////////////////////////////////////////////////////////////
#pragma mark - SuspensionMenuViewDelegate
////////////////////////////////////////////////////////////////////////

- (void)suspensionMenuView:(SuspensionMenuView *)suspensionMenuView clickedCenterButton:(SuspensionView *)centerButton {
    
}

- (void)suspensionMenuView:(SuspensionMenuView *)suspensionMenuView clickedHypotenuseButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 3) {
        
        UIViewController *vc = [UIViewController new];
        [suspensionMenuView showViewController:vc animated:YES];
    }
    if (buttonIndex == 4) {
        
        UITableViewController *vc = [UITableViewController new];
        [suspensionMenuView showViewController:vc animated:YES];
    }
}


- (void)suspensionMenuView:(SuspensionMenuView *)suspensionMenuView clickedMoreButtonAtIndex:(NSInteger)buttonIndex fromHypotenuseItem:(HypotenuseAction *)hypotenuseItem {
    if (buttonIndex < 2) {
        UIViewController *vc = [UIViewController new];
        [suspensionMenuView showViewController:vc animated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
