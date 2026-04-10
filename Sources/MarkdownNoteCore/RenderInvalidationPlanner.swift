import Foundation

public enum RenderInvalidationPlanner {
  public static func invalidatedBlockIndexes(previousActive: Int?, newActive: Int?) -> Set<Int> {
    var indexes: Set<Int> = []

    if let previousActive {
      indexes.insert(previousActive)
    }

    if let newActive {
      indexes.insert(newActive)
    }

    return indexes
  }
}
