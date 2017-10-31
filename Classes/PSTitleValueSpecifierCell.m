//
//  PSTitleValueSpecifierCell.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 05.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PSTitleValueSpecifierCell.h"

@implementation PSTitleValueSpecifierCell

-(NSString *)getValueTitle {
  NSArray *titles = [setting valueForKey:@"Titles"];
  NSArray *values = [setting valueForKey:@"Values"];
  if (titles == nil) titles = values;
  if (values != nil) {
    NSInteger l = [titles count];
    if (l > 0 && l == [values count]) {
      NSInteger i = [values indexOfObject:[self getValue]];
      if (i >= 0 && i < l) {
        return [titles objectAtIndex:i];
      }
    }
    return nil;
  }
  return [self getValue];
}

-(void)setValue {
  [super setValue];
  [self setDetail:[self getValueTitle]];
}

-(void)setupCell:(InAppSetting *)inputSetting {
  [super setupCell:inputSetting];
  [self setTitle];
  [self setDisclosure:NO];
}
@end