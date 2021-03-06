// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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


// Test includes
#import "GoGameTest.h"

// Application includes
#import <go/GoBoard.h>
#import <go/GoBoardRegion.h>
#import <go/GoGame.h>
#import <go/GoMove.h>
#import <go/GoPoint.h>
#import <go/GoUtilities.h>
#import <main/ApplicationDelegate.h>
#import <command/game/NewGameCommand.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GoGameTest.
// -----------------------------------------------------------------------------
@interface GoGameTest()
- (void) verifyFragmentedRegionsOfTestUndoCausesRegionToFragment:(NSString*)failureDescription;
@end


@implementation GoGameTest

// -----------------------------------------------------------------------------
/// @brief Exercises the sharedGame() class method.
// -----------------------------------------------------------------------------
- (void) testSharedGame
{
  STAssertEquals(m_game, [GoGame sharedGame], nil);
}

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of a GoGame object after it has been
/// created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  STAssertEquals(GoGameTypeHumanVsHuman, m_game.type, @"game type test failed");
  STAssertNotNil(m_game.board, nil);
  NSUInteger handicapCount = 0;
  STAssertEquals(m_game.handicapPoints.count, handicapCount, nil);
  STAssertEquals(m_game.komi, 6.5, nil);
  STAssertNotNil(m_game.playerBlack, nil);
  STAssertNotNil(m_game.playerWhite, nil);
  STAssertEquals(m_game.currentPlayer, m_game.playerBlack, nil);
  STAssertNil(m_game.firstMove, nil);
  STAssertNil(m_game.lastMove, nil);
  STAssertEquals(GoGameStateGameHasNotYetStarted, m_game.state, @"game state test failed");
  STAssertEquals(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded, nil);
  STAssertFalse(m_game.isComputerThinking, nil);
  STAssertFalse(m_game.nextMoveIsComputerGenerated, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the newGame() convenience constructor.
// -----------------------------------------------------------------------------
- (void) testNewGame
{
  GoGame* newGame = [GoGame newGame];
  STAssertTrue(newGame != m_game, nil);

  STAssertEquals(GoGameTypeUnknown, newGame.type, nil);
  STAssertNil(newGame.board, nil);
  NSUInteger handicapCount = 0;
  STAssertEquals(newGame.handicapPoints.count, handicapCount, nil);
  STAssertEquals(newGame.komi, 0.0, nil);
  STAssertNil(newGame.playerBlack, nil);
  STAssertNil(newGame.playerWhite, nil);
  STAssertNil(newGame.currentPlayer, nil);
  STAssertNil(newGame.firstMove, nil);
  STAssertNil(newGame.lastMove, nil);
  STAssertEquals(GoGameStateGameHasNotYetStarted, newGame.state, nil);
  STAssertEquals(GoGameHasEndedReasonNotYetEnded, newGame.reasonForGameHasEnded, nil);
  STAssertFalse(newGame.isComputerThinking, nil);
  STAssertFalse(newGame.nextMoveIsComputerGenerated, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e type property.
// -----------------------------------------------------------------------------
- (void) testType
{
  STAssertEquals(GoGameTypeHumanVsHuman, m_game.type, nil);
  // Nothing else that we can test for the moment
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e board property.
// -----------------------------------------------------------------------------
- (void) testBoard
{
  STAssertNotNil(m_game.board, nil);
  // The only test that currently comes to mind is whether we can replace an
  // already existing GoBoard instance
  GoBoard* board = [GoBoard boardWithSize:GoBoardSize7];
  m_game.board = board;
  STAssertEquals(board, m_game.board, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e handicapPoints property.
// -----------------------------------------------------------------------------
- (void) testHandicapPoints
{
  NSUInteger handicapCount = 0;
  STAssertEquals(m_game.handicapPoints.count, handicapCount, nil);

  NSMutableArray* handicapPoints = [NSMutableArray arrayWithCapacity:0];
  [handicapPoints setArray:[GoUtilities pointsForHandicap:5 inGame:m_game]];
  for (GoPoint* point in handicapPoints)
    STAssertEquals(GoColorNone, point.stoneState, nil);
  // Setting the handicap points changes the GoPoint's stoneState
  m_game.handicapPoints = handicapPoints;
  // Changing handicapPoints now must not have any influence on the game's
  // handicap points, i.e. we expect that GoGame made a copy of handicapPoints
  [handicapPoints addObject:[m_game.board pointAtVertex:@"A1"]];
  // If GoGame made a copy, A1 will not be in the list that we get and the test
  // will succeed. If GoGame didn't make a copy, A1 will be in the list, but its
  // stoneState will still be GoColorNone, thus causing our test to fail.
  for (GoPoint* point in m_game.handicapPoints)
    STAssertEquals(GoColorBlack, point.stoneState, nil);
  [handicapPoints removeObject:[m_game.board pointAtVertex:@"A1"]];

  // Must be possible to 1) set an empty array, and 2) change a previously set
  // handicap list
  m_game.handicapPoints = [NSArray array];
  // GoPoint object's that were previously set must have their stoneState reset
  for (GoPoint* point in handicapPoints)
    STAssertEquals(GoColorNone, point.stoneState, nil);

  STAssertThrowsSpecificNamed(m_game.handicapPoints = nil,
                              NSException, NSInvalidArgumentException, @"point list is nil");
  m_game.state = GoGameStateGameHasStarted;
  STAssertThrowsSpecificNamed(m_game.handicapPoints = handicapPoints,
                              NSException, NSInternalInconsistencyException, @"handicap set after start");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e currentPlayer property.
// -----------------------------------------------------------------------------
- (void) testCurrentPlayer
{
  STAssertEquals(m_game.currentPlayer, m_game.playerBlack, nil);
  m_game.handicapPoints = [GoUtilities pointsForHandicap:2 inGame:m_game];
  STAssertEquals(m_game.currentPlayer, m_game.playerWhite, nil);
  m_game.handicapPoints = [NSArray array];
  STAssertEquals(m_game.currentPlayer, m_game.playerBlack, nil);
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  STAssertEquals(m_game.currentPlayer, m_game.playerWhite, nil);
  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  STAssertEquals(m_game.currentPlayer, m_game.playerBlack, nil);
  [m_game undo];
  STAssertEquals(m_game.currentPlayer, m_game.playerWhite, nil);
  [m_game undo];
  STAssertEquals(m_game.currentPlayer, m_game.playerBlack, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e firstMove property.
// -----------------------------------------------------------------------------
- (void) testFirstMove
{
  STAssertNil(m_game.firstMove, nil);
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  STAssertNotNil(m_game.firstMove, nil);
  [m_game undo];
  STAssertNil(m_game.firstMove, nil);
  // More detailed checks in testLastMove()
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e lastMove property.
// -----------------------------------------------------------------------------
- (void) testLastMove
{
  STAssertNil(m_game.lastMove, nil);

  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  GoMove* move1 = m_game.lastMove;
  STAssertNotNil(move1, nil);
  STAssertEquals(m_game.firstMove, move1, nil);
  STAssertNil(move1.previous, nil);
  STAssertNil(move1.next, nil);

  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  GoMove* move2 = m_game.lastMove;
  STAssertNotNil(move2, nil);
  STAssertTrue(m_game.firstMove != move2, nil);
  STAssertNil(move1.previous, nil);
  STAssertEquals(move2, move1.next, nil);
  STAssertEquals(move1, move2.previous, nil);
  STAssertNil(move2.next, nil);

  [m_game undo];
  STAssertEquals(move1, m_game.firstMove, nil);
  STAssertEquals(move1, m_game.lastMove, nil);

  [m_game undo];
  STAssertNil(m_game.firstMove, nil);
  STAssertNil(m_game.lastMove, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e state property.
// -----------------------------------------------------------------------------
- (void) testState
{
  // There's no point in setting the state property ourselves because the
  // implementation does not check for correctness of the state machine
  STAssertEquals(GoGameStateGameHasNotYetStarted, m_game.state, nil);
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  STAssertEquals(GoGameStateGameHasStarted, m_game.state, nil);
  [m_game undo];
  STAssertEquals(GoGameStateGameHasStarted, m_game.state, nil);
  [m_game play:[m_game.board pointAtVertex:@"B1"]];
  STAssertEquals(GoGameStateGameHasStarted, m_game.state, nil);
  [m_game resign];
  STAssertEquals(GoGameStateGameHasEnded, m_game.state, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the @e reasonForGameHasEnded property.
// -----------------------------------------------------------------------------
- (void) testReasonForGameHasEnded
{
  STAssertEquals(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded, nil);
  [m_game resign];
  STAssertEquals(GoGameHasEndedReasonResigned, m_game.reasonForGameHasEnded, nil);

  // Cannot undo a "resign", and we don't want to fiddle with game state, so
  // we must create a new game
  [[[NewGameCommand alloc] init] submit];
  m_game = m_delegate.game;
  STAssertEquals(GoGameHasEndedReasonNotYetEnded, m_game.reasonForGameHasEnded, nil);
  [m_game pass];
  [m_game pass];
  STAssertEquals(GoGameHasEndedReasonTwoPasses, m_game.reasonForGameHasEnded, nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the play() method.
// -----------------------------------------------------------------------------
- (void) testPlay
{
  STAssertEquals(GoGameStateGameHasNotYetStarted, m_game.state, nil);

  GoPoint* point1 = [m_game.board pointAtVertex:@"T19"];
  [m_game play:point1];
  STAssertEquals(GoGameStateGameHasStarted, m_game.state, nil);
  GoMove* move1 = m_game.lastMove;
  STAssertEquals(GoMoveTypePlay, move1.type, nil);
  STAssertEquals(m_game.playerBlack, move1.player, nil);
  STAssertEquals(point1, move1.point, nil);

  GoPoint* point2 = [m_game.board pointAtVertex:@"S19"];
  [m_game play:point2];
  GoMove* move2 = m_game.lastMove;
  STAssertEquals(GoMoveTypePlay, move2.type, nil);
  STAssertEquals(m_game.playerWhite, move2.player, nil);
  STAssertEquals(point2, move2.point, nil);

  [m_game pass];

  GoPoint* point3 = [m_game.board pointAtVertex:@"T18"];
  [m_game play:point3];
  GoMove* move3 = m_game.lastMove;
  STAssertEquals(GoMoveTypePlay, move3.type, nil);
  STAssertEquals(m_game.playerWhite, move3.player, nil);
  STAssertEquals(point3, move3.point, nil);
  NSUInteger expectedNumberOfCapturedStones = 1;
  STAssertEquals(expectedNumberOfCapturedStones, move3.capturedStones.count, nil);

  STAssertThrowsSpecificNamed([m_game play:nil],
                              NSException, NSInvalidArgumentException, @"point is nil");
  STAssertThrowsSpecificNamed([m_game play:point1],
                              NSException, NSInvalidArgumentException, @"point is not legal");
  [m_game resign];
  STAssertThrowsSpecificNamed([m_game play:[m_game.board pointAtVertex:@"B1"]],
                              NSException, NSInternalInconsistencyException, @"play after game end");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the pass() method.
// -----------------------------------------------------------------------------
- (void) testPass
{
  STAssertEquals(GoGameStateGameHasNotYetStarted, m_game.state, nil);

  // Can start game with a pass
  [m_game pass];
  STAssertEquals(GoGameStateGameHasStarted, m_game.state, nil);
  GoMove* move1 = m_game.lastMove;
  STAssertEquals(GoMoveTypePass, move1.type, nil);
  STAssertEquals(m_game.playerBlack, move1.player, nil);
  STAssertNil(move1.point, nil);

  [m_game play:[m_game.board pointAtVertex:@"B13"]];

  [m_game pass];
  GoMove* move2 = m_game.lastMove;
  STAssertEquals(GoMoveTypePass, move2.type, nil);
  STAssertEquals(m_game.playerBlack, move2.player, nil);
  STAssertNil(move2.point, nil);

  // End the game with two passes in a row
  [m_game pass];
  STAssertEquals(GoGameStateGameHasEnded, m_game.state, nil);
  GoMove* move3 = m_game.lastMove;
  STAssertEquals(GoMoveTypePass, move3.type, nil);
  STAssertEquals(m_game.playerWhite, move3.player, nil);
  STAssertNil(move3.point, nil);

  STAssertThrowsSpecificNamed([m_game pass],
                              NSException, NSInternalInconsistencyException, @"pass after game end");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the resign() method.
// -----------------------------------------------------------------------------
- (void) testResign
{
  STAssertEquals(GoGameStateGameHasNotYetStarted, m_game.state, nil);

  // Can start game with resign
  [m_game resign];
  STAssertEquals(GoGameStateGameHasEnded, m_game.state, nil);
  // Resign in other situations already tested

  STAssertThrowsSpecificNamed([m_game resign],
                              NSException, NSInternalInconsistencyException, @"resign after game end");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the undo() method.
// -----------------------------------------------------------------------------
- (void) testUndo
{
  STAssertEquals(GoGameStateGameHasNotYetStarted, m_game.state, nil);

  STAssertThrowsSpecificNamed([m_game undo],
                              NSException, NSInternalInconsistencyException, @"undo before game start");

  [m_game pass];
  STAssertNotNil(m_game.firstMove, nil);
  STAssertNotNil(m_game.lastMove, nil);
  [m_game undo];
  STAssertNil(m_game.firstMove, nil);
  STAssertNil(m_game.lastMove, nil);

  STAssertThrowsSpecificNamed([m_game undo],
                              NSException, NSInternalInconsistencyException, @"no moves to undo");
  
  [m_game pass];
  [m_game pass];
  STAssertEquals(GoGameStateGameHasEnded, m_game.state, nil);
  STAssertThrowsSpecificNamed([m_game undo],
                              NSException, NSInternalInconsistencyException, @"undo after game end");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the pause() method.
// -----------------------------------------------------------------------------
- (void) testPause
{
  STAssertEquals(GoGameStateGameHasNotYetStarted, m_game.state, nil);
  STAssertThrowsSpecificNamed([m_game pause],
                              NSException, NSInternalInconsistencyException, @"pause before game start");
  [m_game pass];
  STAssertThrowsSpecificNamed([m_game pause],
                              NSException, NSInternalInconsistencyException, @"no computer vs. computer game");
  [m_game pass];
  STAssertEquals(GoGameStateGameHasEnded, m_game.state, nil);
  STAssertThrowsSpecificNamed([m_game pause],
                              NSException, NSInternalInconsistencyException, @"pause after game end");
  
  // Currently no more tests possible because we can't simulate
  // computer vs. computer games
}

// -----------------------------------------------------------------------------
/// @brief Exercises the continue() method.
// -----------------------------------------------------------------------------
- (void) testContinue
{
  STAssertEquals(GoGameStateGameHasNotYetStarted, m_game.state, nil);
  STAssertThrowsSpecificNamed([m_game continue],
                              NSException, NSInternalInconsistencyException, @"continue before game start");
  [m_game pass];
  STAssertThrowsSpecificNamed([m_game continue],
                              NSException, NSInternalInconsistencyException, @"no computer vs. computer game");
  [m_game pass];
  STAssertEquals(GoGameStateGameHasEnded, m_game.state, nil);
  STAssertThrowsSpecificNamed([m_game continue],
                              NSException, NSInternalInconsistencyException, @"continue after game end");

  // Currently no more tests possible because we can't simulate
  // computer vs. computer games
}

// -----------------------------------------------------------------------------
/// @brief Exercises the isLegalMove() method.
// -----------------------------------------------------------------------------
- (void) testIsLegalMove
{
  // Unoccupied point is legal for both players
  GoPoint* point1 = [m_game.board pointAtVertex:@"T1"];
  STAssertTrue([m_game isLegalMove:point1], nil);
  [m_game pass];
  STAssertTrue([m_game isLegalMove:point1], nil);

  // Play it with black
  [m_game undo];
  [m_game play:point1];

  // Point occupied by black is not legal for either player
  STAssertFalse([m_game isLegalMove:point1], nil);
  [m_game pass];
  STAssertFalse([m_game isLegalMove:point1], nil);

  // Play stone with white
  [m_game undo];
  GoPoint* point2 = [m_game.board pointAtVertex:@"S1"];
  [m_game play:point2];

  // Point occupied by white is not legal for either player
  STAssertFalse([m_game isLegalMove:point1], nil);
  [m_game pass];
  STAssertFalse([m_game isLegalMove:point1], nil);

  // Play capturing stone stone with white
  GoPoint* point3 = [m_game.board pointAtVertex:@"T2"];
  [m_game play:point3];

  // Original point not legal for black, is suicide
  STAssertFalse([m_game isLegalMove:point1], nil);
  // But legal for white, just a fill
  [m_game pass];
  STAssertTrue([m_game isLegalMove:point1], nil);

  // Counter-attack by black to create Ko situation
  [m_game undo];
  GoPoint* point4 = [m_game.board pointAtVertex:@"R1"];
  [m_game play:point4];
  [m_game pass];
  GoPoint* point5 = [m_game.board pointAtVertex:@"S2"];
  [m_game play:point5];
  [m_game pass];

  // Original point now legal for black, is no longer suicide
  STAssertTrue([m_game isLegalMove:point1], nil);
  [m_game play:point1];

  // Not legal for white because of Ko
  STAssertFalse([m_game isLegalMove:point2], nil);

  // White passes, black plays somewhere else
  [m_game pass];
  GoPoint* point6 = [m_game.board pointAtVertex:@"A19"];
  [m_game play:point6];

  // Again legal for white because Ko has gone
  STAssertTrue([m_game isLegalMove:point2], nil);
  [m_game play:point2];
  // Not legal for black, again because of Ko
  STAssertFalse([m_game isLegalMove:point1], nil);

  // Black passes, white connects
  [m_game pass];
  [m_game play:point1];


  // Setup situation that resembles Ko, but is not, because it allows to
  // capture back more than 1 stone
  [m_game play:[m_game.board pointAtVertex:@"A1"]];
  [m_game play:[m_game.board pointAtVertex:@"A2"]];
  [m_game play:[m_game.board pointAtVertex:@"D1"]];
  [m_game play:[m_game.board pointAtVertex:@"B2"]];
  [m_game play:[m_game.board pointAtVertex:@"C2"]];
  GoPoint* point7 = [m_game.board pointAtVertex:@"C1"];
  [m_game play:point7];
  // Is legal for black, captures C1
  GoPoint* point8 = [m_game.board pointAtVertex:@"B1"];
  STAssertTrue([m_game isLegalMove:point8], nil);
  [m_game play:point8];
  // Is legal for white, captures back A1 and B1 (no Ko!)
  STAssertTrue([m_game isLegalMove:point7], nil);
  [m_game play:point7];

  // Setup situation that resembles Ko, but is not, because it allows to
  // capture back more than 1 stone
  [m_game play:[m_game.board pointAtVertex:@"Q18"]];
  [m_game play:[m_game.board pointAtVertex:@"R18"]];
  [m_game play:[m_game.board pointAtVertex:@"R17"]];
  [m_game play:[m_game.board pointAtVertex:@"S18"]];
  [m_game play:[m_game.board pointAtVertex:@"S17"]];
  [m_game pass];
  [m_game play:[m_game.board pointAtVertex:@"R19"]];
  [m_game pass];
  [m_game play:[m_game.board pointAtVertex:@"S19"]];
  [m_game pass];
  // Black captures two white stones
  [m_game play:[m_game.board pointAtVertex:@"T18"]];
  // White plays inside the black enclosure, with only one liberty
  [m_game play:[m_game.board pointAtVertex:@"R18"]];
  // Is legal for black, recaptures white stone on R18
  GoPoint* point9 = [m_game.board pointAtVertex:@"S18"];
  STAssertTrue([m_game isLegalMove:point9], nil);
  [m_game play:point9];

  STAssertThrowsSpecificNamed([m_game isLegalMove:nil],
                              NSException, NSInvalidArgumentException, @"point is nil");
}

// -----------------------------------------------------------------------------
/// @brief Exercises the isComputerPlayersTurn() method.
// -----------------------------------------------------------------------------
- (void) testIsComputerPlayersTurn
{
  STAssertEquals(GoGameStateGameHasNotYetStarted, m_game.state, nil);
  STAssertFalse([m_game isComputerPlayersTurn], nil);
  [m_game pass];
  STAssertFalse([m_game isComputerPlayersTurn], nil);
  [m_game undo];
  STAssertFalse([m_game isComputerPlayersTurn], nil);
  [m_game pass];
  [m_game pass];
  STAssertFalse([m_game isComputerPlayersTurn], nil);

  // Currently no more tests possible because we can't simulate
  // computer vs. human games
}

// -----------------------------------------------------------------------------
/// @brief Regression test for bug 137.
///
/// Set up a position where 4 regions, each consisting of a single stone, are
/// merged into a new single region, by placing a single connecting stone. The
/// connecting stone is then removed by undoing the move, which must result
/// in the same 4 regions being re-created.
/// - Single stone regions: A2, B1, B3, C2
/// - Connecting stone: B2
// -----------------------------------------------------------------------------
- (void) testUndoCausesRegionToFragment
{
  GoPoint* point1 = [m_game.board pointAtVertex:@"A2"];
  GoPoint* point2 = [m_game.board pointAtVertex:@"B1"];
  GoPoint* point3 = [m_game.board pointAtVertex:@"B3"];
  GoPoint* point4 = [m_game.board pointAtVertex:@"C2"];
  GoPoint* point5 = [m_game.board pointAtVertex:@"B2"];
  GoPoint* pointInMainRegion = [m_game.board pointAtVertex:@"A3"];

  // Set up the initial position
  [m_game play:point1];
  [m_game pass];
  [m_game play:point2];
  [m_game pass];
  [m_game play:point3];
  [m_game pass];
  [m_game play:point4];
  [m_game pass];
  [self verifyFragmentedRegionsOfTestUndoCausesRegionToFragment:@"initial setup"];

  // Play the connecting stone
  [m_game play:point5];
  STAssertEquals(GoColorBlack, point5.stoneState, nil);
  NSUInteger expectedNumberOfRegionsWhenMerged = 3;
  STAssertEquals(expectedNumberOfRegionsWhenMerged, m_game.board.regions.count, nil);
  GoBoardRegion* mergedRegion = point1.region;
  GoBoardRegion* mainRegion = pointInMainRegion.region;
  STAssertTrue(mergedRegion == point2.region, nil);
  STAssertTrue(mergedRegion == point3.region, nil);
  STAssertTrue(mergedRegion == point4.region, nil);
  STAssertTrue(mergedRegion == point5.region, nil);
  STAssertTrue(mergedRegion != mainRegion, nil);
  int expectedSizeOfRegionWhenMerged = 5;
  STAssertEquals(expectedSizeOfRegionWhenMerged, [mergedRegion size], nil);

  // Remove the connecting stone
  [m_game undo];
  [self verifyFragmentedRegionsOfTestUndoCausesRegionToFragment:@"after undo"];
}

// -----------------------------------------------------------------------------
/// @brief Private helper method of testUndoCausesRegionToFragment(). Verifies
/// the correctness of region fragmentation twice: Once before the connecting
/// move is made, and and once after the connecting move has been undone.
// -----------------------------------------------------------------------------
- (void) verifyFragmentedRegionsOfTestUndoCausesRegionToFragment:(NSString*)failureDescription
{
  GoPoint* point1 = [m_game.board pointAtVertex:@"A2"];
  GoPoint* point2 = [m_game.board pointAtVertex:@"B1"];
  GoPoint* point3 = [m_game.board pointAtVertex:@"B3"];
  GoPoint* point4 = [m_game.board pointAtVertex:@"C2"];
  GoPoint* point5 = [m_game.board pointAtVertex:@"B2"];
  GoPoint* pointInMainRegion = [m_game.board pointAtVertex:@"A3"];

  STAssertEquals(GoColorBlack, point1.stoneState, failureDescription);
  STAssertEquals(GoColorBlack, point2.stoneState, failureDescription);
  STAssertEquals(GoColorBlack, point3.stoneState, failureDescription);
  STAssertEquals(GoColorBlack, point4.stoneState, failureDescription);
  STAssertEquals(GoColorNone, point5.stoneState, failureDescription);
  NSUInteger expectedNumberOfRegionsWhenFragmented = 7;
  STAssertEquals(expectedNumberOfRegionsWhenFragmented, m_game.board.regions.count, failureDescription);
  GoBoardRegion* point1Region = point1.region;
  GoBoardRegion* point2Region = point2.region;
  GoBoardRegion* point3Region = point3.region;
  GoBoardRegion* point4Region = point4.region;
  GoBoardRegion* point5Region = point5.region;
  GoBoardRegion* mainRegion = pointInMainRegion.region;
  STAssertTrue(point1Region != point2Region, failureDescription);
  STAssertTrue(point1Region != point3Region, failureDescription);
  STAssertTrue(point1Region != point4Region, failureDescription);
  STAssertTrue(point1Region != point5Region, failureDescription);
  STAssertTrue(point1Region != mainRegion, failureDescription);
  STAssertTrue(point2Region != point3Region, failureDescription);
  STAssertTrue(point2Region != point4Region, failureDescription);
  STAssertTrue(point2Region != point5Region, failureDescription);
  STAssertTrue(point2Region != mainRegion, failureDescription);
  STAssertTrue(point3Region != point4Region, failureDescription);
  STAssertTrue(point3Region != point5Region, failureDescription);
  STAssertTrue(point3Region != mainRegion, failureDescription);
  STAssertTrue(point4Region != point5Region, failureDescription);
  STAssertTrue(point4Region != mainRegion, failureDescription);
  STAssertTrue(point5Region != mainRegion, failureDescription);
  int expectedSizeOfRegionsWhenFragmented = 1;
  STAssertEquals(expectedSizeOfRegionsWhenFragmented, [point1Region size], failureDescription);
  STAssertEquals(expectedSizeOfRegionsWhenFragmented, [point2Region size], failureDescription);
  STAssertEquals(expectedSizeOfRegionsWhenFragmented, [point3Region size], failureDescription);
  STAssertEquals(expectedSizeOfRegionsWhenFragmented, [point4Region size], failureDescription);
  STAssertEquals(expectedSizeOfRegionsWhenFragmented, [point5Region size], failureDescription);
}

@end
