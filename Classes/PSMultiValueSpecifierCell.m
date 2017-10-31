//
//  PSMultiValueSpecifierCell.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 05.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PSMultiValueSpecifierCell.h"

@implementation PSMultiValueSpecifierCell

-(void)setupCell:(InAppSetting *)inputSetting {
  [super setupCell:inputSetting];
  [self setDisclosure:YES];
}

@end