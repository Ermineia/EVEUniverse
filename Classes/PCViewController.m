//
//  PCViewController.m
//  EVEUniverse
//
//  Created by Shimanski on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PCViewController.h"
#import "EVEOnlineAPI.h"
#import "UIDevice+IP.h"
#import "Globals.h"

@interface PCViewController(Private)

- (void) updateAddress;

@end


@implementation PCViewController
@synthesize addressLabel;

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
	self.title = @"Add API Key";
	
	NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[[EVEAccountStorage sharedAccountStorage] reload];
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		server = [[EUHTTPServer alloc] initWithDelegate:self];
		[server run];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
	
	[self updateAddress];
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
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[addressLabel release];

	[server shutdown];
	[server release];
    [super dealloc];
}

#pragma mark EUHTTPServerDelegate

- (BOOL) server:(EUHTTPServer*) server didReceiveKeyID:(NSInteger) keyID vCode:(NSString*) vCode error:(NSError**) errorPtr {
	return [[EVEAccountStorage sharedAccountStorage] addAPIKeyWithKeyID:keyID vCode:vCode error:errorPtr];
}

@end

@implementation PCViewController(Private)

- (void) updateAddress {
	NSArray *addresses = [UIDevice localIPAddresses];
	if (addresses.count == 0) {
		[self performSelector:@selector(updateAddress) withObject:nil afterDelay:1];
		self.addressLabel.text = @"Unknown IP Address";
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

@end

/*
Connect your device via Wi-Fi to LAN

*/