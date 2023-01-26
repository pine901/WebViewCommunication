//
//  IntroVC.swift
//  WebViewDemo
//
//  Created by Nimrod Borochov on 04/03/2021.
//
//let kSafariViewControllerCloseNotification = "kSafariViewControllerCloseNotification"

import Foundation
import UIKit
import SafariServices
import WebKit
import NFCPassportReader

class MainVC: BaseVCWithNavigation {
    
    
    @IBOutlet weak var urlET: UITextField!
    
    var webView:WKWebView?
    private let passportReader = PassportReader()
    private var isInProcess = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        urlET.delegate = self;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        urlET.text = "https://uat-pia-client.scanovate.com?sid=Mdc/vQlXujT1VvqDvqxtht1Ck+ahzcN69X6x7M6bC7KcRg8qkUV9lKF3vI1WYilnZoYrwvC5H4cofE8uDtxYD84XzhVaZRUlE+J8JuusNKzpUh0s88hnwrAUPMVZkrj+gLPOsP5HUtfz8VADBvr/sRyTiMg7K5ZmNPhmvCPs+I4=&process_id=df56d729-5c0c-4992-be15-fd138dd4ab7c"
//        urlET.text = "https://192.168.1.114:3001/" ;
    }
    
    
    @IBAction func btnStartProcessTapped(_ sender: UIButton) {
        
        if Reachability.isConnectedToNetwork() {
            
            let strURL = urlET.text ?? "";

            if let url = URL(string: strURL) {
                
                let webConfiguration = WKWebViewConfiguration()
                
                webConfiguration.allowsInlineMediaPlayback = true
                webConfiguration.userContentController.add(self, name: "startNFCProcess");
                webConfiguration.userContentController.add(self, name: "stopNFCProcess");
                webConfiguration.userContentController.add(self, name: "storeFace");
                webConfiguration.userContentController.add(self, name: "faceRetrieve");
                webConfiguration.userContentController.add(self, name: "processEnded");
                
                webView = WKWebView(frame: view.frame, configuration: webConfiguration)
                webView?.navigationDelegate = self;
                let myRequest = URLRequest(url: url)
                webView!.load(myRequest)
                self.view.addSubview(webView!);
            }
        }
        else{
            showAlert(message: "To continue this process, make sure your device is connected to the Internet")
        }
    }
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    func readPassportNFC(_ passportNumber: String, _ dateOfBirth: String, _ dateOfExpiry: String) {
        let passportUtils = PassportUtils()
        let mrzKey = passportUtils.getMRZKey( passportNumber: passportNumber, dateOfBirth: dateOfBirth, dateOfExpiry: dateOfExpiry)
        
        // Set the masterListURL on the Passport Reader to allow auto passport verification
        let masterListURL = Bundle.main.url(forResource: "masterList", withExtension: ".pem")!
        passportReader.setMasterListURL( masterListURL )
        
        passportReader.passiveAuthenticationUsesOpenSSL = true;
        
        // If we want to read only specific data groups we can using:
        let dataGroups : [DataGroupId] =  [.COM, .SOD, .DG1 , .DG2]
        
        Task {
            let customMessageHandler : (NFCViewDisplayMessage)->String? = { (displayMessage) in
                print("displayMessage: ֿ\(displayMessage)");
                switch displayMessage {
                case .requestPresentPassport:
                    return "הצמידו את הכרטיס לגב הטלפון"
                case .authenticatingWithPassport(_):
                    DispatchQueue.main.async {
                        self.webView?.evaluateJavaScript("window.handleNFCEvent('CHIP_DETECTED')");
                    }
                    return "הצ'יפ נמצא, נא לא לזוז"
                case .error(let tagError): // TODO:: with Adi
                    print("tagError: ", tagError);
                    print("errorDescription: \(String(describing: tagError.errorDescription))");
                    self.isInProcess = false
                    switch tagError {
                    case NFCPassportReaderError.NFCNotSupported, NFCPassportReaderError.NotYetSupported:
                        DispatchQueue.main.async {
                            self.webView?.evaluateJavaScript("window.handleNFCEvent('THERE_IS_NO_NFC_IN_DEVICE')");
                        }
                        return ""
                        
                    case NFCPassportReaderError.ConnectionError:
                        DispatchQueue.main.async {
                            self.webView?.evaluateJavaScript("window.handleNFCEvent('CONNECTION_LOST')");
                        }
                        return "היה קצר בתקשורת, נסו שוב"

                    case NFCPassportReaderError.InvalidMRZKey:
                        DispatchQueue.main.async {
                            self.webView?.evaluateJavaScript("window.handleNFCEvent('INVALID_MRZ_KEY')");
                        }
                        return "מפתח MRZ לא חוקי"
                        
                        
                    default:
                        self.isInProcess = false
                        DispatchQueue.main.async {
                            self.webView?.evaluateJavaScript("window.handleNFCEvent('NATIVE_EXCEPTION')");
                        }
                        return ""
                    }
                    
                    
                case .successfulRead:
                    self.isInProcess = false
                    return "הסריקה הסתיימה בהצלחה"
                default:
                    
                    return "הצ'יפ נמצא, נא לא לזוז"
                }
            }
            
            do {
                
                
                let passport = try await passportReader.readPassport( mrzKey: mrzKey,tags: dataGroups, customDisplayMessage:customMessageHandler)
                

                guard let faceImage = passport.passportImage else {
                    DispatchQueue.main.async {
                        self.webView?.evaluateJavaScript("window.handleNFCEvent('CONNECTION_LOST')");
                    }
                    return;
                }
                
                let base64 = faceImage.toBase64String();
                
                //                print("face image?: ")
                //                print(base64);
                
                let images = NSMutableDictionary();
                images.setValue(base64, forKey: "face_image");
                
                let auth = NSMutableDictionary();
                let chipAuthSucceeded = passport.chipAuthenticationStatus == PassportAuthenticationStatus.success;
                let passiveAuthSuccess = passport.passportCorrectlySigned;
                auth.setValue(chipAuthSucceeded, forKey: "chip");
                auth.setValue(passiveAuthSuccess, forKey: "passive");
                
                
                let fields = NSMutableDictionary();
                
                let passportMRZ = passport.passportMRZ;
                
                print("passportMRZ.count: \(passportMRZ.count)");
                
                if (passportMRZ.count == 88) {
                    print("as Android: ")
                    print("\(passportMRZ.prefix(44))\n\(passportMRZ.suffix(44))\n");
                }
                
                
                fields.setValue(passport.passportMRZ, forKey: ("mrz_lines"));
                //                fields.setValue(passport.documentSubType, forKey: "mrz_type"); // documentSubType?
                //                fields.setValue(passport.documentType, forKey: "document_type");
                fields.setValue(passport.issuingAuthority, forKey: "issuing_country_code"); // issuingAuthority?
                fields.setValue(passport.lastName, forKey: "last_name");
                fields.setValue(passport.firstName, forKey: "first_name");
                fields.setValue(passport.documentNumber, forKey: "passport_number");
                fields.setValue(passport.nationality, forKey: "nationality_code");
                fields.setValue(passport.dateOfBirth, forKey: "date_of_birth");
                fields.setValue(passport.gender, forKey: "gender");
                fields.setValue(passport.documentExpiryDate, forKey: "date_of_expiry");
                fields.setValue(passport.personalNumber, forKey: "personal_number");
                
                let payload = NSMutableDictionary();
                payload.setValue(images, forKey: "images");
                payload.setValue(auth, forKey: "auth");
                payload.setValue(fields, forKey: "fields");
                
                let payloadJSON = try JSONSerialization.data(withJSONObject: payload, options: JSONSerialization.WritingOptions(rawValue: 0))
                
                let allInfoJSONString = NSString(data: payloadJSON, encoding: String.Encoding.utf8.rawValue)!
                
                DispatchQueue.main.async {
                    self.webView?.evaluateJavaScript("window.handleNFCSuccess(JSON.parse('\(allInfoJSONString)'))");
                }
            } catch let e {
                print("catch e: ֿ\(e.localizedDescription)");
                
                if (e.localizedDescription == "UserCanceled" && isInProcess) {
                    DispatchQueue.main.async {
                        self.webView?.evaluateJavaScript("window.handleNFCEvent('USER_CANCELED')");
                    }
                }
                else if (e.localizedDescription == "UnexpectedError" && isInProcess) { // we get here after 1 min (timeout)
                    // we should not get here couse we have a 30 sec timeout from webview that call stopProcess
                    DispatchQueue.main.async {
                        self.webView?.evaluateJavaScript("window.handleNFCEvent('CHIP_NOT_DETECTED')");
                    }
                }
                else if (e.localizedDescription == "Tag connection lost") {
                    //TODO:: Do nothing because we handle it in messages supply
                }
                else {
                    //TODO:: check if we need other senerios
                }
            }
        }
    }
    
    func stopReadPassportNFC() {
        print("stopReadPassportNFC");
        passportReader.readerSession?.invalidate();
    }
}


extension MainVC: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("webView didReceiveServerRedirectForProvisionalNavigation");
        print("webView: \(webView)");
        print("navigation: \(navigation.description)");
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("webView decidePolicyFor");
        print("webView: \(webView)");
        print("webView url: \(String(describing: webView.url))");
        print("webView pathComponents: \(String(describing: webView.url?.pathComponents))");
        print("navigationAction: \(navigationAction)");
        print("navigationAction pathComponents: \(String(describing: navigationAction.request.url?.pathComponents))");
        
        
        if let pathComponentsCount = navigationAction.request.url?.pathComponents.count {
            
            if (pathComponentsCount > 1 && navigationAction.request.url?.pathComponents[1] == "needToRecordVideoState") {
                OperationQueue.main.addOperation {
                    if let token = self.getQueryStringParameter(url: navigationAction.request.url?.absoluteString ?? "" , param: "token") {
                        // do something with token
                        print("Token: \(token)");
                    }
                    
                    if let processId = self.getQueryStringParameter(url: navigationAction.request.url?.absoluteString ?? "" , param: "processId") {
                        // do something with processId
                        print("processId: \(processId)");
                    }
                    
                    decisionHandler(.cancel)
                    
                    self.webView?.removeFromSuperview();
                    self.webView = nil;
                }
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        let exceptions = SecTrustCopyExceptions(serverTrust)
        SecTrustSetExceptions(serverTrust, exceptions)
        completionHandler(.useCredential, URLCredential(trust: serverTrust));
    }
}

extension MainVC: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("message body: \(message.body)")
        
        switch message.name {
        case "startNFCProcess":
            guard let data = message.body as? NSDictionary else {
                return
            }
            
            guard let passportNumber = data["passportNumber"] as? String else {
                return
            }
            
            guard let dateOfBirth = data["dateOfBirth"] as? String else {
                return
            }
            
            guard let dateOfExpiry = data["dateOfExpiry"] as? String else {
                return
            }
            
            isInProcess = true;
            readPassportNFC(passportNumber, dateOfBirth, dateOfExpiry);
            break;
            
        case "stopNFCProcess":
            stopReadPassportNFC();
            isInProcess = false;
            break;
            
        case "storeFace":
            print("storeFace");
            
            guard let data = message.body as? NSDictionary else {
                DispatchQueue.main.async {
                    self.webView?.evaluateJavaScript("window.handleFaceStore('false')");
                }
                return
            }
            
            guard let imgPart2 = data["img_part2"] as? String else {
                DispatchQueue.main.async {
                    self.webView?.evaluateJavaScript("window.handleFaceStore('false')");
                }
                return
            }
            
            guard let kcv = data["kcv"] as? String else {
                DispatchQueue.main.async {
                    self.webView?.evaluateJavaScript("window.handleFaceStore('false')");
                }
                return
            }
            
            guard let uuid = data["uuid"] as? String else {
                DispatchQueue.main.async {
                    self.webView?.evaluateJavaScript("window.handleFaceStore('false')");
                }
                return
            }
            
            let defaults = UserDefaults.standard;
            defaults.set(imgPart2, forKey: "IMG_PART2");
            defaults.set(kcv, forKey: "KCV");
            defaults.set(uuid, forKey: "UUID");
            
            DispatchQueue.main.async {
                self.webView?.evaluateJavaScript("window.handleFaceStore('true')");
            }
            
            break;
          
        case "faceRetrieve":
            print("faceRetrieve");
            let defaults = UserDefaults.standard;
            
            let payload = NSMutableDictionary();
            
            payload.setValue(defaults.string(forKey:"IMG_PART2"), forKey: "img_part2");
            payload.setValue(defaults.string(forKey:"KCV"), forKey: "kcv");
            payload.setValue(defaults.string(forKey:"UUID"), forKey: "uuid");
            
            do {
                let payloadJSON = try JSONSerialization.data(withJSONObject: payload, options: JSONSerialization.WritingOptions(rawValue: 0))
                
                let allInfoJSONString = NSString(data: payloadJSON, encoding: String.Encoding.utf8.rawValue)!
                
                DispatchQueue.main.async {
                    self.webView?.evaluateJavaScript("window.handleFaceRetrieve(JSON.parse('\(allInfoJSONString)'))");
                }
            } catch {
                DispatchQueue.main.async {
                    self.webView?.evaluateJavaScript("window.handleFaceRetrieve(JSON.parse('{}'))"); // can we check it?
                }
            }

            break;
        case "processEnded":
            guard let data = message.body as? NSDictionary else {
                print("processEnded sucess: false")
                self.webView?.removeFromSuperview();
                self.webView = nil;
                return
            }
            
            guard let success = data["success"] as? Bool else {
                print("processEnded sucess: false")
                self.webView?.removeFromSuperview();
                self.webView = nil;
                return
            }
            
            if (success) {
                print("processEnded sucess: true")
            }
            else {
                print("processEnded sucess: false")
            }
            
            
            self.webView?.removeFromSuperview();
            self.webView = nil;
            
            
            break;
        default:
            print("userContentController message: \(message.name)");
            return
        }
    }
}

extension MainVC: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

          return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }

}

extension UIImage {
    func toBase64String() -> String {
        
        guard let imageData = self.jpegData(compressionQuality: 1)
        else {
            return ""
        }
        
        let str64 = imageData.base64EncodedString()
        
        return str64
        //        return "data:image/jpg;base64,\(str64)"
    }
}


//extension Data {
//    var prettyPrintedJSONString: NSString? { /// NSString gives us a nice sanitized debugDescription
//        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
//              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
//              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }
//
//        return prettyPrintedString
//    }
//}
