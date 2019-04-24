import UIKit

class RecapViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
	@IBOutlet weak var recapCollectionView: UICollectionView!
	
	var cards = [(id: String, deck: Deck, card: Card, correct: Bool, next: Date?)]()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		navigationItem.setHidesBackButton(true, animated: true)
		let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(back))
		navigationItem.setRightBarButton(done, animated: true)
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		updateChangeHandler { change in
			if change == .cardModified {
				self.recapCollectionView.reloadData()
			}
		}
	}
	
	@objc func back() {
		performSegue(withIdentifier: "done", sender: self)
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return cards.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! RecapCollectionViewCell
		let element = cards[indexPath.item]
		if let image = element.deck.image {
			cell.imageView.image = image
		} else {
			cell.imageActivityIndicator.startAnimating()
			storage.child("decks/\(element.deck.id)").getData(maxSize: fileLimit) { data, error in
				guard error == nil, let data = data, let image = UIImage(data: data) else { return }
				element.deck.image = image
				cell.imageActivityIndicator.stopAnimating()
				cell.imageView.image = image
			}
		}
		cell.deckLabel.text = element.deck.name
		cell.cardLabel.text = element.card.front
		if let next = element.next {
			cell.nextLabel.text = next.format()
		} else {
			cell.nextLabel.text = "Loading..."
			firestore.document("users/\(id!)/decks/\(element.deck.id)/cards/\(element.card.id)/history/\(element.id)").addSnapshotListener { snapshot, error in
				guard error == nil, let next = snapshot?.get("next") as? Date else { return }
				self.cards[indexPath.item] = (id: element.id, deck: element.deck, card: element.card, correct: element.correct, next: next)
				cell.nextLabel.text = next.format()
			}
		}
		return cell
	}
}

class RecapCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var imageActivityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var deckLabel: UILabel!
	@IBOutlet weak var cardLabel: UILabel!
	@IBOutlet weak var nextLabel: UILabel!
}
