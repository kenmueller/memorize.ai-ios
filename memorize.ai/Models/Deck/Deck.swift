import SwiftUI
import FirebaseFirestore
import PromiseKit
import LoadingState

final class Deck: ObservableObject, Identifiable, Equatable, Hashable {
	static let maxNumberOfPreviewCards = 20
	
	static var cache = [String: Deck]()
	static var imageCache = [String: Image]()
	
	let id: String
	let creatorId: String
	let dateCreated: Date
	
	@Published var topics: [String]
	@Published var hasImage: Bool
	@Published var image: Image?
	@Published var name: String
	@Published var subtitle: String
	@Published var numberOfViews: Int
	@Published var numberOfUniqueViews: Int
	@Published var numberOfRatings: Int
	@Published var averageRating: Double
	@Published var numberOfDownloads: Int
	@Published var numberOfCards: Int
	@Published var dateLastUpdated: Date
	
	@Published var userData: UserData?
	@Published var sections: [Section]
	@Published var creator: User?
	@Published var previewCards: [Card]
	
	@Published var imageLoadingState = LoadingState()
	@Published var userDataLoadingState = LoadingState()
	@Published var getLoadingState = LoadingState()
	@Published var sectionsLoadingState = LoadingState()
	@Published var creatorLoadingState = LoadingState()
	@Published var previewCardsLoadingState = LoadingState()
	
	init(
		id: String,
		topics: [String],
		hasImage: Bool,
		image: Image? = nil,
		name: String,
		subtitle: String,
		numberOfViews: Int,
		numberOfUniqueViews: Int,
		numberOfRatings: Int,
		averageRating: Double,
		numberOfDownloads: Int,
		numberOfCards: Int,
		creatorId: String,
		dateCreated: Date,
		dateLastUpdated: Date,
		userData: UserData? = nil,
		sections: [Section] = [],
		creator: User? = nil,
		previewCards: [Card] = []
	) {
		self.id = id
		self.topics = topics
		self.hasImage = hasImage
		self.image = image
		self.name = name
		self.subtitle = subtitle
		self.numberOfViews = numberOfViews
		self.numberOfUniqueViews = numberOfUniqueViews
		self.numberOfRatings = numberOfRatings
		self.averageRating = averageRating
		self.numberOfDownloads = numberOfDownloads
		self.numberOfCards = numberOfCards
		self.creatorId = creatorId
		self.dateCreated = dateCreated
		self.dateLastUpdated = dateLastUpdated
		self.userData = userData
		self.sections = sections
		self.creator = creator
		self.previewCards = previewCards
	}
	
	convenience init(snapshot: DocumentSnapshot) {
		self.init(
			id: snapshot.documentID,
			topics: snapshot.get("topics") as? [String] ?? [],
			hasImage: snapshot.get("hasImage") as? Bool ?? false,
			name: snapshot.get("name") as? String ?? "Unknown",
			subtitle: snapshot.get("subtitle") as? String ?? "(empty)",
			numberOfViews: snapshot.get("viewCount") as? Int ?? 0,
			numberOfUniqueViews: snapshot.get("uniqueViewCount") as? Int ?? 0,
			numberOfRatings: snapshot.get("ratingCount") as? Int ?? 0,
			averageRating: snapshot.get("averageRating") as? Double ?? 0,
			numberOfDownloads: snapshot.get("downloadCount") as? Int ?? 0,
			numberOfCards: snapshot.get("cardCount") as? Int ?? 0,
			creatorId: snapshot.get("creator") as? String ?? "0",
			dateCreated: snapshot.getDate("created") ?? .now,
			dateLastUpdated: snapshot.getDate("updated") ?? .now
		)
	}
	
	var documentReference: DocumentReference {
		firestore.document("decks/\(id)")
	}
	
	@discardableResult
	func loadImage() -> Self {
		guard imageLoadingState.isNone && hasImage else { return self }
		imageLoadingState.startLoading()
		if let cachedImage = Self.imageCache[id] {
			image = cachedImage
			imageLoadingState.succeed()
		} else {
			storage.child("decks/\(id)").getData().done { data in
				guard let image = Image(data: data) else {
					self.imageLoadingState.fail(message: "Malformed data")
					return
				}
				self.image = image
				Self.imageCache[self.id] = image
				self.imageLoadingState.succeed()
			}.catch { error in
				self.imageLoadingState.fail(error: error)
			}
		}
		return self
	}
	
	@discardableResult
	func loadUserData(user: User) -> Self {
		guard userDataLoadingState.isNone else { return self }
		userDataLoadingState.startLoading()
		firestore.document("users/\(user.id)/decks/\(id)").addSnapshotListener { snapshot, error in
			guard error == nil, let snapshot = snapshot else {
				self.userDataLoadingState.fail(
					error: error ?? UNKNOWN_ERROR
				)
				return
			}
			self.updateUserDataFromSnapshot(snapshot)
			self.userDataLoadingState.succeed()
		}
		return self
	}
	
	@discardableResult
	func loadSections() -> Self {
		guard sectionsLoadingState.isNone else { return self }
		sectionsLoadingState.startLoading()
		documentReference.collection("sections").addSnapshotListener { snapshot, error in
			guard error == nil, let documentChanges = snapshot?.documentChanges else {
				self.sectionsLoadingState.fail(error: error ?? UNKNOWN_ERROR)
				return
			}
			for change in documentChanges {
				let document = change.document
				let sectionId = document.documentID
				switch change.type {
				case .added:
					self.sections.append(.init(parent: self, snapshot: document))
				case .modified:
					self.sections.first { $0.id == sectionId }?
						.updateFromSnapshot(document)
				case .removed:
					self.sections.removeAll { $0.id == sectionId }
				}
			}
			self.sectionsLoadingState.succeed()
		}
		return self
	}
	
	@discardableResult
	func loadCreator() -> Self {
		guard creatorLoadingState.isNone else { return self }
		creatorLoadingState.startLoading()
		firestore.document("users/\(creatorId)").addSnapshotListener { snapshot, error in
			guard error == nil, let snapshot = snapshot else {
				self.creatorLoadingState.fail(error: error ?? UNKNOWN_ERROR)
				return
			}
			if let creator = self.creator {
				creator.updateFromSnapshot(snapshot)
			} else {
				self.creator = .init(snapshot: snapshot)
			}
			self.creatorLoadingState.succeed()
		}
		return self
	}
	
	@discardableResult
	func loadPreviewCards() -> Self {
		guard previewCardsLoadingState.isNone else { return self }
		previewCardsLoadingState.startLoading()
		documentReference
			.collection("cards")
			.order(by: "viewCount")
			.limit(to: Self.maxNumberOfPreviewCards)
			.addSnapshotListener { snapshot, error in
				guard error == nil, let documentChanges = snapshot?.documentChanges else {
					self.previewCardsLoadingState.fail(error: error ?? UNKNOWN_ERROR)
					return
				}
				for change in documentChanges {
					let document = change.document
					let cardId = document.documentID
					switch change.type {
					case .added:
						self.previewCards.append(.init(snapshot: document))
					case .modified:
						self.previewCards.first { $0.id == cardId }?
							.updateFromSnapshot(document)
						self.previewCards.sort(by: \.numberOfViews)
					case .removed:
						self.previewCards.removeAll { $0.id == cardId }
					}
				}
				self.previewCardsLoadingState.succeed()
			}
		return self
	}
	
	@discardableResult
	func get(user: User) -> Self {
		getLoadingState.startLoading()
		firestore.document("users/\(user.id)/decks/\(id)").setData([
			"added": FieldValue.serverTimestamp()
		]).done {
			self.getLoadingState.succeed()
		}.catch { error in
			self.getLoadingState.fail(error: error)
		}
		return self
	}
	
	@discardableResult
	func remove(user: User) -> Self {
		getLoadingState.startLoading()
		firestore.document("users/\(user.id)/decks/\(id)").delete().done {
			self.getLoadingState.succeed()
		}.catch { error in
			self.getLoadingState.fail(error: error)
		}
		return self
	}
	
	@discardableResult
	func setFavorite(to newValue: Bool, forUser user: User) -> Promise<Void> {
		firestore.document("users/\(user.id)/decks/\(id)").updateData([
			"favorite": newValue
		])
	}
	
	@discardableResult
	func updatePublicDataFromSnapshot(_ snapshot: DocumentSnapshot) -> Self {
		hasImage = snapshot.get("hasImage") as? Bool ?? false
		if !hasImage { image = nil }
		name = snapshot.get("name") as? String ?? name
		subtitle = snapshot.get("subtitle") as? String ?? subtitle
		numberOfViews = snapshot.get("viewCount") as? Int ?? numberOfViews
		numberOfUniqueViews = snapshot.get("uniqueViewCount") as? Int ?? numberOfUniqueViews
		numberOfRatings = snapshot.get("ratingCount") as? Int ?? numberOfRatings
		averageRating = snapshot.get("averageRating") as? Double ?? averageRating
		numberOfDownloads = snapshot.get("downloadCount") as? Int ?? numberOfDownloads
		dateLastUpdated = snapshot.getDate("updated") ?? dateLastUpdated
		return self
	}
	
	@discardableResult
	func updateUserDataFromSnapshot(_ snapshot: DocumentSnapshot) -> Self {
		if userData == nil {
			userData = .init(snapshot: snapshot)
		} else {
			userData?.isFavorite = snapshot.get("favorite") as? Bool ?? false
			userData?.numberOfDueCards = snapshot.get("dueCardCount") as? Int ?? 0
			userData?.unlockedSections = snapshot.get("unlockedSections") as? [String] ?? []
		}
		return self
	}
	
	static func fromId(_ id: String) -> Promise<Deck> {
		var didFulfill = false
		var deck: Deck?
		return .init { seal in
			if let cachedDeck = cache[id] {
				return seal.fulfill(cachedDeck)
			}
			firestore.document("decks/\(id)").addSnapshotListener { snapshot, error in
				guard error == nil, let snapshot = snapshot else {
					return seal.reject(error ?? UNKNOWN_ERROR)
				}
				if didFulfill {
					deck?.updatePublicDataFromSnapshot(snapshot)
				} else {
					didFulfill = true
					deck = .init(snapshot: snapshot)
					seal.fulfill(deck!.cache())
				}
			}
		}
	}
	
	@discardableResult
	func cache() -> Self {
		Self.cache[id] = self
		return self
	}
	
	static func == (lhs: Deck, rhs: Deck) -> Bool {
		lhs.id == rhs.id
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}
