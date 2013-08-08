//
//  CharacterEVE.h
//  EVEUniverse
//
//  Created by Mr. Depth on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Character.h"

@class EVEAccount;
@class EVEAccountStorageCharacter;
@interface CharacterEVE : Character


+ (id) characterWithCharacter:(EVEAccountStorageCharacter*) character;
+ (id) characterWithCharacterID:(NSInteger) characterID keyID:(NSInteger) keyID vCode:(NSString*) vCode name:(NSString*) name;
+ (id) characterWithAccount:(EVEAccount*) account;

- (id) initWithCharacter:(EVEAccountStorageCharacter*) character;
- (id) initWithCharacterID:(NSInteger) characterID keyID:(NSInteger) keyID vCode:(NSString*) vCode name:(NSString*) name;
- (id) initWithAccount:(EVEAccount*) account;
@end