//
//  CellOwner.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 27.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TableCell.h"

@interface CellOwner : NSObject {
  IBOutlet TableCell *cell;
}

-(BOOL)loadNibNamed:(NSString *)nibName owner:(id)delegate;

@property (retain, nonatomic) TableCell *cell;

@end
