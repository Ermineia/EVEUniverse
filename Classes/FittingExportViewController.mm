//
//  FittingExportViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 06.04.12.
//  Copyright (c) 2012 Belprog. All rights reserved.
//

#import "FittingExportViewController.h"
#import "UIDevice+IP.h"
#import "EUOperationQueue.h"
#import "Globals.h"
#import "EVEDBAPI.h"
#import "ShipFit.h"
#import "ItemInfo.h"
#import "NSArray+GroupBy.h"
#include "eufe.h"
#import "EUStorage.h"

@interface FittingExportViewController ()
@property(nonatomic, strong) EUHTTPServer *server;
@property(nonatomic, strong) NSArray* fits;
@property(nonatomic, strong) NSString* page;


- (void) updateAddress;
- (NSString*) eveXMLWithFit:(NSDictionary*) fit;
- (NSString*) dnaWithFit:(NSDictionary*) fit;

@end

@implementation FittingExportViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)]];
	self.title = NSLocalizedString(@"Export", nil);
	
	NSMutableArray* fitsTmp = [NSMutableArray array];
	NSMutableString* eveXML = [NSMutableString string];
	NSMutableString *pageTmp = [NSMutableString stringWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"fits" ofType:@"html"]] encoding:NSUTF8StringEncoding error:nil];
	
//	[eveXML appendString:@"<?xml version=\"1.0\" ?>\n<fittings>\n"];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"FittingExportViewController" name:NSLocalizedString(@"Exporting Fits", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^{
		EUStorage* storage = [EUStorage sharedStorage];
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"ShipFit" inManagedObjectContext:storage.managedObjectContext];
		[fetchRequest setEntity:entity];
		
		NSError *error = nil;
		NSMutableArray *fitsArray = [NSMutableArray arrayWithArray:[storage.managedObjectContext executeFetchRequest:fetchRequest error:&error]];

		[eveXML appendString:[ShipFit allFitsEveXML]];
		
		[fitsArray sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
		[fitsTmp addObjectsFromArray:[fitsArray arrayGroupedByKey:@"type.groupID"]];
		[fitsTmp sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			ShipFit* a = [obj1 objectAtIndex:0];
			ShipFit* b = [obj2 objectAtIndex:0];
			return [a.type.group.groupName compare:b.type.group.groupName];
		}];
		weakOperation.progress = 0.75;
		
		NSMutableString* body = [NSMutableString string];
		NSInteger groupID = 0;
		for (NSArray* group in fitsTmp) {
			NSString* groupName = [[group objectAtIndex:0] valueForKeyPath:@"type.group.groupName"];
			[body appendFormat:@"<tr><td colspan=4 class=\"group\"><b>%@</b></td></tr>\n", groupName];
			NSInteger fitID = 0;
			for (ShipFit* fit in group) {
				EVEDBInvType* type = fit.type;
				[body appendFormat:@"<tr><td class=\"icon\"><image src=\"%@\" width=32 height=32 /></td><td width=\"20%%\">%@</td><td>%@</td><td width=\"30%%\">Download <a href=\"%d_%d.xml\">EVE XML file</a> or <a href=\"javascript:CCPEVE.showFitting('%@');\">Show Fitting</a> ingame</td></tr>\n",
				 type.typeSmallImageName, type.typeName, fit.fitName, groupID, fitID, fit.dna];
				fitID++;
			}
			groupID++;
		}
		
		[pageTmp replaceOccurrencesOfString:@"{body}" withString:body options:0 range:NSMakeRange(0, pageTmp.length)];
		weakOperation.progress = 1.0;
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
//		[eveXML appendString:@"</fittings>"];
		NSString* path = [[Globals documentsDirectory] stringByAppendingPathComponent:@"exportedFits.xml"];
		[eveXML writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
		
		self.fits = fitsTmp;
		
		self.page = pageTmp;
		
		self.server = [[EUHTTPServer alloc] initWithDelegate:self];
		[self.server run];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
	
	[self updateAddress];	
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	self.addressLabel = nil;
	[self.server shutdown];
	self.server = nil;
	self.fits = nil;
	self.page = nil;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateAddress) object:nil];

    // Release any retained subviews of the main view.
}

- (void)dealloc {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateAddress) object:nil];
	[self.server shutdown];
}

#pragma mark EUHTTPServerDelegate

- (void) server:(EUHTTPServer*) server didReceiveRequest:(EUHTTPRequest*) request connection:(EUHTTPConnection*) connection {
	NSURL* url = request.url;
	NSString* path = [url path];
	NSString* extension = [path pathExtension];

	if ([extension compare:@"png" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		NSData* data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:path ofType:nil]];
		CFHTTPMessageRef message;
		if (data) {
			message = CFHTTPMessageCreateResponse(NULL, 200, NULL, kCFHTTPVersion1_0);
			connection.response.message = message;

			CFHTTPMessageSetBody(connection.response.message, (__bridge CFDataRef)data);
			CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef) @"Content-Length", (__bridge CFStringRef) [NSString stringWithFormat:@"%d", data.length]);
			CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef) @"Content-Type", (__bridge CFStringRef) @"image/png");
			CFRelease(message);
		}
		else {
			message = CFHTTPMessageCreateResponse(NULL, 404, NULL, kCFHTTPVersion1_0);
			connection.response.message = message;
			CFRelease(message);
		}
		[connection.response run];
	}
	else if ([extension compare:@"xml" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		NSArray* components = [[[path lastPathComponent] stringByDeletingPathExtension] componentsSeparatedByString:@"_"];
		NSString* xml = nil;
		NSString* typeName = nil;
		if (components.count == 2) {
			NSInteger groupID = [[components objectAtIndex:0] integerValue];
			NSInteger fitID = [[components objectAtIndex:1] integerValue];
			if (self.fits.count > groupID) {
				NSArray* group = [self.fits objectAtIndex:groupID];
				if (group.count > fitID) {
					ShipFit* fit = [group objectAtIndex:fitID];
					xml = [NSString stringWithFormat:@"<?xml version=\"1.0\" ?>\n<fittings>\n%@</fittings>", [fit eveXML]];
					typeName = fit.type.typeName;
				}
			}
		}
		else if ([[path lastPathComponent] compare:@"allFits.xml" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
			NSString* path = [[Globals documentsDirectory] stringByAppendingPathComponent:@"exportedFits.xml"];
			xml = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
			typeName = @"allFits";
		}
		
		CFHTTPMessageRef message;
		if (xml) {
			CFHTTPMessageRef message = CFHTTPMessageCreateResponse(NULL, 200, NULL, kCFHTTPVersion1_0);
			connection.response.message = message;
			CFRelease(message);
			NSData* bodyData = [xml dataUsingEncoding:NSUTF8StringEncoding];
			CFHTTPMessageSetBody(connection.response.message, (__bridge CFDataRef) bodyData);
			CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef) @"Content-Length", (__bridge CFStringRef) [NSString stringWithFormat:@"%d", bodyData.length]);
			
			CFHTTPMessageSetHeaderFieldValue(connection.response.message, (CFStringRef) @"Content-Type", (CFStringRef) @"application/xml");
			CFHTTPMessageSetHeaderFieldValue(connection.response.message,
											 (__bridge CFStringRef) @"Content-Disposition",
											 (__bridge CFStringRef) [NSString stringWithFormat:@"attachment; filename=\"%@.xml\"", typeName]);
		}
		else {
			message = CFHTTPMessageCreateResponse(NULL, 404, NULL, kCFHTTPVersion1_0);
			connection.response.message = message;
			CFRelease(message);
		}
		[connection.response run];
	}
	else {
		CFHTTPMessageRef message = CFHTTPMessageCreateResponse(NULL, 200, NULL, kCFHTTPVersion1_0);
		connection.response.message = message;
		CFRelease(message);
		NSData* bodyData = [self.page dataUsingEncoding:NSUTF8StringEncoding];
		CFHTTPMessageSetBody(connection.response.message, (__bridge CFDataRef) bodyData);
		CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef) @"Content-Length", (__bridge CFStringRef) [NSString stringWithFormat:@"%d", bodyData.length]);
		CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef) @"Content-Type", (__bridge CFStringRef) @"text/html; charset=UTF-8");
		[connection.response run];
	}
}

#pragma mark - Private

- (void) updateAddress {
	NSArray *addresses = [UIDevice localIPAddresses];
	if (addresses.count == 0) {
		[self performSelector:@selector(updateAddress) withObject:nil afterDelay:1];
		self.addressLabel.text = NSLocalizedString(@"Unknown IP Address", nil);
	}
	else {
		NSMutableString *text = [NSMutableString string];
		for (NSString *ip in addresses)
			[text appendFormat:@"http://%@:8080\n", ip];
		self.addressLabel.text = text;
		CGRect r = CGRectMake(self.addressLabel.frame.origin.x, self.addressLabel.frame.origin.y, self.addressLabel.frame.size.width, 100);
		r = [self.addressLabel textRectForBounds:r limitedToNumberOfLines:0];
		r.origin = self.addressLabel.frame.origin;
		r.size.width = self.addressLabel.frame.size.width;
		r.size.height += 20;
		self.addressLabel.frame = r;
	}
}

- (NSString*) eveXMLWithFit:(NSDictionary*) record {
	NSMutableString* xml = [NSMutableString string];
	NSDictionary* fit = [record valueForKey:@"fit"];
	EVEDBInvType* ship = [EVEDBInvType invTypeWithTypeID:[[fit valueForKeyPath:@"shipID"] integerValue] error:nil];
	
	[xml appendFormat:@"<fitting name=\"%@\">\n<description value=\"Neocom fitting engine\"/>\n<shipType value=\"%@\"/>\n", [record valueForKey:@"fitName"], ship.typeName];
	

	NSMutableArray* arrays[] = {[fit valueForKey:@"highs"], [fit valueForKey:@"meds"], [fit valueForKey:@"lows"], [fit valueForKey:@"rigs"], [fit valueForKey:@"subsystems"]};
	int counters[5] = {0};
	const char* slots[] = {"hi slot", "med slot", "low slot", "rig slot", "subsystem slot"};
	
	for (int i = 0; i < 5; i++) {
		for (NSDictionary* record in arrays[i]) {
			NSInteger typeID = [[record valueForKey:@"typeID"] integerValue];
			EVEDBInvType* module = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
			[xml appendFormat:@"<hardware slot=\"%s %d\" type=\"%@\"/>\n", slots[i], counters[i]++, module.typeName];
		}
	}
	
	NSCountedSet* drones = [NSCountedSet set];
	
	for (NSDictionary* record in [fit valueForKey:@"drones"]) {
		[drones addObject:[record valueForKey:@"typeID"]];
	}

	for (NSNumber* typeID in drones) {
		EVEDBInvType* drone = [EVEDBInvType invTypeWithTypeID:[typeID integerValue] error:nil];
		[xml appendFormat:@"<hardware slot=\"drone bay\" qty=\"%d\" type=\"%@\"/>\n", [drones countForObject:typeID], drone.typeName];
	}
	[xml appendString:@"</fitting>\n"];
	return xml;
}

- (NSString*) dnaWithFit:(NSDictionary*) record {
	NSMutableString* dna = [NSMutableString string];
	NSDictionary* fit = [record valueForKey:@"fit"];
	NSInteger shipID = [[fit valueForKeyPath:@"shipID"] integerValue];

	NSCountedSet* subsystems = [NSCountedSet set];
	NSCountedSet* highs = [NSCountedSet set];
	NSCountedSet* meds = [NSCountedSet set];
	NSCountedSet* lows = [NSCountedSet set];
	NSCountedSet* rigs = [NSCountedSet set];
	NSCountedSet* drones = [NSCountedSet set];
	NSCountedSet* charges = [NSCountedSet set];
	
	NSCountedSet* slots[] = {subsystems, highs, meds, lows, rigs, drones, charges};
	NSMutableArray* arrays[] = {[fit valueForKey:@"subsystems"], [fit valueForKey:@"highs"], [fit valueForKey:@"meds"], [fit valueForKey:@"lows"], [fit valueForKey:@"rigs"]};

	for (int i = 0; i < 5; i++) {
		for (NSDictionary* record in arrays[i]) {
			NSNumber* typeID = [record valueForKey:@"typeID"];
			NSNumber* chargeID = [record valueForKey:@"chargeID"];
			if (typeID)
				[slots[i] addObject:typeID];
			if (chargeID && ![charges containsObject:chargeID])
				[charges addObject:chargeID];
		}
	}

	for (NSDictionary* record in [fit valueForKey:@"drones"]) {
		[drones addObject:[record valueForKey:@"typeID"]];
	}

	[dna appendFormat:@"%d:", shipID];
	
	for (int i = 0; i < 7; i++) {
		for (NSNumber* typeID in slots[i]) {
			[dna appendFormat:@"%d;%d:", [typeID integerValue], [slots[i] countForObject:typeID]];
		}
	}
	[dna appendString:@":"];
	return dna;
}

@end
