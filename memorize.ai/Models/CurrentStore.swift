import Combine
import FirebaseFirestore
import PromiseKit
import LoadingState

final class CurrentStore: ObservableObject {
	@Published var user: User
	@Published var userLoadingState = LoadingState()
	
	@Published var topics: [Topic]
	@Published var topicsLoadingState = LoadingState()
	
	@Published var interestsLoadingState = LoadingState()
	@Published var topicLoadingState = LoadingState()
	
	@Published var recommendedDecks: [Deck]
	@Published var recommendedDecksLoadingState = LoadingState()
	
	@Published var selectedDeck: Deck?
	
	@Published var mainTabViewSelection = MainTabView.Selection.home
	@Published var isSideBarShowing = false
	
	init(user: User, topics: [Topic] = [], recommendedDecks: [Deck] = []) {
		self.user = user
		self.topics = topics
		self.recommendedDecks = recommendedDecks
	}
	
	@discardableResult
	func initializeIfNeeded() -> Self {
		loadUser()
		loadRecommendedDecks()
		user.loadDecks()
		return self
	}
	
	var interests: [Topic?] {
		user.interests.map { topicId in
			topics.first { $0.id == topicId }
		}
	}
	
	@discardableResult
	func loadUser() -> Self {
		guard userLoadingState.isNone else { return self }
		userLoadingState.startLoading()
		firestore.document("users/\(user.id)").addSnapshotListener { snapshot, error in
			guard error == nil, let snapshot = snapshot else {
				self.userLoadingState.fail(error: error ?? UNKNOWN_ERROR)
				return
			}
			self.user.updateFromSnapshot(snapshot)
			self.userLoadingState.succeed()
			self.loadInterests()
		}
		return self
	}
	
	@discardableResult
	func loadTopic(_ topicId: String, loadImage: Bool = true) -> Self {
		if (topics.contains { $0.id == topicId }) { return self }
		topicLoadingState.startLoading()
		Topic.fromId(topicId).done { topic in
			self.topics.append(loadImage ? topic.loadImage() : topic)
			self.topicLoadingState.succeed()
		}.catch { error in
			self.topicLoadingState.fail(error: error)
		}
		return self
	}
	
	@discardableResult
	func loadInterests(loadImages: Bool = true) -> Self {
		guard interestsLoadingState.isNone else { return self }
		interestsLoadingState.startLoading()
		for topicId in user.interests where !(topics.contains { $0.id == topicId }) {
			Topic.fromId(topicId).done { topic in
				self.topics.append(loadImages ? topic.loadImage() : topic)
				self.interestsLoadingState.succeed()
			}.catch { error in
				self.interestsLoadingState.fail(error: error)
			}
		}
		return self
	}
	
	@discardableResult
	func loadAllTopics() -> Self {
		guard topicsLoadingState.isNone else { return self }
		topicsLoadingState.startLoading()
		firestore.collection("topics").addSnapshotListener { snapshot, error in
			guard error == nil, let documentChanges = snapshot?.documentChanges else {
				self.topicsLoadingState.fail(error: error ?? UNKNOWN_ERROR)
				return
			}
			for change in documentChanges {
				let document = change.document
				let topicId = document.documentID
				switch change.type {
				case .added:
					if (self.topics.contains { $0.id == topicId }) { continue }
					self.topics.append(Topic(
						id: topicId,
						name: document.get("name") as? String ?? "Unknown",
						topDecks: document.get("topDecks") as? [String] ?? []
					).loadImage().cache())
				case .modified:
					if (self.topics.contains { $0.id == topicId }) { continue }
					self.topics.first { $0.id == topicId }?
						.updateFromSnapshot(document)
				case .removed:
					self.topics.removeAll { $0.id == topicId }
				}
			}
			self.topics.sort(by: \.name)
			self.topicsLoadingState.succeed()
		}
		return self
	}
	
	@discardableResult
	func loadRecommendedDecks() -> Self {
		guard recommendedDecksLoadingState.isNone else { return self }
		// TODO: Load recommended decks
		recommendedDecksLoadingState.startLoading()
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
			self.recommendedDecks = [
				.init(
					id: "0",
					topics: [],
					hasImage: true,
					image: .init("GeometryPrepDeck"),
					name: "Geometry Prep #1",
					subtitle: "Angles, lines, triangles and other polygons",
					numberOfViews: 1000000000,
					numberOfUniqueViews: 200000,
					numberOfRatings: 12400,
					averageRating: 4.5,
					numberOfDownloads: 196400,
					dateCreated: .init(),
					dateLastUpdated: .init(),
					userData: .init(
						dateAdded: .init(),
						isFavorite: false,
						numberOfDueCards: 23
					)
				),
				.init(
					id: "1",
					topics: [],
					hasImage: true,
					image: .init("GeometryPrepDeck"),
					name: "Geometry Prep #2",
					subtitle: "Angles, lines, triangles and other polygons",
					numberOfViews: 1000000000,
					numberOfUniqueViews: 200000,
					numberOfRatings: 12400,
					averageRating: 4.5,
					numberOfDownloads: 196400,
					dateCreated: .init(),
					dateLastUpdated: .init(),
					userData: .init(
						dateAdded: .init(),
						isFavorite: true,
						numberOfDueCards: 0
					)
				),
				.init(
					id: "2",
					topics: [],
					hasImage: true,
					image: .init("GeometryPrepDeck"),
					name: "Geometry Prep #3",
					subtitle: "Angles, lines, triangles and other polygons",
					numberOfViews: 1000000000,
					numberOfUniqueViews: 200000,
					numberOfRatings: 12400,
					averageRating: 4.5,
					numberOfDownloads: 196400,
					dateCreated: .init(),
					dateLastUpdated: .init()
				),
				.init(
					id: "3",
					topics: [],
					hasImage: true,
					image: .init("GeometryPrepDeck"),
					name: "Geometry Prep #4",
					subtitle: "Angles, lines, triangles and other polygons",
					numberOfViews: 1000000000,
					numberOfUniqueViews: 200000,
					numberOfRatings: 12400,
					averageRating: 4.5,
					numberOfDownloads: 196400,
					dateCreated: .init(),
					dateLastUpdated: .init(),
					userData: .init(
						dateAdded: .init(),
						isFavorite: true,
						numberOfDueCards: 36
					)
				),
				.init(
					id: "4",
					topics: [],
					hasImage: false,
					name: "Geometry Prep #5",
					subtitle: "Angles, lines, triangles and other polygons",
					numberOfViews: 1000000000,
					numberOfUniqueViews: 200000,
					numberOfRatings: 12400,
					averageRating: 4.5,
					numberOfDownloads: 196400,
					dateCreated: .init(),
					dateLastUpdated: .init(),
					userData: .init(
						dateAdded: .init(),
						isFavorite: false,
						numberOfDueCards: 568
					)
				),
				.init(
					id: "5",
					topics: [],
					hasImage: true,
					name: "Geometry Prep #6",
					subtitle: "Angles, lines, triangles and other polygons",
					numberOfViews: 1000000000,
					numberOfUniqueViews: 200000,
					numberOfRatings: 12400,
					averageRating: 4.5,
					numberOfDownloads: 196400,
					dateCreated: .init(),
					dateLastUpdated: .init(),
					userData: .init(
						dateAdded: .init(),
						isFavorite: true,
						numberOfDueCards: 1
					)
				)
			]
			self.recommendedDecksLoadingState.succeed()
		}
		return self
	}
}
