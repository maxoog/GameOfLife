import Foundation

public struct Size {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        guard width >= 0 && height >= 0 else { fatalError() }
        self.width = width
        self.height = height
    }
}

public struct Point {
    public let x: Int
    public let y: Int
    
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

public struct Rect {
    public let origin: Point
    public let size: Size
    
    public var width: Int {
        size.width
    }
    
    public var height: Int {
        size.height
    }
}
 
extension Size: Hashable, CustomStringConvertible {
    static let zero = Self(width: 0, height: 0)
    
    public var description: String {
        return "(w: \(self.width), h: \(self.height))"
    }
    
    var area: Int {
        self.width * self.height
    }
}

extension Point: Hashable, CustomStringConvertible {
    static let zero = Self(x: 0, y: 0)
    
    public var description: String {
        return "(x: \(self.x), y: \(self.y))"
    }
    
    public static func + (lhs: Self, rhs: Self) -> Self {
        return Self(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    public static func - (lhs: Self, rhs: Self) -> Self {
        return Self(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}

extension Rect: Hashable, CustomStringConvertible {
    static let zero = Self(origin: .zero, size: .zero)
    
    public var description: String {
        return "{ \(self.origin), \(self.size) }"
    }
    
    var area: Int {
        self.size.area
    }
    
    var indices: [Point] {
        self.verticalIndices.flatMap { y in
            self.horizontalIndices.compactMap { x in Point(x: x, y: y) }
        }
    }
    
    func contains(point: Point) -> Bool {
        return self.horizontalIndices.contains(point.x) && self.verticalIndices.contains(point.y)
    }
    
    var horizontalIndices: Range<Int> {
        self.origin.x ..< self.origin.x + self.size.width
    }
    
    var verticalIndices: Range<Int> {
        self.origin.y ..< self.origin.y + self.size.height
    }
    
    var leftTopCorner: Point {
        Point(x: self.origin.x - 1, y: self.origin.y - 1)
    }
    
    var rightTopCorner: Point {
        Point(x: self.origin.x + self.size.width, y: self.origin.y - 1)
    }
    
    var leftBottomCorner: Point {
        Point(x: self.origin.x - 1, y: self.origin.y + self.size.height)
    }
    
    var rightBottomCorner: Point {
        Point(x: self.origin.x + self.size.width, y: self.origin.y + self.size.height)
    }
    
    func resizing(toInclude point: Point) -> Rect {
        let newOrigin = Point(x: min(self.origin.x, point.x), y: min(self.origin.y, point.y))
        let newSize = Size(
            width: max(self.origin.x + self.size.width, point.x + 1) - newOrigin.x,
            height: max(self.origin.y + self.size.height, point.y + 1) - newOrigin.y
        )
        return Rect(origin: newOrigin, size: newSize)
    }
    
}
