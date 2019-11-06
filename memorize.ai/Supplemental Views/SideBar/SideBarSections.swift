import SwiftUI

struct SideBarSections: View {
	@ObservedObject var currentUser: User
	
	@Binding var selectedDeck: Deck?
	
	var searchText: String
	
	func normalizeText(_ text: String) -> String {
		text
			.lowercased()
			.replacingOccurrences(of: " ", with: "")
	}
	
	func sortByNumberOfDueCards(_ decks: [Deck]) -> [Deck] {
		decks.sorted {
			$0.userData?.numberOfDueCards ?? 0 >
			$1.userData?.numberOfDueCards ?? 0
		}
	}
	
	func filterForSearchText(_ decks: [Deck]) -> [Deck] {
		searchText.isTrimmedEmpty
			? decks
			: decks.filter { deck in
				normalizeText(deck.name)
					.contains(normalizeText(searchText))
			}
	}
	
	var dueDecks: [Deck] {
		sortByNumberOfDueCards(filterForSearchText(
			currentUser.dueDecks
		))
	}
	
	var favoriteDecks: [Deck] {
		sortByNumberOfDueCards(filterForSearchText(
			currentUser.favoriteDecks
		))
	}
	
	var allDecks: [Deck] {
		sortByNumberOfDueCards(filterForSearchText(
			currentUser.decks
		))
	}
	
	var body: some View {
		VStack {
			if !dueDecks.isEmpty {
				SideBarSection(
					title: "Due",
					decks: dueDecks,
					selectedDeck: $selectedDeck
				)
				SideBarSectionDivider()
			}
			if !favoriteDecks.isEmpty {
				SideBarSection(
					title: "Favorites",
					decks: favoriteDecks,
					selectedDeck: $selectedDeck
				)
				SideBarSectionDivider()
			}
			if !allDecks.isEmpty {
				SideBarSection(
					title: "All",
					decks: allDecks,
					selectedDeck: $selectedDeck
				)
			}
		}
	}
}

#if DEBUG
struct SideBarSections_Previews: PreviewProvider {
	static var previews: some View {
		SideBarSections(
			currentUser: .init(
				id: "0",
				name: "Ken Mueller",
				email: "kenmueller0@gmail.com",
				interests: [],
				numberOfDecks: 0
			),
			selectedDeck: .constant(nil),
			searchText: ""
		)
	}
}
#endif
