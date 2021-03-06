//
//  EVEAPIKeyCell.h
//  EVEUniverse
//
//  Created by mr_depth on 21.07.13.
//
//

#import "ASCollectionViewCell.h"

@class EVEAPIKeyCell;
@protocol EVEAPIKeyCellDelegate<NSObject>
- (void) apiKeyCell:(EVEAPIKeyCell*) cell deleteButtonTapped:(UIButton*) button;
@end

@interface EVEAPIKeyCell : ASCollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) id<EVEAPIKeyCellDelegate> delegate;

- (IBAction)onDelete:(id)sender;

@end
