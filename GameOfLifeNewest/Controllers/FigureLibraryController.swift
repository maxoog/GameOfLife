import UIKit

class FigureLibraryController: UIViewController {
    
    let table = UITableView()
    var popAction: ((AutomataState) -> Void)?
    static var storage: [(name: String, state: AutomataState)] = []
    
    static func add(pair: (name: String, state: AutomataState)) {
        storage.append((name: pair.name, state: pair.state.copy()))
    }
    
    init(popAction: @escaping (AutomataState) -> Void) {
        super.init(nibName: nil, bundle: nil)
        self.popAction = popAction
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .blue
        
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(FigurePreviewCell.self, forCellReuseIdentifier: "cell")
        table.dataSource = self
        table.rowHeight = 100
        table.delegate = self
        view.addSubview(table)
        
        NSLayoutConstraint.activate([
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.topAnchor.constraint(equalTo: view.topAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

class FigurePreviewCell: UITableViewCell {
    
    var figureName: UILabel!
    var image: UIImageView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        figureName = UILabel()
        image = UIImageView()
        
        figureName.translatesAutoresizingMaskIntoConstraints = false
        image.translatesAutoresizingMaskIntoConstraints = false
        figureName.contentMode = .center
        figureName.numberOfLines = 3
        image.contentMode = .scaleAspectFit
        
        contentView.addSubview(image)
        contentView.addSubview(figureName)
        contentView.layer.cornerRadius = 30
        
        NSLayoutConstraint.activate([
            image.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            image.trailingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -20),
            image.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            image.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            
            figureName.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 20),
            figureName.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            figureName.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            figureName.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FigureLibraryController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Self.storage.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FigurePreviewCell
        let index = indexPath.row
        cell.figureName.text = Self.storage[index].name
        cell.image.image = UIImage(systemName: "wand.and.stars")
        return cell
    }
    
}

extension FigureLibraryController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.popAction?(FigureLibraryController.storage[indexPath.row].state)
        navigationController?.popViewController(animated: true)
    }
}
