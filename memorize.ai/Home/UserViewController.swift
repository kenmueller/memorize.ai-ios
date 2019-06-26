import UIKit
import Firebase
import WebKit

class UserViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
	@IBOutlet weak var loadingView: UIView!
	@IBOutlet weak var loadingImage: UIImageView!
	@IBOutlet weak var offlineView: UIView!
	@IBOutlet weak var retryButton: UIButton!
	@IBOutlet weak var helloLabel: UILabel!
	@IBOutlet weak var decksView: UIView!
	@IBOutlet weak var decksLabel: UILabel!
	@IBOutlet weak var decksBarView: UIView!
	@IBOutlet weak var cardsView: UIView!
	@IBOutlet weak var cardsLabel: UILabel!
	@IBOutlet weak var cardsBarView: UIView!
	@IBOutlet weak var createView: UIView!
	@IBOutlet weak var createLabel: UILabel!
	@IBOutlet weak var createBarView: UIView!
	@IBOutlet weak var marketplaceView: UIView!
	@IBOutlet weak var marketplaceLabel: UILabel!
	@IBOutlet weak var marketplaceBarView: UIView!
	@IBOutlet weak var cardsCollectionView: UICollectionView!
	@IBOutlet weak var cardsCollectionViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var reviewButton: UIButton!
	@IBOutlet weak var dueCardsLabel: UILabel!
	
	var enabled = [false, false, true, true]
	var cards = [(image: UIImage, card: Card)]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		if startup {
			navigationController?.setNavigationBarHidden(true, animated: false)
			loadingView.isHidden = false
			loadingImage.isHidden = false
			if auth.currentUser == nil {
				signIn()
			} else if let user = User.get() {
				darkMode(user.darkMode)
				loadProfileBarButtonItem(user.image)
				id = user.id
				name = user.name
				email = user.email
				profilePicture = user.image
				User.pushToken()
				loadingImage.isHidden = true
				loadingView.isHidden = true
				navigationController?.setNavigationBarHidden(false, animated: false)
				reloadProfileBarButtonItem()
				startup = false
				ChangeHandler.call(.profileModified)
				guard let id = id else { return }
				listeners["users/\(id)"] = firestore.document("users/\(id)").addSnapshotListener { snapshot, error in
					if let error = error {
						switch error.localizedDescription {
						case "Network error (such as timeout, interrupted connection or unreachable host) has occurred.":
							self.loadingImage.isHidden = true
							self.offlineView.isHidden = false
							self.retryButton.isHidden = false
						default:
							self.signIn()
						}
					} else if let snapshot = snapshot {
						name = snapshot.get("name") as? String ?? name
						email = snapshot.get("email") as? String ?? email
						slug = snapshot.get("slug") as? String
						self.createHelloLabel()
						User.save()
						ChangeHandler.call(.profileModified)
					}
				}
				updateLastOnline()
				loadSettings()
				loadDecks()
				loadUploads()
				loadCardDrafts()
				loadRatings()
				loadRatingDrafts()
			} else {
				signIn()
			}
			Card.poll()
		}
		navigationItem.setHidesBackButton(true, animated: true)
		let flowLayout = UICollectionViewFlowLayout()
		flowLayout.itemSize = CGSize(width: view.bounds.width - 80, height: 40)
		flowLayout.minimumLineSpacing = 8
		cardsCollectionView.collectionViewLayout = flowLayout
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		reviewButton.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
		ChangeHandler.update { change in
			if change == .deckModified || change == .deckRemoved || change == .cardModified || change == .cardRemoved || change == .cardDue {
				self.loadCards()
				self.reloadActions()
				self.reloadReview()
			}
		}
		Setting.updateHandler { setting in
			switch setting.type {
			case .darkMode:
				self.darkMode(setting.data as? Bool ?? false)
			default:
				return
			}
		}
		reloadReview()
		loadCards()
		createHelloLabel()
		reloadActions()
		loadProfileBarButtonItem(nil)
		cardsCollectionView.reloadData()
		if shouldLoadDecks {
			updateLastOnline()
			loadBarButtonItems(image: #imageLiteral(resourceName: "Person"))
			reloadProfileBarButtonItem()
			loadDecks()
			loadUploads()
			loadCardDrafts()
			loadRatings()
			loadRatingDrafts()
			Card.poll()
			createHelloLabel()
			navigationController?.setNavigationBarHidden(false, animated: true)
			navigationItem.setHidesBackButton(true, animated: true)
			shouldLoadDecks = false
		}
		updateCurrentViewController()
	}
	
	func darkMode(_ enabled: Bool) {
		self.loadingView.backgroundColor = enabled ? .darkGray : .white
		let backgroundColor = enabled ? .darkGray : #colorLiteral(red: 0.9529411765, green: 0.9529411765, blue: 0.9529411765, alpha: 1)
		self.view.backgroundColor = backgroundColor
		self.cardsCollectionView.backgroundColor = backgroundColor
	}
	
	@IBAction func retry() {
		offlineView.isHidden = true
		retryButton.isHidden = true
		viewDidLoad()
	}
	
	func createHelloLabel() {
		guard let name = name else { return }
		helloLabel.text = "Hello, \(name)"
	}
	
	func updateLastOnline() {
		guard auth.currentUser != nil else { return }
		functions.httpsCallable("updateLastOnline").call { _, _ in }
	}
	
	func loadSettings() {
		guard let id = id else { return }
		listeners["settings"] = firestore.collection("settings").addSnapshotListener { snapshot, error in
			guard error == nil, let snapshot = snapshot?.documentChanges else { return }
			snapshot.forEach {
				let setting = $0.document
				let settingId = setting.documentID
				switch $0.type {
				case .added:
					listeners["users/\(id)/settings/\(settingId)"] = firestore.document("users/\(id)/settings/\(settingId)").addSnapshotListener { settingSnapshot, settingError in
						guard settingError == nil, let settingSnapshot = settingSnapshot else { return }
						if let localSetting = Setting.get(settingId) {
							localSetting.update(settingSnapshot, type: .user)
							ChangeHandler.call(.settingValueModified)
						} else {
							settings.append(Setting(
								id: settingId,
								section: setting.get("section") as? String ?? "",
								slug: setting.get("slug") as? String ?? "",
								title: setting.get("title") as? String ?? "Error",
								description: setting.get("description") as? String ?? "",
								value: settingSnapshot.get("value"),
								default: setting.get("default") ?? true,
								order: setting.get("order") as? Int ?? 0
							))
							ChangeHandler.call(.settingAdded)
						}
						Setting.loadSectionedSettings()
						Setting.callHandler(settingId)
					}
				case .modified:
					Setting.get(settingId)?.update(setting, type: .setting)
					Setting.loadSectionedSettings()
					Setting.callHandler(settingId)
					ChangeHandler.call(.settingModified)
				case .removed:
					settings = settings.filter { $0.id != settingId }
					Listener.remove("users/\(id)/settings/\(settingId)")
					Setting.loadSectionedSettings()
					ChangeHandler.call(.settingRemoved)
				@unknown default:
					break
				}
			}
		}
	}
	
	func loadCards() {
		let count = cards.count
		cards = Card.sort(Deck.allDue(), by: .due).map { (image: #imageLiteral(resourceName: "Due"), card: $0) }
		cards.append(contentsOf: Card.all.filter { $0.last != nil }.sorted { $0.last?.date.timeIntervalSinceNow ?? 0 < $1.last?.date.timeIntervalSinceNow ?? 0 }.map { (image: PerformanceRating.image($0.last?.rating ?? 0), card: $0) })
		if count != cards.count {
			cardsCollectionView.reloadData()
		}
	}
	
	func loadCardDrafts() {
		guard let id = id else { return }
		listeners["users/\(id)/cardDrafts"] = firestore.collection("users/\(id)/cardDrafts").addSnapshotListener { snapshot, error in
			guard error == nil, let snapshot = snapshot?.documentChanges else { return }
			snapshot.forEach {
				let draft = $0.document
				let draftId = draft.documentID
				switch $0.type {
				case .added:
					guard let deckId = draft.get("deck") as? String, let front = draft.get("front") as? String, let back = draft.get("back") as? String else { return }
					cardDrafts.append(CardDraft(
						id: draftId,
						deckId: deckId,
						cardId: draft.get("card") as? String,
						front: front,
						back: back
					))
					ChangeHandler.call(.cardDraftAdded)
				case .modified:
					CardDraft.get(draftId)?.update(draft)
					ChangeHandler.call(.cardDraftModified)
				case .removed:
					cardDrafts = cardDrafts.filter { $0.id != draftId }
					ChangeHandler.call(.cardDraftRemoved)
				@unknown default:
					break
				}
			}
		}
	}
	
	func loadRatings() {
		guard let id = id else { return }
		listeners["users/\(id)/ratings"] = firestore.collection("users/\(id)/ratings").addSnapshotListener { snapshot, error in
			guard error == nil, let snapshot = snapshot?.documentChanges else { return }
			snapshot.forEach {
				let rating = $0.document
				let deckId = rating.documentID
				switch $0.type {
				case .added:
					if let ratingValue = rating.get("rating") as? Int, let title = rating.get("title") as? String, let review = rating.get("review") as? String, let date = rating.getDate("date") {
						deckRatings.append(DeckRating(
							id: deckId,
							rating: ratingValue,
							title: title,
							review: review,
							date: date
						))
					}
					self.loadCardRatings(deckId)
					ChangeHandler.call(.deckRatingAdded)
				case .modified:
					if rating.get("x") == nil {
						if let deckRating = DeckRating.get(deckId) {
							deckRating.update(rating)
						} else {
							let deckRating = DeckRating(id: deckId, rating: 0, title: "", review: "", date: Date())
							deckRating.update(rating)
							deckRatings.append(deckRating)
						}
						ChangeHandler.call(.deckRatingModified)
					} else {
						deckRatings = deckRatings.filter { $0.id != deckId }
						ChangeHandler.call(.deckRatingRemoved)
					}
				case .removed:
					deckRatings = deckRatings.filter { $0.id != deckId }
					ChangeHandler.call(.deckRatingRemoved)
				@unknown default:
					break
				}
			}
		}
	}
	
	func loadCardRatings(_ deckId: String) {
		guard let id = id else { return }
		listeners["users/\(id)/ratings/\(deckId)/cards"] = firestore.collection("users/\(id)/ratings/\(deckId)/cards").addSnapshotListener { snapshot, error in
			guard error == nil, let snapshot = snapshot?.documentChanges else { return }
			snapshot.forEach {
				let rating = $0.document
				let cardId = rating.documentID
				switch $0.type {
				case .added:
					cardRatings.append(CardRating(
						deckId: deckId,
						id: cardId,
						rating: CardRatingType(rating.get("rating") as? Int ?? 0),
						date: rating.getDate("date") ?? Date()
					))
					ChangeHandler.call(.cardRatingAdded)
				case .modified:
					CardRating.get(cardId)?.update(rating)
					ChangeHandler.call(.cardRatingModified)
				case .removed:
					cardRatings = cardRatings.filter { $0.id != cardId }
					ChangeHandler.call(.cardRatingRemoved)
				@unknown default:
					break
				}
			}
		}
	}
	
	func loadRatingDrafts() {
		guard let id = id else { return }
		listeners["users/\(id)/ratingDrafts"] = firestore.collection("users/\(id)/ratingDrafts").addSnapshotListener { snapshot, error in
			guard error == nil, let snapshot = snapshot?.documentChanges else { return }
			snapshot.forEach {
				let draft = $0.document
				let deckId = draft.documentID
				switch $0.type {
				case .added:
					ratingDrafts.append(RatingDraft(
						id: deckId,
						rating: draft.get("rating") as? Int,
						title: draft.get("title") as? String,
						review: draft.get("review") as? String
					))
					ChangeHandler.call(.ratingDraftAdded)
				case .modified:
					RatingDraft.get(deckId)?.update(draft)
					ChangeHandler.call(.ratingDraftModified)
				case .removed:
					ratingDrafts = ratingDrafts.filter { $0.id != deckId }
					ChangeHandler.call(.ratingDraftRemoved)
				@unknown default:
					break
				}
			}
		}
	}
	
	func signIn() {
		performSegue(withIdentifier: "signIn", sender: self)
	}
	
	func loadBarButtonItems(image: UIImage) {
		let editProfileButton = UIButton(type: .custom)
		editProfileButton.setImage(image, for: .normal)
		editProfileButton.addTarget(self, action: #selector(editProfile), for: .touchUpInside)
		editProfileButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
		editProfileButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
		editProfileButton.layer.cornerRadius = 16
		editProfileButton.layer.masksToBounds = true
		let titleLabel = UILabel()
		titleLabel.text = "  memorize.ai"
		titleLabel.font = UIFont(name: "Nunito-ExtraBold", size: 20)
		titleLabel.textColor = .white
		titleLabel.sizeToFit()
		navigationItem.setLeftBarButtonItems([UIBarButtonItem(customView: editProfileButton), UIBarButtonItem(customView: titleLabel)], animated: false)
	}
	
	func loadProfileBarButtonItem(_ image: UIImage?) {
		guard let image = image ?? profilePicture else { return }
		loadBarButtonItems(image: image)
		profilePicture = image
	}
	
	func reloadProfileBarButtonItem() {
		User.getImageFromStorage { image in
			self.loadBarButtonItems(image: image ?? DEFAULT_PROFILE_PICTURE)
			ChangeHandler.call(.profilePicture)
		}
	}
	
	func reloadReview() {
		let dueCards = Deck.allDue()
		if reviewButton.isHidden && !dueCards.isEmpty {
			dueCardsLabel.text = "1 card due"
			reviewButton.transform = CGAffineTransform(translationX: 0, y: 79)
			dueCardsLabel.transform = CGAffineTransform(translationX: 0, y: 25)
			reviewButton.isHidden = false
			dueCardsLabel.isHidden = false
			cardsCollectionViewBottomConstraint.constant = 20
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
				self.view.layoutIfNeeded()
				self.reviewButton.transform = .identity
				self.dueCardsLabel.transform = .identity
			}, completion: nil)
		} else if !reviewButton.isHidden && dueCards.isEmpty {
			dueCardsLabel.text = "0 cards due"
			cardsCollectionViewBottomConstraint.constant = -60
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseIn, animations: {
				self.view.layoutIfNeeded()
				self.reviewButton.transform = CGAffineTransform(translationX: 0, y: 79)
				self.dueCardsLabel.transform = CGAffineTransform(translationX: 0, y: 25)
			}) {
				guard $0 else { return }
				self.reviewButton.isHidden = true
				self.dueCardsLabel.isHidden = true
			}
		} else {
			dueCardsLabel.text = "\(dueCards.count) card\(dueCards.count == 1 ? "" : "s") due"
		}
	}
	
	@objc func editProfile() {
		performSegue(withIdentifier: "editProfile", sender: self)
	}
	
	@IBAction func review() {
		performSegue(withIdentifier: "review", sender: self)
	}
	
	func loadDecks() {
		guard let id = id else { return }
		listeners["users/\(id)/decks"] = firestore.collection("users/\(id)/decks").addSnapshotListener { snapshot, error in
			guard error == nil, let snapshot = snapshot?.documentChanges else { return }
			snapshot.forEach {
				let deck = $0.document
				let deckId = deck.documentID
				switch $0.type {
				case .added:
					listeners["decks/\(deckId)"] = firestore.document("decks/\(deckId)").addSnapshotListener { deckSnapshot, deckError in
						guard deckError == nil, let deckSnapshot = deckSnapshot else { return }
						if let localDeck = Deck.getFromAll(deckId) {
							localDeck.update(deckSnapshot, type: .deck)
						} else {
							allDecks.append(Deck(
								id: deckId,
								image: nil,
								name: deckSnapshot.get("name") as? String ?? "Error",
								subtitle: deckSnapshot.get("subtitle") as? String ?? "Error",
								description: deckSnapshot.get("description") as? String ?? "Error",
								tags: deckSnapshot.get("tags") as? [String] ?? [],
								isPublic: deckSnapshot.get("public") as? Bool ?? true,
								count: deckSnapshot.get("count") as? Int ?? 0,
								views: DeckViews(deckSnapshot),
								downloads: DeckDownloads(deckSnapshot),
								ratings: DeckRatings(deckSnapshot),
								users: [],
								creator: deckSnapshot.get("creator") as? String ?? "Error",
								owner: deckSnapshot.get("owner") as? String ?? "Error",
								created: deckSnapshot.getDate("created") ?? Date(),
								updated: deckSnapshot.getDate("updated") ?? Date(),
								permissions: [],
								cards: [],
								mastered: deck.get("mastered") as? Int ?? 0,
								role: Role(deck.get("role") as? String),
								hidden: deck.get("hidden") as? Bool ?? false
							))
						}
						ChangeHandler.call(.deckModified)
						listeners["decks/\(deckId)/cards"] = firestore.collection("decks/\(deckId)/cards").addSnapshotListener { snapshot, error in
							guard error == nil, let snapshot = snapshot?.documentChanges else { return }
							snapshot.forEach {
								let card = $0.document
								let cardId = card.documentID
								guard let localDeck = Deck.getFromAll(deckId) else { return }
								switch $0.type {
								case .added:
									listeners["users/\(id)/decks/\(deckId)/cards/\(cardId)"] = firestore.document("users/\(id)/decks/\(deckId)/cards/\(cardId)").addSnapshotListener { cardSnapshot, cardError in
										guard cardError == nil, let cardSnapshot = cardSnapshot else { return }
										if let localCard = Card.get(cardId, deckId: deckId) {
											if cardSnapshot.exists {
												localCard.update(cardSnapshot, type: .user)
											} else {
												localCard.reset()
											}
										} else {
											localDeck.cards.append(Card(
												id: cardId,
												front: card.get("front") as? String ?? "Error",
												back: card.get("back") as? String ?? "Error",
												created: card.getDate("created") ?? Date(),
												updated: card.getDate("updated") ?? Date(),
												likes: card.get("likes") as? Int ?? 0,
												dislikes: card.get("dislikes") as? Int ?? 0,
												count: cardSnapshot.get("count") as? Int ?? 0,
												correct: cardSnapshot.get("correct") as? Int ?? 0,
												e: cardSnapshot.get("e") as? Double ?? DEFAULT_E,
												streak: cardSnapshot.get("streak") as? Int ?? 0,
												mastered: cardSnapshot.get("mastered") as? Bool ?? false,
												last: CardLast(cardSnapshot),
												next: cardSnapshot.getDate("next") ?? Date(),
												history: [],
												deck: deckId
											))
										}
										self.reloadReview()
										ChangeHandler.call(.cardModified)
									}
								case .modified:
									Card.get(cardId, deckId: deckId)?.update(card, type: .card)
									self.reloadReview()
									ChangeHandler.call(.cardModified)
								case .removed:
									localDeck.cards = localDeck.cards.filter { $0.id != cardId }
									Listener.remove("users/\(id)/decks/\(deckId)/cards/\(cardId)")
									self.reloadReview()
									ChangeHandler.call(.cardRemoved)
								@unknown default:
									return
								}
							}
						}
					}
				case .modified:
					Deck.getFromAll(deckId)?.update(deck, type: .user)
					ChangeHandler.call(.deckModified)
				case .removed:
					allDecks = allDecks.filter { $0.id != deckId }
					Listener.remove("decks/\(deckId)")
					ChangeHandler.call(.deckRemoved)
				@unknown default:
					return
				}
			}
		}
	}
	
	func loadUploads() {
		guard let id = id else { return }
		listeners["users/\(id)/uploads"] = firestore.collection("users/\(id)/uploads").addSnapshotListener { snapshot, error in
			guard error == nil, let snapshot = snapshot?.documentChanges else { return }
			snapshot.forEach {
				let upload = $0.document
				let uploadId = upload.documentID
				switch $0.type {
				case .added:
					uploads.append(Upload(
						id: uploadId,
						name: upload.get("name") as? String ?? "Error",
						created: upload.getDate("created") ?? Date(),
						updated: upload.getDate("updated") ?? Date(),
						type: UploadType(rawValue: upload.get("type") as? String ?? "") ?? .image,
						mime: upload.get("mime") as? String ?? "image/png",
						extension: upload.get("extension") as? String ?? "png",
						size: upload.get("size") as? String ?? "0 MB",
						data: nil
					))
					ChangeHandler.call(.uploadAdded)
				case .modified:
					Upload.get(uploadId)?.update(upload)
					ChangeHandler.call(.uploadModified)
				case .removed:
					uploads = uploads.filter { $0.id != uploadId }
					ChangeHandler.call(.uploadRemoved)
				@unknown default:
					return
				}
			}
		}
	}
	
	func toggle(_ label: UILabel, _ barView: UIView, enabled: Bool) {
		let color = enabled ? #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1) : #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
		label.textColor = color
		barView.backgroundColor = color
	}
	
	func reloadActions() {
		let actions = [
			(view: decksView, label: decksLabel, barView: decksBarView),
			(view: cardsView, label: cardsLabel, barView: cardsBarView),
			(view: createView, label: createLabel, barView: createBarView),
			(view: marketplaceView, label: marketplaceLabel, barView: marketplaceBarView)
		]
		(0...3).forEach {
			let action = actions[$0]
			guard let view = action.view, let label = action.label, let barView = action.barView else { return }
			view.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
			enabled[$0] = !(($0 == 0 && decks.isEmpty) || ($0 == 1 && Card.all.isEmpty))
			toggle(label, barView, enabled: enabled[$0])
		}
	}
	
	@IBAction func showDecks() {
		guard enabled.first ?? false else { return }
		performSegue(withIdentifier: "decks", sender: self)
	}
	
	@IBAction func showCards() {
		guard enabled[1] else { return }
		performSegue(withIdentifier: "cards", sender: self)
	}
	
	@IBAction func showCreate() {
		guard enabled[2] else { return }
		performSegue(withIdentifier: "createDeck", sender: self)
	}
	
	@IBAction func showMarketplace() {
		guard enabled[3] else { return }
		performSegue(withIdentifier: "searchDeck", sender: self)
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return cards.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let _cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
		guard let cell = _cell as? UserCardsCollectionViewCell else { return _cell }
		let element = cards[indexPath.item]
		cell.imageView.image = element.image
		cell.load(element.card.front)
		return cell
	}
}

class UserCardsCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var label: UILabel!
	
	func load(_ text: String) {
		layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
		label.text = text.clean()
	}
}
