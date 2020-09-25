/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol Reusable {
    static var reuseIdentifier: String { get }
}

protocol Configurable {
    associatedtype Item
    
    func configure(_ input: Item)
}

class TableViewManager<Cell: UITableViewCell & Reusable & Configurable>: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    var numberOfSections: (() -> Int)?
    var numberOfRowsInSection: ((_ section: Int) -> Int)?
    var itemForCellAtIndexPath: ((_ indexPath: IndexPath) -> Cell.Item)?
    var didSelectItem: ((Cell.Item) -> Void)?
    var titleForHeaderInSection: ((_ section: Int) -> String?)?
    
    weak var tableView: UITableView?
    
    func manage(_ tableView: UITableView) {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseIdentifier)
        self.tableView = tableView
    }
    
    func reloadData() {
        tableView?.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections?() ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsInSection?(section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseIdentifier) as! Cell
        itemForCellAtIndexPath.map { cell.configure($0(indexPath)) }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let inputForCellAtIndexPath = itemForCellAtIndexPath, let didSelectInput = didSelectItem else { return }
        
        didSelectInput(inputForCellAtIndexPath(indexPath))
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titleForHeaderInSection?(section)
    }
    
}

extension Reusable where Self: UITableViewCell {
    
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
    
}
