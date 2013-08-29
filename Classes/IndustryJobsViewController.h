//
//  IndustryJobsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FilterViewController.h"
#import "EUFilter.h"

@interface IndustryJobsViewController : UITableViewController
@property (nonatomic, strong) IBOutlet UISegmentedControl *ownerSegmentControl;
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet FilterViewController *filterViewController;
@property (nonatomic, strong) IBOutlet UINavigationController *filterNavigationViewController;

- (IBAction) onChangeOwner:(id) sender;

@end
