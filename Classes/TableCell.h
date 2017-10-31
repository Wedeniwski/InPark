//
//  TableCell.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 12.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TableCell : UITableViewCell {
	id delegate;
}

@property (assign, nonatomic) id delegate;

@end
