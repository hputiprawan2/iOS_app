//
//  ViewController.swift
//  WhatFlower
//
//  Created by Hanna Putiprawan on 2/25/21.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    private let imagePicker = UIImagePickerController()
    private var pickedImage: UIImage?
    private let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false // true; allow user to crop a photo
        imagePicker.sourceType = .camera
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func detect(flowerImage: CIImage) {
        guard let model = try? VNCoreMLModel(for: MLModel(contentsOf: FlowerClassifier.urlOfModelInThisBundle)) else {
            fatalError("Load CoreML Model failed!")
        }
        
        // Make a request ask model to classify data
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let result = request.results?.first as? VNClassificationObservation else {
                fatalError("Model failed to process image")
            }
            self.navigationItem.title = result.identifier.capitalized
            self.requestInfo(flowerName: result.identifier)
        }
        
        // Perform classify image
        let handler = VNImageRequestHandler(ciImage: flowerImage)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    private func requestInfo(flowerName: String) {
        let parameters: [String: String] = [
            "format"    : "json",
            "action"    : "query",
            "prop"      : "extracts|pageimages",
            "exintro"   : "",
            "explaintext": "",
            "titles"    : flowerName,
            "indexpageids": "",
            "redirects" : "1",
            "pithumbsize": "500"
        ]
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print("Successfully retrieved wikipedia info.")
                print(response)
                
                // SwiftyJSON
                let flowerJSON: JSON = JSON(response.result.value!) // safe to unwrap cuz inside isSuccess
                let pageId = flowerJSON["query"]["pageids"][0].stringValue // get the first value of pageId
                let flowerDescription = flowerJSON["query"]["pages"][pageId]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                self.label.text = flowerDescription
                
            }
        }
        
        
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        let userPickedImage = info[UIImagePickerController.InfoKey.editedImage]
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // Convert image to CIImage
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert image to CIImage")
            }
            pickedImage = userPickedImage
            detect(flowerImage: ciImage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
}
