import UIKit

class DeckPermissionsViewController: UIViewController {
	var deck: Deck?
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		updateCurrentViewController()
	}
}