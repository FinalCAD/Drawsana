//
//  DrawingToolForShapeWithThreePoints.swift
//  Drawsana
//
//  Created by Thanh Vu on 5/3/19.
//  Copyright © 2019 Asana. All rights reserved.
//

import Foundation

import CoreGraphics

/**
 Base class for tools (angle)
 */
open class DrawingToolForShapeWithThreePoints: DrawingTool {
  public typealias ShapeType = Shape & ShapeWithThreePoints
  
  open var name: String { fatalError("Override me") }
  
  public var shapeInProgress: ShapeType?
  
  public var isProgressive: Bool { return false }
  
  private var dragEndCount: Int = 0
  
  public init() { }
  
  /// Override this method to return a shape ready to be drawn to the screen.
  open func makeShape() -> ShapeType {
    fatalError("Override me")
  }
  
  public func handleTap(context: ToolOperationContext, point: CGPoint) {
  }
  
  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    if dragEndCount == 0 {
      shapeInProgress = makeShape()
      shapeInProgress?.a = point.shapeRelativePoint(drawingSize: context.drawing.size)
      shapeInProgress?.b = point.shapeRelativePoint(drawingSize: context.drawing.size)
      shapeInProgress?.c = point.shapeRelativePoint(drawingSize: context.drawing.size)
      shapeInProgress?.apply(userSettings: context.userSettings)
      return
    }
    shapeInProgress?.c = point
  }
  
  public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    if dragEndCount == 0 {
      shapeInProgress?.b = point.shapeRelativePoint(drawingSize: context.drawing.size)
      return
    }
    shapeInProgress?.c = point.shapeRelativePoint(drawingSize: context.drawing.size)
  }
  
  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    guard var shape = shapeInProgress else { return }
    if dragEndCount == 0 {
      dragEndCount += 1
      shape.b = point.shapeRelativePoint(drawingSize: context.drawing.size)
      context.operationStack.apply(operation: AddShapeOperation(shape: shape))
      return
    }
    shape.c = point.shapeRelativePoint(drawingSize: context.drawing.size)
    context.operationStack.undo()
    context.operationStack.apply(operation: AddShapeOperation(shape: shape))
    dragEndCount = 0
    shapeInProgress = nil
  }
  
  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    // No such thing as a cancel for this tool. If this was recognized as a tap,
    // just end the shape normally.
    handleDragEnd(context: context, point: point)
  }
  
  public func renderShapeInProgress(transientContext: CGContext, drawingSize: CGSize) {
    shapeInProgress?.render(in: transientContext, drawingSize: drawingSize)
  }
  
  public func apply(context: ToolOperationContext, userSettings: UserSettings) {
    shapeInProgress?.apply(userSettings: userSettings)
    context.toolSettings.isPersistentBufferDirty = true
  }
}
