//
//  ViewController.swift
//  ImageRecognition
//
//  Created by Terry Jason on 2023/8/30.
//

import UIKit
import PhotosUI
import CoreML
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpAll()
    }
    
}


// MARK: Setting

extension ViewController {
    
    private func setUpAll() {
        navbarSet()
        toolbarSet()
        setTitleText()
    }
    
}


// MARK: LayOut

extension ViewController {
    
    private func navbarSet() {
        navigationController?.toolbar.tintColor = .label
    }
    
    private func toolbarSet() {
        let changeImageButton = UIBarButtonItem(title: "Change", style: .done, target: self, action: #selector(changeImageButtonClicked))
        let space = UIBarButtonItem(systemItem: .flexibleSpace)
        
        toolbarItems = [space, changeImageButton]
    }
    
    private func setTitleText() {
        self.title = "What ?"
    }
    
}


// MARK: @Objc Func

extension ViewController {
    
    @objc func changeImageButtonClicked() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        
        present(picker, animated: true)
    }
    
}


// MARK: PHPicker

extension ViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        let itemProviders = results.map(\.itemProvider)
        checkItemProviders(itemProviders: itemProviders)
    }
    
    private func checkItemProviders(itemProviders: [NSItemProvider]) {
        if let itemProvider = itemProviders.first, itemProvider.canLoadObject(ofClass: UIImage.self) {
            processItemProvider(itemProvider: itemProvider)
        }
    }
    
    private func processItemProvider(itemProvider: NSItemProvider) {
        let previousImage = self.imageView.image
        
        itemProvider.loadObject(ofClass: UIImage.self) {[weak self] (image, error) in
            DispatchQueue.main.async {
                guard let self = self, let image = image as? UIImage, self.imageView.image == previousImage else { return }
                self.imageView.image = image
                
                self.createCIImage(chosenImage: image)
            }
        }
    }
    
}


// MARK: Recogbize Image

extension ViewController {
    
    private func createCIImage(chosenImage: UIImage) {
        if let ciImage = CIImage(image: chosenImage) {
            recognizeImage(image: ciImage)
        }
    }
    
    private func recognizeImage(image: CIImage) {
        self.title = "Finding..."
        
        if let model = try? VNCoreMLModel(for: MobileNetV2(configuration: .init()).model) {
            makeRequest(model: model, image: image)
        }
    }
    
    private func makeRequest(model: VNCoreMLModel, image: CIImage) {
        let request = VNCoreMLRequest(model: model) { vnrequest, error in
            self.getResults(vnRequest: vnrequest)
        }
        
        makeHandler(image: image, request: request)
    }
    
    private func getResults(vnRequest: VNRequest) {
        if let results = vnRequest.results as? [VNClassificationObservation] {
            processResults(results: results)
        }
    }
    
    private func processResults(results: [VNClassificationObservation]) {
        if results.count > 0 {
            updateUI(result: results.first!)
        }
    }
    
    private func updateUI(result: VNClassificationObservation) {
        DispatchQueue.main.async {
            let confidenceLevel = result.confidence * 100
            let rounded = Int(confidenceLevel * 100) / 100
            
            self.title = "\(rounded)% it's \(result.identifier)"
        }
    }
    
    private func makeHandler(image: CIImage, request: VNCoreMLRequest) {
        let handler = VNImageRequestHandler(ciImage: image)
        
        DispatchQueue.global(qos: .userInteractive).async {
            try? handler.perform([request])
        }
    }
    
}






































