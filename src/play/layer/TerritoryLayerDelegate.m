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


// Project includes
#import "TerritoryLayerDelegate.h"
#import "../PlayViewMetrics.h"
#import "../PlayViewModel.h"
#import "../ScoringModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoBoardRegion.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/UIColorAdditions.h"

// System includes
#import <QuartzCore/QuartzCore.h>


/// @brief Enumerates all possible layer types to mark up territory
enum TerritoryLayerType
{
  TerritoryLayerTypeBlack,
  TerritoryLayerTypeWhite,
  TerritoryLayerTypeInconsistentFillColor,
  TerritoryLayerTypeInconsistentDotSymbol
};

// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for TerritoryLayerDelegate.
// -----------------------------------------------------------------------------
@interface TerritoryLayerDelegate()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Private helpers
//@{
- (CGLayerRef) territoryLayerWithContext:(CGContextRef)context layerType:(enum TerritoryLayerType)layerType;
- (void) releaseLayers;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) ScoringModel* scoringModel;
@property(nonatomic, assign) CGLayerRef blackTerritoryLayer;
@property(nonatomic, assign) CGLayerRef whiteTerritoryLayer;
@property(nonatomic, assign) CGLayerRef inconsistentFillColorTerritoryLayer;
@property(nonatomic, assign) CGLayerRef inconsistentDotSymbolTerritoryLayer;
//@}
@end


@implementation TerritoryLayerDelegate

@synthesize scoringModel;
@synthesize blackTerritoryLayer;
@synthesize whiteTerritoryLayer;
@synthesize inconsistentFillColorTerritoryLayer;
@synthesize inconsistentDotSymbolTerritoryLayer;


// -----------------------------------------------------------------------------
/// @brief Initializes a TerritoryLayerDelegate object.
///
/// @note This is the designated initializer of TerritoryLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithLayer:(CALayer*)aLayer metrics:(PlayViewMetrics*)metrics playViewModel:(PlayViewModel*)playViewModel scoringModel:(ScoringModel*)theScoringModel
{
  // Call designated initializer of superclass (PlayViewLayerDelegate)
  self = [super initWithLayer:aLayer metrics:metrics model:playViewModel];
  if (! self)
    return nil;
  self.scoringModel = theScoringModel;
  self.blackTerritoryLayer = NULL;
  self.whiteTerritoryLayer = NULL;
  self.inconsistentFillColorTerritoryLayer = NULL;
  self.inconsistentDotSymbolTerritoryLayer = NULL;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TerritoryLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.scoringModel = nil;
  [self releaseLayers];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Releases layers for marking up territory if they are currently
/// allocated. Otherwise does nothing.
// -----------------------------------------------------------------------------
- (void) releaseLayers
{
  if (self.blackTerritoryLayer)
  {
    CGLayerRelease(self.blackTerritoryLayer);
    self.blackTerritoryLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (self.whiteTerritoryLayer)
  {
    CGLayerRelease(self.whiteTerritoryLayer);
    self.whiteTerritoryLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (self.inconsistentFillColorTerritoryLayer)
  {
    CGLayerRelease(self.inconsistentFillColorTerritoryLayer);
    self.inconsistentFillColorTerritoryLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (self.inconsistentDotSymbolTerritoryLayer)
  {
    CGLayerRelease(self.inconsistentDotSymbolTerritoryLayer);
    self.inconsistentDotSymbolTerritoryLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
}

// -----------------------------------------------------------------------------
/// @brief PlayViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) notify:(enum PlayViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  switch (event)
  {
    case PVLDEventRectangleChanged:
    {
      self.layer.frame = self.playViewMetrics.rect;
      [self releaseLayers];
      self.dirty = true;
      break;
    }
    case PVLDEventGoGameStarted:  // possible board size change
    {
      [self releaseLayers];
      self.dirty = true;
      break;
    }
    case PVLDEventScoreCalculationEnds:
    case PVLDEventInconsistentTerritoryMarkupTypeChanged:
    case PVLDEventScoringModeDisabled:
    {
      self.dirty = true;
      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief CALayer delegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  if (! self.scoringModel.scoringMode)
    return;

  if (! self.blackTerritoryLayer)
    self.blackTerritoryLayer = [self territoryLayerWithContext:context layerType:TerritoryLayerTypeBlack];
  if (! self.whiteTerritoryLayer)
    self.whiteTerritoryLayer = [self territoryLayerWithContext:context layerType:TerritoryLayerTypeWhite];
  if (! self.inconsistentFillColorTerritoryLayer)
    self.inconsistentFillColorTerritoryLayer = [self territoryLayerWithContext:context layerType:TerritoryLayerTypeInconsistentFillColor];
  if (! self.inconsistentDotSymbolTerritoryLayer)
    self.inconsistentDotSymbolTerritoryLayer = [self territoryLayerWithContext:context layerType:TerritoryLayerTypeInconsistentDotSymbol];

  CGLayerRef inconsistentTerritoryLayer = NULL;
  enum InconsistentTerritoryMarkupType inconsistentTerritoryMarkupType = self.scoringModel.inconsistentTerritoryMarkupType;
  switch (inconsistentTerritoryMarkupType)
  {
    case InconsistentTerritoryMarkupTypeDotSymbol:
    {
      inconsistentTerritoryLayer = self.inconsistentDotSymbolTerritoryLayer;
      break;
    }
    case InconsistentTerritoryMarkupTypeFillColor:
    {
      inconsistentTerritoryLayer = self.inconsistentFillColorTerritoryLayer;
      break;
    }
    case InconsistentTerritoryMarkupTypeNeutral:
    {
      inconsistentTerritoryLayer = NULL;
      break;
    }
    default:
    {
      DDLogError(@"Unknown value %d for property ScoringModel.inconsistentTerritoryMarkupType", inconsistentTerritoryMarkupType);
      break;
    }
  }

  NSEnumerator* enumerator = [[GoGame sharedGame].board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    switch (point.region.territoryColor)
    {
      case GoColorBlack:
        [self.playViewMetrics drawLayer:self.blackTerritoryLayer withContext:context centeredAtPoint:point];
        break;
      case GoColorWhite:
        [self.playViewMetrics drawLayer:self.whiteTerritoryLayer withContext:context centeredAtPoint:point];
        break;
      case GoColorNone:
        if (! point.region.territoryInconsistencyFound)
          continue;  // territory is truly neutral, no markup needed
        else if (InconsistentTerritoryMarkupTypeNeutral == inconsistentTerritoryMarkupType)
          continue;  // territory is inconsistent, but user does not want markup
        else
          [self.playViewMetrics drawLayer:inconsistentTerritoryLayer withContext:context centeredAtPoint:point];
        break;
      default:
        continue;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a CGLayer object that is associated with graphics
/// context @a context and contains the drawing operations to markup territory
/// of the specified type @a layerType.
///
/// All sizes are taken from the current values in self.playViewMetrics.
///
/// The drawing operations in the returned layer do not use gHalfPixel, i.e.
/// gHalfPixel must be added to the CTM just before the layer is actually drawn.
///
/// @note Whoever invokes this method is responsible for releasing the returned
/// CGLayer object using the function CGLayerRelease when the layer is no
/// longer needed.
// -----------------------------------------------------------------------------
- (CGLayerRef) territoryLayerWithContext:(CGContextRef)context layerType:(enum TerritoryLayerType)layerType
{
  UIColor* territoryColor;
  switch (layerType)
  {
    case TerritoryLayerTypeBlack:
    {
      territoryColor = [UIColor colorWithWhite:0.0 alpha:self.scoringModel.alphaTerritoryColorBlack];
      break;
    }
    case TerritoryLayerTypeWhite:
    {
      territoryColor = [UIColor colorWithWhite:1.0 alpha:self.scoringModel.alphaTerritoryColorWhite];
      break;
    }
    case TerritoryLayerTypeInconsistentFillColor:
    {
      UIColor* fillColor = self.scoringModel.inconsistentTerritoryFillColor;
      territoryColor = [UIColor colorWithRed:fillColor.red
                                       green:fillColor.green
                                        blue:fillColor.blue
                                       alpha:self.scoringModel.inconsistentTerritoryFillColorAlpha];
      break;
    }
    case TerritoryLayerTypeInconsistentDotSymbol:
    {
      territoryColor = self.scoringModel.inconsistentTerritoryDotSymbolColor;
      break;
    }
    default:
    {
      DDLogError(@"Unknown territory layer type %d", layerType);
      return NULL;
    }
  }

  CGRect layerRect;
  layerRect.origin = CGPointZero;
  layerRect.size = self.playViewMetrics.pointCellSize;
  CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, NULL);
  CGContextRef layerContext = CGLayerGetContext(layer);

  CGContextSetFillColorWithColor(layerContext, territoryColor.CGColor);
  if (TerritoryLayerTypeInconsistentDotSymbol == layerType)
  {
    CGPoint layerCenter = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
    const int startRadius = [UiUtilities radians:0];
    const int endRadius = [UiUtilities radians:360];
    const int clockwise = 0;
    CGContextAddArc(layerContext,
                    layerCenter.x,
                    layerCenter.y,
                    self.playViewMetrics.stoneRadius * self.scoringModel.inconsistentTerritoryDotSymbolPercentage,
                    startRadius,
                    endRadius,
                    clockwise);
  }
  else
  {
    CGContextAddRect(layerContext, layerRect);
    CGContextSetBlendMode(layerContext, kCGBlendModeNormal);
  }
  CGContextFillPath(layerContext);

  return layer;
}

@end
