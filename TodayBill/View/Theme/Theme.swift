//
//  Theme.swift
//  TodayBill
//
//  Created by 김건호 on 2/22/25.
//

import Foundation
import UIKit

struct Theme {

    static let backgroundColor = UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.07, blue: 0.09, alpha: 1)
            : UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1)
    })

    static let cellBackgroundColor = UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.12, blue: 0.15, alpha: 1)
            : UIColor.white
    })

    /// Surface for translucent-white dashboard cards; brighter than cellBackgroundColor so cards read as "elevated" in dark mode.
    static let surfaceElevated = UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.16, blue: 0.20, alpha: 1)
            : UIColor.white
    })

    static let separator = UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.1)
            : UIColor.black.withAlphaComponent(0.06)
    })

    static let textColor = UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1)
            : UIColor(red: 0.07, green: 0.09, blue: 0.13, alpha: 1)
    })

    static let emptyLabelTextColor = UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.62, green: 0.66, blue: 0.73, alpha: 1)
            : UIColor(red: 0.49, green: 0.54, blue: 0.62, alpha: 1)
    })

    /// Named font roles standing in for the ad hoc ofSize literals that used to be scattered across the views.
    /// Sizes/weights match prior call sites exactly - this is a naming pass, not a visual redesign.
    struct Font {
        static let heroTitle = UIFont.systemFont(ofSize: 28, weight: .bold)
        static let statNumber = UIFont.systemFont(ofSize: 26, weight: .bold)
        static let pageTitle = UIFont.systemFont(ofSize: 23, weight: .bold)
        static let screenTitle = UIFont.systemFont(ofSize: 20, weight: .bold)
        static let sectionTitle = UIFont.systemFont(ofSize: 18, weight: .bold)
        static let cardTitle = UIFont.systemFont(ofSize: 16, weight: .bold)
        static let navTitle = UIFont.systemFont(ofSize: 16, weight: .semibold)
        static let statusMessage = UIFont.systemFont(ofSize: 16, weight: .medium)
        static let bodyText = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let rowTitle = UIFont.systemFont(ofSize: 15, weight: .semibold)
        static let rowValue = UIFont.systemFont(ofSize: 15, weight: .medium)
        static let linkAction = UIFont.systemFont(ofSize: 15, weight: .regular)
        static let buttonLabel = UIFont.systemFont(ofSize: 14, weight: .regular)
        static let emptyMessage = UIFont.systemFont(ofSize: 14, weight: .medium)
        static let metaTextStrong = UIFont.systemFont(ofSize: 13, weight: .semibold)
        static let metaText = UIFont.systemFont(ofSize: 13, weight: .medium)
        static let smallStrong = UIFont.systemFont(ofSize: 12, weight: .semibold)
        static let smallStrongBold = UIFont.systemFont(ofSize: 12, weight: .bold)
        static let captionText = UIFont.systemFont(ofSize: 12, weight: .medium)
        static let tinyBadge = UIFont.systemFont(ofSize: 10, weight: .semibold)
    }

    /// Corner radius scale for cards/badges. True circles and exact-half pill shapes are computed
    /// at their call site instead (e.g. height / 2) - those aren't inconsistencies, just a different shape.
    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
    }
}
