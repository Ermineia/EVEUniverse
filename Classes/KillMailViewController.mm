//
//  KillMailViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 09.11.12.
//
//

#import "KillMailViewController.h"
#import "Globals.h"
#import "UIImageView+URL.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "KillMailItemCellView.h"
#import "KillMailAttackerCellView.h"
#import "UITableViewCell+Nib.h"
#import "FittingViewController.h"
#import "FitCharacter.h"
#import "ShipFit.h"
#import "EVEAccount.h"
#import "ItemViewController.h"
#import "NSNumberFormatter+Neocom.h"
#import "appearance.h"

@interface KillMailViewController ()
@property (nonatomic, strong) NSMutableArray* itemsSections;
- (IBAction)onOpenFit:(id)sender;
@end

@implementation KillMailViewController

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
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	
	self.title = self.killMail.victim.characterName;

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		self.navigationItem.titleView = self.sectionSegmentedControler;

	if (self.killMail.victim.shipType.group.categoryID == 6)
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Open fit", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onOpenFit:)];

	[self.sectionSegmentedControler setTitle:[NSString stringWithFormat:NSLocalizedString(@"Involved Parties (%d)", nil), self.killMail.attackers.count] forSegmentAtIndex:1];
	
	
	EVEImageSize portraitImageSize;
	EVEImageSize corpImageSize;
	if (RETINA_DISPLAY) {
		portraitImageSize = EVEImageSize128;
		corpImageSize = EVEImageSize64;
	}
	else {
		portraitImageSize = EVEImageSize64;
		corpImageSize = EVEImageSize32;
	}

	self.characterNameLabel.text = self.killMail.victim.characterName;
	[self.characterImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:self.killMail.victim.characterID size:portraitImageSize error:nil]];

	if (self.killMail.victim.allianceID > 0) {
		self.corporationNameLabel.text = self.killMail.victim.corporationName;
		self.allianceNameLabel.text = self.killMail.victim.allianceName;
		[self.allianceImageView setImageWithContentsOfURL:[EVEImage allianceLogoURLWithAllianceID:self.killMail.victim.allianceID size:corpImageSize error:nil]];
		[self.corporationImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:self.killMail.victim.corporationID size:corpImageSize error:nil]];
	}
	else {
		self.allianceNameLabel.text = self.killMail.victim.corporationName;
		[self.allianceImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:self.killMail.victim.corporationID size:corpImageSize error:nil]];
		CGRect frame = self.allianceNameLabel.frame;
		frame.origin.x -= self.corporationImageView.frame.size.width;
		frame.size.width += self.corporationImageView.frame.size.width;
		self.allianceNameLabel.frame = frame;
		
		self.corporationImageView.hidden = YES;
		self.corporationNameLabel.hidden = YES;
	}

	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
	[formatter setDateFormat:@"yyyy.MM.dd HH:mm"];
	self.killTimeLabel.text = [formatter stringFromDate:self.killMail.killTime];
	
	self.shipNameLabel.text = [NSString stringWithFormat:@"%@ (%@)", self.killMail.victim.shipType.typeName, self.killMail.victim.shipType.group.groupName];
	self.shipImageView.image = [UIImage imageNamed:self.killMail.victim.shipType.typeSmallImageName];
	
	self.damageTakenLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ Total Damage Taken", nil), [NSNumberFormatter localizedStringFromNumber:@(self.killMail.victim.damageTaken) numberStyle:NSNumberFormatterDecimalStyle]];
	
	self.solarSystemNameLabel.text = self.killMail.solarSystem.solarSystemName;
	self.securityStatusLabel.text = [NSString stringWithFormat:@"%.1f", self.killMail.solarSystem.security];
	self.regionNameLabel.text = [NSString stringWithFormat:@"< %@ < %@", self.killMail.solarSystem.constellation.constellationName, self.killMail.solarSystem.region.regionName];

	if (self.killMail.solarSystem.security >= 0.5)
		self.securityStatusLabel.textColor = [UIColor greenColor];
	else if (self.killMail.solarSystem.security > 0)
		self.securityStatusLabel.textColor = [UIColor orangeColor];
	else
		self.securityStatusLabel.textColor = [UIColor redColor];
	
	[self.solarSystemNameLabel sizeToFit];
	[self.securityStatusLabel sizeToFit];
	[self.regionNameLabel sizeToFit];

	CGRect frame = self.securityStatusLabel.frame;
	frame.origin.x = CGRectGetMaxX(self.solarSystemNameLabel.frame) + 5;
	self.securityStatusLabel.frame = frame;
	
	frame = self.regionNameLabel.frame;
	frame.origin.x = CGRectGetMaxX(self.securityStatusLabel.frame) + 5;
	self.regionNameLabel.frame = frame;
	
	self.itemsSections = [NSMutableArray array];
	
	if (self.killMail.hiSlots.count > 0)
		[self.itemsSections addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"High power slots", nil), @"title", self.killMail.hiSlots, @"rows", nil]];
	if (self.killMail.medSlots.count > 0)
		[self.itemsSections addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Medium power slots", nil), @"title", self.killMail.medSlots, @"rows", nil]];
	if (self.killMail.lowSlots.count > 0)
		[self.itemsSections addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Low power slots", nil), @"title", self.killMail.lowSlots, @"rows", nil]];
	if (self.killMail.rigSlots.count > 0)
		[self.itemsSections addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Rig power slots", nil), @"title", self.killMail.rigSlots, @"rows", nil]];
	if (self.killMail.subsystemSlots.count > 0)
		[self.itemsSections addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Sub system slots", nil), @"title", self.killMail.subsystemSlots, @"rows", nil]];
	if (self.killMail.droneBay.count > 0)
		[self.itemsSections addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Drone bay", nil), @"title", self.killMail.droneBay, @"rows", nil]];
	if (self.killMail.cargo.count > 0)
		[self.itemsSections addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Cargo", nil), @"title", self.killMail.cargo, @"rows", nil]];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
	[self setCharacterNameLabel:nil];
	[self setAllianceNameLabel:nil];
	[self setCorporationNameLabel:nil];
	[self setCharacterImageView:nil];
	[self setAllianceImageView:nil];
	[self setCorporationImageView:nil];
	[self setKillTimeLabel:nil];
	[self setShipNameLabel:nil];
	[self setSolarSystemNameLabel:nil];
	[self setSecurityStatusLabel:nil];
	[self setRegionNameLabel:nil];
	[self setSectionSegmentedControler:nil];
	[self setDamageTakenLabel:nil];
	[self setShipImageView:nil];
	[self setItemsSections:nil];
	[super viewDidUnload];
}

- (IBAction)onChangeSection:(id)sender {
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (self.sectionSegmentedControler.selectedSegmentIndex == 0)
		return self.itemsSections.count;
	else
		return self.killMail.attackers.count > 0 ? 3 : 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.sectionSegmentedControler.selectedSegmentIndex == 0)
		return [[[self.itemsSections objectAtIndex:section] valueForKey:@"rows"] count];
	else {
		if (section == 0 || section == 1)
			return 1;
		else
			return self.killMail.attackers.count - 1;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.sectionSegmentedControler.selectedSegmentIndex == 0) {
		static NSString *cellIdentifier = @"ItemCell";
		
		GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.accessoryView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
			cell.accessoryView.contentMode = UIViewContentModeScaleToFill;
		}
		
		KillMailItem* item = [[[self.itemsSections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
		cell.textLabel.text = item.type.typeName;
		cell.imageView.image = [UIImage imageNamed:item.type.typeSmallImageName];
		cell.detailTextLabel.text = [NSNumberFormatter neocomLocalizedStringFromNumber:@(item.qty)];
		UIImageView* imageView = (UIImageView*) cell.accessoryView;
		imageView.image = [UIImage imageNamed:item.destroyed ? @"Icons/icon22_11.png" : @"Icons/icon26_11.png"];
		
		int groupStyle = 0;
		if (indexPath.row == 0)
			groupStyle |= GroupedCellGroupStyleTop;
		if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
			groupStyle |= GroupedCellGroupStyleBottom;
		cell.groupStyle = static_cast<GroupedCellGroupStyle>(groupStyle);
		return cell;
	}
	else {
		static NSString *cellIdentifier = @"KillMailAttackerCellView";
		
		KillMailAttackerCellView *cell = (KillMailAttackerCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [KillMailAttackerCellView cellWithNibName:@"KillMailAttackerCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		KillMailAttacker* attacker = nil;
		if (indexPath.section == 0) {
			for (attacker in self.killMail.attackers)
				if (attacker.finalBlow)
					break;
		}
		else if (indexPath.section == 1)
			attacker = [self.killMail.attackers objectAtIndex:0];
		else
			attacker = [self.killMail.attackers objectAtIndex:indexPath.row + 1];
		
		cell.characterNameLabel.text = attacker.characterName;
		cell.corporationNameLabel.text = attacker.corporationName;
		cell.damageDoneLabel.text = [NSString stringWithFormat:@"%@ (%.1f%%)", [NSNumberFormatter localizedStringFromNumber:@(attacker.damageDone) numberStyle:NSNumberFormatterDecimalStyle],
									 self.killMail.victim.damageTaken > 0 ? (float) attacker.damageDone / (float) self.killMail.victim.damageTaken * 100.0 : 0.0];
		
		EVEImageSize portraitImageSize;
		if (RETINA_DISPLAY)
			portraitImageSize = EVEImageSize128;
		else
			portraitImageSize = EVEImageSize64;
		
		[cell.portraitImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:attacker.characterID size:portraitImageSize error:nil]];
		cell.shipImageView.image = [UIImage imageNamed:attacker.shipType.typeSmallImageName];
		cell.weaponImageView.image = [UIImage imageNamed:attacker.weaponType.typeSmallImageName];
	
		int groupStyle = 0;
		if (indexPath.row == 0)
			groupStyle |= GroupedCellGroupStyleTop;
		if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
			groupStyle |= GroupedCellGroupStyleBottom;
		cell.groupStyle = static_cast<GroupedCellGroupStyle>(groupStyle);
		return cell;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (self.sectionSegmentedControler.selectedSegmentIndex == 0)
		return [[self.itemsSections objectAtIndex:section] valueForKey:@"title"];
	else {
		if (section == 0)
			return NSLocalizedString(@"Final blow", nil);
		else if (section == 1)
			return NSLocalizedString(@"Top damage", nil);
		else
			return nil;
	}
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.sectionSegmentedControler.selectedSegmentIndex == 0)
		return 40;
	else
		return 72;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	EVEDBInvType* type = nil;
	if (self.sectionSegmentedControler.selectedSegmentIndex == 0) {
		KillMailItem* item = [[[self.itemsSections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
		type = item.type;
	}
	else {
		KillMailAttacker* attacker = nil;
		if (indexPath.section == 0) {
			for (attacker in self.killMail.attackers)
				if (attacker.finalBlow)
					break;
		}
		else if (indexPath.section == 1)
			attacker = [self.killMail.attackers objectAtIndex:0];
		else
			attacker = [self.killMail.attackers objectAtIndex:indexPath.row + 1];
		type = attacker.shipType;
	}
	
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	controller.type = type;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentViewController:navController animated:YES completion:nil];
	}
	else
		[self.navigationController pushViewController:controller animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.titleLabel.text = title;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return [self tableView:tableView titleForHeaderInSection:section] ? 22 : 0;
}


#pragma mark - Private

- (IBAction)onOpenFit:(id)sender {
	FittingViewController *fittingViewController = [[FittingViewController alloc] initWithNibName:@"FittingViewController" bundle:nil];
	EUOperation* operation = [EUOperation operationWithIdentifier:@"KillMailViewController+OpenFit" name:NSLocalizedString(@"Loading Ship Fit", nil)];
	__weak EUOperation* weakOperation = operation;
	__block ShipFit* fit = nil;
	__block eufe::Character* character = NULL;
	
	[operation addExecutionBlock:^{
		character = new eufe::Character(fittingViewController.fittingEngine);
		
		EVEAccount* currentAccount = [EVEAccount currentAccount];
		weakOperation.progress = 0.3;
		if (currentAccount.characterSheet) {
			FitCharacter* fitCharacter = [FitCharacter fitCharacterWithAccount:currentAccount];
			character->setCharacterName([fitCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
			character->setSkillLevels(*[fitCharacter skillsMap]);
		}
		else
			character->setCharacterName([NSLocalizedString(@"All Skills 0", nil) UTF8String]);
		weakOperation.progress = 0.6;
		fit = [[ShipFit alloc] initWithKillMail:self.killMail character:character];
		weakOperation.progress = 1.0;
	}];
	
	[operation setCompletionBlockInMainThread:^{
		if (![weakOperation isCancelled]) {
			fittingViewController.fittingEngine->getGang()->addPilot(character);
			fittingViewController.fit = fit;
			[fittingViewController.fits addObject:fit];
			[self.navigationController pushViewController:fittingViewController animated:YES];
		}
		else {
			if (character)
				delete character;
		}
	}];
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
