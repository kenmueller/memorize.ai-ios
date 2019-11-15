import SwiftUI

struct OwnedDeckCellWithPerformanceGraph: View {
	static let defaultWidth: CGFloat = 200
	static let imageAspectRatio: CGFloat = 3 / 5
	
	@EnvironmentObject var currentStore: CurrentStore
	
	@ObservedObject var deck: Deck
	
	let width: CGFloat
	let noCardsDueEmoji: String
	
	init(deck: Deck, width: CGFloat = Self.defaultWidth) {
		self.deck = deck
		self.width = width
		noCardsDueEmoji = [
			"😃",
			"😇",
			"😌",
			"😘",
			"🥳",
			"💪"
		].randomElement()!
	}
	
	var cardsDueMessage: String {
		let count = deck.userData?.numberOfDueCards ?? 0
		return "\(count.formatted) card\(count == 1 ? "" : "s") due"
	}
	
	var body: some View {
		CustomRectangle(
			background: Color.white,
			borderColor: .lightGray,
			borderWidth: 1.5,
			cornerRadius: 8
		) {
			VStack {
				Group {
					if deck.imageLoadingState.didFail {
						ZStack {
							Color.lightGrayBackground
							Image(systemName: .exclamationmarkTriangle)
								.foregroundColor(.gray)
								.scaleEffect(1.5)
						}
					} else if deck.hasImage {
						if deck.image == nil {
							ZStack {
								Color.lightGrayBackground
								ActivityIndicator(color: .gray)
							}
						} else {
							deck.image?
								.resizable()
								.renderingMode(.original)
								.aspectRatio(contentMode: .fill)
								.frame(height: width * Self.imageAspectRatio)
						}
					} else {
						ZStack {
							Color.lightGrayBackground
							Image(systemName: .questionmark)
								.foregroundColor(.gray)
								.scaleEffect(1.5)
						}
					}
				}
				.cornerRadius(8, corners: [.topLeft, .topRight])
				.frame(height: width * Self.imageAspectRatio)
				VStack(alignment: .leading) {
					Text(deck.name)
						.font(.muli(.bold, size: 13.5))
						.foregroundColor(.darkGray)
					Text(deck.subtitle)
						.font(.muli(.regular, size: 11))
						.foregroundColor(.lightGrayText)
						.lineLimit(1)
						.padding(.top, 4)
				}
				.align(to: .leading)
				.padding(.horizontal, 8)
				.padding(.top, 4)
				Rectangle()
					.frame(height: 78)
					.padding(.horizontal, 30)
					.padding(.top, 4)
					.padding(.bottom, 8) // TODO: Change to graph
				HStack {
					if deck.userData?.isDue ?? false {
						Button(action: {
							// TODO: Review deck
						}) {
							CustomRectangle(
								background: Color.extraPurple,
								cornerRadius: 14
							) {
								Text("REVIEW")
									.font(.muli(.bold, size: 12))
									.foregroundColor(.white)
									.frame(width: 92, height: 28)
							}
						}
						Text(cardsDueMessage)
							.font(.muli(.regular, size: 10))
							.foregroundColor(.lightGrayText)
					} else {
						Text(noCardsDueEmoji)
						Text("Woohoo!")
							.font(.muli(.regular, size: 14))
							.foregroundColor(.lightGrayText)
							.padding(.leading, -2)
					}
					Spacer()
				}
				.padding(.horizontal)
				.padding(.bottom, 16)
			}
			.frame(width: width)
		}
		.onTapGesture {
			self.currentStore.selectedDeck = self.deck
			// TODO: Go to decks view with this deck selected
		}
	}
}

#if DEBUG
struct OwnedDeckCellWithPerformanceGraph_Previews: PreviewProvider {
	static var previews: some View {
		VStack(spacing: 30) {
			OwnedDeckCellWithPerformanceGraph(
				deck: PREVIEW_CURRENT_STORE.user.decks[0]
			)
			.environmentObject(PREVIEW_CURRENT_STORE)
			OwnedDeckCellWithPerformanceGraph(
				deck: PREVIEW_CURRENT_STORE.user.decks[1]
			)
			.environmentObject(PREVIEW_CURRENT_STORE)
		}
	}
}
#endif
