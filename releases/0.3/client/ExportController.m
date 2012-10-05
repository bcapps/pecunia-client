//
//  ExportController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 07.08.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "ExportController.h"
#import "Category.h"
#import "BankStatement.h"
#import "ShortDate.h"
#import "StatCatAssignment.h"

static ExportController *exportController = nil;

@implementation ExportController

-(id)init
{
	self = [super init ];
	exportController = self;
	selectedFields = [[NSMutableArray arrayWithCapacity: 10 ] retain ];
	return self;
}

+(ExportController*)controller
{
	return exportController;
}


-(NSArray*)exportedFields
{
/*	
	int i;
	NSArray *fields = [NSArray arrayWithObjects: @"valutaDate", @"date", @"value", @"currency", @"localAccount", 
					   @"localBankCode", @"localName", @"localCountry",
					   @"localSuffix", @"localBranch", @"remoteName", @"purpose", @"remoteAccount", @"remoteBankCode", 
					   @"remoteBankName", @"remoteBankLocation", @"remoteIBAN", @"remoteBranch", @"remoteSuffix",
					   @"transactionKey", @"customerReference", @"bankReference", @"transactionText", @"primaNota",
					   @"textKey", @"transactionCode", @"categories", nil ];
*/	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	return [defaults objectForKey: @"Exporter.fields" ];
/*	
	if(indxs == nil || [indxs count] == 0 ) return nil;
	NSMutableArray	*result = [NSMutableArray arrayWithCapacity:20 ];
	for(i=0; i<[indxs count ]; i++) [result addObject: [fields objectAtIndex: [[indxs objectAtIndex:i ] intValue ] ] ];
	return result;
*/ 
}

-(void)startExport: (Category*)cat fromDate:(ShortDate*)from toDate:(ShortDate*)to
{
	NSSavePanel *sp;
	NSError		*error = nil;
	int runResult;

	// which fields shall be exported?
	NSArray	*fields = [self exportedFields ];
	if(fields == nil) {
		NSRunAlertPanel(NSLocalizedString(@"AP71", @""),
						NSLocalizedString(@"AP72", @""),
						NSLocalizedString(@"ok", @"Ok"),
						nil,
						nil);
		return;
	}
	
	[self setValue:  [to highDate ] forKey: @"toDate" ];
	[self setValue:  [from lowDate ] forKey: @"fromDate" ];
	
	/* create or get the shared instance of NSSavePanel */
	sp = [NSSavePanel savePanel];
	
	/* set up new attributes */
	[sp setAccessoryView:accessoryView];
	[sp setTitle: @"Exportdatei wählen" ];
	//	[sp setRequiredFileType:@"txt"];
	
	/* display the NSSavePanel */
	runResult = [sp runModalForDirectory:NSHomeDirectory() file:[[cat name] stringByAppendingString:@".csv"]];
	
	/* if successful, save file under designated name */
	if (runResult == NSOKButton) {
		// init date formatter
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		
		NSMutableString* res = [NSMutableString stringWithCapacity: 1000 ];
		NSArray* cats = [[cat allChildren ] allObjects ];

		ShortDate *from_Date = [ShortDate dateWithDate: fromDate ];
		ShortDate *to_Date = [ShortDate dateWithDate: toDate ];
		
		// addObjectsFromArray
		Category *cat;
		NSSortDescriptor	*sd = [[[NSSortDescriptor alloc] initWithKey:@"statement.date" ascending:NO] autorelease];
		for(cat in cats) {
			NSArray* stats = [cat statementsFrom: from_Date to: to_Date withChildren: withChildren ];
			stats = [stats sortedArrayUsingDescriptors:[NSArray arrayWithObject:sd ] ];
			for(StatCatAssignment *stat in stats) {
				NSString* s = [stat stringForFields: fields usingDateFormatter: dateFormatter ];
				[res appendString: s ];
			}
		}
		
		[dateFormatter release ];
		
		if([res writeToFile: [sp filename ] atomically: NO encoding: NSUTF8StringEncoding error: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		};
		// issue success message
		NSRunInformationalAlertPanel(NSLocalizedString(@"AP71", @""),
									 NSLocalizedString(@"AP74", @""),
									 NSLocalizedString(@"ok", @"Ok"),
									 nil, nil,
									 [sp filename ]
									 );
	}
}



@end