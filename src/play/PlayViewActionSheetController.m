// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// -----------------------------------------------------------------------------


// Project includes
#import "PlayViewActionSheetController.h"
#import "../go/GoGame.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates buttons that are displayed when the user taps the
/// "Game Actions" button on the "Play" view.
///
/// The order in which buttons are enumerated also defines the order in which
/// they appear in the UIActionSheet.
// -----------------------------------------------------------------------------
enum ActionSheetButton
{
  ResignButton,
  SaveGameButton,
  NewGameButton,
  MaxButton     ///< @brief Pseudo enum value, used to iterate over the other enum values
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for PlayViewActionSheetController.
// -----------------------------------------------------------------------------
@interface PlayViewActionSheetController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIActionSheetDelegate protocol
//@{
- (void) actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex;
//@}
/// @name UIAlertViewDelegate protocol
//@{
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
//@}
/// @name NewGameDelegate protocol
//@{
- (void) newGameController:(NewGameController*)controller didStartNewGame:(bool)didStartNewGame;
//@}
/// @name Helpers
//@{
- (void) resign;
- (void) saveGame;
- (void) newGame;
- (void) doNewGame;
//@}
@end


@implementation PlayViewActionSheetController

@synthesize modalMaster;
@synthesize buttonIndexes;


// -----------------------------------------------------------------------------
/// @brief Initializes a PlayViewActionSheetController object.
///
/// @a aController refers to a view controller based on which modal view
/// controllers can be displayed.
///
/// @note This is the designated initializer of PlayViewActionSheetController.
// -----------------------------------------------------------------------------
- (id) initWithModalMaster:(UIViewController*)aController
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.modalMaster = aController;
  self.buttonIndexes = [NSMutableDictionary dictionaryWithCapacity:MaxButton];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayViewActionSheetController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.modalMaster = nil;
  self.buttonIndexes = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Action" button. Displays an action
/// sheet with actions that are not used very often during a game.
// -----------------------------------------------------------------------------
- (void) showActionSheetFromBarButtonItem:(UIBarButtonItem*)item
{
  // TODO iPad: Modify this to not include a cancel button (see HIG).
  UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"Game actions"
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:nil];

  // Add buttons in the order that they appear in the ActionSheetButton enum
  for (int iterButtonIndex = 0; iterButtonIndex < MaxButton; ++iterButtonIndex)
  {
    NSString* title = nil;
    switch (iterButtonIndex)
    {
      case ResignButton:
        if (ComputerVsComputerGame == [GoGame sharedGame].type)
          continue;
        if (GameHasEnded == [GoGame sharedGame].state)
          continue;
        title = @"Resign";
        break;
      case SaveGameButton:
        title = @"Save game";
        break;
      case NewGameButton:
        title = @"New game";
        break;
      default:
        assert(0);
        break;
    }
    NSInteger buttonIndex = [actionSheet addButtonWithTitle:title];
    [self.buttonIndexes setObject:[NSNumber numberWithInt:iterButtonIndex]
                           forKey:[NSNumber numberWithInt:buttonIndex]];
  }
  actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];

  // TODO iPad: On the iPad only, using this method apparently does not disable
  // the other buttons on the toolbar, i.e. the user can still tap other buttons
  // in the toolbar such as "Pass". Review whether this is true, and if it is
  // make sure that the sheet is dismissed if a button from the toolbar is
  // tapped. For details about this, see the UIActionSheet class reference,
  // specifically the documentation for showFromBarButtonItem:animated:().
  [actionSheet showFromBarButtonItem:item animated:NO];
  [actionSheet release];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user selecting an action from the action sheet
/// displayed when the "Action" button was tapped.
///
/// We could also implement actionSheet:clickedButtonAtIndex:(), but visually
/// it looks slighly better to do UI stuff (e.g. display "new game" modal view)
/// *AFTER* the alert sheet has been dismissed.
// -----------------------------------------------------------------------------
- (void) actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (actionSheet.cancelButtonIndex == buttonIndex)
    return;
  id object = [self.buttonIndexes objectForKey:[NSNumber numberWithInt:buttonIndex]];
  assert(object != nil);
  enum ActionSheetButton button = [object intValue];
  switch (button)
  {
    case ResignButton:
      [self resign];
      break;
    case SaveGameButton:
      [self saveGame];
      break;
    case NewGameButton:
      [self newGame];
      break;
    default:
      assert(0);
      break;
  }
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Resign" action sheet button.
/// Generates a "Resign" move for the human player whose turn it currently is.
// -----------------------------------------------------------------------------
- (void) resign
{
  // TODO ask user for confirmation because this action cannot be undone
  [[GoGame sharedGame] resign];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Save game" action sheet button. Saves
/// the current game to .sgf.
// -----------------------------------------------------------------------------
- (void) saveGame
{
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "New game" action sheet button. Starts
/// a new game, discarding the current game.
// -----------------------------------------------------------------------------
- (void) newGame
{
  GoGame* game = [GoGame sharedGame];
  switch (game.state)
  {
    case GameHasStarted:
    case GameIsPaused:
    {
      UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"New game"
                                                      message:@"Are you sure you want to start a new game and discard the game in progress?"
                                                     delegate:self
                                            cancelButtonTitle:@"No"
                                            otherButtonTitles:@"Yes", nil];
      [alert show];
      break;
    }
    default:
    {
      [self doNewGame];
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user dismissing an alert view for which this controller
/// is the delegate.
// -----------------------------------------------------------------------------
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  switch (buttonIndex)
  {
    case 0:
      // "No" button clicked
      break;
    case 1:
      // "Yes" button clicked
      [self doNewGame];
      break;
    default:
      break;
  }
}

// -----------------------------------------------------------------------------
/// @brief Displays NewGameController as a modal view controller to gather
/// information required to start a new game.
// -----------------------------------------------------------------------------
- (void) doNewGame;
{
  // This controller manages the actual "New Game" view
  NewGameController* newGameController = [[NewGameController controllerWithDelegate:self] retain];

  // This controller provides a navigation bar at the top of the screen where
  // it will display the navigation item that represents the "new game"
  // controller. The "new game" controller internally configures this
  // navigation item according to its needs.
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:newGameController];
  // Present the navigation controller, not the "new game" controller.
  navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self.modalMaster presentModalViewController:navigationController animated:YES];
  // Cleanup
  [navigationController release];
  [newGameController release];
}

// -----------------------------------------------------------------------------
/// @brief This method is invoked when the user has finished working with
/// @a controller. The implementation is responsible for dismissing the modal
/// @a controller.
///
/// If @a didStartNewGame is true, the user has requested starting a new game.
/// If @a didStartNewGame is false, the user has cancelled starting a new game.
// -----------------------------------------------------------------------------
- (void) newGameController:(NewGameController*)controller didStartNewGame:(bool)didStartNewGame
{
  [self.modalMaster dismissModalViewControllerAnimated:YES];
}

@end
