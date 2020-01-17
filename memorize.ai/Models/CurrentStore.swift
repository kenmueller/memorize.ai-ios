import SwiftUI
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
	
	@Published var signOutLoadingState = LoadingState()
	
	@Published var selectedDeck: Deck?
	
	@Published var mainTabViewSelection = MainTabView.Selection.home
	@Published var isSideBarShowing = false
	
	init(user: User, topics: [Topic] = [], recommendedDecks: [Deck] = []) {
		self.user = user
		self.topics = topics
		self.recommendedDecks = recommendedDecks
		
		initializeUser()
	}
	
	func initializeUser() {
		user.setOnDecksChange { decks in
			if decks.isEmpty && self.mainTabViewSelection == .decks {
				self.mainTabViewSelection = .home
			}
		}
	}
	
	var interests: [Topic?] {
		user.interests.map { topicId in
			topics.first { $0.id == topicId }
		}
	}
	
	@discardableResult
	func initializeIfNeeded() -> Self {
		loadUser()
		loadAllTopics(withImages: false)
		user.loadDecks {
			self.selectedDeck = $0
		}
		return self
	}
	
	@discardableResult
	func goToDecksView(withDeck deck: Deck) -> Self {
		withAnimation(SIDE_BAR_ANIMATION) {
			selectedDeck = deck.loadSections()
			isSideBarShowing = false
			mainTabViewSelection = .decks
		}
		return self
	}
	
	@discardableResult
	func reloadSelectedDeck() -> Self {
		selectedDeck = user.decks.first
		if selectedDeck == nil && mainTabViewSelection == .decks {
			mainTabViewSelection = .home
		}
		return self
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
			for topicId in self.user.interests {
				self.topics.first { $0.id == topicId }?.loadImage()
			}
			self.loadRecommendedDecks()
		}
		return self
	}
	
	@discardableResult
	func signOut() -> Self {
		if let error = auth.signOutWithError() {
			signOutLoadingState.fail(error: error)
		} else {
			signOutLoadingState.succeed()
		}
		return self
	}
	
	@discardableResult
	func loadAllTopics(withImages loadImages: Bool = true) -> Self {
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
					let topic = Topic(
						id: topicId,
						name: document.get("name") as? String ?? "Unknown"
					)
					if loadImages || self.user.interests.contains(topicId) {
						topic.loadImage()
					}
					self.topics.append(topic.cache())
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
		recommendedDecksLoadingState.startLoading()
		user.recommendedDecks().done { decks in
			self.recommendedDecks = decks
			self.recommendedDecksLoadingState.succeed()
		}.catch { error in
			self.recommendedDecksLoadingState.fail(error: error)
		}
		return self
	}
}
