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
        switch item.taskType {
        case .contact:
            configureForContactDetails(task: item)
        }
    }
    
    private func configureForContactDetails(task: Task) {
        titleLabel.text = task.label
        titleLabel.font = Theme.fonts.bodyBold
        
        subtitleLabel.text = task.taskContext
        
        subtitleLabel.font = Theme.fonts.callout
        subtitleLabel.textColor = Theme.colors.captionGray
        
        statusView.status = task.status
    }

    private func build() {
        statusView.setContentHuggingPriority(.required, for: .horizontal)
        
        let disclosureIndicator = UIImageView(image: UIImage(named: "Chevron"))
        disclosureIndicator.contentMode = .right
        disclosureIndicator.setContentHuggingPriority(.required, for: .horizontal)
        
        HStack(spacing: 16,
               statusView,
               VStack(spacing: 4, titleLabel, subtitleLabel),
               disclosureIndicator)
            .alignment(.center)
            .embed(in: containerView)
        
        containerView
            .embed(in: contentView.readableWidth, insets: .topBottom(16))
        
        SeparatorView()
            .snap(to: .bottom, of: contentView.readableIdentation)
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
    private let statusView = StatusView()
}
