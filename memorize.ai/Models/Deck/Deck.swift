import SwiftUI
import FirebaseFirestore
import PromiseKit

final class Deck: ObservableObject, Identifiable, Equatable {
	let id: String
	
	@Published var image: Image?
	@Published var name: String
	@Published var subtitle: String
	@Published var numberOfViews: Int
	@Published var numberOfUniqueViews: Int
	@Published var numberOfRatings: Int
	@Published var averageRating: Double
	@Published var numberOfDownloads: Int
	
	@Published var imageLoadingState = LoadingState.none
	
	init(
		id: String,
		image: Image? = nil,
		name: String,
		subtitle: String,
		numberOfViews: Int,
		numberOfUniqueViews: Int,
		numberOfRatings: Int,
		averageRating: Double,
		numberOfDownloads: Int
	) {
		self.id = id
		self.image = image
		self.name = name
		self.subtitle = subtitle
		self.numberOfViews = numberOfViews
		self.numberOfUniqueViews = numberOfUniqueViews
		self.numberOfRatings = numberOfRatings
		self.averageRating = averageRating
		self.numberOfDownloads = numberOfDownloads
	}
	
	@discardableResult
	func loadImage() -> Self {
		imageLoadingState = .loading()
		storage.child("decks/\(id)").getData().done { data in
			guard let image = Image(data: data) else {
				return self.imageLoadingState = .failure(
					message: "Malformed data"
				)
			}
			self.image = image
			self.imageLoadingState = .success()
		}.catch { error in
			self.imageLoadingState = .failure(
				message: error.localizedDescription
			)
		}
		return self
	}
	
	@discardableResult
	func updatePublicDataFromSnapshot(_ snapshot: DocumentSnapshot) -> Self {
		name = snapshot.get("name") as? String ?? name
		return self
	}
	
	static func fromId(_ id: String) -> Promise<Deck> {
		var didFulfill = false
		var deck: Deck?
		return .init { seal in
			firestore.document("decks/\(id)").addSnapshotListener { snapshot, error in
				guard error == nil, let snapshot = snapshot else {
					return seal.reject(error ?? UNKNOWN_ERROR)
				}
				if didFulfill {
					deck?.updatePublicDataFromSnapshot(snapshot)
				} else {
					didFulfill = true
					deck = Deck(
						id: id,
						name: snapshot.get("name") as? String ?? "Unknown",
						subtitle: snapshot.get("subtitle") as? String ?? "(empty)",
						numberOfViews: snapshot.get("viewCount") as? Int ?? 0,
						numberOfUniqueViews: snapshot.get("uniqueViewCount") as? Int ?? 0,
						numberOfRatings: snapshot.get("ratingCount") as? Int ?? 0,
						averageRating: snapshot.get("averageRating") as? Double ?? 0,
						numberOfDownloads: snapshot.get("downloadCount") as? Int ?? 0
					)
					seal.fulfill(deck!)
				}
			}
		}
	}
	
	static func == (lhs: Deck, rhs: Deck) -> Bool {
		lhs.id == rhs.id
	}
}