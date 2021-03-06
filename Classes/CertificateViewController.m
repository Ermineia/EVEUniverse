//
//  CertificateViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CertificateViewController.h"
#import "EVEDBAPI.h"
#import "ItemViewController.h"
#import "GroupedCell.h"
#import "EUOperationQueue.h"
#import "NSArray+GroupBy.h"
#import "appearance.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"

@interface CertificateViewController()
@property (nonatomic, strong) NSMutableArray* sections;

@end

@implementation CertificateViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		if ([[self.navigationController viewControllers] objectAtIndex:0] == self)
			[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)]];
	}

	self.title = self.certificate.certificateClass.className;
	self.certificateTreeView.certificate = self.certificate;
    // Do any additional setup after loading the view from its nib.
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)viewDidUnload
{
    [self setCertificateTreeView:nil];
    [self setScrollView:nil];
	[self setRecommendationsTableView:nil];
	[self setContentView:nil];
	self.sections = nil;
	[self setPageSegmentControl:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (IBAction) onSwitchScreens:(id)sender {
	UIView* currentView = [[self.contentView subviews] objectAtIndex:0];
	UIView* nextView = self.pageSegmentControl.selectedSegmentIndex == 0 ? self.scrollView : self.recommendationsTableView;
	if (currentView != nextView) {
		[currentView removeFromSuperview];
		[self.contentView addSubview:nextView];
		nextView.frame = self.contentView.bounds;
	}
//	[UIView setAnimationDuration:1];
//	[UIView commitAnimations];
//	[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:currentView == scrollView ? @"graphButton.png" : @"linesButton.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(onSwitchScreens:)] autorelease]
//									  animated:YES];
}

#pragma mark UIScrollViewDelegate

- (UIView*) viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return self.certificateTreeView;
}

#pragma mark CertificateTreeViewDelegate

- (void) certificateTreeViewDidFinishLoad:(CertificateTreeView*) aCertificateTreeView {
	self.scrollView.zoomScale = 1.0;
	self.scrollView.contentSize = self.certificateTreeView.frame.size;
	
	CGPoint offset = self.certificateTreeView.certificateView.center;
	offset.x -= self.scrollView.frame.size.width / 2.0;
	offset.y -= self.scrollView.frame.size.height / 2.0;
	offset.x = MAX(offset.x, 0.0);
	offset.y = MAX(offset.y, 0.0);
	self.scrollView.contentOffset = offset;
	
	float scaleX = self.scrollView.frame.size.width / self.certificateTreeView.frame.size.width;
	float scaleY = self.scrollView.frame.size.height / self.certificateTreeView.frame.size.height;
	self.scrollView.maximumZoomScale = 1;
	self.scrollView.minimumZoomScale = MIN(scaleX, scaleY);
	
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"CertificateViewController+load" name:NSLocalizedString(@"Loading Certificates", nil)];
	__weak EUOperation* weakOperation = operation;
	NSMutableArray* rowsTmp = [NSMutableArray array];
	NSMutableArray* sectionsTmp = [NSMutableArray array];
	[operation addExecutionBlock:^{
		for (EVEDBCrtRecommendation* recommendation in self.certificate.recommendations)
			[rowsTmp addObject:recommendation.shipType];
		[rowsTmp sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
		[sectionsTmp addObjectsFromArray:[rowsTmp arrayGroupedByKey:@"groupID"]];
		[sectionsTmp sortUsingComparator:^(id obj1, id obj2) {
			return [[[obj1 objectAtIndex:0] valueForKeyPath:@"group.groupName"] compare:[[obj2 objectAtIndex:0] valueForKeyPath:@"group.groupName"]];
		}];
	}];
	
	[operation setCompletionBlockInMainThread:^{
		if (![weakOperation isCancelled]) {
			self.sections = sectionsTmp;
			[self.recommendationsTableView reloadData];
			UIView* currentView = [[self.contentView subviews] objectAtIndex:0];
			if (currentView != self.scrollView) {
				[self.contentView addSubview:self.scrollView];
				self.scrollView.frame = self.contentView.bounds;
			}

			if (self.sections.count > 0)
				[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.pageSegmentControl]];
			else {
				self.navigationItem.rightBarButtonItem = nil;
			}
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) certificateTreeView:(CertificateTreeView*) aCertificateTreeView didSelectCertificate:(EVEDBCrtCertificate*) aCertificate {
	self.certificate = aCertificate;
	self.certificateTreeView.certificate = aCertificate;
	self.title = self.certificate.certificateClass.className;

}

- (void) certificateTreeView:(CertificateTreeView*) aCertificateTreeView didSelectType:(EVEDBInvType*) type {
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	controller.type = type;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	[self.navigationController pushViewController:controller animated:YES];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[self.sections objectAtIndex:section] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"Cell";
	
	GroupedCell* cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];//[ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	EVEDBInvType *row = [[self.sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	cell.textLabel.text = row.typeName;
	cell.imageView.image = [UIImage imageNamed:[row typeSmallImageName]];
	
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [[[self.sections objectAtIndex:section] objectAtIndex:0] valueForKeyPath:@"group.groupName"];
}

#pragma mark -
#pragma mark Table view delegate



- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
	view.titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
	return view;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 22;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	controller.type = [[self.sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	[controller setActivePage:ItemViewControllerActivePageInfo];
	[self.navigationController pushViewController:controller animated:YES];
}

@end
