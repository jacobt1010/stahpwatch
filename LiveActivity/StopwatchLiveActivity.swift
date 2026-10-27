import SwiftUI
import WidgetKit

// Placeholder until the Live Activity checklist item.
struct StopwatchLiveActivity: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "placeholder", provider: Provider()) { _ in EmptyView() }
    }
    struct Provider: TimelineProvider {
        func placeholder(in context: Context) -> SimpleEntry { SimpleEntry(date: .now) }
        func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) { completion(SimpleEntry(date: .now)) }
        func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
            completion(Timeline(entries: [SimpleEntry(date: .now)], policy: .never))
        }
    }
    struct SimpleEntry: TimelineEntry { let date: Date }
}
