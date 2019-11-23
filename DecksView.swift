import SwiftUI

struct DecksView: View {
	@EnvironmentObject var currentStore: CurrentStore
	
	var body: some View {
		GeometryReader { geometry in
			ZStack(alignment: .top) {
				HomeViewTopGradient(
					addedHeight: geometry.safeAreaInsets.top
				)
				.edgesIgnoringSafeArea(.all)
				VStack(spacing: 20) {
					DecksViewTopControls()
						.padding(.horizontal, 23)
					ScrollView {
						EmptyView() // TODO: Replace with content
					}
				}
			}
		}
	}
}

#if DEBUG
struct DecksView_Previews: PreviewProvider {
	static var previews: some View {
		DecksView()
			.environmentObject(PREVIEW_CURRENT_STORE)
	}
}
#endif
