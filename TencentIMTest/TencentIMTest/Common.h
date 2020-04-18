//
//  Common.h
//  newLivePadTest
//
//  Created by 胡晓伟 on 2020/4/8.
//  Copyright © 2020 ofweek. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Common : NSObject

+ (NSString *)getFormatString:(NSString *)string;

+ (NSString *)timeWithTimeStamp:(NSString *)timeStampString;

@end

NS_ASSUME_NONNULL_END
