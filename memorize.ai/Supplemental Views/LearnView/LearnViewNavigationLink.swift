import SwiftUI

struct LearnViewNavigationLink<Label: View>: View {
	@EnvironmentObject var currentStore: CurrentStore
	
	let deck: Deck
	let section: Deck.Section?
	let label: Label
	
	init(
		deck: Deck,
		section: Deck.Section? = nil,
		label: () -> Label
	) {
		self.deck = deck
		self.section = section
		self.label = label()
	}
	
	var body: some View {
		NavigationLink(
			destination: LearnView()
				.environmentObject(currentStore)
				.environmentObject(LearnViewModel(
					deck: deck,
					section: section
				))
		) {
			label
		}
	}
}

#if DEBUG
struct LearnViewNavigationLink_Previews: PreviewProvider {
	static var previews: some View {
		LearnViewNavigationLink(
			deck: PREVIEW_CURRENT_STORE.user.decks.first!
		) {
			Text("Learn")
		}
		.environmentObject(PREVIEW_CURRENT_STORE)
	}
}
#endif