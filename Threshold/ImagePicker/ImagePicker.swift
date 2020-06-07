

import UIKit

public protocol ImagePickerDelegate: class {
    func didSelect(image: UIImage?)
}

open class ImagePicker: NSObject {

    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?
    var alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
    var viewController: UIViewController?

    public init(presentationController: UIViewController, delegate: ImagePickerDelegate) {
        self.pickerController = UIImagePickerController()

        super.init()

        self.presentationController = presentationController
        self.delegate = delegate
        
        self.pickerController.sourceType = .photoLibrary
        self.pickerController.delegate = self
        self.pickerController.allowsEditing = false
        self.pickerController.mediaTypes = ["public.image"]
        
    }
    
    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }
        
        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.pickerController.sourceType = type
            self.presentationController?.present(self.pickerController, animated: true)
            
        }
    }
    func openGallery(){
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            return
        }
         alert.dismiss(animated: true, completion: nil)
         pickerController.sourceType = .photoLibrary
         self.presentationController?.present(self.pickerController, animated: true)
     }
    
    
    
     public func present(from sourceView: UIView) {

         let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
         alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
         self.presentationController?.present(alertController, animated: true)
     }
     

    
    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        //controller.dismiss(animated: true, completion: nil)
        
        self.delegate?.didSelect(image: image)
    }
}

extension ImagePicker: UIImagePickerControllerDelegate {
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.imageURL] as? UIImage else {
            return self.pickerController(picker, didSelect: nil)
        }
        let getUrl = UIImagePickerController.InfoKey.imageURL
        print(getUrl)
        print(image)
        self.pickerController(picker, didSelect: image)
    }
}

extension ImagePicker: UINavigationControllerDelegate {
    
}
