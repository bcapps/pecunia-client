//
//  BankAccount.h
//  Pecunia
//
//  Created by Frank Emminghaus on 01.07.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Category.h"

@class BankQueryResult;
@class PurposeSplitRule;
@class BankStatement;

@interface BankAccount : Category {
	NSDate				*newLatestTransferDate;
	PurposeSplitRule	*purposeSplitRule;
}

-(NSString*)bankCode;
-(NSDate*)latestTransferDate;


-(void)evaluateQueryResult: (BankQueryResult*)res;
-(int)updateFromQueryResult: (BankQueryResult*)result;
-(void)updateStandingOrders:(NSArray*)orders;
-(void)resetIsNew;
-(void)copyStatement:(BankStatement*)stat;
-(NSDate*)nextDateForDate:(NSDate*)date;

+(BankAccount*)bankRootForCode:(NSString*)bankCode;
+(BankAccount*)accountWithNumber:(NSString*)number bankCode:(NSString*)code;

@property (nonatomic, retain) NSDate * latestTransferDate;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSString * bankName;
@property (nonatomic, retain) NSString * bankCode;
@property (nonatomic, retain) NSString * bic;
@property (nonatomic, retain) NSString * iban;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * customerId;
@property (nonatomic, retain) NSString * accountNumber;
@property (nonatomic, retain) NSString * owner;
@property (nonatomic, retain) NSNumber * uid;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSDecimalNumber * balance;
@property (nonatomic, retain) NSNumber * noAutomaticQuery;
@property (nonatomic, retain) NSNumber * collTransfer;
@property (nonatomic, retain) NSNumber * isManual;
@property (nonatomic, retain) NSNumber * isStandingOrderSupported;
@property (nonatomic, retain) NSString * splitRule;
@property (nonatomic, retain) NSString * accountSuffix;

@end

// coalesce these into one @interface BankAccount (CoreDataGeneratedAccessors) section
@interface BankAccount (CoreDataGeneratedAccessors)
@end
