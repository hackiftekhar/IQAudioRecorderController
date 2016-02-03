//
//  IQTimeIntervalFormatter.m
//  IQAudioRecorderController Demo
//
//  Created by Sebastian Ludwig on 03.02.16.
//  Copyright © 2016 Iftekhar. All rights reserved.
//

#import "IQTimeIntervalFormatter.h"

@implementation IQTimeIntervalFormatter

- (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval
{
    long ti = (long)timeInterval;
    long seconds = ti % 60;
    long minutes = (ti / 60) % 60;
    long hours = (ti / 3600);
    
    if (hours > 0) {
        return [NSString stringWithFormat:@"%02li:%02li:%02li", hours, minutes, seconds];
    } else {
        return [NSString stringWithFormat:@"%02li:%02li", minutes, seconds];
    }
}

@end
