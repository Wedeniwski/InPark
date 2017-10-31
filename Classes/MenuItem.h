//
//  MenuItem.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 05.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MenuItem : NSObject {
  NSString *menuId;
  int order;
  double distance;
  double tolerance;
  NSString *name;
  NSString *imageName;
  NSString *fileName;
  BOOL closed;
  BOOL priorityDistance;
  NSString *badgeText; // for Badge notification
}

-(id)initWithMenuId:(NSString *)mId order:(NSNumber *)o distance:(double)d tolerance:(double)t name:(NSString *)n imageName:(NSString *)i closed:(BOOL)c;
-(NSComparisonResult)compare:(MenuItem *)otherMenuItem;

@property (readonly, nonatomic) NSString *menuId;
@property (readonly) int order;
@property double distance;
@property (readonly) double tolerance;
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSString *imageName;
@property (retain, nonatomic) NSString *fileName;
@property (readonly) BOOL closed;
@property BOOL priorityDistance;
@property (retain, nonatomic) NSString *badgeText;

@end
