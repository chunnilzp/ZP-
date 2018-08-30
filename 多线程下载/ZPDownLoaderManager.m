//
//  ZPDownLoaderManager.m
//  多线程下载
//
//  Created by 李泽平 on 2018/8/29.
//  Copyright © 2018年 李泽平. All rights reserved.
//

#import "ZPDownLoaderManager.h"
#import "ZPDownLoad.h"

#define downLoadSize 20000000

@interface ZPDownLoaderManager()

@property (nonatomic, strong) NSMutableDictionary *dicCache;


@property (nonatomic, copy) void(^finish)(NSString *);

@end

@implementation ZPDownLoaderManager

- (NSMutableDictionary *)dicCache{
    if (!_dicCache) {
        _dicCache = [[NSMutableDictionary alloc] init];
    }
    return _dicCache;
}

+ (instancetype)manager{
    static id manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}


- (void)downloadWithUrl:(NSURL *)url progress:(void(^)(float preogress))progress complant:(void(^)(NSString *finish))complant error:(void(^)(NSString *error))error{
    if ([self.dicCache objectForKey:url.path]) {
        error(@"任务已存在");
        return;
    }
    self.finish = complant;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:1 timeoutInterval:20];
    request.HTTPMethod = @"HEAD";
    //解决无法获取文件的实际大小
    [request setValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
    //2.建立网络连接
    NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:NULL];
    NSLog(@"%lld", response.expectedContentLength);
    NSInteger count = response.expectedContentLength/downLoadSize;
    if (response.expectedContentLength%downLoadSize != 0) {
        count++;
    }
    NSMutableArray *ary = [[NSMutableArray alloc] initWithCapacity:count];
    for (int i = 0; i < count; i++) {
        NSString *begin = [NSString stringWithFormat:@"%d", i*downLoadSize];
        if (![begin isEqualToString:@"0"]) {
            begin = [NSString stringWithFormat:@"%d", i*downLoadSize + 1];
        }
        NSString *end = [NSString stringWithFormat:@"%d", i*downLoadSize + downLoadSize];
        if ([end longLongValue] > response.expectedContentLength) {
            end = @"";
        }
        NSString *rangeStr = [NSString stringWithFormat:@"bytes=%@-%@", begin, end];
        
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];

        
        ZPDownLoad *down = [[ZPDownLoad alloc] init];
        [down downloadWithUrl:url range:rangeStr response:response downloadDataLenght:^(long long progress) {
            
        } finish:^(NSString *finish) {
            [dic setObject:finish forKey:@"saveFilePath"];
            [self loadDownOver:url];
        } failed:^(NSString *failed) {
            if (error) {
                error(failed);
            }
            [self.dicCache removeObjectForKey:url.path];
        }];
        [dic setObject:down forKey:@"down"];
        [dic setObject:rangeStr forKey:@"range"];
        [dic setObject:response forKey:@"response"];
        [ary addObject:dic];
    }
    [self.dicCache setObject:ary forKey:url.path];
}

- (void)loadDownOver:(NSURL *)url{
    if ([self.dicCache objectForKey:url.path] == nil) {
        return;
    }
    NSMutableArray *ary = [[NSMutableArray alloc] init];
    NSURLResponse *response = nil;
    for (NSDictionary *dic in [self.dicCache objectForKey:url.path]) {
        response = [dic objectForKey:@"response"];
        if ([dic objectForKey:@"saveFilePath"] == nil) {
            return;
        }
        [ary addObject:[dic objectForKey:@"saveFilePath"]];
    }
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingString:response.suggestedFilename];
    NSFileHandle *fp;
    for (NSString *path in ary) {
        fp = [NSFileHandle fileHandleForWritingAtPath:filePath];
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (fp == nil) {
            [data writeToFile:filePath atomically:YES];
        }else{
            [fp seekToEndOfFile];
            [fp writeData:data];
        }
        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    }
    [fp closeFile];
    [self.dicCache removeObjectForKey:url.path];
    if (self.finish) {
        self.finish(filePath);
    }
}




@end
