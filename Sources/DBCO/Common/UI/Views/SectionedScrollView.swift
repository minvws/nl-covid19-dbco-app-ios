/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// A UIScrollView subclass for SectionViews that automatically calls [updateHeaderForOffset](x-source-tag://SectionView.updateHeaderForOffset) for its [SectionView](x-source-tag://SectionView)s
///
/// - Tag: SectionedScrollView
class SectionedScrollView: UIScrollView {
    private let stackView = VStack()
    private var sectionViews = [SectionView]()
    private var offsetObserver: Any?
    
    init(_ sectionViews: SectionView ...) {
        super.init(frame: .zero)
        self.sectionViews = sectionViews
        setup()
    }
    
    init(_ sectionViews: [SectionView]) {
        super.init(frame: .zero)
        self.sectionViews = sectionViews
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        stackView.embed(in: self)
        
        sectionViews.forEach(stackView.addArrangedSubview)
        
        self.offsetObserver = observe(\.contentOffset, options: .new) { [weak self] _, change in
            guard let value = change.newValue?.y else { return }
            guard let self = self else { return }
            
            self.sectionViews.forEach { $0.offset = value + self.safeAreaInsets.top - $0.frame.minY }
        }
    }
    
}
