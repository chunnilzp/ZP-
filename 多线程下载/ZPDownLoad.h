//
//  ZPDownLoad.h
//  多线程下载
//
//  Created by 李泽平 on 2018/8/28.
//  Copyright © 2018年 李泽平. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZPDownLoad : NSObject
- (void)downloadWithUrl:(NSURL *)url range:(NSString *)range response:(NSURLResponse *)response downloadDataLenght:(void(^)(long long downloadDataLenght))downloadDataLenght finish:(void(^)(NSString *finish))finish failed:(void(^)(NSString *failed))failed;

@end
