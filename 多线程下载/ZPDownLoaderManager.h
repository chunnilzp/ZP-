//
//  ZPDownLoaderManager.h
//  多线程下载
//
//  Created by 李泽平 on 2018/8/29.
//  Copyright © 2018年 李泽平. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZPDownLoaderManager : NSObject

+ (instancetype)manager;

- (void)downloadWithUrl:(NSURL *)url progress:(void(^)(float preogress))progress complant:(void(^)(NSString *finish))complant error:(void(^)(NSString *error))error;

@end
