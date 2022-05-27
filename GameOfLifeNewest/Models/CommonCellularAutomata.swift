public protocol Automata {
    
    init()
    
    func simulate(_ state: AutomataState, generations: UInt) throws -> AutomataState
}

public protocol AutomataState: CustomStringConvertible {
    init()
    
    init(_ rect: Rect)

    var viewport: Rect { get set }
    
    func copy() -> AutomataState
    
    mutating func resize(width: UInt, height: UInt)

    subscript(_: Point) -> BinaryCell { get set }
    
    subscript(_: Rect) -> AutomataState { get set }
    
    mutating func switchValue(point: Point)

    mutating func translate(to: Point)
    
    mutating func refreshVicinity(point: Point, oldValue: BinaryCell)
}

public class BinaryCell: CustomStringConvertible {
    
    var value: Int8
    
    var copy: Self {
        return Self(value)
    }
    
    required init() {
        value = 0
    }
    
    public var description: String {
        return rawValue.description
    }
    
    required init(_ value: Int8) {
        self.value = value
    }
    
    public func isActive() -> Bool {
        return value == 1
    }
    
    var rawValue: Int8 {
        get {
            value
        }
        set {
            value = newValue
        }
    }
    
    public class func zero() -> Self {
        let res = Self()
        return res
    }
}

// Представление окрестности клетки
// младшие 4 бита - количество живых соседей
// 5 бит - состояние клетки
public class GolCell: BinaryCell { // класс неэффективно, переделать
    public override func isActive() -> Bool {
        return !(self.rawValue & 0b00010000 == 0)
    }
    
}
