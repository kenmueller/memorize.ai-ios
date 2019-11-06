import SwiftUI

struct SideBarDeckRow: View {
	@ObservedObject var deck: Deck
	
	var body: some View {
		HStack {
			Group {
				if deck.imageLoadingState.didFail {
					Image(systemName: .exclamationmarkTriangle)
						.foregroundColor(.gray)
						.scaleEffect(1.5)
				} else if deck.hasImage {
					if deck.image == nil {
						ActivityIndicator(color: .gray)
					} else {
						deck.image?
							.resizable()
							.renderingMode(.original)
							.aspectRatio(contentMode: .fill)
					}
				} else {
					Image(systemName: .questionmark)
						.foregroundColor(.gray)
						.scaleEffect(1.5)
				}
			}
			.frame(width: 40, height: 40)
			.clipShape(Circle())
			Text(deck.name)
		}
	}
}

#if DEBUG
struct SideBarDeckRow_Previews: PreviewProvider {
	static var previews: some View {
		SideBarDeckRow(deck: .init(
			id: "0",
			topics: [],
			hasImage: true,
			image: .init("GeometryPrepDeck"),
			name: "Geometry Prep",
			subtitle: "Angles, lines, triangles and other polygons",
			numberOfViews: 1000000000,
			numberOfUniqueViews: 200000,
			numberOfRatings: 12400,
			averageRating: 4.5,
			numberOfDownloads: 196400,
			dateCreated: .init(),
			dateLastUpdated: .init()
		))
	}
}
#endif
