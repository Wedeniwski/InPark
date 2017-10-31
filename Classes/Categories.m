//
//  Categories.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 22.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "Categories.h"
#import "MenuData.h"

@implementation Categories

-(void)validateTypes {
#ifdef DEBUG_MAP
  NSLog(@"Validate types.plist");
  NSDictionary *parkTypes = [types objectForKey:@"PARK_TYPES"];
  NSDictionary *allCategories = [types objectForKey:@"CATEGORIES"];
  NSDictionary *allTypes = [types objectForKey:@"TYPES"];
  [parkTypes enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    NSString *parkType = key;
    NSDictionary *names = [object objectForKey:@"Name"];
    if (names == nil) NSLog(@"Missing Name for park type %@", parkType);
    NSString *name = [names objectForKey:@"de"];
    if (name == nil || [name length] == 0) NSLog(@"Missing de name for park type %@", parkType);
    name = [names objectForKey:@"en"];
    if (name == nil || [name length] == 0) NSLog(@"Missing en name for park type %@", parkType);
    NSArray *parkCategories = [object objectForKey:@"Categories"];
    if (parkCategories == nil) NSLog(@"Missing Categories for park type %@", parkType);
    for (NSString *parkCategory in parkCategories) {
      NSDictionary *cat = [allCategories objectForKey:parkCategory];
      if (cat == nil) NSLog(@"Missing definition of category %@ which is defined at park type %@", parkCategory, parkType);
      NSDictionary *names = [cat objectForKey:@"Name"];
      if (names == nil) NSLog(@"Missing Name for category %@", parkCategory);
      NSString *name = [names objectForKey:@"de"];
      if (name == nil || [name length] == 0) NSLog(@"Missing de name for category %@", parkCategory);
      name = [names objectForKey:@"en"];
      if (name == nil || [name length] == 0) NSLog(@"Missing en name for category %@", parkCategory);
      NSString *icon = [cat objectForKey:@"Icon"];
      if (icon != nil && ![icon hasSuffix:@".png"]) NSLog(@"Not valid icon '%@' for category %@", icon, parkCategory);
      NSArray *typesOfCategory = [cat objectForKey:@"Types"];
      for (NSString *type in typesOfCategory) {
        NSDictionary *t = [allTypes objectForKey:type];
        if (t == nil) NSLog(@"Missing Type %@ for category %@", type, parkCategory);
        NSDictionary *names = [object objectForKey:@"Name"];
        if (names == nil) NSLog(@"Missing Name for type %@", type);
        NSString *name = [names objectForKey:@"de"];
        if (name == nil || [name length] == 0) NSLog(@"Missing de name for type %@", type);
        name = [names objectForKey:@"en"];
        if (name == nil || [name length] == 0) NSLog(@"Missing en name for type %@", type);
        NSString *icon = [t objectForKey:@"Icon"];
        if (icon != nil && ![icon hasSuffix:@".png"]) NSLog(@"Not valid icon '%@' for type %@", icon, type);
      }
    }
  }];
#endif
}

-(id)init {
  self = [super init];
  if (self != nil) {
    types = [[NSDictionary dictionaryWithContentsOfFile:[[MenuData dataPath] stringByAppendingPathComponent:@"types.plist"]] retain];
    if (types == nil) NSLog(@"ERROR: file 'types.plist' is missing or corrupt");
    NSDictionary *allTypes = [types objectForKey:@"TYPES"];
    typesIdx =[[NSMutableArray alloc] initWithArray:[allTypes allKeys]];
    [typesIdx sortUsingSelector:@selector(compare:)];
    excludingCategoryIds = [[NSMutableSet alloc] initWithCapacity:6];
    icons = [[NSMutableDictionary alloc] initWithCapacity:2*[typesIdx count]+1];
    categoryOrTypeIds = [[NSMutableDictionary alloc] initWithCapacity:2*[typesIdx count]+1];
#if TARGET_IPHONE_SIMULATOR
    [self validateTypes];
#endif
    NSDictionary *allCategories = [types objectForKey:@"CATEGORIES"];
    [allCategories enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
      NSString *icon = [object objectForKey:@"Icon"];
      if (icon != nil) {
        if ([icon hasPrefix:@"small_"]) [icons setObject:[icon substringFromIndex:6] forKey:key]; // ToDo: REMOVE; long time not used; but forgot to remove in first version of types.plist in 1.6
        else [icons setObject:icon forKey:key];
      }
      NSString *name = [MenuData objectForKey:@"Name" at:object];
      if (name == nil) NSLog(@"Name missing for category %@", key);
      else if ([categoryOrTypeIds objectForKey:name] != nil) {
        if (![[categoryOrTypeIds objectForKey:name] isEqualToString:key]) NSLog(@"category name %@ is not unique", name);
      } else [categoryOrTypeIds setObject:key forKey:name];
    }];
    [allTypes enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
      NSString *icon = [object objectForKey:@"Icon"];
      if (icon == nil) {
        NSArray *categoryIds = [self getCategoryIds:key];
        for (NSString *categoryId in categoryIds) {
          icon = [icons objectForKey:categoryId];
          if (icon != nil) break;
        }
      }
      if (icon == nil) NSLog(@"No icon defined for type %@", key);
      else if ([icon hasPrefix:@"small_"]) [icons setObject:[icon substringFromIndex:6] forKey:key]; // ToDo: REMOVE; long time not used; but forgot to remove in first version of types.plist in 1.6
      else [icons setObject:icon forKey:key];
      NSString *name = [MenuData objectForKey:@"Name" at:object];
      if (name == nil) NSLog(@"Name missing for type %@", key);
      else if ([categoryOrTypeIds objectForKey:name] != nil) {
        if (![[categoryOrTypeIds objectForKey:name] isEqualToString:key]) NSLog(@"type name %@ is not unique (incl. category names)", name);
      } else [categoryOrTypeIds setObject:key forKey:name];
    }];
    NSString *directMenu[6] = {NSLocalizedString(@"menu.button.attractions", nil), NSLocalizedString(@"menu.button.catering", nil), NSLocalizedString(@"menu.button.dining", nil), NSLocalizedString(@"menu.button.restroom", nil), NSLocalizedString(@"menu.button.service", nil), NSLocalizedString(@"menu.button.shop", nil)};
    // ToDo: improve and not fix
    //seperatedKindOf = [[NSMutableSet alloc] initWithCapacity:6];
    for (int i = 0; i < 6; ++i) {
      //if ([categories objectForKey:directMenu[i]] != nil) [seperatedKindOf addObject:directMenu[i]];
      NSString *categoryId = [self getCategoryId:directMenu[i]];
      if (categoryId != nil) [excludingCategoryIds addObject:categoryId];
    }
  }
  return self;
}

-(void)dealloc {
  [types release];
  types = nil;
  [typesIdx release];
  typesIdx = nil;
  [excludingCategoryIds release];
  excludingCategoryIds = nil;
  [icons release];
  icons = nil;
  [categoryOrTypeIds release];
  categoryOrTypeIds = nil;
  [super dealloc];
}

+(Categories *)getCategories:(BOOL)reload {
  static Categories *cat = nil;
  @synchronized([Categories class]) {
    if (cat == nil) {
      cat = [[Categories alloc] init];
    } else if (reload) {
      NSLog(@"reload categories");
      [cat release];
      cat = [[Categories alloc] init];
    }
    return cat;
  }
}

+(Categories *)getCategories {
  return [self getCategories:NO];
}

-(int)numberOfCategories {
  return (int)[[types objectForKey:@"CATEGORIES"] count];
}

-(int)numberOfTypes {
  return (int)[[types objectForKey:@"TYPES"] count];
}

-(int)getTypeIdx:(NSString *)typeId {
  return [MenuData binarySearch:typeId inside:typesIdx];
}

-(NSString *)getTypeId:(int)typeIdx {
  return (typeIdx < 0 || typeIdx >= [typesIdx count])? @"" : [typesIdx objectAtIndex:typeIdx];
}

-(NSArray *)getTypeIds:(NSString *)categoryId {
  return [[[types objectForKey:@"CATEGORIES"] objectForKey:categoryId] objectForKey:@"Types"];
}

-(NSString *)getTypeNameForIdx:(int)typeIdx {
  if (typeIdx < 0 || typeIdx >= [typesIdx count]) return @"";
  NSDictionary *allTypes = [types objectForKey:@"TYPES"];
  NSString *typeId = [typesIdx objectAtIndex:typeIdx];
  return [MenuData objectForKey:@"Name" at:[allTypes objectForKey:typeId]];
}

-(NSString *)getTypeName:(NSString *)typeId {
  NSDictionary *allTypes = [types objectForKey:@"TYPES"];
  return [MenuData objectForKey:@"Name" at:[allTypes objectForKey:typeId]];
}

-(BOOL)isTypeId:(NSString *)typeId inCategoryId:(NSString *)categoryId {
  if ([typeId isEqualToString:categoryId]) return YES;
  return [[[[types objectForKey:@"CATEGORIES"] objectForKey:categoryId] objectForKey:@"Types"] containsObject:typeId];
}

-(NSArray *)getCategoryNamesForIdx:(int)typeIdx {
  if (typeIdx < 0 || typeIdx >= [typesIdx count]) return nil;
  return [self getCategoryNames:[typesIdx objectAtIndex:typeIdx]];
}

-(NSArray *)getCategoryNames:(NSString *)typeId {
  NSMutableArray *m = [[[NSMutableArray alloc] initWithCapacity:2] autorelease];
  NSEnumerator *i = [[types objectForKey:@"CATEGORIES"] objectEnumerator];
  while (true) {
    NSDictionary *object = [i nextObject];
    if (object == nil) break;
    if ([[object objectForKey:@"Types"] containsObject:typeId]) [m addObject:[MenuData objectForKey:@"Name" at:object]];
  }
  return ([m count] == 0)? nil : m;
}

-(NSArray *)getCategoryIdsForIdx:(int)typeIdx {
  if (typeIdx < 0 || typeIdx >= [typesIdx count]) return nil;
  return [self getCategoryIds:[typesIdx objectAtIndex:typeIdx]];
}

-(NSArray *)getCategoryIds:(NSString *)typeId {
  NSMutableArray *m = [[[NSMutableArray alloc] initWithCapacity:2] autorelease];
  [[types objectForKey:@"CATEGORIES"] enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    if ([[object objectForKey:@"Types"] containsObject:typeId]) [m addObject:key];
  }];
  return ([m count] == 0)? nil : m;
}

-(NSString *)getCategoryId:(NSString *)categoryName {
  __block NSString *cId = [categoryOrTypeIds objectForKey:categoryName];
  if (cId != nil) {
    NSDictionary *category = [[types objectForKey:@"CATEGORIES"] objectForKey:cId];
    if (category != nil && [categoryName isEqualToString:[MenuData objectForKey:@"Name" at:category]]) return cId;
    cId = nil;
  }
  [[types objectForKey:@"CATEGORIES"] enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    if ([categoryName isEqualToString:[MenuData objectForKey:@"Name" at:object]]) {
      cId = key;
      *stop = YES;
    }
  }];
  return cId;
}

-(NSString *)getCategoryOrTypeId:(NSString *)categoryOrTypeName {
  return [categoryOrTypeIds objectForKey:categoryOrTypeName];
}

-(NSString *)getCategoryName:(NSString *)categoryId {
  return [MenuData objectForKey:@"Name" at:[[types objectForKey:@"CATEGORIES"] objectForKey:categoryId]];
}

-(NSString *)getCategoryNamefForMenuId:(NSString *)menuId {
  // ToDo: improve and not fix
  if ([menuId isEqualToString:@"MENU_ATTRACTION"]) return NSLocalizedString(@"menu.button.attractions", nil);
  else if ([menuId isEqualToString:@"MENU_CATERING"]) return NSLocalizedString(@"menu.button.catering", nil);
  else if ([menuId isEqualToString:@"MENU_DINING"]) return NSLocalizedString(@"menu.button.dining", nil);
  else if ([menuId isEqualToString:@"MENU_RESTROOM"]) return NSLocalizedString(@"menu.button.restroom", nil);
  else if ([menuId isEqualToString:@"MENU_SERVICE"]) return NSLocalizedString(@"menu.button.service", nil);
  else if ([menuId isEqualToString:@"MENU_SHOP"]) return NSLocalizedString(@"menu.button.shop", nil);
  return nil;
}

-(BOOL)isExcludingCategoryId:(NSString *)categoryId {
  return [excludingCategoryIds containsObject:categoryId];
}

-(BOOL)isExcludingCategoryName:(NSString *)categoryName {
  NSString *categoryId = [self getCategoryId:categoryName];
  return (categoryId == nil)? NO : [excludingCategoryIds containsObject:categoryId];
}

-(NSString *)getIconForTypeIdOrCategoryId:(NSString *)typeCategoryId {
  return [icons objectForKey:typeCategoryId];
}

@end
