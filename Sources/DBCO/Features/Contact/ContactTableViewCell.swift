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
        let fullName = item.fullName
        let attributedName = NSMutableAttributedString(string: fullName, attributes: [.font: Theme.fonts.body])
        if let firstName = item.contactFirstName.value {
            let range = (fullName as NSString).range(of: firstName)
            attributedName.addAttribute(.font, value: Theme.fonts.bodyBold, range: range)
        }
        titleLabel.attributedText = attributedName
    }

    private func build() {
        SeparatorView(style: .gray)
            .snap(to: .bottom, of: contentView.readableIdentation)
        
        titleLabel.embed(in: contentView.readableWidth, insets: .topBottom(12))
    }

    // MARK: - Private

    private let titleLabel = Label(body: "")
}
