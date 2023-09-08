//
//  TwoButtonAlert.swift
//  OnTheMap
//
//  Created by Guido Roos on 07/08/2023.
//

import Foundation
import UIKit

//present(alertVC, animated: true)
class TwoButtonAlert {
    class func create (
        title: String,
        message: String,
        actionLabel: String,
         action: @escaping () -> Void
    ) -> UIAlertController {
        let alertVC = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
       
        alertVC.addAction(UIAlertAction(
            title: NSLocalizedString(actionLabel, comment: ""),
            style: .default,
            handler: { _ in action()}
        ))
        alertVC.addAction(UIAlertAction(
            title: NSLocalizedString("cancel_button_text", comment: ""),
            style: .default,
            handler: nil
        ))
        
        return alertVC
        
    }
}
