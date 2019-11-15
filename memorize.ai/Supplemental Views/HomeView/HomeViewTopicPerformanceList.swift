import SwiftUI

struct HomeViewTopicPerformanceList: View {
	static let cellDimension: CGFloat = 72
	
	@EnvironmentObject var currentStore: CurrentStore
	
	@State var shouldShowTopicPerformance = false
	@State var selectedTopic: Topic!
	
	func topicCell(forTopic topic: Topic) -> some View {
		Button(action: {
			self.shouldShowTopicPerformance = true
			self.selectedTopic = topic
		}) {
			BasicTopicCell(
				topic: topic,
				dimension: Self.cellDimension
			)
		}
		.sheet(isPresented: $shouldShowTopicPerformance) {
			TopicPerformanceSheetView(
				currentUser: self.currentStore.user,
				topic: self.selectedTopic
			)
			.environmentObject(self.currentStore)
		}
	}
	
	var interests: some View {
		ForEach(currentStore.interests, id: \.self) { topic in
			Group {
				if topic == nil {
					LoadingTopicCell(
						dimension: Self.cellDimension
					)
				} else {
					self.topicCell(forTopic: topic!)
				}
			}
		}
	}
	
	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack {
				interests
			}
			.padding(.horizontal)
		}
	}
}

#if DEBUG
struct HomeViewTopicPerformanceList_Previews: PreviewProvider {
	static var previews: some View {
		HomeViewTopicPerformanceList()
			.environmentObject(PREVIEW_CURRENT_STORE)
	}
}
#endif
