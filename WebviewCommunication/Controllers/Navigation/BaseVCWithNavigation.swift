//
//  BaseVCWithNavigation.swift
//  SNBeneficiaryDeclarationDemo
//
//  Created by Nimrod Borochov on 10/10/2019.
//  Copyright © 2019 Scanovate. All rights reserved.
//

import UIKit

class BaseVCWithNavigation: UIViewController {

//    var appData = AppData.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        addBackButton()
        
//        navigationController?.setToolbarHidden(false, animated: false)
        // Do any additional setup after loading the view.
    }
    
    func addBackButton() {
        navigationItem.leftBarButtonItem = nil

        let backBtn = UIButton(type: .custom)
        let backBtnImage = UIImage(named: "BackBtnB.png")
        backBtn.setBackgroundImage(backBtnImage, for: .normal)
        backBtn.addTarget(self, action: #selector(btnBackTapped(_:)), for: .touchUpInside)
        backBtn.frame = CGRect(x: 0, y: 0, width: 16, height: 14)
        let backButton = UIBarButtonItem(customView: backBtn)
        navigationItem.leftBarButtonItem = backButton
    }

    @objc func btnBackTapped(_ sender: UIBarButtonItem?) {
        navigationController?.popViewController(animated: true)
       }
    
    func setNaveigationTitleImage(_ image: UIImage?) {
        let myImageView = UIImageView(frame: CGRect(x: 0, y: 44, width: 176, height: 16))

        myImageView.image = image

        myImageView.contentMode = .scaleAspectFit

        navigationItem.titleView = myImageView

    }

    func showAlert(message: String?) {
        showAlert(withTitle: nil, andMessage: message, image: nil)
    }

    func showAlert(message: String? , image: UIImage) {
        showAlert(withTitle: nil, andMessage: message, image: image)
    }
    
    func showAlert(withTitle title: String?, andMessage message: String? , image: UIImage?) {
        showAlert(withTitle: title, andMessage: message, buttonText: "OK",image: image)
    }

    func showAlert(withTitle title: String?, andMessage message: String?, buttonText btnText: String?, image: UIImage?) {
        OperationQueue.main.addOperation({

            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            if image != nil {
                           alert.addImage(image: image!)
                       }
            
            let okButton = UIAlertAction(title: btnText, style: .default, handler: { action in

                })

           
            
            alert.addAction(okButton)
            
            
            
            self.present(alert, animated: true)
        })
    }

    static var deviceNamesByCode: [AnyHashable : Any]? = nil

    var deviceName: String? {
        return UIDevice.modelName
    }
    
    func decodeBase64(toImage strEncodeData: String?) -> UIImage? {
        var strEncodeData = strEncodeData
        strEncodeData = strEncodeData?.replacingOccurrences(of: "data:image/jpg;base64,", with: "")
        let data = Data(base64Encoded: strEncodeData ?? "", options: .ignoreUnknownCharacters)
        if let data = data {
            return UIImage(data: data)
        }
        return nil
    }
    
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
     }
}

extension UIImage {
    func imageWithSize(_ size:CGSize) -> UIImage {
        var scaledImageRect = CGRect.zero
        
        let aspectWidth:CGFloat = size.width / self.size.width
        let aspectHeight:CGFloat = size.height / self.size.height
        let aspectRatio:CGFloat = min(aspectWidth, aspectHeight)
        
        scaledImageRect.size.width = self.size.width * aspectRatio
        scaledImageRect.size.height = self.size.height * aspectRatio
        scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        self.draw(in: scaledImageRect)
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
}

extension UIAlertController {
    
    func addImage(image: UIImage) {
        
        let maxSize = CGSize(width: 245, height: 300)
        let imgsize = image.size
        
        var ratio: CGFloat!
        if imgsize.width > imgsize.height {
            ratio = maxSize.width / imgsize.width
        } else {
            ratio = maxSize.height / imgsize.height
        }
        
        let scaledSize = CGSize(width: imgsize.width * ratio, height: imgsize.height * ratio)
        
        var resizedImage = image.imageWithSize(scaledSize)
        
        if imgsize.height > imgsize.width {
            let left = (maxSize.width - resizedImage.size.width) / 2
            resizedImage = resizedImage.withAlignmentRectInsets(UIEdgeInsets(top: 0,left: -left,bottom: 0,right: 0))
        }
        
        
        let imgAction = UIAlertAction(title: "", style: .default, handler: nil)
        imgAction.isEnabled = false
        imgAction.setValue(resizedImage.withRenderingMode(.alwaysOriginal), forKey: "image")
        self.addAction(imgAction)
    }
}

public extension UIDevice {

    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "iPod_touch_(5th_generation)"
            case "iPod7,1":                                 return "iPod_touch_(6th_generation)"
            case "iPod9,1":                                 return "iPod_touch_(7th_generation)"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone_4"
            case "iPhone4,1":                               return "iPhone_4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone_5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone_5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone_5s"
            case "iPhone7,2":                               return "iPhone_6"
            case "iPhone7,1":                               return "iPhone_6_Plus"
            case "iPhone8,1":                               return "iPhone_6s"
            case "iPhone8,2":                               return "iPhone_6s_Plus"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone_7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone_7_Plus"
            case "iPhone8,4":                               return "iPhone_SE"
            case "iPhone10,1", "iPhone10,4":                return "iPhone_8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone_8_Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone_X"
            case "iPhone11,2":                              return "iPhone_XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone_XS_Max"
            case "iPhone11,8":                              return "iPhone_XR"
            case "iPhone12,1":                              return "iPhone_11"
            case "iPhone12,3":                              return "iPhone_11_Pro"
            case "iPhone12,5":                              return "iPhone_11_Pro_Max"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad_2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad_3"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad_4"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad_Air"
            case "iPad5,3", "iPad5,4":                      return "iPad_Air_2"
            case "iPad6,11", "iPad6,12":                    return "iPad_5"
            case "iPad7,5", "iPad7,6":                      return "iPad_6"
            case "iPad7,11", "iPad7,12":                    return "iPad_7"
            case "iPad11,4", "iPad11,5":                    return "iPad_Air_(3rd_generation)"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad_Mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad_Mini_2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad_Mini_3"
            case "iPad5,1", "iPad5,2":                      return "iPad_Mini_4"
            case "iPad11,1", "iPad11,2":                    return "iPad_Mini_5"
            case "iPad6,3", "iPad6,4":                      return "iPad_Pro_(9.7-inch)"
            case "iPad6,7", "iPad6,8":                      return "iPad_Pro_(12.9-inch)"
            case "iPad7,1", "iPad7,2":                      return "iPad_Pro_(12.9-inch)_(2nd_generation)"
            case "iPad7,3", "iPad7,4":                      return "iPad_Pro_(10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad_Pro_(11-inch)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad_Pro_(12.9-inch)_(3rd_generation)"
            case "AppleTV5,3":                              return "Apple_TV"
            case "AppleTV6,2":                              return "Apple_TV_4K"
            case "AudioAccessory1,1":                       return "HomePod"
            case "i386", "x86_64":                          return "Simulator_\(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple_TV_4"
            case "AppleTV6,2": return "Apple_TV_4K"
            case "i386", "x86_64": return "Simulator_\(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }

        return mapToDevice(identifier: identifier)
    }()

}
