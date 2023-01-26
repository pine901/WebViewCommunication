//
//  SNNavigation.swift
//  SNBeneficiaryDeclarationDemo
//
//  Created by Nimrod Borochov on 10/10/2019.
//  Copyright © 2019 Scanovate. All rights reserved.
//

import UIKit

class SNNavigation: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension SNNavigation {

override open var shouldAutorotate: Bool {
    get {
        return true
    }
}

override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation{
    get {
        return .portrait
    }
}

override open var supportedInterfaceOrientations: UIInterfaceOrientationMask{
    get {
        return .portrait
    }
 }}

//extension UINavigationBar {
//    override open func sizeThatFits(_ size: CGSize) -> CGSize {
//        let screenRect = UIScreen.main.bounds
//        // Change navigation bar height. The height must be even, otherwise there will be a white line above the navigation bar.
//        let newSize = CGSize(width: screenRect.size.width, height: 85)
//        return newSize
//    }
//}
