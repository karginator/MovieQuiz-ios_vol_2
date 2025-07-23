import UIKit

final class AlertPresenter {
    
    // MARK: - Public Properties
    weak var viewController: UIViewController?
    
    // MARK: - Public Methods
    func showAlert(alertModel: AlertModel) {
        let alert = UIAlertController(
            title: alertModel.title,
            message: alertModel.message,
            preferredStyle: .alert)
        
        let action = UIAlertAction(
            title: alertModel.buttonText,
            style: .default) { _ in
                alertModel.compilition()
            }
        
        alert.addAction(action)
        
        guard let viewController else { return }
        viewController.present(alert, animated: true, completion: nil)
    }
}
