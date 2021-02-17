/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol ScrollViewNavivationbarAdjusting {
    var view: UIView! { get }
    var navigationItem: UINavigationItem { get }
    var shortTitle: String { get }
    
    func adjustNavigationBar(for scrollView: UIScrollView)
}

extension ScrollViewNavivationbarAdjusting {
    
    private var navigationBarBackgroundViewTag: Int { 9999991 }
    private var navigationBarSeparatorViewTag: Int { 9999992 }
    
    func adjustNavigationBar(for scrollView: UIScrollView) {
        func setup() -> (backgroundView: UIView, separatorView: UIView) {
            let navigationBackgroundView = UIView()
            navigationBackgroundView.tag = navigationBarBackgroundViewTag
            
            let separatorView = SeparatorView()
            separatorView.tag = navigationBarSeparatorViewTag
            
            navigationBackgroundView.backgroundColor = .white
            navigationBackgroundView.snap(to: .top, of: view)
            
            navigationBackgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            
            separatorView.snap(to: .top, of: view.safeAreaLayoutGuide)
            
            return (navigationBackgroundView, separatorView)
        }
        
        let backgroundView: UIView
        let separatorView: UIView
        
        if let foundBackgroundView = view.viewWithTag(navigationBarBackgroundViewTag), let foundSeparatorView = view.viewWithTag(navigationBarSeparatorViewTag) {
            backgroundView = foundBackgroundView
            separatorView = foundSeparatorView
        } else {
            (backgroundView, separatorView) = setup()
        }
        
        let shouldShow = scrollView.contentOffset.y + scrollView.safeAreaInsets.top > 0
        let isShown = backgroundView.isHidden == false
        
        if shouldShow != isShown {
            UIView.animate(withDuration: 0.2) {
                if shouldShow {
                    separatorView.alpha = 1
                    backgroundView.isHidden = false
                    self.navigationItem.title = shortTitle
                } else {
                    separatorView.alpha = 0
                    backgroundView.isHidden = true
                    self.navigationItem.title = nil
                }
            }
        }
    }
    
}
