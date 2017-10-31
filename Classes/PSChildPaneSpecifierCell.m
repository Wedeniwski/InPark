//
//  PSChildPaneSpecifierCell.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 05.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PSChildPaneSpecifierCell.h"

@implementation PSChildPaneSpecifierCell

-(void)setupCell:(InAppSetting *)inputSetting {
  [super setupCell:inputSetting];
  [self setTitle];
  [self setDisclosure:YES];
}

@end
