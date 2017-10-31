//
//  SearchData.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 23.05.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "SearchData.h"
#import "MenuData.h"
#import "Attraction.h"
#import "Categories.h"

@implementation SearchData

@synthesize accuracy;
@synthesize allParkDetails;
@synthesize searchedParkIds;
@synthesize searchedAttributes;

+(NSArray *)defaultSearchAttributes {
  return [NSArray arrayWithObjects:NSLocalizedString(@"search.attribute.attraction.name", nil),
          NSLocalizedString(@"search.attribute.category", nil),
          NSLocalizedString(@"search.attribute.type", nil),
          NSLocalizedString(@"search.attribute.description", nil),
          nil];
}

-(id)initWithDetails:(NSDictionary *)parkDetails {
  self = [super init];
  if (self != nil) {
    accuracy = 0.8;
    allParkDetails = [parkDetails retain];
    searchedParkIds = [[NSMutableArray alloc] initWithArray:[allParkDetails allKeys]];
    [searchedParkIds sortUsingComparator:(NSComparator)^(id obj1, id obj2){
      NSString *parkName1 = [[allParkDetails objectForKey:obj1] objectForKey:@"Parkname"];
      NSString *parkName2 = [[allParkDetails objectForKey:obj2] objectForKey:@"Parkname"];
      return [parkName1 compare:parkName2]; }];
    searchedAttributes = [[NSMutableArray alloc] initWithArray:[SearchData defaultSearchAttributes]];
    [searchedAttributes removeObject:NSLocalizedString(@"search.attribute.description", nil)];
  }
  return self;
}

-(void)dealloc {
  [allParkDetails release];
  [searchedParkIds release];
  [searchedAttributes release];
  [super dealloc];
}

+(float)getDistanceGram:(unsigned long)n source:(const char *)source target:(const char *)target {
  unsigned long sl = strlen(source);
  unsigned long tl = strlen(target);
  if (sl == 0 || tl == 0) return (sl == tl)? 1 : 0;
  if (sl < n || tl < n) {
    int cost = 0;
    for (unsigned long i = 0, ni = MIN(sl, tl); i < ni; ++i) {
      if (source[i] == target[i]) ++cost;
    }
    return ((float)cost)/MAX(sl, tl);
  }
  // construct sa with prefix
  char *sa = malloc((sl+n-1)*sizeof(char));
  for (unsigned long i = 0; i < n-1; ++i) sa[i] = 0;
  for (unsigned long i = 0; i < sl; ++i) sa[i+n-1] = source[i];
  
  float *p = malloc((sl+1)*sizeof(float)); //'previous' cost array, horizontally
  float *d = malloc((sl+1)*sizeof(float)); // cost array, horizontally
  char *t_j = malloc(n*sizeof(char)); // jth n-gram of t
  
  for (unsigned long i = 0; i <= sl; ++i) p[i] = i;
  for (unsigned long j = 1; j <= tl; ++j) {
    // construct t_j n-gram
    if (j < n) {
      for (unsigned long ti = 0; ti < n-j; ++ti) t_j[ti] = 0;
      for (unsigned long ti = 0; ti < j; ++ti) t_j[ti+n-j] = target[ti];
    } else {
      for (unsigned long ti = j-n; ti < j; ++ti) t_j[ti-(j-n)] = target[ti];
    }
    d[0] = j;
    for (unsigned long i = 1; i <= sl; ++i) {
      int cost = 0;
      unsigned long tn = n;
      //compare sa to t_j
      for (int ni = 0; ni < n; ++ni) {
        if (sa[i-1+ni] != t_j[ni]) ++cost;
        else if (sa[i-1+ni] == 0) --tn; //discount matches on prefix
      }
      float ec = ((float)cost)/tn;
      // minimum of cell to the left+1, to the top+1, diagonally left and up +cost
      d[i] = MIN(MIN(d[i-1]+1, p[i]+1),  p[i-1]+ec);
    }
    // copy current distance counts to 'previous row' distance counts
    float *_d = p;
    p = d;
    d = _d;
  }
  // our last action in the above loop was to switch d and p, so p now
  // actually has the most recent cost counts
  float dist = 1.0f - (((float)p[sl]) / MAX(tl, sl));
  free(sa);
  free(t_j);
  free(d);
  free(p);
  return dist;
}

#define REPLACEMENTS 4
+(NSString *)removingAccents:(NSString *)text {
  static NSString *find = @"äöüß";
  static NSString *replace[REPLACEMENTS] = {@"ae", @"oe", @"ue", @"ss"};
  if (text == nil) return text;
  int l = (int)text.length;
  if (l == 0) return text;
  NSCharacterSet *replaceCharacterSet = [NSCharacterSet characterSetWithCharactersInString:find];
  NSRange firstOccurance = [text rangeOfCharacterFromSet:replaceCharacterSet];
  BOOL containsUpperLetters = ([text rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].length > 0);
  BOOL containsAccentLetters = ([text rangeOfCharacterFromSet:[NSCharacterSet decomposableCharacterSet]].length > 0);
  if (firstOccurance.length == 0 && !containsUpperLetters && !containsAccentLetters) return text;
  if (firstOccurance.length > 0) {
    NSMutableString *s = [[NSMutableString alloc] initWithCapacity:l];
    if (firstOccurance.location > 0) [s appendString:[text substringToIndex:firstOccurance.location]];
    for (int i = (int)firstOccurance.location; i < l; ++i) {
      unichar c = [text characterAtIndex:i];
      if ([replaceCharacterSet characterIsMember:c]) {
        int j = 0;
        while (j < REPLACEMENTS && c != [find characterAtIndex:j]) ++j;
        if (j < REPLACEMENTS) [s appendString:replace[j]];
      } else {
        [s appendFormat:@"%C", c];
      }
    }
    text = [NSString stringWithString:s];
    [s release];
  }
  if (containsAccentLetters) { // removing accents
    NSString *t = [[NSString alloc] initWithData:[text dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] encoding:NSASCIIStringEncoding];
    text = [NSString stringWithString:t];
    [t release];
  }
  if (containsUpperLetters) {
    l = (int)[text length];
    const char* c = [text UTF8String];
    l += strlen(c+l);
    char *target = malloc(l+1);
    for (int i = 0; i < l; ++i, ++c) {
      char ch = *c;
      if (!ch) break;
      if (isupper(ch)) ch = tolower(ch);
      target[i] = ch;
    }
    target[l] = '\0';
    text = [NSString stringWithUTF8String:target];
    free(target);
  }
  return text;
}

+(NSString *)simplifyText:(NSString *)text {
  int l = (int)[text length];
  if (l == 0) return nil;
  text = [SearchData removingAccents:text];
  NSCharacterSet *ignorePreSuffixCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@".\",®()'/\\- "];
  NSCharacterSet *numberCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789.,/"];
  if ([text rangeOfCharacterFromSet:ignorePreSuffixCharacterSet].length == 0 &&
      [text rangeOfCharacterFromSet:numberCharacterSet].length == 0) return text;
  BOOL isNumber = YES;
  int ignorePos = 0;
  l = (int)[text length];
  NSMutableString *s = [[NSMutableString alloc] initWithCapacity:l];
  for (int i = 0; i < l; ++i) {
    unichar c = [text characterAtIndex:i];
    BOOL ignore = [ignorePreSuffixCharacterSet characterIsMember:c];
    if (ignorePos > 0 || !ignore) {
      if (isNumber && !ignore && ![numberCharacterSet characterIsMember:c]) isNumber = NO;
      if (!ignore) ignorePos = (int)[s length]+1;
      [s appendFormat:@"%C", c];
    }
  }
  text = (isNumber && ignorePos < 3)? nil : [NSString stringWithString:[s substringToIndex:ignorePos]];
  [s release];
  return text;
}

-(BOOL)compare:(const char **)searchTokens numberOfSearchTokens:(int)n with:(NSString *)text minSearchLength:(int)minSearchLength known:(NSMutableSet *)knownTokens ignore:(NSMutableSet *)ignoreTokens attributeId:(NSString *)attributeId {
  if (attributeId == nil || ![searchedAttributes containsObject:attributeId]) return NO;
  text = [SearchData simplifyText:text];
  if (text == nil) return NO;
  NSRange range = [text rangeOfString:@" "];
  if (range.length == 0) {
    if ([knownTokens containsObject:text]) return YES;
    if (![ignoreTokens containsObject:text]) {
      if ([text length] >= minSearchLength) {
        const char* s = [text UTF8String];
        for (int i = 0; i < n; ++i) {
          if ((accuracy == 1.0f && strstr(s, searchTokens[i]) != NULL) || (accuracy < 1.0f && [SearchData getDistanceGram:2 source:searchTokens[i] target:s] >= accuracy)) {
            [knownTokens addObject:text];
            return YES;
          }
        }
      }
      [ignoreTokens addObject:text];
    }
  } else {
    for (text in [text componentsSeparatedByString:@" "]) {
      if ([knownTokens containsObject:text]) return YES;
      if (![ignoreTokens containsObject:text]) {
        if ([text length] >= minSearchLength) {
          const char* s = [text UTF8String];
          for (int i = 0; i < n; ++i) {
            if ((accuracy == 1.0f && strstr(s, searchTokens[i]) != NULL) || (accuracy < 1.0f && [SearchData getDistanceGram:2 source:searchTokens[i] target:s] >= accuracy)) {
              [knownTokens addObject:text];
              return YES;
            }
          }
        }
        [ignoreTokens addObject:text];
      }
    }
  }
  return NO;
}

-(NSDictionary *)search:(NSString *)text {
  int n = (int)searchedParkIds.count;
  if (n == 0) return nil;
  text = [SearchData simplifyText:text];
  if (text == nil) return nil;
  NSLog(@"simplified search text: %@", text);
  NSMutableSet *ignoreTokens = [[NSMutableSet alloc] initWithCapacity:5000];
  NSMutableSet *knownTokens = [[NSMutableSet alloc] initWithCapacity:5000];
  NSMutableDictionary *result = [[[NSMutableDictionary alloc] initWithCapacity:n] autorelease];
  Categories *categories = [Categories getCategories];
  NSRange range = [text rangeOfString:@" "];
  NSArray *searchTokens = (range.length == 0)? [NSArray arrayWithObject:text] : [text componentsSeparatedByString:@" "];
  int numberOfSearchTokens = (int)searchTokens.count;
  int minSearchLength = (int)text.length;
  const char **cSearchTokens = malloc(numberOfSearchTokens*sizeof(const char*));
  for (int i = 0; i < numberOfSearchTokens; ++i) {
    NSString *t = [searchTokens objectAtIndex:i];
    cSearchTokens[i] = [t UTF8String];
    if ([t length] < minSearchLength) minSearchLength = (int)t.length;
  }
  if (minSearchLength > 0) --minSearchLength;
  NSString *descriptionId = NSLocalizedString(@"search.attribute.description", nil);
  for (NSString *parkId in searchedParkIds) {
    NSDictionary *attractionsDetails = (descriptionId == nil || ![searchedAttributes containsObject:descriptionId])? nil : [[MenuData getAllAttractionDetails:parkId cache:NO] retain];
    NSMutableArray *attractions = [[NSMutableArray alloc] initWithCapacity:100];
    NSEnumerator *i = [[Attraction getAllAttractions:parkId reload:NO] objectEnumerator];
    while (TRUE) {
      Attraction *attraction = [i nextObject];
      if (attraction == nil) break;
      // attraction name
      if ([self compare:cSearchTokens numberOfSearchTokens:(int)numberOfSearchTokens with:attraction.stringAttractionName minSearchLength:minSearchLength known:knownTokens ignore:ignoreTokens attributeId:NSLocalizedString(@"search.attribute.attraction.name", nil)]) [attractions addObject:attraction];
      // category and type
      else {
        BOOL added = YES;
        NSString *t = attraction.typeName;
        if (t != nil) {
          if ([self compare:cSearchTokens numberOfSearchTokens:(int)numberOfSearchTokens with:t minSearchLength:minSearchLength known:knownTokens ignore:ignoreTokens attributeId:NSLocalizedString(@"search.attribute.type", nil)]) [attractions addObject:attraction];
          else {
            added = NO;
            NSArray *a = [categories getCategoryIds:attraction.typeId];
            if (a != nil) {
              for (NSString *t in a) {
                if ([self compare:cSearchTokens numberOfSearchTokens:(int)numberOfSearchTokens with:t minSearchLength:minSearchLength known:knownTokens ignore:ignoreTokens attributeId:NSLocalizedString(@"search.attribute.category", nil)]) {
                  [attractions addObject:attraction];
                  added = YES;
                  break;
                }
              }
            }
          }
        }
        if (!added) {
          NSDictionary *details = [attractionsDetails objectForKey:attraction.attractionId];
          if (details != nil) {
            NSString *t = [MenuData objectForKey:@"Kurzbeschreibung" at:details];
            if (t != nil && [self compare:cSearchTokens numberOfSearchTokens:(int)numberOfSearchTokens with:t minSearchLength:minSearchLength known:knownTokens ignore:ignoreTokens attributeId:descriptionId]) [attractions addObject:attraction];
          }
        }
      }
    }
    //NSLog(@"#found attractions: %d", [attractions count]);
    if ([attractions count] > 0) [result setObject:attractions forKey:parkId];
    [attractions release];
    [attractionsDetails release];
  }
  free(cSearchTokens);
  [knownTokens release];
  [ignoreTokens release];
  return result;
}

@end
