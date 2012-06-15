


#import "CollectionContentsViewController.h"


@implementation CollectionContentsViewController

@synthesize toolbar, collContents, collAtmosId, settingsPanel,segCtrl, syncPanel, docCtrl,progressCtrl,mediaViewer,moviePlayer;


- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Set the content size for the popover: there are just two rows in the table view, so set to rowHeight*2.
    
	NSArray *itemArr = [NSArray arrayWithObjects:@"Sync",@"Settings",nil];
	self.segCtrl = [[UISegmentedControl alloc] initWithItems:itemArr];
	segCtrl.segmentedControlStyle = UISegmentedControlStyleBar;
	segCtrl.momentary = YES;
	[segCtrl addTarget:self action:@selector(segmentedControlClicked) forControlEvents:UIControlEventValueChanged];
	UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:segCtrl];
	self.navigationItem.rightBarButtonItem = barItem;
	
	[barItem release];
	
}

#pragma mark UISegmentedControl event handlers
- (AtmosSettingsPanel *) settingsPanel {
	if(settingsPanel == nil) {
		self.settingsPanel = [[AtmosSettingsPanel alloc] initWithNibName:@"AtmosSettingsPanel" bundle:nil];
	}
	return settingsPanel;
}
	
- (AtmosSyncPanel *) syncPanel {
	if(syncPanel == nil) {
		self.syncPanel = [[AtmosSyncPanel alloc] initWithNibName:@"AtmosSyncPanel" bundle:nil];
	}
	return syncPanel;
	
}

- (ProgressViewController *) progressCtrl {
	if(progressCtrl == nil) {
		self.progressCtrl = [[ProgressViewController alloc] initWithNibName:@"ProgressViewController" bundle:nil];
		progressCtrl.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		progressCtrl.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	return progressCtrl;
	
}

- (void) segmentedControlClicked {
	//NSLog(@"control clicked");
	if(self.segCtrl.selectedSegmentIndex == 0) {
		//sync
		self.syncPanel.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		self.syncPanel.modalPresentationStyle = UIModalPresentationFormSheet;
		[self.navigationController presentModalViewController:self.syncPanel animated:YES];
		
	} else if(self.segCtrl.selectedSegmentIndex == 1) { 
		//show settings panel
		self.settingsPanel.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		self.settingsPanel.modalPresentationStyle = UIModalPresentationFormSheet;
		[self.navigationController presentModalViewController:self.settingsPanel animated:YES];
	}
}

#pragma mark -
#pragma mark Managing the popover

- (void)showRootPopoverButtonItem:(UIBarButtonItem *)barButtonItem {
    
    // Add the popover button to the toolbar.
    /*NSMutableArray *itemsArray = [toolbar.items mutableCopy];
    [itemsArray insertObject:barButtonItem atIndex:0];
    [toolbar setItems:itemsArray animated:NO];
    [itemsArray release];
	*/
	
	self.navigationItem.leftBarButtonItem = barButtonItem;
	
}


- (void)invalidateRootPopoverButtonItem:(UIBarButtonItem *)barButtonItem {
    
    // Remove the popover button from the toolbar.
    /*NSMutableArray *itemsArray = [toolbar.items mutableCopy];
    [itemsArray removeObject:barButtonItem];
    [toolbar setItems:itemsArray animated:NO];
    [itemsArray release];
	 */
	self.navigationItem.leftBarButtonItem = nil;
	
}


#pragma mark -
#pragma mark Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    
	
	return self.collContents.count;
}


- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"CollContentsCellIdentifier";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
	AtmosObject *obj = [self.collContents objectAtIndex:indexPath.row];
	cell.textLabel.text = obj.objectName;
	NSMutableString *detailText = [[NSMutableString alloc] init];
	UIImage *syncImg = nil;
	if(obj.syncState == STATE_OUT_OF_SYNC) {
		//[detailText appendString:@"Out of Sync"];
		syncImg = [UIImage imageNamed:@"cloud_red.png"];
	} else if(obj.syncState == STATE_SYNCING) {
		//[detailText appendString: @"Syncing"];
		syncImg = [UIImage imageNamed:@"cloud_yellow.png"];
	} else {
		//[detailText appendString: @"Synced"];
		syncImg = [UIImage imageNamed:@"cloud_green.png"];
	}
	
	[detailText appendFormat:@" %@ %@ ",[AtmosObject formatObjectSize:obj.objectSize],[AtmosObject formatFriendlyDate:obj.lastContentModified]];

	cell.detailTextLabel.text = detailText;
	/*
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filePath = [documentsDirectory stringByAppendingPathComponent:obj.filepath];
	NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
	UIDocumentInteractionController *docInter = [self docCtrlForFile:fileUrl];
	cell.imageView.image = [docInter.icons objectAtIndex:0];
	 */
	
	NSString *imgName = [NSString stringWithFormat:@"f_%@_32.gif",obj.contentType];
	//cell.imageView.animationImages = [NSArray arrayWithObjects:[UIImage imageNamed:imgName], syncImg,nil];
	//[cell.imageView startAnimating];
	cell.imageView.image = [UIImage imageNamed:imgName];
	UIImageView *bgView = [[UIImageView alloc] init];
	bgView.image = syncImg;
	bgView.contentMode = UIViewContentModeRight;
	cell.backgroundView = bgView;
	
    return cell;
}

#pragma mark Download complete

- (void) downloadComplete {
	[self.tableView reloadData];
}

- (UIDocumentInteractionController *) docCtrlForFile:(NSURL *) fileURL {
	self.docCtrl = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
	self.docCtrl.delegate = self;
	return docCtrl;
}

- (MediaViewerController *) mediaViewer {
	if(mediaViewer == nil) {
		self.mediaViewer = [[MediaViewerController alloc] initWithNibName:@"MediaViewerController" bundle:nil];
		self.mediaViewer.modalPresentationStyle = UIModalPresentationFormSheet;
		self.mediaViewer.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	}
	return mediaViewer;
}

- (MPMoviePlayerViewController *) moviePlayer {
	if(moviePlayer == nil) {
		
	}
	
	
}
	

#pragma mark -
#pragma mark Table view selection

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	//NSLog(@"row selected %d",indexPath.row);
    AtmosObject *aobj = [self.collContents objectAtIndex:indexPath.row];
	//NSLog(@"got aobj %@",aobj.objectName,aobj.atmosId);
	if(aobj.syncState == STATE_OUT_OF_SYNC) {
		//[[AtmosLocalStore getSharedInstance] downloadObject:aobj downloadListener:self];
		
		self.progressCtrl.atmosObj = aobj;
		[self.navigationController presentModalViewController:self.progressCtrl animated:YES];
	} else if(aobj.syncState == STATE_SYNCED) {
		
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		NSString *filePath = [documentsDirectory stringByAppendingPathComponent:aobj.filepath];
		NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
		
		if([aobj.contentType isEqualToString:@"mp4"] || [aobj.contentType isEqualToString:@"mov"] || [aobj.contentType isEqualToString:@"3gp"] 
		   || [aobj.contentType isEqualToString:@"mpv"]
		   || [aobj.contentType isEqualToString:@"mp3"]
		   || [aobj.contentType isEqualToString:@"aac"]
		   || [aobj.contentType isEqualToString:@"m4a"]) {
			
			self.moviePlayer =  [[MPMoviePlayerViewController alloc]
								 initWithContentURL:fileUrl];
			moviePlayer.modalPresentationStyle = UIModalPresentationPageSheet;
			moviePlayer.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
			[self.navigationController presentModalViewController:moviePlayer animated:YES];
			//[self.moviePlayer.moviePlayer play];
			
		} else {
			UIDocumentInteractionController *docViewer = [self docCtrlForFile:fileUrl];
			docViewer.name = aobj.objectName;
			[docViewer presentPreviewAnimated:YES];
		}
	}
	
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UIDocumentInteractionController delegate
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
	return self.navigationController;
	
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [toolbar release];
    [super dealloc];
}	


@end
