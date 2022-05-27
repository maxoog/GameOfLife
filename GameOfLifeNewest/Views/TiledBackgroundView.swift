import UIKit

class TiledBackgroundView: UIView {
    
    enum ActionMode {
        case editingMode
        case selectionMode
        case insertionMode
    }
    
    enum CellShape {
        case rect
        case circle
    }

    var sideLength: CGFloat = 0 {
        didSet {
            self.selectionView.sideLength = sideLength
            tiledLayer.tileSize = CGSize(width: sideLength * contentScaleFactor, height: sideLength * contentScaleFactor)
        }
    }
    
    private var controller: MainScreenViewController?
    
    var widthAnchorConstraint: NSLayoutConstraint!
    var heightAnchorConstraint: NSLayoutConstraint!
    
    var mode: ActionMode = .editingMode
    
    var cellShape: CellShape = .rect {
        didSet {
            layer.setNeedsDisplay()
        }
    }
    
    var selectionView: SelectionView!
    
    private var simulator: CellularAutomataSimulator?
    public var state: AutomataState?
    
    private let activeColor: UIColor = MainScreenViewController.themeColor
    private let inactiveColor: UIColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.3)
    
    override class var layerClass: AnyClass {
        return CATiledLayer.self
    }
    
    var tiledLayer: CATiledLayer {
        return layer as! CATiledLayer
    }
    
    init() {
        super.init(frame: .zero)
        widthAnchorConstraint = widthAnchor.constraint(equalToConstant: 0)
        heightAnchorConstraint = heightAnchor.constraint(equalToConstant: 0)
        backgroundColor = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0)
        self.selectionView = SelectionView()
        addSubview(selectionView)
    }
    
    convenience init(state: AutomataState) {
        self.init()
        self.state = state
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSimulator(_ simulator: CellularAutomataSimulator) {
        self.simulator = simulator
    }
    
    func setController(_ controller: MainScreenViewController) {
        self.controller = controller
    }
    
    @objc func handleFieldTap(_ sender: UIGestureRecognizer) {
        let point = sender.location(in: self)
        
        if mode == .editingMode {
            redrawRectInPoint(point)
        } else if !selectionView.contains(point) {
            if mode == .insertionMode {
                endInsertion()
            } else if mode == .selectionMode {
                endSelection()
            }
        }
    }
    
    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: self)
        switch mode {
        case .editingMode:
            handleInitialLongPress(sender)
        case .selectionMode, .insertionMode:
            if selectionView.isResizing() {
                handleInitialLongPress(sender)
                return
            }
            if selectionView.isMoving() || selectionView.contains(point) {
                handleMovingLongPress(sender)
            } else {
                handleInitialLongPress(sender)
            }
        }
    }
   
    func handleInitialLongPress(_ sender: UIGestureRecognizer) {
        let point = sender.location(in: self)
        switch sender.state {
        case .began:
            if mode == .insertionMode {
                endInsertion()
            }
            startSelection(at: point)
        case .changed:
            selectionView.resize(toInclude: point)
        default:
            endResizing()
        }
    }
    
    func handleMovingLongPress(_ sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: self)
        switch sender.state {
        case .began:
            startMovement(at: point)
        case .changed:
            selectionView.moveToPoint(point)
        default:
            endMovement()
        }
    }
    
    func switchMode(to mode: ActionMode) {
        self.mode = mode
        controller?.updateToolBar(forMode: mode)
        switch mode {
        case .selectionMode:
            setScroll(false)
        case .editingMode:
            selectionView.hide()
            setScroll(true)
        default:
            ()
        }
    }
    
    func setScroll(_ value: Bool) {
        (self.superview as? UIScrollView)?.isScrollEnabled = value
    }
    
    func startSelection(at point: CGPoint) {
        switchMode(to: .selectionMode)
        selectionView.startResizing()
        selectionView.show(at: point,
                           style: .selection,
                           fieldWidth: widthAnchorConstraint.constant,
                           fieldHeight: heightAnchorConstraint.constant)
    }
    
    func endResizing() {
        selectionView.endResizing()
    }
    
    func endSelection() {
        switchMode(to: .editingMode)
    }
    
    func startMovement(at point: CGPoint) {
        setScroll(false)
        selectionView.startMovement(at: point)
    }
    
    func endMovement() {
        setScroll(true)
        selectionView.endMovement()
    }
    
    func startInsertion(state: AutomataState) {
        switchMode(to: .insertionMode)
        selectionView.insertionState = state
        selectionView.show(at: .zero, style: .insertion, fieldWidth: frame.width, fieldHeight: frame.height)
    }
    
    func endInsertion() {
        switchMode(to: .editingMode)
        selectionView.endInsertion()
    }
    
    func clearSelectedSubState() {
        guard let rect = getSelectedRect() else { return }
        simulator?.clearFieldInRect(rect)
    }
    
    func getSelectedRect() -> Rect? {
        guard mode != .editingMode else { return nil }
        
        let selectedRect = selectionView.getSelectedRect()
        return Rect(origin: Point(x: Int(selectedRect.origin.x / sideLength),
                                      y: Int(selectedRect.origin.y / sideLength)),
                        size: Size(width: Int(selectedRect.width / sideLength),
                                   height: Int(selectedRect.height / sideLength)))
    }
    
    func getInsertionState() -> AutomataState? {
        return selectionView.getInsertionViewState()
    }
    
    func updateSize() {
        var viewport: Rect = .zero
        if self.state == nil {
            viewport = self.simulator!.state.viewport
        } else {
            viewport = state!.viewport
        }
        widthAnchorConstraint.constant = CGFloat(viewport.width) * sideLength
        heightAnchorConstraint.constant = CGFloat(viewport.height) * sideLength
        tiledLayer.setNeedsDisplay()
    }
    
    func redrawRectInPoint(_ point: CGPoint) {
        guard let simulator = simulator else { return }
        let localPoint = Point(x: Int(point.x / tiledLayer.tileSize.width * contentScaleFactor),
                               y: Int(point.y / tiledLayer.tileSize.height * contentScaleFactor))
        simulator.switchValue(point: localPoint)
        self.setNeedsDisplay(CGRect(
            x: CGFloat(localPoint.x) * sideLength,
            y: CGFloat(localPoint.y) * sideLength,
            width: sideLength,
            height: sideLength))
    }
    
    override func draw(_ rect: CGRect) {
        guard let state = simulator?.state ?? state else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let statePoint = Point(
            x: Int(rect.origin.x / tiledLayer.tileSize.width * contentScaleFactor),
            y: Int(rect.origin.y / tiledLayer.tileSize.height * contentScaleFactor))
        let correctPoint = self.state == nil ? Point.zero : self.state!.viewport.origin
        let color = state[statePoint + correctPoint].isActive() ? activeColor : inactiveColor
        context.setFillColor(color.cgColor)
        
        switch cellShape {
        case .rect:
            context.fill(CGRect(x: rect.origin.x + rect.width * 0.05,
                                y: rect.origin.y + rect.height * 0.05,
                                width: rect.width * 0.90,
                                height: rect.height * 0.90))
        case .circle:
            context.fillEllipse(in: CGRect(x: rect.origin.x + rect.width * 0.025, y: rect.origin.y + rect.height * 0.025,
                                           width: rect.width * 0.95, height: rect.height * 0.95))
        }
    }
}

extension TiledBackgroundView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer &&
            otherGestureRecognizer is UILongPressGestureRecognizer {
                    return true
        }
        return false
    }
}
