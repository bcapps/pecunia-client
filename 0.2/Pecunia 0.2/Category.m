//
//  Category.m
//  MacBanking
//
//  Created by Frank Emminghaus on 04.07.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import "Category.h"
#import "BankStatement.h"
#import "MOAssistant.h"
#import "ShortDate.h"
#import "BankingController.h"

Category *catRoot = nil;
Category *bankRoot = nil;
Category *nassRoot = nil;

ShortDate *catFromDate = nil;
ShortDate *catToDate = nil;

// balance: sum of own statements
// catSum: sum of balance and child's catSums


@implementation Category

@dynamic rule;
@dynamic name;
@dynamic isBankAcc;
@dynamic currency;
@dynamic parent;
@dynamic isBalanceValid;
@dynamic catSum;
@dynamic balance;


-(void)updateInvalidBalances
{
	NSArray *stats;
	int     i;
	NSMutableSet* childs = [self mutableSetValueForKey: @"children" ];
	if([childs count ] > 0) {
		// first handle children
		NSEnumerator *enumerator = [childs objectEnumerator];
		Category	 *cat;
	
		while ((cat = [enumerator nextObject])) {
			[cat updateInvalidBalances ];
		}
	}
	// now handle self
	if([self.isBalanceValid boolValue ] == NO) {
		NSDecimalNumber	*balance = [NSDecimalNumber zero ];
		
		if([self isBankAccount ]) stats = [[self mutableSetValueForKey: @"statements" ] allObjects ];
		else stats = [self statementsFrom: catFromDate to: catToDate withChildren: NO ];
		
		BankStatement *stat = nil;
		for(i=0; i<[stats count ]; i++) {
			stat = [stats objectAtIndex:i ];
			balance = [balance decimalNumberByAdding: stat.value ];
		}
		if(stat) {
			NSString *curr = stat.currency;
			if(curr != nil && [curr length ] > 0) self.currency = curr;
		}
		self.balance = balance;
		self.isBalanceValid = [NSNumber numberWithBool: YES ];
	}
}

-(void)rebuildValues
{
	NSArray *stats;
	int     i;
	NSMutableSet* childs = [self mutableSetValueForKey: @"children" ];
	if([childs count ] > 0) {
		// first handle children
		NSEnumerator *enumerator = [childs objectEnumerator];
		Category	 *cat;
		
		while ((cat = [enumerator nextObject])) {
			[cat rebuildValues ];
		}
	}
	// now handle self
	NSDecimalNumber	*balance = [NSDecimalNumber zero ];
	
	if([self isBankAccount ]) stats = [[self mutableSetValueForKey: @"statements" ] allObjects ];
	else stats = [self statementsFrom: catFromDate to: catToDate withChildren: NO ];
	
	BankStatement *stat = nil;
	for(i=0; i<[stats count ]; i++) {
		stat = [stats objectAtIndex:i ];
		balance = [balance decimalNumberByAdding: stat.value];
	}
	self.balance = balance;
}

-(NSMutableSet*)combinedStatements
{
	if(![self isBankAccount ]) return [self mutableSetValueForKey: @"statements" ];
	if(self.accountNumber) return [self mutableSetValueForKey: @"statements" ];
	// combine statements
	NSMutableSet *stats = [[[NSMutableSet alloc ] init ] autorelease ];
	NSSet *childs = [self allChildren ];
	NSEnumerator *enumerator = [childs objectEnumerator];
	Category *cat;
	while (cat = [enumerator nextObject]) [stats unionSet: [cat mutableSetValueForKey: @"statements" ] ];
	return stats;
}

-(NSDecimalNumber*)rollup
{
	NSDecimalNumber *res;
	Category		*cat, *cat_old = nil;

	NSMutableSet* childs = [self mutableSetValueForKey: @"children" ];
	NSEnumerator *enumerator = [childs objectEnumerator];
	res = self.balance;
	while ((cat = [enumerator nextObject])) { res = [res decimalNumberByAdding: [cat rollup ] ]; cat_old = cat; }
	self.catSum = res;
	if(cat_old) {
		NSString *curr = cat_old.currency;
		if(curr != nil && [curr length ] > 0) self.currency = curr;
	}
	return res;
}

-(void)invalidateBalance
{
	self.isBalanceValid = [NSNumber numberWithBool: NO ];
}


-(NSDecimalNumber*)valuesOfType: (CatValueType)type from: (ShortDate*)fromDate to: (ShortDate*)toDate
{
	NSDecimalNumber	*result = [NSDecimalNumber zero ];
	NSMutableSet* stats = [self mutableSetValueForKey: @"statements" ];
	NSMutableSet* childs = [self mutableSetValueForKey: @"children" ];

	if([childs count ] > 0) {
		// first handle children
		NSEnumerator *enumerator = [childs objectEnumerator];
		Category	 *cat;
		
		while ((cat = [enumerator nextObject])) {
			result = [result decimalNumberByAdding: [cat valuesOfType: type from: fromDate to: toDate ] ];
		}
	}
	
	if([stats count ] > 0) {
		NSDecimalNumber *zero = [NSDecimalNumber zero ];
		NSEnumerator *enumerator = [stats objectEnumerator ];
		BankStatement *stat;
		while ((stat = [enumerator nextObject])) {
			ShortDate *date = [ShortDate dateWithDate: stat.valutaDate ];
			if(![date isBetween: fromDate and: toDate ]) continue;
			NSDecimalNumber	*value = stat.value;
			if(type == cat_all) result = [result decimalNumberByAdding: value ];
			else {
				if(type == cat_expenses) {
					if([value compare: zero ] == NSOrderedAscending) result = [result decimalNumberByAdding: value ];
				} else {
					if([value compare: zero ] == NSOrderedDescending) result = [result decimalNumberByAdding: value ];
				}
			}
		}
	}
	return result;
}

-(NSArray*)statementsFrom: (ShortDate*)fromDate to: (ShortDate*)toDate withChildren: (BOOL)c
{
	NSMutableArray	*result = [NSMutableArray arrayWithCapacity: 100 ];

	NSMutableSet* stats = [self mutableSetValueForKey: @"statements" ];
	NSMutableSet* childs = [self mutableSetValueForKey: @"children" ];

	if(c == YES && [childs count ] > 0) {
		// first handle children
		NSEnumerator *enumerator = [childs objectEnumerator];
		Category	 *cat;
		
		while ((cat = [enumerator nextObject])) {
			[result addObjectsFromArray: [cat statementsFrom: fromDate to: toDate withChildren: YES ] ];
		}
	}
	
	if([stats count ] > 0) {
		NSEnumerator *enumerator = [stats objectEnumerator ];
		BankStatement *stat;
		while ((stat = [enumerator nextObject])) {
			ShortDate *date = [ShortDate dateWithDate: stat.valutaDate ];
			if(![date isBetween: fromDate and: toDate ]) continue;
			[result addObject: stat ];
		}
	}
	return result;	
}


-(NSString*)accountNumber { return nil; }

-(NSString*)localName
{
	[self willAccessValueForKey:@"name"];
    NSString *n = [self primitiveValueForKey:@"name"];
    [self didAccessValueForKey:@"name"];
	if(self.parent == nil) {
		if([n isEqualToString: @"++bankroot" ]) return NSLocalizedString(@"banking_root", @"Bank Accounts");
		if([n isEqualToString: @"++catroot" ]) return NSLocalizedString(@"category_root", @"Categories");
	}
	if([n isEqualToString: @"++nassroot" ]) return NSLocalizedString(@"nass_root", @"Not assigned");
	return n;
}

-(void)setLocalName: (NSString*)name
{
	[self willAccessValueForKey:@"name"];
    NSString *n = [self primitiveValueForKey:@"name"];
    [self didAccessValueForKey:@"name"];
	NSRange r = [n rangeOfString: @"++" ];
	if(r.location == 0) return;
	[self setValue: name forKey: @"name" ];
}

-(BOOL)isRoot
{
	return self.parent == nil;
}

-(BOOL)isBankAccount
{
	return [self.isBankAcc boolValue ];
}

-(BOOL)isBankingRoot
{
	if( self.parent == nil ) return [self.isBankAcc boolValue ];
	return NO;
}

-(BOOL)isEditable
{
	if(self.parent == nil) return NO;
	NSString *n = [self primitiveValueForKey:@"name"];
	if(n != nil) {
		NSRange r = [n rangeOfString: @"++" ];
		if(r.location == 0) return NO;
	}
	return YES;
//	return [self isMemberOfClass: [Category class ] ];
}

-(BOOL)isRemoveable
{
	if(self.parent == nil) return NO;
	NSString *n = [self primitiveValueForKey:@"name"];
	if(n != nil) {
		NSRange r = [n rangeOfString: @"++" ];
		if(r.location == 0) return NO;
	}
	NSSet* myChildren = [self mutableSetValueForKey: @"children" ];
	if([myChildren count ] > 0) return NO;
	return [self isMemberOfClass: [Category class ] ];
}

-(BOOL)isInsertable
{
	if( [self.isBankAcc boolValue ] == YES) return NO;
//	if( [self valueForKey: @"parent" ] == nil ) return NO;
	NSString *n = [self primitiveValueForKey:@"name"];
	if([n isEqual: @"++nassroot" ]) return NO;
	return TRUE;
}

-(BOOL)isRequestable
{
	if(![self isBankAccount ]) return NO;
	if([[BankingController controller ] requestRunning ]) return NO; else return YES;
}

-(BOOL)isNotAssignedCategory
{
	return self == [Category nassRoot ];
}

-(NSMutableSet*)children
{
	return [self mutableSetValueForKey: @"children" ];
}


-(NSSet*)allChildren
{
	NSMutableSet* childs = [[[NSMutableSet alloc ] init ] autorelease ];
	
	NSSet* myChildren = [self children ];
	NSEnumerator *enumerator = [myChildren objectEnumerator];
	Category	 *cx;
	
	while ((cx = [enumerator nextObject])) {
		NSSet* sub = [cx allChildren ];
		[childs unionSet: sub ];
	}
	[childs addObject: self ];
	return childs;
}

-(NSSet*)siblings
{
	Category* parent = self.parent;
	if(parent == nil) return nil;
	NSMutableSet* set = [NSMutableSet setWithSet: [parent mutableSetValueForKey: @"children" ] ];
	[set removeObject: self ];
	return set;
}

-(NSDictionary*)balanceHistory
{
	int i;
	NSArray* stats = [[self mutableSetValueForKey: @"statements" ] allObjects ];
	NSArray* sortedStats = [stats sortedArrayUsingSelector: @selector(compareValuta:) ];
	NSMutableDictionary* res = [NSMutableDictionary dictionary ];
	NSDecimalNumber* balance = self.balance;
	
	for(i = [sortedStats count ] - 1; i >= 0; i--) {
		BankStatement* stat = [sortedStats objectAtIndex: i ];
		ShortDate *date = [ShortDate dateWithDate: stat.valutaDate ];
		NSDecimalNumber* bal = [res objectForKey: date ];
		if(bal == nil) [res setObject: balance forKey: date ];
		balance = [balance decimalNumberBySubtracting: stat.value ];
	}
	return res;
}

-(BOOL)checkMoveToCategory:(Category*)cat
{
	Category *parent;
	if ([cat isBankAccount]) return NO;
	if (cat == nassRoot) return NO;
	
	// check for cycles
	parent = cat.parent;
	while (parent != nil) {
		if (parent == self) return NO;
		parent = parent.parent;
	}
	return YES;
}

+(Category*)bankRoot
{
	NSError *error = nil;
	if(bankRoot) return bankRoot;
	
	NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];
	NSManagedObjectModel	*model   = [[MOAssistant assistant ] model ];

	NSFetchRequest *request = [model fetchRequestTemplateForName:@"getBankingRoot"];
	NSArray *cats = [context executeFetchRequest:request error:&error];
	if( error != nil || cats == nil || [cats count ] == 0) return nil;
	bankRoot = [cats objectAtIndex: 0 ];
	return bankRoot;
}

+(Category*)catRoot
{
	NSError *error = nil;
	if(catRoot) return catRoot;
	
	NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];
	NSManagedObjectModel	*model   = [[MOAssistant assistant ] model ];
	
	NSFetchRequest *request = [model fetchRequestTemplateForName:@"getCategoryRoot"];
	NSArray *cats = [context executeFetchRequest:request error:&error];
	if( error != nil || cats == nil || [cats count ] == 0) return nil;
	catRoot = [cats objectAtIndex: 0 ];
	return catRoot;
}

+(Category*)nassRoot
{
	NSError *error = nil;
	if(nassRoot) return nassRoot;
	
	NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];
	NSManagedObjectModel	*model   = [[MOAssistant assistant ] model ];
	
	NSFetchRequest *request = [model fetchRequestTemplateForName:@"getNassRoot"];
	NSArray *cats = [context executeFetchRequest:request error:&error];
	if( error != nil || cats == nil || [cats count ] == 0) return nil;
	nassRoot = [cats objectAtIndex: 0 ];
	return nassRoot;
}

+(void)updateCatValues
{
	[[self catRoot ] updateInvalidBalances ];
	[[self catRoot ] rollup ];
}

+(void)setCatReportFrom: (ShortDate*)fDate to: (ShortDate*)tDate
{
	[catFromDate release ];
	[catToDate release ];
	catFromDate = [fDate retain ];
	catToDate = [tDate retain ];
}

+(void)setMonthFromDate: (ShortDate*)date
{
	[catFromDate release ];
	catFromDate = [ShortDate dateWithYear: [date year ] month: [date month ] day: 1 ];
	[catFromDate retain ];
}

+(void)setYearFromDate: (ShortDate*)date
{
	[catFromDate release ];
	catFromDate = [ShortDate dateWithYear: [date year ] month: 1 day: 1 ];
	[catFromDate retain ];
}

+(void)setQuarterFromDate: (ShortDate*)date
{
	int month;
	[catFromDate release ];
	switch([date month ]) {
		case 1:
		case 2:
		case 3: month = 1; break;
		case 4:
		case 5:
		case 6: month = 4; break;
		case 7:
		case 8:
		case 9: month = 7; break;
		case 10:
		case 11:
		case 12: month = 10; break;
	}
	catFromDate = [ShortDate dateWithYear: [date year ] month: month day: 1 ];
	[catFromDate retain ];
}

@end