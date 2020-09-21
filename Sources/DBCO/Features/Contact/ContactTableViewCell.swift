/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

final class ContactTableViewCell: UITableViewCell, Configurable, Reusable {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        build()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(_ item: CNContact) {
        titleLabel.text = item.fullName
    }

    private func build() {
        separatorView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        addSubview(separatorView)
        
        titleLabel.embed(in: contentView, with: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
    }

    private func setupConstraints() {
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }

    // MARK: - Private

    private let separatorView = UIView()
    private let titleLabel = UILabel()
}
