//
//  QMakeCloudAnalysis.m
//  QMakeCloudAnalysis
//
//  Created by mqy on 16/3/11.
//  Copyright © 2016年 GNET. All rights reserved.
//

#import "QMakeCloudAnalysis.h"
#import "Reachability.h"
#import "UIDevice+Hardware.h"
#import "Aspects.h"
@interface QMakeCloudAnalysis()

@property (nonatomic,copy) NSMutableArray *backgroundTimeDurations;


@end
@implementation QMakeCloudAnalysis

+ (QMakeCloudAnalysis *)shareInstance {
    static QMakeCloudAnalysis *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });

    return instance;
}
- (instancetype)init {

    if (self = [super init]) {
        self.startUpCounts = 0;
        self.newAddCounts = 0;
        self.activeDuration = 0;
    }
    return self;
}
- (NSMutableArray *)backgroundTimeDurations {
    if (_backgroundTimeDurations == nil) {
        NSMutableArray *array = [NSMutableArray array];
        _backgroundTimeDurations = array;
    }
    return _backgroundTimeDurations;
}

- (QMakeCloudAnalysis *)startUpCounts:(id) appDelegateClass {
    //获取当前时间 ---  didFinishLaunchingTime打开应用的时间
# pragma mark - didFinishLaunchingTime
    NSDate  *currentDate = [self getCurrenTime];
    self.didFinishLaunchingTime = currentDate;

    //使用用户偏好设施 保存数据，第二次读取出来+1 ，放松到服务器，并且再次保存到 用户偏好设置中。
    NSNumber  *qMakeCloudStartUp = [[NSUserDefaults standardUserDefaults] objectForKey:QMakeCloud_StartUpCounts];
    int startUpCount;
    NSLog(@"%@",qMakeCloudStartUp);
    startUpCount = qMakeCloudStartUp.intValue + 1;
    self.startUpCounts = startUpCount;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:startUpCount] forKey:QMakeCloud_StartUpCounts];
    [[NSUserDefaults standardUserDefaults] synchronize];


#pragma mark -- applicationDidEnterBackground
    __block  NSDate  *didEnterBackgroundTime;
    id<AspectToken> didEnterBackgroundToken = [appDelegateClass aspect_hookSelector:@selector(applicationDidEnterBackground:) withOptions:AspectPositionAfter usingBlock:^(id<AspectToken> info, id application) {

        didEnterBackgroundTime = [self getCurrenTime];
        NSLog(@"Button was pressed by: %@ -- %@",info, application);
        long duration = [self intervalFrom:currentDate toDate:didEnterBackgroundTime];
        self.activeDuration = duration;
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLong:self.activeDuration] forKey:QMakeCloud_StartUpCounts];

        [[NSUserDefaults standardUserDefaults] synchronize];
    } error:NULL];

#pragma mark -- applicationWillEnterForeground
    __block NSDate *willEnterForegroundTime;
    id<AspectToken> willEnterForegroundToken = [appDelegateClass aspect_hookSelector:@selector(applicationWillEnterForeground:) withOptions:AspectPositionAfter usingBlock:^(id<AspectToken> info, id application) {
        willEnterForegroundTime = [self getCurrenTime];

        long  backgroudDuration =  [self intervalFrom:didEnterBackgroundTime toDate:willEnterForegroundTime];
        [self.backgroundTimeDurations addObject:[NSString stringWithFormat:@"%ld",backgroudDuration]];
        NSLog(@"backgroundTimeDurations---:%ld",backgroudDuration);

        [[NSUserDefaults standardUserDefaults] setObject:self.backgroundTimeDurations forKey:QMakeCloud_BackgroundTimeDurations];
        [[NSUserDefaults standardUserDefaults] synchronize];


    } error:NULL];



#pragma mark - applicationWillTerminate

    __block NSDate  *terminate;
    id<AspectToken> willTerminateToken = [appDelegateClass aspect_hookSelector:@selector(applicationWillTerminate:) withOptions:AspectPositionAfter usingBlock:^(id<AspectToken> info, id application) {

        //获取当前关闭应用的时间
        terminate = [self getCurrenTime];
        self.willTerminateTime = terminate;

        //计算累计从应用打开 到关闭的时间
        long  openDuration = [self intervalFrom:self.didFinishLaunchingTime toDate:self.willTerminateTime];

        NSLog(@"打开 关闭 时长---：%ld",openDuration);
        //遍历获取在后台持续的总时长
        long long  totalTime = 0;
        for (NSString * strTime in self.backgroundTimeDurations) {
            totalTime += strTime.longLongValue;
        }

        NSLog(@"---  后台总时长:%zd",totalTime);

        self.activeDuration  =  openDuration - (long)totalTime;
        NSLog(@"---活跃时长：%ld",self.activeDuration);
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLong:self.activeDuration] forKey:QMakeCloud_ActiveDuration];
          [[NSUserDefaults standardUserDefaults] synchronize];

    } error:NULL];

//获取用户的设备信息
    [self deviceInfo];
//获取设备的网络状态
    self.netWorkStatus = [self getNetType];
    NSLog(@"当前的网络状体是:%@",self.netWorkStatus);
    self.uuid = [[UIDevice currentDevice] uuid];
    [[NSUserDefaults standardUserDefaults] setObject:self.uuid forKey:QMakeCloud_UUID];
#pragma mark - 将活跃时间记录到本地，并找合适时机上传服务器中
   //报错数据到后台服务器中
    return self;
}
- (void)deviceInfo {
#pragma mark - 获取设备的信息
    //获取MAC 地址
    NSString *macString = [UIDevice macAddress] ;
    //获取IP 地址
    NSString *iPString = [UIDevice iPAddress];
    //获取设备系统版本
    NSString *deviceSystemVersion = [UIDevice systemVersion];
    NSString *deviceHardwareString = [[UIDevice currentDevice] hardwareDescription];

    NSLog(@"MAC:%@--- IP:%@ --- device:%@ --  Version:%@",macString,iPString,deviceHardwareString,deviceSystemVersion);

}
//计算日期的间距
- (long)intervalFrom:(NSDate *)date1 toDate:(NSDate *)date2 {
    NSCalendar *cal = [NSCalendar currentCalendar];

    unsigned int unitFlags;
    if (IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
       unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute |NSCalendarUnitSecond;
    } else {
          unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    }
    NSDateComponents *d = [cal components:unitFlags fromDate:date1 toDate:date2 options:0];

    long sec = [d hour]*3600 + [d minute] * 60 + [d second];
 //   NSLog(@"second = %ld",[d hour]*3600 + [d minute]*60 + [d second]);
    return sec;
}
- (NSDate *)getCurrenTime {

    //获取当前时间
    NSDate *  sendDate = [NSDate date];

    NSDateFormatter  *dateformatter = [[NSDateFormatter alloc] init];

    [dateformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

    NSString *  locationString = [dateformatter stringFromDate:sendDate];

    NSLog(@"locationString:----%@",locationString);
    NSTimeInterval time = 365 * 24 * 60 * 60;//一年的秒数
    NSDate * lastYear = [sendDate dateByAddingTimeInterval:-time];
    NSString * startDate = [dateformatter stringFromDate:lastYear];
    return sendDate;

}
#pragma mark -- 获取网络状态
- (NSString *)getNetType {

    NSString* result;

    Reachability *reachbility = [Reachability reachabilityWithHostName:@"www.baidu.com"];
    NSLog(@"  ====:%li",(long)[reachbility currentReachabilityStatus]);
    switch ([reachbility currentReachabilityStatus]) {

        case NotReachable:// 没有网络连接
            result = @"没有网络连接";
            break;

        case ReachableViaWWAN:// 使用3G网络
            result = @"3g";

            break;

        case ReachableViaWiFi:// 使用WiFi网络
            result = @"wifi";

            break;

    }
    NSLog(@"caseReachableViaWWAN=%li",(long)ReachableViaWWAN);
    NSLog(@"caseReachableViaWiFi=%li",(long)ReachableViaWiFi);
    return result;

}

@end
