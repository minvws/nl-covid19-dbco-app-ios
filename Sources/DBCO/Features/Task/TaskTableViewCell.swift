/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

final class TaskTableViewCell: UITableViewCell, CellManagable {
    
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
        switch (task.contactName, task.taskContext) {
        case (.some(let name), .some(let context)):
            titleLabel.text = name + " (\(context))"
        case (.some(let name), .none):
            titleLabel.text = name
        case (.none, .some(let context)):
            titleLabel.text = context
        case (.none, .none):
            titleLabel.text = .taskContactUnknownName
        }
        
        titleLabel.font = Theme.fonts.bodyBold
        
        subtitleLabel.font = Theme.fonts.callout
        subtitleLabel.textColor = Theme.colors.captionGray
        
        statusView.status = task.status
        
        if let result = task.questionnaireResult, result.hasAllEssentialAnswers {
            switch task.contact.communication {
            case .staff:
                subtitleLabel.text = .contactTaskStatusStaffWillInform
            case .index where task.contact.informedByIndexAt != nil,
                 .unknown where task.contact.informedByIndexAt != nil:
                subtitleLabel.text = .contactTaskStatusIndexDidInform
            case .index, .unknown:
                subtitleLabel.text = .contactTaskStatusIndexWillInform
                subtitleLabel.textColor = Theme.colors.orange
            }
        } else {
            subtitleLabel.text = .contactTaskStatusMissingDetails
        }
    }

    private func build() {
        statusView.setContentHuggingPriority(.required, for: .horizontal)
        
        HStack(spacing: 16,
               statusView,
               VStack(spacing: 4, titleLabel, subtitleLabel),
               UIImageView(imageName: "Chevron").asIcon())
            .alignment(.center)
            .embed(in: containerView)
        
        containerView
            .embed(in: contentView.readableWidth, insets: .topBottom(16))
        
        SeparatorView(style: .gray)
            .snap(to: .bottom, of: contentView.readableIdentation, insets: .left(40))
        
        accessibilityTraits = .button
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
