import SwiftUI

struct DecksView: View {
	static let horizontalPadding: CGFloat = 23
	
	@EnvironmentObject var currentStore: CurrentStore
	@EnvironmentObject var model: DecksViewModel
	
	var selectedDeck: Deck {
		currentStore.selectedDeck!
	}
	
	var body: some View {
		GeometryReader { geometry in
			ZStack(alignment: .top) {
				HomeViewTopGradient(
					addedHeight: geometry.safeAreaInsets.top
				)
				.edgesIgnoringSafeArea(.all)
				VStack(spacing: 20) {
					DecksViewTopControls(
						selectedDeck: self.selectedDeck
					)
					.padding(.horizontal, Self.horizontalPadding)
					ScrollView {
						VStack {
							DecksViewSections(
								selectedDeck: self.selectedDeck
							)
						}
						.frame(maxWidth: .infinity)
						.padding(.horizontal, Self.horizontalPadding)
						.padding(.top, 1)
					}
				}
			}
		}
		.onAppear {
			self.selectedDeck.loadSections()
		}
	}
}

#if DEBUG
struct DecksView_Previews: PreviewProvider {
	static var previews: some View {
		DecksView()
			.environmentObject(PREVIEW_CURRENT_STORE)
			.environmentObject(DecksViewModel())
	}
}
#endif
