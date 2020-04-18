//
//  Common.m
//  newLivePadTest
//
//  Created by 胡晓伟 on 2020/4/8.
//  Copyright © 2020 ofweek. All rights reserved.
//

#import "Common.h"

@implementation Common

/**从时间戳得到格式化后的时间字符串*/
+ (NSString *)timeWithTimeStamp:(NSString *)timeStampString {
    // 格式化时间
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"yyyy年MM月dd日 HH:mm:ss"];
    
    // 毫秒值转化为秒
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:[timeStampString doubleValue]/ 1000.0];
    NSString* dateString = [formatter stringFromDate:date];
    return dateString;
}

@end
