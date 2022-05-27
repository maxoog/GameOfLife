//
//  ElementaryCellularAutomata.swift
//
//
//  Created by Максим on 02.10.2021.
//

import Foundation

class ElementaryCellularAutomata: Automata {

    let rule: UInt8

    init(rule: UInt8) {
        self.rule = rule
    }
    
    required init() {
        rule = 90
    }
    
    func simulate(_ state: AutomataState, generations: UInt) throws -> AutomataState {
        var newState = state
        for _ in 0 ..< generations {
            guard let y = newState.viewport.verticalIndices.last, newState.viewport.area != 0 else { return newState }
            
            newState.viewport = newState.viewport
                .resizing(toInclude: newState.viewport.leftBottomCorner)
                .resizing(toInclude: newState.viewport.rightBottomCorner)
            for x in newState.viewport.horizontalIndices {
                let l = newState[Point(x: x - 1, y: y)].rawValue
                let m = newState[Point(x: x, y: y)].rawValue
                let r = newState[Point(x: x + 1, y: y)].rawValue
                let newValue = self.rule >> (l << 2 | m << 1 | r << 0) & 1
                let newCell = BinaryCell(Int8(newValue))
                newState[Point(x: x, y: y + 1)] = newCell
            }
        }
        return newState
    }
}

extension ElementaryCellularAutomata {
    struct State: AutomataState, CustomStringConvertible {
        
        typealias Cell = BinaryCell
        typealias SubState = Self
        
        var cells: [Cell]
        
        private var _viewport: Rect
        var viewport: Rect {
            get {
                self._viewport
            }
            set {
                self.cells = Self.resize(self.cells, from: self.viewport, to: newValue)
                self._viewport = newValue
            }
        }
        
        init() {
            self._viewport = .zero
            self.cells = []
        }
        
        public init(_ rect: Rect) {
            self._viewport = rect
            cells = []
            for _ in 0..<_viewport.area {
                cells.append(.zero())
            }
        }
        
        private init(viewport: Rect, cells: [BinaryCell]) {
            self._viewport = viewport
            guard cells.count == viewport.area else { fatalError("internal inconsistensy") }
            self.cells = cells
        }
        
        public func copy() -> AutomataState {
            Self(viewport: viewport, cells: cells)
        }
        
        public mutating func
        switchValue(point: Point) {
            let cell = self[point]
            self[point].rawValue = cell.isActive() ? 0 : 1
        }
        
        var description: String {
            self.viewport.verticalIndices.map { y in
                self.viewport.horizontalIndices.map { x in
                    self[Point(x: x, y: y)].isActive() ? "_" : "*"
                }.joined()
            }.joined(separator: "\n")
        }
        
        public mutating func resize(width: UInt, height: UInt) {
            let newViewport = Rect(origin: self.viewport.origin, size: Size(width: Int(width), height: Int(height)))
            
            var newCells: [BinaryCell] = []
            for _ in 0..<newViewport.area {
                newCells.append(.zero())
            }
            for x in self.viewport.horizontalIndices {
                for y in self.viewport.verticalIndices {
                    guard let arrayIndex = Self.arrayIndex(at: Point(x: x, y: y), in: newViewport) else { continue }
                    newCells[arrayIndex] = self[Point(x: x, y: y)]
                }
            }
            self.cells = newCells
            self._viewport = newViewport
            
        }
        
        subscript(_ point: Point) -> BinaryCell {
            get {
                guard let index = Self.arrayIndex(at: point, in: self.viewport) else {
                    return .zero()
                }
                return self.cells[index]
            }
            set {
                let newViewport = self.viewport.resizing(toInclude: point)
                self.cells = Self.resize(self.cells, from: self.viewport, to: newViewport)
                self._viewport = newViewport
                  
                guard let index = Self.arrayIndex(at: point, in: self.viewport) else {
                    fatalError("Internal inconsistency")
                }
                self.cells[index] = newValue
            }
        }
        public subscript(rect: Rect) -> AutomataState {
            get {
                let newViewport = rect
                var newCells: [BinaryCell] = []
                for point in rect.indices {
                    newCells.append(self[point])
                }
                return Self(viewport: newViewport, cells: newCells)
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
        
        mutating func refreshVicinity(point: Point, oldValue: BinaryCell) {
            fatalError("method doesn't implemented")
        }
        
        mutating func translate(to newOrigin: Point) {
            self._viewport = Rect(origin: newOrigin, size: self._viewport.size)
        }
        
        private static func arrayIndex(at point: Point, in viewport: Rect) -> Int? {
            guard viewport.contains(point: point) else { return nil }
            let localPoint = point - viewport.origin
            return localPoint.y * viewport.size.width + localPoint.x
        }
        
        private static func resize(_ oldArray: [Cell], from oldViewport: Rect, to newViewport: Rect) -> [Cell] {
            var newArray = [Cell]()
            for _ in 0..<newViewport.area {
                newArray.append(.zero())
            }
            
            for point in oldViewport.indices {
                guard let oldArrayIndex = Self.arrayIndex(at: point, in: oldViewport) else { continue }
                guard let newArrayIndex = Self.arrayIndex(at: point, in: newViewport) else { continue }
                    
                newArray[newArrayIndex] = oldArray[oldArrayIndex]
            }
            return newArray
        }
        
    }
}
