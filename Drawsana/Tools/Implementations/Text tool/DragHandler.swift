//
//  DragHandler.swift
//  Drawsana
//
//  Created by Steve Landey on 8/8/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

class DragHandler {
  let shape: TextShape
  weak var textTool: TextTool?
  var startPoint: CGPoint = .zero

  init(
    shape: TextShape,
    textTool: TextTool)
  {
    self.shape = shape
    self.textTool = textTool
  }

  func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    startPoint = point
  }

  func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {

  }

  func handleDragEnd(context: ToolOperationContext, point: CGPoint) {

  }

  func handleDragCancel(context: ToolOperationContext, point: CGPoint) {

  }
}

/// User is dragging the text itself to a new location
class MoveHandler: DragHandler {
  private var originalTransform: ShapeTransform

  override init(
    shape: TextShape,
    textTool: TextTool)
  {
    self.originalTransform = shape.transform
    super.init(shape: shape, textTool: textTool)
  }

  override func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    let delta = point - startPoint
    shape.transform = originalTransform.translated(by: delta, drawingSize: context.drawing.size)
    textTool?.updateTextView()
  }

  override func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
    context.operationStack.apply(operation: ChangeTransformOperation(
      shape: shape,
      transform: originalTransform.translated(by: delta, drawingSize: context.drawing.size),
      originalTransform: originalTransform))
  }

  override func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    shape.transform = originalTransform
    context.toolSettings.isPersistentBufferDirty = true
    textTool?.updateShapeFrame(drawingSize: context.drawing.size)
  }
}

/// User is dragging the lower-right handle to change the size and rotation
/// of the text box
class ResizeAndRotateHandler: DragHandler {
  private var originalTransform: ShapeTransform

  override init(
    shape: TextShape,
    textTool: TextTool)
  {
    self.originalTransform = shape.transform
    super.init(shape: shape, textTool: textTool)
  }

  private func getResizeAndRotateTransform(point: CGPoint, drawingSize: CGSize) -> ShapeTransform {
    let originalDelta = startPoint - shape.transform.translation.shapeRenderingPoint(drawingSize: drawingSize)
    let newDelta = point - shape.transform.translation.shapeRenderingPoint(drawingSize: drawingSize)
    let originalDistance = originalDelta.length
    let newDistance = newDelta.length
    let originalAngle = atan2(originalDelta.y, originalDelta.x)
    let newAngle = atan2(newDelta.y, newDelta.x)
    let scaleChange = newDistance / originalDistance
    let angleChange = newAngle - originalAngle
    return originalTransform.scaled(by: scaleChange).rotated(by: angleChange)
  }

  override func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    shape.transform = getResizeAndRotateTransform(point: point, drawingSize: context.drawing.size)
    textTool?.updateTextView()
  }

  override func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    context.operationStack.apply(operation: ChangeTransformOperation(
      shape: shape,
      transform: getResizeAndRotateTransform(point: point, drawingSize: context.drawing.size),
      originalTransform: originalTransform))
  }

  override func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    shape.transform = originalTransform
    context.toolSettings.isPersistentBufferDirty = true
    textTool?.updateShapeFrame(drawingSize: context.drawing.size)
  }
}

/// User is dragging the middle-right handle to change the width of the text
/// box
class ChangeWidthHandler: DragHandler {
  private var originalWidth: CGFloat?
  private var originalBoundingRect: CGRect = .zero
  private let drawingSize: CGSize

  init(
    drawingSize: CGSize,
    shape: TextShape,
    textTool: TextTool)
  {
    self.originalWidth = shape.explicitWidth
    self.drawingSize = drawingSize
    self.originalBoundingRect = shape.boundingRect(drawingSize: drawingSize)
    super.init(shape: shape, textTool: textTool)
    shape.explicitWidth = shape.explicitWidth ?? shape.size.width
  }

  override func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    guard let textTool = textTool else { return }
    let translatedBoundingRect = shape
      .boundingRect(drawingSize: drawingSize)
      .applying(shape.transform.affineTransform(drawingSize: context.drawing.size))
    // TODO: The math here isn't quite right. Instead of using the distance from
    // the center of the shape, we should use only the distance to the center of
    // the text on the X axis in the text's coordinate space. This isn't too
    // hard to do with some working knowledge of linear algebra and trigonometry,
    // but it didn't make the cut for initial release.
    let distanceFromShapeCenter = (point - translatedBoundingRect.middle).length
    let desiredWidthInScreenCoordinates = (
      distanceFromShapeCenter - textTool.editingView.changeWidthControlView.frame.size.width / 2) * 2
    shape.explicitWidth = desiredWidthInScreenCoordinates / shape.transform.scale
    textTool.updateShapeFrame(drawingSize: context.drawing.size)
  }

  override func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    context.operationStack.apply(operation: ChangeExplicitWidthOperation(
      shape: shape,
      originalWidth: originalWidth,
      originalBoundingRect: originalBoundingRect,
      newWidth: shape.explicitWidth,
      newBoundingRect: shape.boundingRect(drawingSize: drawingSize)))
  }

  override func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    shape.explicitWidth = originalWidth
    shape.size = originalBoundingRect.size
    shape.origin = originalBoundingRect.origin.shapeRelativePoint(drawingSize: context.drawing.size)
    context.toolSettings.isPersistentBufferDirty = true
    textTool?.updateTextView()
  }
}
