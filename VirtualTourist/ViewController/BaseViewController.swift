//
//  BaseViewController.swift
//  VirtualTourist
//
//  Created by Marco Guevara on 11/03/23.
//

import UIKit

class BaseViewController: UIViewController {
    
    var myIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myIndicator = UIActivityIndicatorView (style: UIActivityIndicatorView.Style.medium)
        self.view.addSubview(myIndicator)
        myIndicator.bringSubviewToFront(self.view)
        myIndicator.center = self.view.center
    }

    func showActivityIndicator() {
        myIndicator.isHidden = false
        myIndicator.startAnimating()
    }
    
    func hideActivityIndicator() {
        myIndicator.stopAnimating()
        myIndicator.isHidden = true
    }
    
    func showAlert(message: String, title: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertVC, animated: true)
    }

}
