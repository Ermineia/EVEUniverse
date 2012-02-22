//
//  FittingViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FittingViewController.h"
#import "SelectCharacterBarButtonItem.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "FittingItemsViewController.h"
#import "Fit.h"
#import "ItemInfo.h"
#import "DamagePattern.h"
#import "RequiredSkillsViewController.h"

#include "eufe.h"

#define ActionButtonBack @"Back"
#define ActionButtonSetName @"Set Fit Name"
#define ActionButtonSave @"Save Fit"
#define ActionButtonCharacter @"Switch Character"
#define ActionButtonViewInBrowser @"View in Browser"
#define ActionButtonAreaEffect @"Select Area Effect"
#define ActionButtonClearAreaEffect @"Clear Area Effect"
#define ActionButtonSetDamagePattern @"Set Damage Pattern"
#define ActionButtonRequiredSkills @"Required Skills"
#define ActionButtonCancel @"Cancel"

@interface FittingViewController(Private)

- (void) keyboardWillShow: (NSNotification*) notification;
- (void) keyboardWillHide: (NSNotification*) notification;
- (void) save;

@end

@implementation FittingViewController
@synthesize sectionsView;
@synthesize sectionSegmentControl;
@synthesize modalController;
@synthesize targetsModalController;
@synthesize areaEffectsModalController;
@synthesize areaEffectsViewController;
@synthesize modulesViewController;
@synthesize dronesViewController;
@synthesize implantsViewController;
@synthesize statsViewController;
@synthesize fleetViewController;
@synthesize shadeView;
@synthesize fitNameView;
@synthesize fitNameTextField;
@synthesize statsSectionView;
@synthesize popoverController;
@synthesize targetsPopoverController;
@synthesize areaEffectsPopoverController;
@synthesize fit;

@synthesize fittingEngine;
@synthesize damagePattern;

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

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(onBack:)] autorelease];
	
	self.fitNameTextField.text = fit.fitName;
	self.damagePattern = [DamagePattern uniformDamagePattern];

	[self.sectionsView addSubview:modulesViewController.view];
	modulesViewController.view.frame = self.sectionsView.bounds;
	[modulesViewController viewWillAppear:NO];
	currentSection = modulesViewController;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.statsSectionView addSubview:statsViewController.view];
		statsViewController.view.frame = self.statsSectionView.bounds;
		self.popoverController = [[[UIPopoverController alloc] initWithContentViewController:modalController] autorelease];
		self.popoverController.delegate = (FittingItemsViewController*)  self.modalController.topViewController;

		self.targetsPopoverController = [[[UIPopoverController alloc] initWithContentViewController:targetsModalController] autorelease];
		self.targetsPopoverController.delegate = (FittingItemsViewController*)  self.targetsModalController.topViewController;
		
		self.areaEffectsPopoverController = [[[UIPopoverController alloc] initWithContentViewController:areaEffectsModalController] autorelease];
		self.areaEffectsPopoverController.delegate = (AreaEffectsViewController*)  self.areaEffectsModalController.topViewController;
		
		modulesViewController.popoverController = self.popoverController;
		dronesViewController.popoverController = self.popoverController;
		implantsViewController.popoverController = self.popoverController;
		fleetViewController.popoverController = self.popoverController;
	}
	
	[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Options" style:UIBarButtonItemStyleBordered target:self action:@selector(onMenu:)] autorelease]];
	[self update];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	}
}	

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (actionSheet) {
		[actionSheet dismissWithClickedButtonIndex:actionSheet.cancelButtonIndex animated:YES];
		[actionSheet release];
		actionSheet = nil;
	}
	
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	}
	else {
		[self save];
	}
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
/*	self.sectionsView = nil;
	self.sectionSegmentControl = nil;
	self.modalController = nil;
	self.targetsModalController = nil;
	self.areaEffectsModalController = nil;
	self.areaEffectsViewController = nil;
	self.modulesViewController = nil;
	self.dronesViewController = nil;
	self.implantsViewController = nil;
	self.statsViewController = nil;
	self.fleetViewController = nil;
	self.shadeView = nil;
	self.fitNameView = nil;
	self.fitNameTextField = nil;
	self.statsSectionView = nil;
	self.popoverController = nil;
	self.targetsPopoverController = nil;
	self.areaEffectsPopoverController = nil;
	currentSection = nil;*/
}


- (void)dealloc {

	[sectionsView release];
	[sectionSegmentControl release];
	[modalController release];
	[targetsModalController release];
	[areaEffectsModalController release];
	[areaEffectsViewController release];
	[modulesViewController release];
	[dronesViewController release];
	[implantsViewController release];
	[statsViewController release];
	[fleetViewController release];
	[shadeView release];
	[fitNameView release];
	[fitNameTextField release];
	[statsSectionView release];
	[popoverController release];
	[targetsPopoverController release];
	[areaEffectsPopoverController release];
	
	[fit release];
	
	[actionSheet release];
	[fits release];
	[damagePattern release];
	
	delete fittingEngine;
    [super dealloc];
}

- (IBAction) didCloseModalViewController:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction) didChangeSection:(id) sender {
	UIViewController<FittingSection> *newSection = nil;
	if (sectionSegmentControl.selectedSegmentIndex == 0)
		newSection = modulesViewController;
	else if (sectionSegmentControl.selectedSegmentIndex == 1)
		newSection = dronesViewController;
	else if (sectionSegmentControl.selectedSegmentIndex == 2)
		newSection = implantsViewController;
	else if (sectionSegmentControl.selectedSegmentIndex == 3)
		newSection = fleetViewController;
	else if (sectionSegmentControl.selectedSegmentIndex == 4)
		newSection = statsViewController;
	if (newSection == currentSection)
		return;
	[currentSection.view removeFromSuperview];
	[self.sectionsView addSubview:newSection.view];
	newSection.view.frame = self.sectionsView.bounds;
	[newSection viewWillAppear:NO];
	currentSection = newSection;
}

- (IBAction) onMenu:(id) sender {
	if (actionSheet) {
		[actionSheet dismissWithClickedButtonIndex:actionSheet.cancelButtonIndex animated:YES];
		[actionSheet release];
	}
	actionSheet = [[UIActionSheet alloc] initWithTitle:nil
											  delegate:self
									 cancelButtonTitle:nil
								destructiveButtonTitle:nil
									 otherButtonTitles:nil];
//	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
//		[actionSheet addButtonWithTitle:ActionButtonBack];
	
	if (fittingEngine->getArea() != NULL) {
		[actionSheet addButtonWithTitle:ActionButtonClearAreaEffect];
		actionSheet.destructiveButtonIndex = actionSheet.numberOfButtons - 1;
	}

	[actionSheet addButtonWithTitle:ActionButtonSetName];
	if (fit.fitID <= 0)
		[actionSheet addButtonWithTitle:ActionButtonSave];
	[actionSheet addButtonWithTitle:ActionButtonCharacter];
	if (fit.fitURL)
		[actionSheet addButtonWithTitle:ActionButtonViewInBrowser];
	[actionSheet addButtonWithTitle:ActionButtonAreaEffect];
	
	[actionSheet addButtonWithTitle:ActionButtonSetDamagePattern];
	[actionSheet addButtonWithTitle:ActionButtonRequiredSkills];
	[actionSheet addButtonWithTitle:ActionButtonCancel];
	
	actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
	
	[actionSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction) onDone:(id) sender {
	[fitNameTextField resignFirstResponder];
	fit.fitName = fitNameTextField.text;
	
	boost::shared_ptr<eufe::Character> character = fit.character;
	ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:character->getShip() error:nil];
	self.title = [NSString stringWithFormat:@"%@ - %@", itemInfo.typeName, fit.fitName ? fit.fitName : itemInfo.typeName];
	
	if (currentSection == fleetViewController)
		[fleetViewController update];

	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
		[UIView setAnimationBeginsFromCurrentState:YES];
		self.fitNameView.frame = CGRectMake(self.view.frame.size.width,
											self.fitNameView.frame.origin.y,
											self.fitNameView.frame.size.width,
											self.fitNameView.frame.size.height);
		[UIView commitAnimations];
	}
	
}

- (IBAction) onBack:(id) sender {
	[self save];
	[self.navigationController popViewControllerAnimated:YES];
}

- (eufe::Engine*) fittingEngine {
	if (!fittingEngine)
		fittingEngine = new eufe::Engine([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding]);
	return fittingEngine;
}

- (NSMutableArray*) fits {
	if (!fits)
		fits = [[NSMutableArray alloc] init];
	return fits;
}

- (void) recalculateFit {
	/*__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:@"FittingViewController+RecalculateFit"];
	 [operation addExecutionBlock:^(void) {
	 if ([operation isCancelled])
	 return;
	 NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	 [fit clear];
	 [fit calculateModifiedAttributes];
	 [pool release];
	 }];
	 [operation setCompletionBlockInCurrentThread:^(void) {
	 if (![operation isCancelled]) {
	 [currentSection update];
	 if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	 [statsViewController update];
	 }
	 }];
	 [[EUOperationQueue sharedQueue] addOperation:operation];*/
	[currentSection update];
}

- (void) update {
	[currentSection update];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[statsViewController update];
}

- (void) setFit:(Fit*) value {
	[value retain];
	[fit release];
	fit = value;
	boost::shared_ptr<eufe::Character> character = fit.character;
	ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:character->getShip() error:nil];
	self.title = [NSString stringWithFormat:@"%@ - %@", itemInfo.typeName, fit.fitName ? fit.fitName : itemInfo.typeName];
	self.fitNameTextField.text = fit.fitName;
}

- (void) setDamagePattern:(DamagePattern *)value {
	[value retain];
	[damagePattern release];
	damagePattern = value;
	eufe::DamagePattern eufeDamagePattern;
	eufeDamagePattern.emAmount = damagePattern.emAmount;
	eufeDamagePattern.thermalAmount = damagePattern.thermalAmount;
	eufeDamagePattern.kineticAmount = damagePattern.kineticAmount;
	eufeDamagePattern.explosiveAmount = damagePattern.explosiveAmount;
	for (Fit* item in fits) {
		boost::shared_ptr<eufe::Character> character = item.character;
		character->getShip()->setDamagePattern(eufeDamagePattern);
	}
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)aActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *button = [aActionSheet buttonTitleAtIndex:buttonIndex];
	if ([button isEqualToString:ActionButtonBack]) {
		[self save];
		[self.navigationController popViewControllerAnimated:YES];
	}
	else if ([button isEqualToString:ActionButtonSetName]) {
		[fitNameTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.2];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			[UIView beginAnimations:nil context:nil];
			[UIView setAnimationDuration:0.3];
			[UIView setAnimationBeginsFromCurrentState:YES];
//			self.shadeView.alpha = 1;
			self.fitNameView.frame = CGRectMake(self.sectionsView.frame.size.width,
												self.fitNameView.frame.origin.y,
												self.fitNameView.frame.size.width,
												self.fitNameView.frame.size.height);
			[UIView commitAnimations];
		}
	}
	else if ([button isEqualToString:ActionButtonSave]) {
		[fit save];
	}
	else if ([button isEqualToString:ActionButtonCharacter]) {
		CharactersViewController *charactersViewController = [[CharactersViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"CharactersViewController-iPad" : @"CharactersViewController")
																										bundle:nil];
		charactersViewController.delegate = self;
		
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:charactersViewController];
		navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
		
		[self presentModalViewController:navController animated:YES];
		[navController release];
		[charactersViewController release];
	}
	else if ([button isEqualToString:ActionButtonViewInBrowser]) {
		BrowserViewController *controller = [[BrowserViewController alloc] initWithNibName:@"BrowserViewController" bundle:nil];
		//controller.delegate = self;
		controller.startPageURL = fit.fitURL;
		[self presentModalViewController:controller animated:YES];
	}
	else if ([button isEqualToString:ActionButtonAreaEffect]) {
		boost::shared_ptr<eufe::Item> area = fittingEngine->getArea();
		areaEffectsViewController.selectedArea = area != NULL ? [ItemInfo itemInfoWithItem:area error:nil] : nil;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[areaEffectsPopoverController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self presentModalViewController:areaEffectsModalController animated:YES];
	}
	else if ([button isEqualToString:ActionButtonClearAreaEffect]) {
		fittingEngine->clearArea();
		[self update];
	}
	else if ([button isEqualToString:ActionButtonSetDamagePattern]) {
		DamagePatternsViewController *damagePatternsViewController = [[DamagePatternsViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"DamagePatternsViewController-iPad" : @"DamagePatternsViewController")
																													bundle:nil];
		damagePatternsViewController.delegate = self;
		damagePatternsViewController.currentDamagePattern = self.damagePattern;
		
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:damagePatternsViewController];
		navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
		
		[self presentModalViewController:navController animated:YES];
		[navController release];
		[damagePatternsViewController release];
	}
	else if ([button isEqualToString:ActionButtonRequiredSkills]) {
		RequiredSkillsViewController *requiredSkillsViewController = [[RequiredSkillsViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"RequiredSkillsViewController-iPad" : @"RequiredSkillsViewController")
																													bundle:nil];
		requiredSkillsViewController.fit = self.fit;
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:requiredSkillsViewController];
		navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
		
		[self presentModalViewController:navController animated:YES];
		[navController release];
		[requiredSkillsViewController release];
	}
	[actionSheet release];
	actionSheet = nil;
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	[self onDone:nil];
	return YES;
}

#pragma mark BrowserViewControllerDelegate

- (void) browserViewControllerDidFinish:(BrowserViewController*) controller {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark AreaEffectsViewControllerDelegate

- (void) areaEffectsViewController:(AreaEffectsViewController*) controller didSelectAreaEffect:(EVEDBInvType*) areaEffect {
	fittingEngine->setArea(areaEffect.typeID);
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.areaEffectsPopoverController dismissPopoverAnimated:YES];
	else
		[self dismissModalViewControllerAnimated:YES];
	[self update];
}

#pragma mark CharactersViewControllerDelegate

- (void) charactersViewController:(CharactersViewController*) aController didSelectCharacter:(Character*) character {
	eufe::Character* eufeCharacter = fit.character.get();
	eufeCharacter->setSkillLevels(*[character skillsMap]);
	eufeCharacter->setCharacterName([character.name cStringUsingEncoding:NSUTF8StringEncoding]);
	[self update];
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark DamagePatternsViewControllerDelegate

- (void) damagePatternsViewController:(DamagePatternsViewController*) controller didSelectDamagePattern:(DamagePattern*) aDamagePattern {
	self.damagePattern = aDamagePattern;
	[self update];
	[self dismissModalViewControllerAnimated:YES];
}

@end


@implementation FittingViewController(Private)

- (void) keyboardWillShow: (NSNotification*) notification {
	CGRect r = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:[[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
	[UIView setAnimationCurve:(UIViewAnimationCurve)[[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue]];
	self.shadeView.alpha = 1;
	self.fitNameView.frame = CGRectMake(self.fitNameView.frame.origin.x,
										self.view.frame.size.height - r.size.height - self.fitNameView.frame.size.height,
										self.fitNameView.frame.size.width,
										self.fitNameView.frame.size.height);
	[UIView commitAnimations];
}

- (void) keyboardWillHide: (NSNotification*) notification {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:[[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
	[UIView setAnimationCurve:(UIViewAnimationCurve)[[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue]];
	self.shadeView.alpha = 0;
	self.fitNameView.frame = CGRectMake(self.fitNameView.frame.origin.x, self.view.frame.size.height, self.fitNameView.frame.size.width, self.fitNameView.frame.size.height);
	[UIView commitAnimations];
}

- (void) save {
	for (Fit* item in fits)
		if (item.fitID > 0)
			[item save];
}

@end