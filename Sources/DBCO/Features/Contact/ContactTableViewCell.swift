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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(_ item: CNContact) {
        titleLabel.text = item.fullName
    }

    private func build() {
        SeparatorView()
            .snap(to: .bottom, of: contentView, height: 1, insets: .left(14))
        
        titleLabel.embed(in: contentView, insets: .leftRight(16) + .topBottom(12))
    }

    // MARK: - Private

    private let titleLabel = UILabel()
}
