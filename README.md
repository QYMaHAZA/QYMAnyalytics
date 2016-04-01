# QYMAnyalytics
iOS  应用活跃时长，登录次数，UUID统计。
下载工程之后带入文件即可使用。
使用示例如下：
    QMakeCloudAnalysis *analysis = [QMakeCloudAnalysis shareInstance];
    [analysis startUpCounts:self];
    [[UIDevice currentDevice] identifierForVendor];
    NSString *uuid = [[NSUserDefaults standardUserDefaults]objectForKey:QMakeCloud_UUID];
    NSNumber *time = [[NSUserDefaults standardUserDefaults]objectForKey:QMakeCloud_ActiveDuration];
    NSNumber *counts = [[NSUserDefaults standardUserDefaults]objectForKey:QMakeCloud_StartUpCounts];
