import UIKit

class MainScreenViewController: UIViewController {
    
    enum SimulationSpeed: CGFloat {
        case slow = 1
        case normal = 0.5
        case fast = 0.2
    }
    
    internal static let themeColor: UIColor = .systemBlue
    
    internal var editingToolBarItems: [UIBarButtonItem] = []
    internal var selectionToolBarItems: [UIBarButtonItem] = []
    internal var insertionToolBarItems: [UIBarButtonItem] = []
    
    let scrollView = UIScrollView()
    
    var simulationSpeed: SimulationSpeed = .normal
    
    let actionView = TiledBackgroundView()
    
    var simulator: CellularAutomataSimulator!
    
    let toolBar = UIToolbar()
    
    var toolBarPlayButton: UIBarButtonItem!
    var toolBarPauseButton: UIBarButtonItem!
    
    var simulationSlowSpeedButton: UIBarButtonItem!
    var simulationNormalSpeedButton: UIBarButtonItem!
    var simulationFastSpeedButton: UIBarButtonItem!
    
    private var gameIsGoing: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.systemBackground
        
        title = "Game of Life"
        
        self.simulator = CellularAutomataSimulator(automataType: .twoDimentionalEffectiveAutomata)
        
        setupToolBar()
        
        setupNavigationBar()
        
        setupActionField()
    }
    
    func setupToolBar() {
        guard let toolBar = navigationController?.toolbar else {
            fatalError("ToolBar not found")
        }
        
        selectionToolBarItems = [
            .flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down.on.square"),
                            primaryAction: UIAction(handler: saveSelectionAction)),
            .flexibleSpace(),
            .flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "square.slash"),
                            primaryAction: UIAction(handler: clearSelectionAction)),
            .flexibleSpace()
        ]

        insertionToolBarItems = [
            .flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "plus.square"),
                            primaryAction: UIAction(handler: insertAddAction)),
            .flexibleSpace()
        ]
        
        toolBarPlayButton = UIBarButtonItem.toolBarButton(self, action: #selector(playPauseGame), imageName: "play")
        toolBarPauseButton = UIBarButtonItem.toolBarButton(self, action: #selector(playPauseGame), imageName: "pause")
        
        let snapshotButton = UIBarButtonItem(
            image: UIImage(systemName: "camera.viewfinder"),
            style: .done,
            target: self,
            action: #selector(makeSnapshot)
            )
        let backwardEndButton = UIBarButtonItem(
            image: UIImage(systemName: "backward.end.alt"),
            style: .done,
            target: self,
            action: #selector(recoverLatestSnapshot)
            )
        let playButton = UIBarButtonItem(
            image: UIImage(systemName: "play"),
            style: .done,
            target: self,
            action: #selector(playPauseGame)
            )
        let forwardEndButton = UIBarButtonItem(
            image: UIImage(systemName: "forward.end"),
            style: .done,
            target: self,
            action: #selector(stepForward)
            )
        let addFigureButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .done,
            target: self,
            action: #selector(openFigureLibrary)
            )
        
        createSimulationSpeedButtons()
        let simulationSpeedButton = simulationNormalSpeedButton!
        
        editingToolBarItems = [
            snapshotButton,
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem.flexibleSpace(),
            backwardEndButton,
            UIBarButtonItem.fixedSpace(10),
            playButton,
            UIBarButtonItem.fixedSpace(10),
            forwardEndButton,
            UIBarButtonItem.flexibleSpace(),
            simulationSpeedButton,
            UIBarButtonItem.flexibleSpace(),
            addFigureButton
        ]
        
        toolBar.barTintColor = UIColor.systemBackground
        toolBar.tintColor = Self.themeColor
        navigationController?.setToolbarHidden(false, animated: true)
        setToolbarItems(editingToolBarItems, animated: true)
    }
    
    func createSimulationSpeedButtons() {
        simulationSlowSpeedButton = UIBarButtonItem.toolBarButton(self, action: #selector(switchSimulationSpeed), imageName: "tortoise")
        simulationNormalSpeedButton = UIBarButtonItem.toolBarButton(self, action: #selector(switchSimulationSpeed), imageName: "figure.walk")
        simulationFastSpeedButton = UIBarButtonItem.toolBarButton(self, action: #selector(switchSimulationSpeed), imageName: "hare")
    }
    
    @objc func switchSimulationSpeed() {
        switch simulationSpeed {
        case .slow:
            simulationSpeed = .normal
            toolbarItems?[9] = simulationNormalSpeedButton
        case .normal:
            simulationSpeed = .fast
            toolbarItems?[9] = simulationFastSpeedButton
        case .fast:
            simulationSpeed = .slow
            toolbarItems?[9] = simulationSlowSpeedButton
        }
    }
    
    func setupNavigationBar() {
        let menuItems = UIMenu(title: "", options: .displayInline, children: [
            UIMenu(title: "Game mode", image: UIImage(systemName: "wand.and.stars"), children: [
                
                UIAction(title: "elementary game", image: UIImage(systemName: "brain"), handler: { (_) in
                    self.changeGameModeAction(automataType: .elementaryCellularAutomatt)
                }),
                UIAction(title: "game of life", image: UIImage(systemName: "tablecells"), handler: { (_) in
                    self.changeGameModeAction(automataType: .twoDimentionalEffectiveAutomata)
                })
            ]),
            UIAction(title: "Field size", image: UIImage(systemName: "tablecells.badge.ellipsis"), handler: { (_) in
                self.changeFieldSizeAction()
            }),
            UIAction(title: "Clear field", image: UIImage(systemName: "trash"), attributes: .destructive, handler: { (_) in
                self.clearingFieldAction()
            }),
            UIMenu(title: "Appearance", image: UIImage(systemName: "paintbrush.pointed"), children: [
                UIAction(title: "Default", handler: changeAppearanceModeAction(to: .unspecified)),
                UIAction(title: "Light", handler: changeAppearanceModeAction(to: .light)),
                UIAction(title: "Dark", handler: changeAppearanceModeAction(to: .dark)),
                UIMenu(title: "Cell shape", image: UIImage(systemName: "rectangle.dashed"), children: [
                    UIAction(title: "rectangle", handler: { (_) in self.changeCellShape(to: .rect) }),
                    UIAction(title: "circle", handler: { (_) in self.changeCellShape(to: .circle) })
                ])
            ])
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .edit)
        let gearButton = navigationItem.rightBarButtonItem
        gearButton?.tintColor = Self.themeColor
        gearButton?.menu = menuItems
    }
    
    func changeAppearanceModeAction(to style: UIUserInterfaceStyle) -> (UIAction) -> Void {
        return { [weak self] (_: UIAction) -> Void in
            guard let self = self else { return }
            let styleAnimation = CATransition()
            styleAnimation.duration = 0.1
            styleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            styleAnimation.type = .fade
            self.view.layer.add(styleAnimation, forKey: "styleAnimation")
            self.view.window?.overrideUserInterfaceStyle = style
        }
    }
    
    func changeCellShape(to shape: TiledBackgroundView.CellShape) {
        actionView.cellShape = shape
    }
    
    func setupActionField() {
        actionView.sideLength = 50
        actionView.setController(self)
        actionView.setSimulator(simulator)
        view.addSubview(scrollView)
        scrollView.addSubview(actionView)
        
        actionView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 5
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        actionView.isUserInteractionEnabled = true
        
        addActionViewRecognizers()
        
        let frameGuide = scrollView.frameLayoutGuide
        let contentGuide = scrollView.contentLayoutGuide
        
        actionView.updateSize()
        NSLayoutConstraint.activate([
            frameGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            frameGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            frameGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            frameGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            actionView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            actionView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            actionView.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            actionView.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),
            actionView.heightAnchorConstraint,
            actionView.widthAnchorConstraint
        ])
    }
    
    func addActionViewRecognizers() {
        let fieldTapGestureRecongnizer = UITapGestureRecognizer(
            target: actionView,
            action: #selector(actionView.handleFieldTap(_:))
        )
        fieldTapGestureRecongnizer.delegate = actionView
        actionView.addGestureRecognizer(fieldTapGestureRecongnizer)
        
        let longPressFiedGestureRecognizer = UILongPressGestureRecognizer(
            target: actionView,
            action: #selector(actionView.handleLongPress(_:))
        )
        longPressFiedGestureRecognizer.delegate = actionView
        longPressFiedGestureRecognizer.minimumPressDuration = 0.35
        actionView.addGestureRecognizer(longPressFiedGestureRecognizer)
    }
    
    func updateToolBar(forMode mode: TiledBackgroundView.ActionMode) {
        switch mode {
        case .selectionMode:
            toolbarItems = selectionToolBarItems
        case .insertionMode:
            toolbarItems = insertionToolBarItems
        case .editingMode:
            toolbarItems = editingToolBarItems
        }
    }
    
    func changeGameModeAction(automataType type: AutomataType) {
        self.simulator.clearField()
        self.actionView.setNeedsDisplay()
        self.simulator = CellularAutomataSimulator(automataType: type)
        actionView.setSimulator(simulator)
        actionView.updateSize()
    }
    
    func clearingFieldAction() {
        let alertController = UIAlertController(
            title: "Clearing field",
            message: "Are you sure you wanna clear field?",
            preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] (_) in
            guard let self = self else { return }
            guard self.simulator != nil else { fatalError("cannot find simulator") }
            self.simulator.clearField()
            self.actionView.setNeedsDisplay()
        })
        present(alertController, animated: true)
    }
    
    func changeFieldSizeAction() {
        let alertController =
        UIAlertController(title: "Resize field",
                          message: "current size: \(simulator.state.viewport.size.width) * " +
                          "\(simulator.state.viewport.size.height)",
                          preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "width"
            textField.keyboardType = .numberPad
        }
        alertController.addTextField { (textField) in
            textField.placeholder = "height"
            textField.keyboardType = .numberPad
        }
        alertController.addAction(UIAlertAction(title: "Resize", style: .destructive) { [weak self] (_) in
            guard let self = self,
                  let width = alertController.textFields?.first?.text,
                  let height = alertController.textFields?[1].text,
                  let newWidth = NumberFormatter().number(from: width),
                  let newHeight = NumberFormatter().number(from: height)
            else { return }
            self.simulator.resizeField(width: UInt(truncating: newWidth), height: UInt(truncating: newHeight))
            self.actionView.updateSize()
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
    
    // откатить поле до последнего сохранённого состояния
    @objc func recoverLatestSnapshot() {
        guard let snapshotState = simulator.getLastSnapshot() else {
            return()
        }
        self.simulator.state = snapshotState
        self.actionView.updateSize()
    }
    
    @objc func openFigureLibrary() {
        navigationController?.pushViewController(FigureLibraryController(popAction: actionView.startInsertion), animated: true)
    }
    
    @objc func makeSnapshot() {
        simulator.makeSnapshot()
    }
    
    func insertAddAction(action: UIAction) {
        guard let rect = actionView.getSelectedRect(),
              let state = actionView.getInsertionState()
        else { return }
        simulator.insertSubState(in: rect, state: state)
        actionView.updateSize()
    }
    
    func saveSelectionAction(action: UIAction) {
        guard let rect = actionView.getSelectedRect()
        else { return }
        let state = simulator.getSubStateInRect(rect)
        
        let alertController =
        UIAlertController(title: "Save selected field", message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "name to save"
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        alertController.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] (_) in
            guard self != nil,
                let name = alertController.textFields?.first?.text
            else { return }
            FigureLibraryController.add(pair: (name: name, state: state))
        })
        present(alertController, animated: true)
    }
    
    func clearSelectionAction(action: UIAction) {
        guard let rect = actionView.getSelectedRect()
        else { return }
        simulator.clearFieldInRect(rect)
        actionView.updateSize()
    }

    @objc func playPauseGame() {
        gameIsGoing = !gameIsGoing
        guard toolbarItems?[5] != nil
        else { fatalError("internal inconsistency") }
        
        if gameIsGoing {
            toolbarItems?[5] = toolBarPauseButton
            RunLoop.current.add(Timer(timeInterval: simulationSpeed.rawValue, repeats: false, block: runGame(_:)), forMode: .common)
        } else {
            toolbarItems?[5] = toolBarPlayButton
        }
    }
    
    @objc func stepForward() {
        actionView.isUserInteractionEnabled = false
        RunLoop.current.add(Timer(timeInterval: simulationSpeed.rawValue, repeats: false, block: runGame(_:)), forMode: .common)
        gameIsGoing = false
        actionView.isUserInteractionEnabled = true
    }
    
    func runGame(_: Timer) {
        simulator.state = simulator.simulate(generations: 1)
        actionView.updateSize()
        actionView.setNeedsDisplay()
        if gameIsGoing {
            RunLoop.current.add(Timer(timeInterval: simulationSpeed.rawValue, repeats: false, block: runGame(_:)), forMode: .common)
        }
    }
}

extension MainScreenViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        actionView
    }
}

extension UIBarButtonItem {

    static func toolBarButton(_ target: Any?, action: Selector, imageName: String) -> UIBarButtonItem {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)

        let menuBarItem = UIBarButtonItem(customView: button)
        menuBarItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        menuBarItem.customView?.heightAnchor.constraint(equalToConstant: 30).isActive = true
        menuBarItem.customView?.widthAnchor.constraint(equalToConstant: 30).isActive = true

        return menuBarItem
    }
}
