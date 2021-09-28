/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

func listItem(_ text: String, imageName: String = "PrivacyItem") -> UIView {
    let attributedString = NSAttributedString.makeFromHtml(text: text, style: .bodyCaptionGray)
    let label = UILabel(attributedString: attributedString, textColor: Theme.colors.captionGray)
    label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    
    return HStack(spacing: 16,
                  UIImageView(imageName: imageName).asIcon(),
                  label)
        .alignment(.top)
}
