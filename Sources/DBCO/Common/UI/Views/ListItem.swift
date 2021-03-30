/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

func listItem(_ text: String, imageName: String = "PrivacyItem") -> UIView {
    return HStack(spacing: 16,
                  UIImageView(imageName: imageName).asIcon(),
                  UILabel(body: text, textColor: Theme.colors.captionGray).multiline())
        .alignment(.top)
}

func htmlListItem(_ text: String, imageName: String = "PrivacyItem") -> UIView {
    let attributedString = NSAttributedString.makeFromHtml(text: text,
                                                         font: Theme.fonts.body,
                                                         textColor: Theme.colors.captionGray,
                                                         boldTextColor: .black)
    return HStack(spacing: 16,
                  UIImageView(imageName: imageName).asIcon(),
                  UILabel(attributedString: attributedString, textColor: Theme.colors.captionGray).multiline())
        .alignment(.top)
}
