//
//  QMakeCloudAnalysis.h
//  QMakeCloudAnalysis
//
//  Created by mqy on 16/3/11.
//  Copyright © 2016年 GNET. All rights reserved.
//

#import <Foundation/Foundation.h>
//判断版本
#define IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define LS_IOS_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]

static NSString *QMakeCloud_StartUpCounts = @"QMakeCloud_StartUpCounts";
static NSString *QMakeCloud_ActiveDuration = @"QMakeCloud_ActiveDuration";
static NSString *QMakeCloud_BackgroundTimeDurations = @"QMakeCloud_BackgroundTimeDurations";
static NSString *QMakeCloud_UUID = @"QMakeCloud_UUID";

@interface QMakeCloudAnalysis : NSObject
//新增用户数
@property (nonatomic,assign) NSUInteger newAddCounts;
//启动次数
@property (nonatomic,assign) NSUInteger startUpCounts;

//活跃时长
@property (nonatomic,assign) long activeDuration;

//进入应用程序的时间
@property (nonatomic,strong) NSDate *didFinishLaunchingTime;

//@应用程序关闭的时间
@property (nonatomic,strong) NSDate *willTerminateTime;

//网络状态
@property (nonatomic,copy)NSString *netWorkStatus;
//UUID
@property (nonatomic,copy)NSString *uuid;

- (QMakeCloudAnalysis *)startUpCounts:(id) appDelegateClass;

+ (QMakeCloudAnalysis *)shareInstance;
@end
