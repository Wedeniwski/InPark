//
//  NewsData.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 31.05.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HelpData.h"

@interface NewsData : NSObject {
  NSString *parkId;
  HelpData *newsData;
  int numberOfNewEntries;
}

-(id)initWithParkId:(NSString *)pId;

-(BOOL)update:(BOOL)considerLocalData;
-(BOOL)updateIfNecessary;

-(void)resetNumberOfNewEntries;

@property (readonly, nonatomic) HelpData *newsData;
@property (readonly) int numberOfNewEntries;

@end
