//
//  Categories.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 22.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Categories : NSObject {
@private
  NSDictionary *types;
  NSMutableArray *typesIdx;
  NSMutableSet *excludingCategoryIds;
  NSMutableDictionary *icons;
  NSMutableDictionary *categoryOrTypeIds;
}

+(Categories *)getCategories:(BOOL)reload;
+(Categories *)getCategories;

-(int)numberOfCategories;
-(int)numberOfTypes;
-(int)getTypeIdx:(NSString *)typeId;
-(NSString *)getTypeId:(int)typeIdx;
-(NSArray *)getTypeIds:(NSString *)categoryId;
-(NSString *)getTypeNameForIdx:(int)typeIdx;
-(NSString *)getTypeName:(NSString *)typeId;
-(BOOL)isTypeId:(NSString *)typeId inCategoryId:(NSString *)categoryId;
-(NSArray *)getCategoryNamesForIdx:(int)typeIdx;
-(NSArray *)getCategoryNames:(NSString *)typeId;
-(NSArray *)getCategoryIdsForIdx:(int)typeIdx;
-(NSArray *)getCategoryIds:(NSString *)typeId;
-(NSString *)getCategoryId:(NSString *)categoryName;
-(NSString *)getCategoryOrTypeId:(NSString *)categoryOrTypeName;
-(NSString *)getCategoryName:(NSString *)categoryId;
-(NSString *)getCategoryNamefForMenuId:(NSString *)menuId;
-(BOOL)isExcludingCategoryId:(NSString *)categoryId;
-(BOOL)isExcludingCategoryName:(NSString *)categoryName;
-(NSString *)getIconForTypeIdOrCategoryId:(NSString *)typeCategoryId;

@end
