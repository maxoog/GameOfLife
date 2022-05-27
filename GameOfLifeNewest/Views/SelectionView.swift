import UIKit

class SelectionView: UIView {
    
    enum Style {
        case insertion
        case selection
    }
    
    private var style: Style = .selection
    
    var fieldWidth: CGFloat = 0
    var fieldHeight: CGFloat = 0
    
    var insertionView: TiledBackgroundView!
    var insertionState: AutomataState?
    
    var sideLength: CGFloat = 0
    
    var startPoint: CGPoint = .zero
    var movingPoint: CGPoint?
    
    private var _isMoving: Bool = false
    private var _isResizing: Bool = false

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: .zero)
        layer.borderWidth = 2.8
        layer.cornerRadius = 10
        isHidden = true
        isUserInteractionEnabled = false
    }
    
    func show(at point: CGPoint, style: Style, fieldWidth: CGFloat, fieldHeight: CGFloat) {
        self.fieldWidth = fieldWidth
        self.fieldHeight = fieldHeight
        
        var size = CGSize(width: sideLength, height: sideLength)
        
        if let state = insertionState {
            size = CGSize(width: CGFloat(state.viewport.width) * sideLength,
                          height: CGFloat(state.viewport.height) * sideLength)
        }
        
        setFrame(at: point, size: size)
        
        setStyle(style)
        isUserInteractionEnabled = true
        isHidden = false
        
        alpha = 1
    }
    
    private func setStyle(_ style: Style) {
        self.style = style
        switch style {
        case .selection:
            backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
            layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.6).cgColor
        case .insertion:
            backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
            layer.borderColor = UIColor.systemRed.withAlphaComponent(0.6).cgColor
            addTiledView()
        }
    }
    
    private func setFrame(at point: CGPoint, size: CGSize) {
        let point = roundedPoint(point)
        self.startPoint = point
        frame = CGRect(origin: point, size: size)
    }
    
    func isMoving() -> Bool {
        return _isMoving
    }
    
    func isResizing() -> Bool {
        return _isResizing
    }
    
    func addTiledView() {
        guard let insertionState = insertionState
        else {
            return
        }
        
        insertionView = TiledBackgroundView(state: insertionState)
        insertionView.sideLength = sideLength
        addSubview(insertionView)
        insertionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            insertionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            insertionView.topAnchor.constraint(equalTo: topAnchor),
            insertionView.heightAnchorConstraint,
            insertionView.widthAnchorConstraint
        ])
        insertionView.updateSize()
    }
    
    func getSelectedRect() -> CGRect {
        return frame
    }
    
    func getInsertionViewState() -> AutomataState? {
        insertionView?.state
    }

    func hide() {
        frame = .zero
        startPoint = .zero
        isUserInteractionEnabled = false
        UIView.animate(withDuration: 3, delay: 0.2) {
            self.alpha = 0
        }
        isHidden = true
    }
    
    func startMovement(at point: CGPoint) {
        movingPoint = point
        _isMoving = true
    }
    
    func moveToPoint(_ point: CGPoint) {
        guard let lastPoint = movingPoint else { return }
        let newPoint = self.frame.origin + (point - lastPoint)
        let xPos = min(max(newPoint.x, 0), fieldWidth - frame.size.width)
        let yPos = min(max(newPoint.y, 0), fieldHeight - frame.size.height)
        startPoint = CGPoint(x: xPos, y: yPos)
        UIView.animate(withDuration: 0.1, delay: 0) {
            self.frame = CGRect(origin: self.startPoint, size: self.frame.size)
        }
        movingPoint = point
    }
    
    func endMovement() {
        _isMoving = false
        movingPoint = nil
        let resultPoint = roundedPoint(CGPoint(x: (frame.origin.x + sideLength / 2),
                                               y: (frame.origin.y + sideLength / 2)))
        startPoint = resultPoint
        UIView.animate(withDuration: 0.1, delay: 0) {
            self.frame = CGRect(origin: resultPoint, size: self.frame.size)
        }
    }
    
    func roundedPoint(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: Int(point.x - point.x.truncatingRemainder(dividingBy: sideLength)),
                       y: Int(point.y - point.y.truncatingRemainder(dividingBy: sideLength)))
    }
    
    func contains(_ point: CGPoint) -> Bool {
        return frame.contains(point)
    }
    
    func startResizing() {
        _isResizing = true
    }
    
    func resize(toInclude point: CGPoint) {
        let point = roundedPoint(CGPoint(x: min(max(point.x, 0), fieldWidth - 1),
                                         y: min(max(point.y, 0), fieldHeight - 1)))
        let minX = min(point.x, startPoint.x)
        let minY = min(point.y, startPoint.y)
        let maxX = max(point.x, startPoint.x)
        let maxY = max(point.y, startPoint.y)
        let width = maxX - minX + sideLength
        let height = maxY - minY + sideLength
        UIView.animate(withDuration: 0.1, delay: 0) {
            self.frame = CGRect(origin: CGPoint(x: minX, y: minY), size: CGSize(width: width, height: height))
        }
    }
    
    func endResizing() {
        _isResizing = false
        startPoint = frame.origin
    }
    
    func endInsertion() {
        insertionView.removeFromSuperview()
        insertionState = nil
        hide()
    }
}

extension CGPoint {
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}
