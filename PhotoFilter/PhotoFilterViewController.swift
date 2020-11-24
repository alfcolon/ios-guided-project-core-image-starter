import UIKit
import CoreImage
import Photos

class PhotoFilterViewController: UIViewController {

	@IBOutlet weak var brightnessSlider: UISlider!
	@IBOutlet weak var contrastSlider: UISlider!
	@IBOutlet weak var saturationSlider: UISlider!
	@IBOutlet weak var imageView: UIImageView!
    
    private let context = CIContext(options: nil)
	
    var originalImage: UIImage? {
        didSet {
            //we want to scale down the image to make it easier to filter until the user is ready to save the image
            guard let image = self.originalImage else { return }
            
            //height and width of the image view
            var scaledSize = imageView.bounds.size
            
            //1, 2 or 3
            let scale = UIScreen.main.scale
            scaledSize = CGSize(width: scaledSize.width * scale, height: scaledSize.height * scale)
            
            //'imageByScaling' is coming from the UIImage+Scaling.swift
            let scaledImage = image.imageByScaling(toSize: scaledSize)
            
            self.scaledImage = scaledImage
        }
    }
    var scaledImage: UIImage? {
        didSet {
            guard let image = self.scaledImage else { return }
//            self.imageView.image = scaledImage
        }
    }
    
	override func viewDidLoad() {
		super.viewDidLoad()
        
        self.originalImage = self.imageView.image

	}
	
	// MARK: Actions
	
	@IBAction func choosePhotoButtonPressed(_ sender: Any) {
		// TODO: show the photo picker so we can choose on-device photos
		// UIImagePickerController + Delegate
        self.presentImagePicker()
        
	}
	
	@IBAction func savePhotoButtonPressed(_ sender: UIButton) {
        // TODO: Save to photo library
        guard let originalImage = self.originalImage else { return }
        let filteredImage = image(byFiltering: originalImage)
        //Request permission from the user to access and add photos to their photo library
        PHPhotoLibrary.requestAuthorization { (status) in
            guard status == .authorized else { return NSLog ("The user has not authorized permission for PhotoLibrary usage.")}

            
            PHPhotoLibrary.shared().performChanges ({

                //Make a new photo asset request
                PHAssetCreationRequest.creationRequestForAsset(from: filteredImage)

            }) { (success, error) in
                if let error = error { return NSLog("Error saving photo asset: \(error)") }
            }

            //Present user with
        }
//        UIImageWriteToSavedPhotosAlbum(filteredImage, nil, nil, nil)
	}
	

	// MARK: Slider events
	
	@IBAction func brightnessChanged(_ sender: UISlider) {
        self.updateImage()
	}
	
	@IBAction func contrastChanged(_ sender: Any) {
        self.updateImage()
	}
	
	@IBAction func saturationChanged(_ sender: Any) {
        self.updateImage()
	}
    
    //MARK: - Image Filtering
    
    private func updateImage() {
        self.imageView.image = self.scaledImage == nil ? nil : image(byFiltering: self.scaledImage!)
    }
    
    private func image(byFiltering image: UIImage) -> UIImage {
    
        //UIImage -> CGImage -> CIImage "recipe"
        guard var cgImage = image.cgImage else { return image }
        
        //create the color controls filter both ways and set the appropriate values to the slider values
        
        let colorControlsFilter = CIFilter.init(name: "CIColorControls")
        
        let ciImage = CIImage(cgImage: cgImage)
        let sliderBrightness = self.brightnessSlider.value
        let sliderContrast = self.contrastSlider.value
        let sliderSaturation = self.saturationSlider.value
        
        colorControlsFilter?.setValue(ciImage, forKey: "inputImage")
        colorControlsFilter?.setValue(sliderBrightness / 100, forKey: "inputBrightness")
        colorControlsFilter?.setValue(sliderContrast, forKey: "inputContrast")
        colorControlsFilter?.setValue(sliderSaturation, forKey: "inputSaturation")
        
        guard var outputImage = colorControlsFilter?.outputImage else { return image }
        // This is where the image filtering actually happens (where the graphics processor will perform the fiter)
        guard var outputCGImage = self.context.createCGImage(outputImage, from: outputImage.extent) else { return image }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    //MARK: - Private Functions
    
    func presentImagePicker() {
        //Make sure the photo library is available to use in the first place
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return NSLog("The photo libray is not available") }
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        present(imagePicker, animated: true, completion: nil)
    }
}

extension PhotoFilterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            self.originalImage = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
