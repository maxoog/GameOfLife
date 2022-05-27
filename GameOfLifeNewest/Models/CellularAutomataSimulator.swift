import Foundation

public enum AutomataType {
    case elementaryCellularAutomatt
    case twoDimentionalEffectiveAutomata
}

public class CellularAutomataSimulator {
    public typealias State = AutomataState
    
    public var automata: Automata
    public var state: State
    var snapshots: Stack<State>
    var automataType: AutomataType
    
    public init(automataType type: AutomataType) {
        self.automataType = type
        self.snapshots = Stack()
        switch type {
        case .elementaryCellularAutomatt:
            self.automata = ElementaryCellularAutomata()
            self.state = ElementaryCellularAutomata.State(Rect(origin: Point(x: 0, y: 0), size: Size(width: 20, height: 1)))
        case .twoDimentionalEffectiveAutomata:
            self.automata = TwoDimentionalEffectiveAutomata()
            self.state = TwoDimentionalEffectiveAutomata.State( Rect(origin: Point(x: 0, y: 0), size: Size(width: 15, height: 15)))
        }
    }

    public func clearField() {
        clearFieldInRect(state.viewport)
    }
    
    public func resizeField(width: UInt, height: UInt) {
        state.resize(width: width, height: height)
    }
    
    public func simulate(generations: UInt) -> State {
        self.state = (try? automata.simulate(state, generations: generations)) ?? state
        return state
    }
    
    public func insertSubState(in rect: Rect, state: AutomataState) {
        self.state[rect] = state
    }
    
    public func clearFieldInRect(_ rect: Rect) {
        switch automataType {
        case .elementaryCellularAutomatt:
            state[rect] = ElementaryCellularAutomata.State(rect)
        case .twoDimentionalEffectiveAutomata:
            state[rect] = TwoDimentionalEffectiveAutomata.State(rect)
        }
    }
    
    public func getSubStateInRect(_ rect: Rect) -> AutomataState {
        return state[rect]
    }
    
    public func switchValue(point: Point) {
        state.switchValue(point: point)
    }

    public func makeSnapshot() {
        snapshots.push(state)
    }
    
    public func getLastSnapshot() -> State? {
        guard let lastSnapshot = snapshots.pop() else { return nil }
        state = lastSnapshot
        return state
    }
}

struct Stack<Element> {
    var items: [Element] = []
    
    mutating func push(_ item: Element) {
        items.append(item)
    }
    
    mutating func pop() -> Element? {
        return items.popLast()
    }
}
