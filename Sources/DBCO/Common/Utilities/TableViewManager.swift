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

/// Helper class that proxies UITableViewDataSource and UITableViewDelegate to optional closures, configuring the cells in a typeSafe manner.
/// Requires that cells conform to Reusable and Configurable.
///
/// For example usages see: [TaskOverviewViewModel](x-source-tag://TaskOverviewViewModel) or [SelectContactViewModel](x-source-tag://SelectContactViewModel)
class TableViewManager<Cell: UITableViewCell & Reusable & Configurable>: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    var numberOfSections: (() -> Int)?
    var numberOfRowsInSection: ((_ section: Int) -> Int)?
    var itemForCellAtIndexPath: ((_ indexPath: IndexPath) -> Cell.Item)?
    var didSelectItem: ((_ item: Cell.Item, _ indexPath: IndexPath) -> Void)?
    var titleForHeaderInSection: ((_ section: Int) -> String?)?
    var viewForHeaderInSection: ((_ section: Int) -> UIView?)?
    var viewForFooterInSection: ((_ section: Int) -> UIView?)?

    weak var tableView: UITableView?
    
    /// Start managing a table view. Will register the required cell class and set the delegate and datasource to the supplied table view.
    ///
    /// - parameter tableView: The UITableView to be proxied
    func manage(_ tableView: UITableView) {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseIdentifier)
        self.tableView = tableView
    }
    
    /// Reload the table view, querying the closures for data.
    func reloadData() {
        tableView?.reloadData()
    }
    
    // MARK: - UITableViewDataSource, UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections?() ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsInSection?(section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseIdentifier) as! Cell
        itemForCellAtIndexPath.map { cell.configure($0(indexPath)) }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let inputForCellAtIndexPath = itemForCellAtIndexPath, let didSelectInput = didSelectItem else { return }
        
        didSelectInput(inputForCellAtIndexPath(indexPath), indexPath)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titleForHeaderInSection?(section)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return viewForHeaderInSection?(section)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return viewForFooterInSection?(section)
    }
    
}

extension Reusable where Self: UITableViewCell {
    
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
    
}
