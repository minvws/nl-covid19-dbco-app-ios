/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

func listItem(_ text: String, imageName: String = "PrivacyItem") -> UIView {
    return HStack(spacing: 16,
                  ImageView(imageName: imageName).asIcon(),
                  Label(body: text, textColor: Theme.colors.captionGray).multiline())
        .alignment(.top)
}

func htmlListItem(_ text: String, imageName: String = "PrivacyItem") -> UIView {
    let attributedString: NSAttributedString = .makeFromHtml(text: text,
                                                             font: Theme.fonts.body,
                                                             textColor: Theme.colors.captionGray,
                                                             boldTextColor: .black)
    let label = Label("")
    label.attributedText = attributedString
    
    return HStack(spacing: 16,
                  ImageView(imageName: imageName).asIcon(),
                  label.multiline())
        .alignment(.top)
}
