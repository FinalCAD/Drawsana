//
//  AMShape.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/23/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

/**
 Base protocol which all shapes must implement.

 Note: If you implement your own shapes, see `Drawing.shapeDecoder`!
 */
public protocol Shape: AnyObject, Codable {
  /// Globally unique identifier for this shape. Meant to be used for equality
  /// checks, especially for network-based updates.
  var id: String { get set }

  /// String value of this shape, for serialization and debugging
  static var type: String { get }

  /// Draw this shape to the given Core Graphics context. Transforms for drawing
  /// position and scale are already applied.
  func render(in context: CGContext, drawingSize: CGSize)

  /// Return true iff the given point meaningfully intersects with the pixels
  /// drawn by this shape. See `ShapeWithBoundingRect` for a shortcut.
  func hitTest(point: CGPoint, drawingSize: CGSize) -> Bool

  /// Apply any relevant values in `userSettings` (colors, sizes, fonts...) to
  /// this shape
  func apply(userSettings: UserSettings)
}

/**
 Enhancement to `Shape` protocol that allows you to simply specify a
 `boundingRect` property and have `hitTest` implemented automatically.
 */
public protocol ShapeWithBoundingRect: Shape {
  func boundingRect(drawingSize: CGSize) -> CGRect
}

extension ShapeWithBoundingRect {
  public func hitTest(point: CGPoint, drawingSize: CGSize) -> Bool {
    return boundingRect(drawingSize: drawingSize).contains(point)
  }
}

/**
 Enhancement to `Shape` protocol that has a `transform` property, meaning it can
 be translated, rotated, and scaled relative to its original characteristics.
 */
public protocol ShapeWithTransform: Shape {
  var transform: ShapeTransform { get set }
}

/**
 Enhancement to `Shape` protocol that enforces requirements necessary for a
 shape to be used with the selection tool. This includes
 `ShapeWithBoundingRect` to render the selection rect around the shape, and
 `ShapeWithTransform` to allow the shape to be moved from its original
 position
 */
public protocol ShapeSelectable: ShapeWithBoundingRect, ShapeWithTransform {
}

extension ShapeSelectable {
  public func hitTest(point: CGPoint, drawingSize: CGSize) -> Bool {
    return boundingRect(drawingSize: drawingSize).applying(transform.affineTransform(drawingSize: drawingSize)).contains(point)
  }
}

/**
 Enhancement to `Shape` adding properties to match all `UserSettings`
 properties. There is a convenience method `apply(userSettings:)` which updates
 the shape to match the given values.
 */
public protocol ShapeWithStandardState: AnyObject {
  var strokeColor: UIColor? { get set }
  var fillColor: UIColor? { get set }
  var strokeWidth: CGFloat { get set }
}

extension ShapeWithStandardState {
  public func apply(userSettings: UserSettings) {
    strokeColor = userSettings.strokeColor
    fillColor = userSettings.fillColor
    strokeWidth = userSettings.strokeWidth
  }
}

/**
 Like `ShapeWithStandardState`, but ignores `UserSettings.fillColor`.
 */
public protocol ShapeWithStrokeState: AnyObject {
  var strokeColor: UIColor { get set }
  var strokeWidth: CGFloat { get set }
}

extension ShapeWithStrokeState {
  public func apply(userSettings: UserSettings) {
    strokeColor = userSettings.strokeColor ?? .black
    strokeWidth = userSettings.strokeWidth
  }
}

/**
 Special case of `Shape` where the shape is defined by exactly two points.
 This case is used to share code between the line, ellipse, and rectangle shapes
 and tools.
 */
public protocol ShapeWithTwoPoints {
  var a: CGPoint { get set }
  var b: CGPoint { get set }

  var strokeWidth: CGFloat { get set }
}

extension ShapeWithTwoPoints {
  public func rect(drawingSize: CGSize) -> CGRect {
    let a = self.a.shapeRenderingPoint(drawingSize: drawingSize)
    let b = self.b.shapeRenderingPoint(drawingSize: drawingSize)
    let x1 = min(a.x, b.x)
    let y1 = min(a.y, b.y)
    let x2 = max(a.x, b.x)
    let y2 = max(a.y, b.y)
    return CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
  }
    
    public func squareRect(drawingSize: CGSize) -> CGRect {
        let a = self.a.shapeRenderingPoint(drawingSize: drawingSize)
        let b = self.b.shapeRenderingPoint(drawingSize: drawingSize)
        let width = min(abs(b.x - a.x), abs(b.y - a.y))
        let x = b.x < a.x ? a.x - width : a.x
        let y = b.y < a.y ? a.y - width : a.y
        return CGRect(x: x, y: y, width: width, height: width)
    }

  public func boundingRect(drawingSize: CGSize) -> CGRect {
    return rect(drawingSize: drawingSize).insetBy(dx: -strokeWidth/2, dy: -strokeWidth/2)
  }
}

/**
 Special case of `Shape` where the shape is defined by exactly three points.
 */
public protocol ShapeWithThreePoints {
  var a: CGPoint { get set }
  var b: CGPoint { get set }
  var c: CGPoint { get set }
  
  var strokeWidth: CGFloat { get set }
}

extension ShapeWithThreePoints {
  public func rect(drawingSize: CGSize) -> CGRect {
    let a = self.a.shapeRenderingPoint(drawingSize: drawingSize)
    let b = self.b.shapeRenderingPoint(drawingSize: drawingSize)
    let x1 = min(a.x, b.x, c.x)
    let y1 = min(a.y, b.y, c.y)
    let x2 = max(a.x, b.x, c.x)
    let y2 = max(a.y, b.y, c.y)
    return CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
  }
  
  public func boundingRect(drawingSize: CGSize) -> CGRect {
    return rect(drawingSize: drawingSize).insetBy(dx: -strokeWidth/2, dy: -strokeWidth/2)
  }
}
