//
//  NetWorkUtils.h
//  NetWorkReachability
//
//  Created by David on 17/12/17.
//  Copyright © 2017年 David. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^netStateBlock)(NSInteger netState);


@interface SZKNetWorkUtils : NSObject

/**
 *  网络监测
 *
 *  @param block 判断结果回调
 *
 *  @return 网络监测
 */
+(void)netWorkState:(netStateBlock)block;

@end
