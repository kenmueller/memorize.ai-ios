import UIKit
import Firebase

class SignUpViewController: UIViewController, UITextFieldDelegate {
	@IBOutlet weak var nameTextField: UITextField!
	@IBOutlet weak var nameBarView: UIView!
	@IBOutlet weak var emailTextField: UITextField!
	@IBOutlet weak var emailBarView: UIView!
	@IBOutlet weak var invalidEmailLabel: UILabel!
	@IBOutlet weak var passwordTextField: UITextField!
	@IBOutlet weak var passwordBarView: UIView!
	@IBOutlet weak var passwordTooShortLabel: UILabel!
	@IBOutlet weak var signUpButton: UIButton!
	@IBOutlet weak var signUpButtonBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var signUpActivityIndicator: UIActivityIndicatorView!
	
	deinit {
		KeyboardHandler.removeListener(self)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		disable()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		KeyboardHandler.addListener(self) { direction in
			switch direction {
			case .up:
				self.keyboardWillShow()
			case .down:
				self.keyboardWillHide()
			}
		}
		updateCurrentViewController()
	}
	
	@IBAction
	func back() {
		navigationController?.popViewController(animated: true)
	}
	
	func keyboardWillShow() {
		signUpButtonBottomConstraint.constant = keyboardOffset - view.safeAreaInsets.bottom
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: view.layoutIfNeeded, completion: nil)
	}
	
	func keyboardWillHide() {
		signUpButtonBottomConstraint.constant = 145
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveLinear, animations: view.layoutIfNeeded, completion: nil)
	}
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		switch textField {
		case nameTextField: enable(barView: nameBarView)
		case emailTextField: enable(barView: emailBarView)
		case passwordTextField: enable(barView: passwordBarView)
		default: return
		}
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		switch textField {
		case nameTextField: disable(barView: nameBarView)
		case emailTextField: disable(barView: emailBarView)
		case passwordTextField: disable(barView: passwordBarView)
		default: return
		}
	}
	
	@IBAction
	func nameTextFieldChanged() {
		updateSignUpButton()
	}
	
	@IBAction
	func emailTextFieldChanged() {
		guard let emailText = emailTextField.text?.trim() else { return }
		invalidEmailLabel.isHidden = emailText.checkEmail() || emailText.isEmpty
		updateSignUpButton()
	}
	
	@IBAction
	func passwordTextFieldChanged() {
		guard let passwordText = passwordTextField.text?.trim() else { return }
		passwordTooShortLabel.isHidden = passwordText.count >= 6 || passwordText.isEmpty
		updateSignUpButton()
	}
	
	@IBAction
	func signUp() {
		guard let nameText = nameTextField.text?.trim(), let emailText = emailTextField.text?.trim(), let passwordText = passwordTextField.text?.trim() else { return }
		showActivityIndicator()
		dismissKeyboard()
		auth.createUser(withEmail: emailText, password: passwordText) { authResult, error in
			if error == nil, let user = authResult?.user {
				id = user.uid
				guard let id = id else { return }
				User.pushToken()
				user.createProfileChangeRequest().displayName = nameText
				firestore.document("users/\(id)").setData(["name": nameText, "email": emailText]) { error in
					self.hideActivityIndicator()
					if let error = error {
						self.showError(error)
					} else {
						listeners["users/\(id)"] = firestore.document("users/\(id)").addSnapshotListener { snapshot, error in
							if error == nil, let snapshot = snapshot {
								name = snapshot.get("name") as? String ?? "Error"
								email = snapshot.get("email") as? String ?? "Error"
								slug = snapshot.get("slug") as? String
								ChangeHandler.call(.profileModified)
								User.save()
								self.hideActivityIndicator()
								self.performSegue(withIdentifier: "signUp", sender: self)
							} else if let error = error {
								self.showError(error)
							}
						}
					}
				}
			} else if let error = error {
				self.showError(error)
			}
		}
	}
	
	func showError(_ error: Error) {
		hideActivityIndicator()
		switch error.localizedDescription {
		case "Network error (such as timeout, interrupted connection or unreachable host) has occurred.":
			showNotification("No internet", type: .error)
		default:
			showNotification("There was a problem creating a new account", type: .error)
		}
	}
	
	func showActivityIndicator() {
		signUpButton.isEnabled = false
		signUpButton.setTitle(nil, for: .normal)
		signUpActivityIndicator.startAnimating()
	}
	
	func hideActivityIndicator() {
		signUpButton.isEnabled = true
		signUpButton.setTitle("SIGN UP", for: .normal)
		signUpActivityIndicator.stopAnimating()
	}
	
	func enable() {
		signUpButton.isEnabled = true
		signUpButton.setTitleColor(#colorLiteral(red: 0, green: 0.5694751143, blue: 1, alpha: 1), for: .normal)
		signUpButton.backgroundColor = .white
	}
	
	func disable() {
		signUpButton.isEnabled = false
		signUpButton.setTitleColor(#colorLiteral(red: 0.9411764706, green: 0.9411764706, blue: 0.9411764706, alpha: 1), for: .normal)
		signUpButton.backgroundColor = #colorLiteral(red: 0.862745098, green: 0.862745098, blue: 0.862745098, alpha: 1)
	}
	
	func enable(barView: UIView) {
		UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
			barView.transform = CGAffineTransform(scaleX: 1.01, y: 2)
			barView.backgroundColor = #colorLiteral(red: 0, green: 0.5694751143, blue: 1, alpha: 1)
		}, completion: nil)
	}
	
	func disable(barView: UIView) {
		UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
			barView.transform = .identity
			barView.backgroundColor = .lightGray
		}, completion: nil)
	}
	
	func updateSignUpButton() {
		guard let nameText = nameTextField.text?.trim(), let emailText = emailTextField.text?.trim(), let passwordText = passwordTextField.text?.trim() else { return }
		!nameText.isEmpty && emailText.checkEmail() && passwordText.count >= 6 ? enable() : disable()
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		dismissKeyboard()
		return false
	}
}
