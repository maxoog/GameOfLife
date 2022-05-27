import Foundation

// В этом автомате используется эффективное представление клеток:
// младшие 4 бита каждой клетки представляют количество живых соседей в окрестности,
// 5 бит - значение самой клетки

 public class TwoDimentionalEffectiveAutomata: Automata {
    required public init() {
    }
    
    public func simulate(_ state: AutomataState, generations: UInt) throws -> AutomataState {
        var nextGenerationState = state
        for _ in 0 ..< generations {
            let state = nextGenerationState
            nextGenerationState = State(state.viewport)
            for point in state.viewport.indices {
                let oldValue = state[point]
                nextGenerationState.refreshVicinity(point: point, oldValue: oldValue)
            }
            
        }
        return nextGenerationState
    }
}

extension TwoDimentionalEffectiveAutomata {
    public struct State: AutomataState, CustomStringConvertible {

        typealias Cell = BinaryCell
        typealias SubState = Self
        
        var cells: [GolCell]
        public var viewport: Rect
        
        public init() {
            self.viewport = .zero
            self.cells = []
        }
        
        public init(_ viewport: Rect) {
            self.viewport = viewport
            cells = []
            for _ in 0..<viewport.area {
                cells.append(.zero())
            }
        }
        
        private init(viewport: Rect, cells: [GolCell]) {
            self.viewport = viewport
            guard cells.count == viewport.area else { fatalError("internal inconsistensy") }
            self.cells = cells
        }
        
        public var description: String {
            self.viewport.verticalIndices.map { y in
                self.viewport.horizontalIndices.map { x in
                    (self[Point(x: x, y: y)].isActive() ? "*" : "_")
                }.joined()
            }.joined(separator: "\n")
        }
        
        public mutating func resize(width: UInt, height: UInt) {
            let newViewport = Rect(origin: self.viewport.origin, size: Size(width: Int(width), height: Int(height)))
            
            var newCells: [GolCell] = []
            for _ in 0..<newViewport.area {
                newCells.append(.zero())
            }
            for x in self.viewport.horizontalIndices {
                for y in self.viewport.verticalIndices {
                    guard let arrayIndex = Self.arrayIndex(at: Point(x: x, y: y), in: newViewport) else { continue }
                    newCells[arrayIndex] = self[Point(x: x, y: y)] as! GolCell
                }
            }
            self.cells = newCells
            self.viewport = newViewport
        }
        
        public subscript(_ point: Point) -> BinaryCell {
            get {
                guard let index = Self.arrayIndex(at: point, in: self.viewport) else {
                    return .zero()
                }
                return self.cells[index]
            }
            set {
                guard let index = Self.arrayIndex(at: point, in: self.viewport) else {
                    return
                }
                self.cells[index] = newValue as! GolCell
            }
        }
        
        public subscript(rect: Rect) -> AutomataState {
            get {
                let newViewport = rect
                var newCells: [BinaryCell] = []
                for point in rect.indices {
                    newCells.append(self[point])
                }
                return Self(viewport: newViewport, cells: newCells as! [GolCell])
            }
            set {
                var newRoundedValue = newValue
                if newValue.viewport != rect {
                    newRoundedValue.viewport = rect
                }
                for point in rect.indices {
                    if self[point].isActive() != newRoundedValue[point].isActive() {
                        switchValue(point: point)
                    }
                }
            }
        }
        
        public func copy() -> AutomataState {
            var newCells: [GolCell] = []
            for value in cells {
                newCells.append(value.copy)
            }
            return Self(viewport: viewport, cells: newCells)
        }
        
        public mutating func switchValue(point: Point) {
            let cell = self[point]
            if cell.isActive() {
                cell.rawValue &= 0b00001111
                deleteNeighbour(vicinityAround: point)
            } else {
                cell.rawValue |= 0b00010000
                addNeighbour(vicinityAround: point)
            }
        }
        
        mutating public func translate(to newOrigin: Point) {
            self.viewport = Rect(origin: newOrigin, size: self.viewport.size)
        }
        
        private static func arrayIndex(at point: Point, in viewport: Rect) -> Int? {
            guard viewport.contains(point: point) else { return nil }
            let localPoint = point - viewport.origin
            return localPoint.y * viewport.size.width + localPoint.x
        }
        
        private mutating func addNeighbour(vicinityAround point: Point) {
            let x = point.x
            let y = point.y
            self[Point(x: x - 1, y: y - 1)].rawValue += 1
            self[Point(x: x, y: y - 1)].rawValue += 1
            self[Point(x: x + 1, y: y - 1)].rawValue += 1
            self[Point(x: x - 1, y: y)].rawValue += 1
            self[Point(x: x + 1, y: y)].rawValue += 1
            self[Point(x: x - 1, y: y + 1)].rawValue += 1
            self[Point(x: x, y: y + 1)].rawValue += 1
            self[Point(x: x + 1, y: y + 1)].rawValue += 1
        }
        
        private mutating func deleteNeighbour(vicinityAround point: Point) {
            let x = point.x
            let y = point.y
            self[Point(x: x - 1, y: y - 1)].rawValue -= 1
            self[Point(x: x, y: y - 1)].rawValue -= 1
            self[Point(x: x + 1, y: y - 1)].rawValue -= 1
            self[Point(x: x - 1, y: y)].rawValue -= 1
            self[Point(x: x + 1, y: y)].rawValue -= 1
            self[Point(x: x - 1, y: y + 1)].rawValue -= 1
            self[Point(x: x, y: y + 1)].rawValue -= 1
            self[Point(x: x + 1, y: y + 1)].rawValue -= 1
        }
        
        private func switched(_ value: Cell) -> Cell {
            let aliveNeighbours = value.rawValue & 0b00001111
            let cell = value.rawValue >> 4
            if cell == 0 {
                if aliveNeighbours == 3 {
                    return GolCell(0b00010011)
                }
            } else if aliveNeighbours > 3 || aliveNeighbours < 2 {
                return GolCell(value.rawValue & 0b00001111)
            }
            return value
        }
        
        mutating public func refreshVicinity(point: Point, oldValue: BinaryCell) {
            if oldValue.rawValue == 0 { return }
            let newValue = switched(oldValue)
            
            let difference = (oldValue.rawValue & 0b00010000) - (newValue.rawValue & 0b00010000)
            if difference == -0b00010000 {
                addNeighbour(vicinityAround: point)
            } else if difference == 0b00010000 {
                deleteNeighbour(vicinityAround: point)
            }
            
            self[point].rawValue += newValue.rawValue
        }
        
    }
}
