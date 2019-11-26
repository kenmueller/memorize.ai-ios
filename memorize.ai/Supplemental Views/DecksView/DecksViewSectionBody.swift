import SwiftUI

struct DecksViewSectionBody: View {
	@EnvironmentObject var model: DecksViewModel
	
	@ObservedObject var section: Deck.Section
	
	var body: some View {
		VStack(spacing: 8) {
			ForEach(section.cards) { card in
				DecksViewCardCell(card: card)
			}
		}
	}
}

#if DEBUG
struct DecksViewSectionBody_Previews: PreviewProvider {
	static var previews: some View {
		DecksViewSectionBody(section: .init(
			id: "0",
			parent: PREVIEW_CURRENT_STORE.user.decks.first!,
			name: "CSS",
			numberOfCards: 56,
			cards: [
				.init(
					id: "0",
					sectionId: "CSS",
					front: "This is the front of the card",
					back: "This is the back of the card",
					numberOfViews: 670,
					numberOfSkips: 40,
					userData: .init(dueDate: .init())
				),
				.init(
					id: "1",
					sectionId: "CSS",
					front: "This is the front of the second card",
					back: "This is the back of the second card",
					numberOfViews: 670,
					numberOfSkips: 40,
					userData: .init(dueDate: .init())
				)
			]
		))
		.padding(.horizontal, DecksView.horizontalPadding)
		.environmentObject(DecksViewModel())
	}
}
#endif