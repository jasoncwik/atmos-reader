
#import <UIKit/UIKit.h>
#import "AtmosObject.h"
#import "AtmosLocalStore.h"
#import "AtmosSettingsPanel.h"
#import "AtmosSyncPanel.h"
#import "ProgressViewController.h"
#import "MediaViewerController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface CollectionContentsViewController : UITableViewController <UIDocumentInteractionControllerDelegate>  {

    UIToolbar *toolbar;
	NSArray *collContents;
	NSString *collAtmosId;
	AtmosSettingsPanel *settingsPanel;
	AtmosSyncPanel *syncPanel;
	UISegmentedControl *segCtrl;
	UIDocumentInteractionController *docCtrl;
	ProgressViewController *progressCtrl;
	MediaViewerController *mediaViewer;
	MPMoviePlayerViewController *moviePlayer;
}

- (void) downloadComplete;

- (void) segmentedControlClicked;
- (UIDocumentInteractionController *) docCtrlForFile:(NSURL *) fileURL;

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) NSArray *collContents;
@property (nonatomic, retain) NSString *collAtmosId;
@property (nonatomic, retain) AtmosSettingsPanel *settingsPanel;
@property (nonatomic, retain) AtmosSyncPanel *syncPanel;
@property (nonatomic, retain) UISegmentedControl *segCtrl;
@property (nonatomic, retain) UIDocumentInteractionController *docCtrl;
@property (nonatomic, retain) ProgressViewController *progressCtrl;
@property (nonatomic, retain) MediaViewerController *mediaViewer;
@property (nonatomic, retain) MPMoviePlayerViewController *moviePlayer;

@end
