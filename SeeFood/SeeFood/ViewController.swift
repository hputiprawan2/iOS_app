//
//  ViewController.swift
//  SeeFood
//
//  Created by Hanna Putiprawan on 2/25/21.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false // allow to edit image
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil) // present a user to choose image from lib or taking new picture
    }
    
}

extension ViewController: UIImagePickerControllerDelegate {
    // Tells the delegate that the user picked an image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Make sure the picked image wasn't nil, make sure the user pick an image
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // Convert UI image to CI image (Core Image)
            guard let ciImage = CIImage(image: userPickedImage) else {
                // If unable to convert UI image to CI image
                fatalError("Unable to convert image to CIImage.")
            }
            detect(image: ciImage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    private func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: MLModel(contentsOf: Inceptionv3.urlOfModelInThisBundle)) else {
            fatalError("Loading CoreML model failed.")
        }
        
        // Make a request ask model to classify data we passed in
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let result = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image.")
            }
            if let firstResult = result.first {
                if firstResult.identifier.contains("hotdog") {
                    self.navigationItem.title = "Hotdog"
                } else {
                    self.navigationItem.title = "Not Hotdog!"
                }
            }
        }
        
        // Perform classify image
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
}



extension ViewController: UINavigationControllerDelegate {
    
}
