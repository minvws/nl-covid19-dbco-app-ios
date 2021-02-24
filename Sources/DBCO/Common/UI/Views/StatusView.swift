/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// Represents the status of a task.
/// For tasks that have not yet started it will show a warning icon.
/// For in progress tasks a progress indicator.
/// For completed tasks a checkmark.
class StatusView: UIView {
    
    var status: Task.Status {
        didSet {
            applyStatus()
        }
    }

    private let imageView = UIImageView()

    init(status: Task.Status = .missingEssentialInput) {
        self.status = status
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 24, height: 24)))
        setup()
    }
    
    required init?(coder: NSCoder) {
        self.status = .missingEssentialInput
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        isOpaque = false
        imageView.image = UIImage(named: "Status/Warning")
        imageView.tintColor = Theme.colors.ok
        imageView.embed(in: self)
    }
    
    private func applyStatus() {
        switch status {
        case .missingEssentialInput:
            imageView.image = UIImage(named: "Status/Warning")
            imageView.isHidden = false
        case .indexShouldInform:
            imageView.image = UIImage(named: "Status/WarningFilled")
            imageView.isHidden = false
        case .completed:
            imageView.image = UIImage(named: "Status/Completed")
            imageView.isHidden = false
        case .inProgress:
            imageView.image = UIImage(named: "Status/Completed")
            imageView.isHidden = false
        }
        
        setNeedsDisplay()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 24, height: 24)
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.clear(rect)
        
        let progress: Double
        switch status {
        case .inProgress(let value):
            progress = value
        case .completed:
            progress = 1
        case .missingEssentialInput, .indexShouldInform:
            return
        }
        
        let clampedProgress = min(max(CGFloat(progress), 0), 1)
    
        context.addEllipse(in: bounds.inset(by: .all(1)))
        context.setLineWidth(2)
        
        Theme.colors.disabledBorder.setStroke()
        Theme.colors.ok.setFill()
        context.drawPath(using: .stroke)
        
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let startAngle: CGFloat = -.pi / 2
        let endAngle: CGFloat = (.pi * 2) * clampedProgress + startAngle
        
        context.move(to: center)
        context.addArc(
            center: center,
            radius: bounds.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false)
        
        context.fillPath()
    
        context.addEllipse(in: bounds.inset(by: .all(2)))
        UIColor.clear.setFill()
        context.setBlendMode(.clear)
        context.fillPath()
    }
    
}
