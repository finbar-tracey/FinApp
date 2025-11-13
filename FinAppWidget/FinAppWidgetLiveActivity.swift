//
//  FinAppWidgetLiveActivity.swift
//  FinAppWidget
//
//  Created by Finbar Tracey on 13/11/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FinAppWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FinAppWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FinAppWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension FinAppWidgetAttributes {
    fileprivate static var preview: FinAppWidgetAttributes {
        FinAppWidgetAttributes(name: "World")
    }
}

extension FinAppWidgetAttributes.ContentState {
    fileprivate static var smiley: FinAppWidgetAttributes.ContentState {
        FinAppWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FinAppWidgetAttributes.ContentState {
         FinAppWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FinAppWidgetAttributes.preview) {
   FinAppWidgetLiveActivity()
} contentStates: {
    FinAppWidgetAttributes.ContentState.smiley
    FinAppWidgetAttributes.ContentState.starEyes
}
