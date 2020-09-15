/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class HelpQuestionViewModel {
    private let question: HelpQuestion

    init(question: HelpQuestion) {
        self.question = question
    }
    
    var title: String {
        return question.question
    }
    
    var body: String {
        return question.answer
    }
    
    var showLinkedItems: Bool {
        return !question.linkedItems.isEmpty
    }
    
    var linkedItemRowCount: Int {
        return question.linkedItems.count
    }
    
    func linkedItem(at index: Int) -> HelpOverviewItem {
        return question.linkedItems[index]
    }
}

protocol HelpQuestionViewControllerDelegate: class {
    
    func helpQuestionViewController(_ controller: HelpQuestionViewController, didSelect item: HelpOverviewItem)
    
}

final class HelpQuestionViewController: UIViewController {
    private let viewModel: HelpQuestionViewModel
    private let tableView: UITableView = createLinkedItemsTableView()
    
    weak var delegate: HelpQuestionViewControllerDelegate?
    
    required init(viewModel: HelpQuestionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        title = .helpTitle
        
        setupContentView()
    }
    
    private func setupContentView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(HelpItemTableViewCell.self, forCellReuseIdentifier: HelpItemTableViewCell.reuseIdentifier)
        
        let scrollView = UIScrollView(frame: .zero)
        scrollView.delaysContentTouches = false
        
        scrollView.embed(in: view)
        
        let titleLabel = UILabel(frame: .zero)
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        titleLabel.numberOfLines = 0
        titleLabel.text = viewModel.title
        
        let bodyLabel = UILabel(frame: .zero)
        bodyLabel.numberOfLines = 0
        bodyLabel.attributedText = NSAttributedString.makeFromHtml(text: viewModel.body,
                                                                   font: UIFont.preferredFont(forTextStyle: .body),
                                                                   textColor: .black)

        let textSection = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        textSection.axis = .vertical
        textSection.spacing = 20
        
        let linkedItemsLabel = UILabel(frame: .zero)
        linkedItemsLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        linkedItemsLabel.text = .helpAlsoRead
        linkedItemsLabel.textColor = .systemBlue
        
        let tableSection = UIStackView(arrangedSubviews: [
            linkedItemsLabel.withInsets(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)),
            tableView
        ])
        tableSection.axis = .vertical
    
        let stackView = UIStackView(arrangedSubviews: [
            textSection.withInsets(UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16)),
            tableSection
        ])
            
        stackView.axis = .vertical
        stackView.spacing = 40
        stackView.distribution = .equalSpacing
        
        scrollView.addSubview(stackView)
        
        stackView.embed(in: scrollView)
        
        // Ensure the stackview extends to the edges and at least fills the scrollview
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        stackView.heightAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.heightAnchor).isActive = true
        
    }
    
    private static func createLinkedItemsTableView() -> UITableView {
        let tableView = FlexibleTableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.isScrollEnabled = false

        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension

        tableView.estimatedSectionHeaderHeight = 50
        tableView.sectionHeaderHeight = UITableView.automaticDimension

        tableView.allowsMultipleSelection = false
        tableView.tableFooterView = UIView()
        return tableView
    }

}

// MARK: - UITableViewDataSource
extension HelpQuestionViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.linkedItemRowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HelpItemTableViewCell.reuseIdentifier, for: indexPath) as! HelpItemTableViewCell
        cell.configure(for: viewModel.linkedItem(at: indexPath.row))
        return cell
    }
    
}

// MARK: - UITableViewDelegate
extension HelpQuestionViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        delegate?.helpQuestionViewController(self, didSelect: viewModel.linkedItem(at: indexPath.row))
    }
    
}

class FlexibleTableView: UITableView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
    }
    
    override var intrinsicContentSize: CGSize {
        return contentSize
    }
    
}


