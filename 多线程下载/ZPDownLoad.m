//
//  ZPDownLoad.m
//  多线程下载
//
//  Created by 李泽平 on 2018/8/28.
//  Copyright © 2018年 李泽平. All rights reserved.
//

#import "ZPDownLoad.h"

#define OutTime 20

@interface ZPDownLoad()<NSURLConnectionDataDelegate>

@property (nonatomic, assign) long long fileSize;

@property (nonatomic, strong) NSURL *downloadUrl;

@property (nonatomic, strong) NSString *downloadRange;

@property (nonatomic, strong) NSURLConnection *con;

@property (nonatomic, strong) NSOutputStream *stream;

@property (nonatomic, strong) NSURLResponse *response;

@property (nonatomic, strong) NSString *filePath;

@property (nonatomic, assign) CFRunLoopRef runloop;

#pragma mark block

@property (nonatomic, copy) void(^downloadDataLenght)(long long);

@property (nonatomic, copy) void(^finish)(NSString *);

@property (nonatomic, copy) void(^failed)(NSString *);

@end

@implementation ZPDownLoad

- (void)downloadWithUrl:(NSURL *)url range:(NSString *)range response:(NSURLResponse *)response downloadDataLenght:(void(^)(long long downloadDataLenght))downloadDataLenght finish:(void(^)(NSString *finish))finish failed:(void(^)(NSString *failed))failed{
    self.downloadUrl = url;
    self.downloadRange = range;
    self.downloadDataLenght = downloadDataLenght;
    self.finish = finish;
    self.failed = failed;
    self.response = response;
    self.filePath = [NSTemporaryDirectory() stringByAppendingString:self.response.suggestedFilename];
    if (self.downloadRange) {
        self.filePath = [self.filePath stringByAppendingString:self.downloadRange];
    }
    
    //1.检查本地文件是否存在
    if (![self checkDownloadDataLenght]) {
        NSLog(@"文件已经存在");
        return;
    }
    [self downFile];
}

- (BOOL)checkDownloadDataLenght{
    long long fileSize = 0;
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
        fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:NULL].fileSize;
    }
    self.fileSize = fileSize;
    if (self.downloadRange) {
        NSString *str = [self.downloadRange substringFromIndex:6];
        NSArray *ary = [str componentsSeparatedByString:@"-"];
        long long begin = [ary.firstObject longLongValue];
        long long end = [ary.lastObject longLongValue];
        if (end == 0) {
            end = self.response.expectedContentLength;
        }
        if (fileSize == end - begin + 1) {
            return NO;
        }
        if (fileSize > end - begin + 1) {
            [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:NULL];
        }
        begin += self.fileSize;
        NSString *endStr = [NSString stringWithFormat:@"%lld", end];
        if (end == 0) {
            endStr = @"";
        }
        NSString *range = [@[[NSNumber numberWithLongLong:begin], endStr] componentsJoinedByString:@"-"];
        self.downloadRange = [NSString stringWithFormat:@"bytes=%@", range];
    }else{
        self.downloadRange = [NSString stringWithFormat:@"bytes=%lld-",fileSize];
    }
    return YES;
}


- (void)downFile{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.downloadUrl];
        [request setValue:self.downloadRange forHTTPHeaderField:@"Range"];
        self.con = [NSURLConnection connectionWithRequest:request delegate:self];
        [self.con start];
        
        self.runloop = CFRunLoopGetCurrent();
        CFRunLoopRun();
    });
}

#pragma mark - <NSURLConnectionDataDelegate>
//1
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    self.stream = [[NSOutputStream alloc] initToFileAtPath:self.filePath append:YES];
    [self.stream open];
}

//2
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [self.stream write:data.bytes maxLength:[data length]];
    if (self.downloadDataLenght) {
        self.downloadDataLenght(data.length);
    }
}

//3
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    [self.stream close];
    CFRunLoopStop(self.runloop);
    if (self.finish) {
        dispatch_sync(dispatch_get_main_queue(),^{self.finish(self.filePath);});
    }
}

//4
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [self.stream close];
    CFRunLoopStop(self.runloop);
    if (self.failed) {
        dispatch_sync(dispatch_get_main_queue(),^{self.failed(self.filePath);});
    }
}


@end
