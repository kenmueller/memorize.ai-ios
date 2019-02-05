import UIKit

class DecksViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate {
	@IBOutlet weak var decksCollectionView: UICollectionView!
	@IBOutlet weak var cardsTableView: UITableView!
	@IBOutlet weak var startView: UIView!
	
	var deck: Deck?
	var card: Card?
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let layout = UICollectionViewFlowLayout()
		layout.itemSize = CGSize(width: 84, height: 102)
		layout.minimumLineSpacing = 8
		layout.minimumInteritemSpacing = 8
		decksCollectionView.collectionViewLayout = layout
		firestore.collection("users").document(id!).collection("decks").addSnapshotListener { snapshot, error in
			if let snapshot = snapshot?.documents, error == nil {
				decks = snapshot.map { deck in
					let deckId = deck.documentID
					storage.child("decks/\(deckId)").getData(maxSize: 50000000) { data, error in
						if let data = data, error == nil {
							decks[Deck.id(deckId)!].image = UIImage(data: data) ?? #imageLiteral(resourceName: "Gray Deck")
							self.decksCollectionView.reloadData()
						}
					}
					return Deck(id: deckId, image: #imageLiteral(resourceName: "Gray Deck"), name: deck["name"] as? String ?? "Error", description: deck["description"] as? String ?? "Error", cards: [])
				}
			}
		}
    }
	
	@objc @IBAction func newDeck() {
		if let chooseDeckTypeVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chooseDeckType") as? ChooseDeckTypeViewController {
			addChild(chooseDeckTypeVC)
			chooseDeckTypeVC.view.frame = view.frame
			view.addSubview(chooseDeckTypeVC.view)
			chooseDeckTypeVC.didMove(toParent: self)
		}
	}
	
	func createDeck() {
		performSegue(withIdentifier: "createDeck", sender: self)
	}
	
	func searchDeck() {
		performSegue(withIdentifier: "searchDeck", sender: self)
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return decks.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! DeckCollectionViewCell
		let element = decks[indexPath.item]
		cell.layer.borderWidth = 1
		cell.layer.borderColor = #colorLiteral(red: 0.198331058, green: 0.198331058, blue: 0.198331058, alpha: 1)
		cell.imageView.image = element.image
		cell.nameLabel.text = element.name
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? DeckCollectionViewCell
		cell?.layer.borderWidth = 2
		cell?.layer.borderColor = #colorLiteral(red: 0.4470588235, green: 0.537254902, blue: 0.8549019608, alpha: 1)
		if !startView.isHidden {
			UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
				self.startView.alpha = 0
			}) { finished in
				if finished {
					self.startView.isHidden = true
				}
			}
			navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newDeck)), animated: true)
		}
		deck = decks[indexPath.item]
		cardsTableView.reloadData()
	}
	
	func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? DeckCollectionViewCell
		cell?.layer.borderWidth = 1
		cell?.layer.borderColor = #colorLiteral(red: 0.1977208257, green: 0.2122347951, blue: 0.2293028235, alpha: 1)
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return "CARDS"
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let deck = deck else { return 0 }
		return deck.cards.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		cell.textLabel?.text = deck?.cards[indexPath.row].front
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		card = deck?.cards[indexPath.row]
		performSegue(withIdentifier: "card", sender: self)
	}
}

class DeckCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
}
