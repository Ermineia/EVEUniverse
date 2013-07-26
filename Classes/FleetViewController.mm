//
//  FleetViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 12/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FleetViewController.h"
#import "FittingViewController.h"
#import "EVEDBAPI.h"
#import "ModuleCellView.h"
#import "FleetMemberCellView.h"
#import "UITableViewCell+Nib.h"
#import "NSString+Fitting.h"
#import "ItemViewController.h"
#import "EUOperationQueue.h"
#import "ShipFit.h"

#import "ItemInfo.h"

#define ActionButtonCharacter NSLocalizedString(@"Switch Character", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonSelect NSLocalizedString(@"Set Active Ship", nil)
#define ActionButtonShowShipInfo NSLocalizedString(@"Ship Info", nil)
#define ActionButtonAddShip NSLocalizedString(@"Add Ship", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonBooster NSLocalizedString(@"Booster", nil)
#define ActionButtonSetFleetBooster NSLocalizedString(@"Set Fleet Booster", nil)
#define ActionButtonSetWingBooster NSLocalizedString(@"Set Wing Booster", nil)
#define ActionButtonSetSquadBooster NSLocalizedString(@"Set Squad Booster", nil)
#define ActionButtonRemoveBooster NSLocalizedString(@"Remove Booster", nil)

@interface FleetViewController()
@property (nonatomic, strong) NSMutableArray* pilots;
@property (nonatomic, strong) NSIndexPath *modifiedIndexPath;


@end

@implementation FleetViewController

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 if (self) {
 // Custom initialization.
 }
 return self;
 }
 */

/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad {
 [super viewDidLoad];
 }
 */

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewWillAppear:(BOOL)animated {
	[self update];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.tableView = nil;
/*	[modifiedIndexPath release];
	modifiedIndexPath = nil;
	[pilots release];
	pilots = nil;*/
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.pilots.count + 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row >= self.pilots.count) {
		NSString *cellIdentifier = @"ModuleCellView";
		ModuleCellView *cell = (ModuleCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		cell.iconView.image = [UIImage imageNamed:@"Icons/icon17_04.png"];
		cell.titleLabel.text = NSLocalizedString(@"Add Fleet Member", nil);
		cell.stateView.image = nil;
		return cell;
	}
	else {
		NSString *cellIdentifier = @"FleetMemberCellView";
		FleetMemberCellView *cell = (FleetMemberCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [FleetMemberCellView cellWithNibName:@"FleetMemberCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		NSDictionary* row = [self.pilots objectAtIndex:indexPath.row];
		ItemInfo* ship = [row valueForKey:@"ship"];
		cell.titleLabel.text = [row valueForKey:@"title"];
		cell.fitNameLabel.text = [row valueForKey:@"fitName"];
		cell.iconView.image = [UIImage imageNamed:[ship typeSmallImageName]];
		if (self.fittingViewController.fit == [[self.pilots objectAtIndex:indexPath.row] valueForKey:@"fit"])
			cell.stateView.image = [UIImage imageNamed:@"checkmark.png"];
		else
			cell.stateView.image = nil;
		return cell;
	}
}


#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [[self tableView:aTableView cellForRowAtIndexPath:indexPath] frame].size.height;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.row == self.pilots.count) {
		[self.fittingViewController addFleetMember];
	}
	else {
		UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
		[actionSheet addButtonWithTitle:ActionButtonShowShipInfo];
		[actionSheet addButtonWithTitle:ActionButtonCharacter];
		ShipFit* fit = [[self.pilots objectAtIndex:indexPath.row] valueForKey:@"fit"];

		if (fit != self.fittingViewController.fit) {
			[actionSheet addButtonWithTitle:ActionButtonSelect];
		}
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			eufe::Character* character = fit.character;
			eufe::Gang* gang = self.fittingViewController.fittingEngine->getGang();
			
			bool isBooster = false;
			if (gang->getFleetBooster() != character)
				[actionSheet addButtonWithTitle:ActionButtonSetFleetBooster];
			else
				isBooster = true;
			
			if (gang->getWingBooster() != character)
				[actionSheet addButtonWithTitle:ActionButtonSetWingBooster];
			else
				isBooster = true;
			
			if (gang->getSquadBooster() != character)
				[actionSheet addButtonWithTitle:ActionButtonSetSquadBooster];
			else
				isBooster = true;
			
			if (isBooster)
				[actionSheet addButtonWithTitle:ActionButtonRemoveBooster];
		}
		else
			[actionSheet addButtonWithTitle:ActionButtonBooster];

		if (indexPath.row > 0 && fit != self.fittingViewController.fit) {
			[actionSheet addButtonWithTitle:ActionButtonDelete];
			actionSheet.destructiveButtonIndex = actionSheet.numberOfButtons - 1;
		}
		
		[actionSheet addButtonWithTitle:ActionButtonCancel];
		actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
		[actionSheet showFromRect:[aTableView rectForRowAtIndexPath:indexPath] inView:aTableView animated:YES];
		self.modifiedIndexPath = indexPath;
	}
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];
	if ([button isEqualToString:ActionButtonCharacter]) {
		ShipFit* fit = [[self.pilots objectAtIndex:self.modifiedIndexPath.row] valueForKey:@"fit"];
		[self.fittingViewController selectCharacterForFit:fit];
	}
	else if ([button isEqualToString:ActionButtonSelect]) {
		self.fittingViewController.fit = [[self.pilots objectAtIndex:self.modifiedIndexPath.row] valueForKey:@"fit"];
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonDelete]) {
		ShipFit* fit = [[self.pilots objectAtIndex:self.modifiedIndexPath.row] valueForKey:@"fit"];
		[self.fittingViewController.fits removeObject:fit];
		self.fittingViewController.fittingEngine->getGang()->removePilot(fit.character);
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonBooster]) {
		UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
		ShipFit* fit = [[self.pilots objectAtIndex:self.modifiedIndexPath.row] valueForKey:@"fit"];
		eufe::Character* character = fit.character;
		eufe::Gang* gang = self.fittingViewController.fittingEngine->getGang();
		
		bool isBooster = false;
		if (gang->getFleetBooster() != character)
			[actionSheet addButtonWithTitle:ActionButtonSetFleetBooster];
		else
			isBooster = true;

		if (gang->getWingBooster() != character)
			[actionSheet addButtonWithTitle:ActionButtonSetWingBooster];
		else
			isBooster = true;

		if (gang->getSquadBooster() != character)
			[actionSheet addButtonWithTitle:ActionButtonSetSquadBooster];
		else
			isBooster = true;
		
		if (isBooster) {
			[actionSheet addButtonWithTitle:ActionButtonRemoveBooster];
			actionSheet.destructiveButtonIndex = actionSheet.numberOfButtons - 1;
		}
		
		[actionSheet addButtonWithTitle:ActionButtonCancel];
		actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
		[actionSheet showFromRect:[self.tableView rectForRowAtIndexPath:self.modifiedIndexPath] inView:self.tableView animated:YES];
		
	}
	else if ([button isEqualToString:ActionButtonSetFleetBooster]) {
		ShipFit* fit = [[self.pilots objectAtIndex:self.modifiedIndexPath.row] valueForKey:@"fit"];
		self.fittingViewController.fittingEngine->getGang()->setFleetBooster(fit.character);
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonSetWingBooster]) {
		ShipFit* fit = [[self.pilots objectAtIndex:self.modifiedIndexPath.row] valueForKey:@"fit"];
		self.fittingViewController.fittingEngine->getGang()->setWingBooster(fit.character);
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonSetSquadBooster]) {
		ShipFit* fit = [[self.pilots objectAtIndex:self.modifiedIndexPath.row] valueForKey:@"fit"];
		self.fittingViewController.fittingEngine->getGang()->setSquadBooster(fit.character);
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonRemoveBooster]) {
		ShipFit* fit = [[self.pilots objectAtIndex:self.modifiedIndexPath.row] valueForKey:@"fit"];
		eufe::Character* character = fit.character;
		eufe::Gang* gang = self.fittingViewController.fittingEngine->getGang();
		
		if (gang->getFleetBooster() == character)
			gang->removeFleetBooster();
		else if (gang->getWingBooster() == character)
			gang->removeWingBooster();
		else if (gang->getSquadBooster() == character)
			gang->removeSquadBooster();
		
		[self.fittingViewController update];
	}
	else if ([button isEqualToString:ActionButtonShowShipInfo]) {
		ItemInfo* itemInfo = [[self.pilots objectAtIndex:self.modifiedIndexPath.row] valueForKey:@"ship"];
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		
		[itemInfo updateAttributes];
		itemViewController.type = itemInfo;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self.fittingViewController presentModalViewController:navController animated:YES];
		}
		else
			[self.fittingViewController.navigationController pushViewController:itemViewController animated:YES];
	}
}

#pragma mark FittingSection

- (void) update {
	NSMutableArray* pilotsTmp = [NSMutableArray array];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ImplantsViewController+Update" name:NSLocalizedString(@"Updating Fleet", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		@synchronized(self.fittingViewController) {
			eufe::Gang* gang = self.fittingViewController.fittingEngine->getGang();
			
			eufe::Character* fleetBooster = gang->getFleetBooster();
			eufe::Character* wingBooster = gang->getWingBooster();
			eufe::Character* squadBooster = gang->getSquadBooster();
			
			//for (i = characters.begin(); i != end; i++) {
			float n = self.fittingViewController.fits.count;
			float i = 0;
			for (ShipFit* fit in self.fittingViewController.fits) {
				weakOperation.progress = i++ / n;
				eufe::Character* character = fit.character;
				ItemInfo* ship = [ItemInfo itemInfoWithItem:character->getShip() error:NULL];
				NSString *booster = nil;
				
				if (character == fleetBooster)
					booster = NSLocalizedString(@" (Fleet Booster)", nil);
				else if (character == wingBooster)
					booster = NSLocalizedString(@" (Wing Booster)", nil);
				else if (character == squadBooster)
					booster = NSLocalizedString(@" (Squad Booster)", nil);
				else
					booster = @"";
				
				NSMutableDictionary* row = [NSMutableDictionary dictionaryWithObjectsAndKeys:ship, @"ship",
											fit, @"fit",
											[NSString stringWithFormat:@"%@ - %s%@", ship.typeName, character->getCharacterName(), booster], @"title",
											fit.fitName ? fit.fitName : ship.typeName, @"fitName", nil];
				[pilotsTmp addObject:row];
			}
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.pilots = pilotsTmp;
			[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
