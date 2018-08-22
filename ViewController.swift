//
//  ViewController.swift
//  Services

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK:- Instance Variables
    @IBOutlet weak var imagePicked: UIImageView!
    @IBOutlet weak var guidTextField: UITextField!
    @IBOutlet weak var jsonTextView: UITextView!
    
    let hostedServicesUrl = "https://azure.leadtools.com/api/"
    var firstPage = 1
    var lastPage = -1
    let fileUrl = "https://www.leadtools.com/support/publicforumimages/barcode1.png"
    var symbologies = "popular"
    
    // Users AppID and AppPassword
    let appId = "APP ID"
    let appPassword = "APP PASSWORD"
    
    let hostedServiceQuery = "https://azure.leadtools.com/api/Query?id="
    var responseString: String?
    
    //MARK:- Send Request Button
    @IBAction func sendReqButton(_ sender: UIButton) {
        let recognitionUrl = "Recognition/ExtractAllBarcodes?firstPage=\(firstPage)&lastPage=\(lastPage)&fileurl=\(fileUrl)&symbologies=\(symbologies)"
        let base64LoginString = initClientLogin()
        setupInitReq(with: recognitionUrl, login: base64LoginString)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let resonseString = self.responseString {
                self.setupInitReq(with: resonseString, login: base64LoginString)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Encode Authentication Info
    func initClientLogin() -> String {
        let loginString = String(format: "%@:%@", appId, appPassword)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        return loginData.base64EncodedString()
    }
    
    // Create URL Request with Authentication
    func setupInitReq(with url: String, login data: String) {
        
        if responseString != nil {
            if let url = URL(string: self.hostedServiceQuery + (responseString!)) {
                let request = setupRequest(with: url, login: data)
                sendUIDRequest(request)
            }
        } else {
            
            if let url = URL(string:hostedServicesUrl + url) {
                let request = setupRequest(with: url, login: data)
                sendInitRequest(request)
            }
        }
    }
    
    func setupRequest(with url: URL, login data: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(data)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    //MARK:-
    func sendInitRequest(_ request: URLRequest) {
        let task = URLSession.shared.dataTask(with: request, completionHandler: {
            (data, response, error) in
            
            guard let data = data, error == nil else {
                print("error=\(String(describing: error))")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
            self.responseString = String(data: data, encoding: .utf8)!
            print("responseString = \(String(describing: self.responseString))")
            //self.guidTextField.text = self.responseString
            //setupInitReq(with: request, login: base64LoginString)
            //setupInitReq(with: <#T##String#>, login: <#T##String#>)
            //self.done()
            
        })
        task.resume()
    }
    
    //MARk:- Init UID Request
    func done() {
        if responseString != nil {
            
            
            if let url = URL(string: self.hostedServiceQuery + (responseString!)) {
                var request = URLRequest(url: url)
                
                request.httpMethod = "POST"
                
                let loginString = String(format: "%@:%@", appId, appPassword)
                let loginData = loginString.data(using: String.Encoding.utf8)!
                let base64LoginString = loginData.base64EncodedString()
                
                request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
                
                sendUIDRequest(request)
            }
        }
    }
    
    //MARK:- Send UID Request
    func sendUIDRequest(_ request: URLRequest) {
        let task2 = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            //                    guard let data = data, error == nil else {
            //                        print("error=\(String(describing: error))")
            //                        return
            //                    }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {     
                print("statusCode is \(httpStatus.statusCode)")
                //print("response = \(String(describing: response))")
            }
            
            //MARK: trying
            if data != nil {
                do {
                    let resultObject = try JSONSerialization.jsonObject(with: data!, options: [])
                    DispatchQueue.main.async(execute: {
                        let status = self.parseJSON(data!)
                        if status == false {
                            self.sendUIDRequest(request)
                        }
                    })
                    return
                    
                } catch {
                    DispatchQueue.main.async(execute: {
                        print("Unable to parse JSON response")
                    })
                }
            } else {
                DispatchQueue.main.async(execute: {
                    print("Received empty response.")
                })
            }
        })
        task2.resume()
    }
    
    //MARK:- Parse JSON
    func parseJSON(_ data: Data) -> Bool {
        var decodedJSON = false
        
        guard let BarcodeModel = try? JSONDecoder().decode(BarcodeModel.self, from: data) else {
            return decodedJSON
        }
        
        if BarcodeModel.FileStatus == 200 {
            decodedJSON = true		
        }
        var finalString = ""
        print("File Status: \(BarcodeModel.FileStatus)")
        finalString.append("File Status: " + String(BarcodeModel.FileStatus) + "\n")
        
        for requestData in BarcodeModel.RequestData {
            print("Recognition Type: \(requestData.RecognitionType) \n")
            finalString.append("\nRecognition Type: " + String(requestData.RecognitionType) + "\n")
            
            for BarcodeData in requestData.data {
                print("Symbology: \(BarcodeData.Symbology)")
                finalString.append("\nSymbology: " + String(BarcodeData.Symbology) + "\n")
                
                print("Value: \(BarcodeData.Value)")
                finalString.append("Value: " + String(BarcodeData.Value) + "\n")
                
                print("Bounds: \(BarcodeData.Bounds)")
                finalString.append("Bounds: " + String(BarcodeData.Bounds) + "\n")
                
                print("Rotation Angle: \(BarcodeData.RotationAngle) \n")
                finalString.append("Rotation Angle: \(BarcodeData.RotationAngle) \n")
            }
            print("\nService Type: \(requestData.ServiceType)")
            finalString.append("\nService Type: \(requestData.ServiceType)")
            printToJsonTextView(finalString)
        }
        
        return decodedJSON
    }
    
    func printToJsonTextView(_ string: String) {
        jsonTextView.text = string
    }
    
    //FIXME:- Open Camera
    @IBAction func openCameraButton(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    //FIXME:- Photo Library
    @IBAction func openPhotoLibrary(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            var imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imagePicked.image = image
        dismiss(animated:true, completion: nil)
    }
}

