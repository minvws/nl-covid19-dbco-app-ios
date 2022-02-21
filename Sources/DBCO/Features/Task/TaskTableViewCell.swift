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
        
        subtitleLabel.text = .contactTaskStatusMissingDetails
        
        statusView.status = task.status
        
        if let result = task.questionnaireResult, result.hasAllEssentialAnswers {
            let informedByIndexAt = task.contact.informedByIndexAt
            let hasInformedByIndexValue = task.contact.informedByIndexAt != nil
            
            switch task.contact.communication {
            case .staff:
                subtitleLabel.text = .contactTaskStatusStaffWillInform
            case .index where hasInformedByIndexValue, .unknown where hasInformedByIndexValue:
                if informedByIndexAt == Task.Contact.indexWontInformIndicator {
                    subtitleLabel.text = .contactTaskStatusIndexWontInform
                } else {
                    subtitleLabel.text = .contactTaskStatusIndexDidInform
                }
            case .index, .unknown:
                subtitleLabel.text = .contactTaskStatusIndexWillInform
                subtitleLabel.textColor = Theme.colors.orange
            }
        }
        
        guard let title = titleLabel.text, let subtitle = subtitleLabel.text else { return }
        if let status = statusView.accessibilityLabel {
            accessibilityLabel = String(format: "%@: %@, %@", title, subtitle, status)
        } else {
            accessibilityLabel = String(format: "%@: %@", title, subtitle)
        }
    }

    private func build() {
        statusView.setContentHuggingPriority(.required, for: .horizontal)
        statusView.setContentCompressionResistancePriority(.required, for: .horizontal)
        
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
        
        isAccessibilityElement = true
        shouldGroupAccessibilityChildren = true
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

    private let titleLabel = UILabel(bodyBold: nil)
    private let subtitleLabel = UILabel(callout: nil, textColor: Theme.colors.captionGray)
    private let containerView = UIView()
    private let statusView = StatusView()
}
