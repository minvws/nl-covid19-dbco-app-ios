/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class Fonts {
    // Using default textStyles from Apple typography guidelines:
    // https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/typography/
    // Table with point in sizes can be found on the link.

    var largeTitle: UIFont {
        font(textStyle: .largeTitle, isBold: true) // Size 34 points
    }

    var title1: UIFont {
        font(textStyle: .title1, isBold: true) // Size 28 points
    }

    var title2: UIFont {
        font(textStyle: .title2, isBold: true) // Size 22 points
    }

    var title3: UIFont {
        font(textStyle: .title3, isBold: true) // Size 20 points
    }

    var headline: UIFont {
        font(textStyle: .headline) // Size 17 points
    }

    var body: UIFont {
        font(textStyle: .body) // Size 17 points
    }

    var bodyBold: UIFont {
        font(textStyle: .body, isBold: true) // Size 17 points
    }

    var callout: UIFont {
        font(textStyle: .callout) // Size 16 points
    }

    var subhead: UIFont {
        font(textStyle: .subheadline) // Size 15 points
    }

    var subheadBold: UIFont {
        font(textStyle: .subheadline, isBold: true) // Size 15 points
    }

    var footnote: UIFont {
        font(textStyle: .footnote) // Size 13 points
    }

    var caption1: UIFont {
        font(textStyle: .caption1, isBold: true) // size 12 points
    }

    // MARK: - Private

    private func font(textStyle: UIFont.TextStyle, isBold: Bool = false) -> UIFont {
        var fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)

        if isBold, let boldFontDescriptor = fontDescriptor.withSymbolicTraits(.traitBold) {
            fontDescriptor = boldFontDescriptor
        }

        return UIFont(descriptor: fontDescriptor, size: fontDescriptor.pointSize)
    }
}

final class Colors {
    var primary: UIColor {
        return color(for: "PrimaryColor")
    }

    var tertiary: UIColor {
        return color(for: "TertiaryColor")
    }

    var warning: UIColor {
        return color(for: "WarningColor")
    }

    var gray: UIColor {
        return color(for: "GrayColor")
    }

    var ok: UIColor {
        return color(for: "OkGreen")
    }

    var notified: UIColor {
        return color(for: "NotifiedRed")
    }

    var statusGradientActive: UIColor {
        return color(for: "StatusGradientBlue")
    }

    var statusGradientNotified: UIColor {
        return color(for: "StatusGradientRed")
    }

    var navigationControllerBackground: UIColor {
        return color(for: "NavigationControllerBackgroundColor")
    }

    var viewControllerBackground: UIColor {
        return color(for: "ViewControllerBackgroundColor")
    }

    var headerBackgroundBlue: UIColor {
        return color(for: "HeaderBackgroundBlue")
    }

    var headerBackgroundRed: UIColor {
        return color(for: "HeaderBackgroundRed")
    }

    var orange: UIColor {
        return color(for: "Orange")
    }

    var captionGray: UIColor {
        return color(for: "CaptionGray")
    }
    
    var separator: UIColor {
        return color(for: "Separator")
    }
    
    var graySeparator: UIColor {
        return color(for: "GraySeparator")
    }
    
    var disabledBorder: UIColor {
        return color(for: "DisabledBorder")
    }
    
    var disabledIcon: UIColor {
        return color(for: "DisabledIcon")
    }
    
    var tipBackgroundPrimary: UIColor {
        return color(for: "Tip/BackgroundPrimary")
    }
    
    var tipBackgroundSecondary: UIColor {
        return color(for: "Tip/BackgroundSecondary")
    }
    
    var tipHeaderBackground: UIColor {
        return color(for: "Tip/HeaderBackground")
    }
    
    var tipItemColor: UIColor {
        return color(for: "Tip/ItemColor")
    }

    // MARK: - Private

    private func color(for name: String) -> UIColor {
        let bundle = Bundle(for: Colors.self)
        if let color = UIColor(named: name, in: bundle, compatibleWith: nil) {
            return color
        }
        return .clear
    }
}

/// - Tag: Theme
struct Theme {
    static let fonts = Fonts()
    static let colors = Colors()
}
