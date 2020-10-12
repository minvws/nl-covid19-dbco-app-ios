/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */


import UIKit

class StatusView: UIView {
    enum Status {
        case warning
        case completed
        case progress(CGFloat)
    }
    
    var status: Status {
        didSet {
            applyStatus()
        }
    }

    private let imageView = UIImageView()

    init(status: Status = .warning) {
        self.status = status
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 24, height: 24)))
        setup()
    }
    
    required init?(coder: NSCoder) {
        self.status = .warning
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        imageView.image = UIImage(named: "Status/Warning")
        imageView.highlightedImage = UIImage(named: "Status/Completed")
        imageView.embed(in: self)
    }
    
    private func applyStatus() {
        switch status {
        case .warning:
            imageView.isHighlighted = false
            imageView.isHidden = false
        case .completed:
            imageView.isHighlighted = true
            imageView.isHidden = false
        case .progress:
            imageView.isHidden = true
        }
        
        setNeedsDisplay()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 24, height: 24)
    }
    
    override func draw(_ rect: CGRect) {
        guard case .progress(let progress) = status else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let clampedProgress = min(max(progress, 0), 1)
        
        UIColor.white.setFill()
        context.fill(rect)
    
        context.addEllipse(in: bounds.inset(by: .all(1)))
        context.setLineWidth(2)
        
        Theme.colors.primary.setStroke()
        Theme.colors.primary.setFill()
        context.drawPath(using: .stroke)
        
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let startAngle: CGFloat = -.pi / 2
        let endAngle: CGFloat = (.pi * 2) * clampedProgress + startAngle
        
        context.move(to: center)
        context.addArc(
            center: center,
            radius: bounds.width / 2 - 4,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false)
        
        context.fillPath()
    }
    
}
