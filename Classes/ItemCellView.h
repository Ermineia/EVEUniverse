//
//  ItemCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupedCell.h"


@interface ItemCellView : GroupedCell
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@end
