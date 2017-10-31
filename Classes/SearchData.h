//
//  SearchData.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 23.05.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SearchData : NSObject {
  float accuracy;
  NSDictionary *allParkDetails;
  NSMutableArray *searchedParkIds;
  NSMutableArray *searchedAttributes;
}

+(NSArray *)defaultSearchAttributes;

-(id)initWithDetails:(NSDictionary *)parkDetails;

+(float)getDistanceGram:(unsigned long)n source:(const char *)source target:(const char *)target;
+(NSString *)removingAccents:(NSString *)text;
+(NSString *)simplifyText:(NSString *)text;

-(NSDictionary *)search:(NSString *)text;

@property float accuracy;
@property (readonly, nonatomic) NSDictionary *allParkDetails;
@property (readonly, nonatomic) NSMutableArray *searchedParkIds;
@property (readonly, nonatomic) NSMutableArray *searchedAttributes;

@end
