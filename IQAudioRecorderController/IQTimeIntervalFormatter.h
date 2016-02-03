//
//  IQTimeIntervalFormatter.h
//  IQAudioRecorderController Demo
//
//  Created by Sebastian Ludwig on 03.02.16.
//  Copyright © 2016 Iftekhar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IQTimeIntervalFormatter : NSFormatter

- (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval;

@end
