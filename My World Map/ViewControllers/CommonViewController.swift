//
//  CommonViewController.swift
//  Virtual Tourist
//
//  Created by Norah Al Ibrahim on 1/26/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showInfo(withTitle: String = "Info", withMessage: String, action: (() -> Void)? = nil) {
        performUIUpdatesOnMain {
            let alert = UIAlertController(title: withTitle, message: withMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alertAction) in
                action?()
            }))
            self.present(alert, animated: true)
        }
    }
    
    func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
        DispatchQueue.main.async {
            updates()
        }
    }
}


