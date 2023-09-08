//
//  OneButtonAlert.swift
//  OnTheMap
//
//  Created by Guido Roos on 07/08/2023.
//

import UIKit

//present(alertVC, animated: true)
class OneButtonAlert {
    class func create (
        title: String,
        message: String,
        action: (() -> Void)? = nil
    ) -> UIAlertController {
        let alertVC = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
       
        alertVC.addAction(UIAlertAction(
            title: NSLocalizedString("ok_button_text", comment: ""),
            style: .default,
            handler: { _ in
                if let action = action {
                    action()
                }
                
            }
        ))
        
        return alertVC
        
    }
}
