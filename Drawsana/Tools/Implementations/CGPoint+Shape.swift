import Foundation

public extension CGPoint {
  /// Point for rendering shape in drawing size
  func shapeRenderingPoint(drawingSize: CGSize) -> CGPoint {
      return CGPoint(x: x * drawingSize.width, y: y * drawingSize.height)
  }

  /// Compute relative point in a tool operation context to have relative coordinates, adaptable to any size of image (useful to handle rotation)
  func shapeRelativePoint(drawingSize: CGSize) -> CGPoint {
    return CGPoint(
      x: x / drawingSize.width,
      y: y / drawingSize.height
    )
  }
}
