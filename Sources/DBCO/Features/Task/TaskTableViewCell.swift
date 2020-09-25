/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

final class TaskTableViewCell: UITableViewCell, Configurable, Reusable {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(_ item: Task) {
        switch item {
        case let contactDetailsTask as ContactDetailsTask:
            configureForContactDetails(task: contactDetailsTask)
        default:
            break
        }
    }
    
    private func configureForContactDetails(task: ContactDetailsTask) {
        titleLabel.text = task.contact?.fullName ?? task.name
        titleLabel.font = Theme.fonts.bodyBold
        
        subtitleLabel.text = task.completed ? "Gegevens toegevoegd" : "Vul gegevens aan"
        subtitleLabel.font = Theme.fonts.callout
        subtitleLabel.textColor = Theme.colors.captionGray
        
        icon.isHighlighted = task.completed
    }

    private func build() {
        icon.image = UIImage(named: "Warning")
        icon.highlightedImage = UIImage(named: "Checkmark")
        icon.contentMode = .center
        
        let disclosureIndicator = UIImageView(image: UIImage(named: "Chevron"))
        disclosureIndicator.contentMode = .right
        
        let text = UIStackView(vertical: [titleLabel,
                                          UIStackView(horizontal: [icon, subtitleLabel], spacing: 4)],
                               spacing: 4)
        
        UIStackView(horizontal: [text, disclosureIndicator])
            .embed(in: containerView, insets: .all(16))
        
        
        containerView.backgroundColor = Theme.colors.tertiary
        containerView.layer.cornerRadius = 8
        
        
        containerView.embed(in: contentView.readableWidth, insets: .topBottom(4))
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        applyState(selected: selected, animated: true)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        applyState(selected: highlighted, animated: true)
    }
    
    private func applyState(selected: Bool, animated: Bool) {
        func applyState() {
            containerView.transform = selected ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
        }
        
        if animated {
            UIButton.animate(withDuration: 0.2) {
                applyState()
            }
        } else {
            applyState()
        }
    }

    // MARK: - Private

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let containerView = UIView()
    private let icon = UIImageView()
}
