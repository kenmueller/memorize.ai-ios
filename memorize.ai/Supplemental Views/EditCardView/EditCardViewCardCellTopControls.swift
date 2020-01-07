import SwiftUI

struct EditCardViewCardCellTopControls: View {
	@Environment(\.presentationMode) var presentationMode
	
	@ObservedObject var card: Card.Draft
	
	var body: some View {
		HStack {
			Spacer()
			if card.publishLoadingState.isLoading {
				ActivityIndicator(color: .white)
			} else {
				Button(action: {
					self.card.showDeleteAlert {
						self.presentationMode.wrappedValue.dismiss()
					}
				}) {
					Image.whiteTrashIcon
						.resizable()
						.renderingMode(.original)
						.aspectRatio(contentMode: .fit)
						.frame(height: 17)
				}
			}
		}
	}
}

#if DEBUG
struct EditCardViewCardCellTopControls_Previews: PreviewProvider {
	static var previews: some View {
		EditCardViewCardCellTopControls(card: .init(
			parent: PREVIEW_CURRENT_STORE.user.decks.first!
		))
	}
}
#endif