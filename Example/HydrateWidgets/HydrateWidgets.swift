import SwiftUI
import WidgetKit

/// The widget extension of the fictional Hydrate water tracker. Both widgets support every accessory family, so
/// they can be added to any complication slot of a watch face and to the Smart Stack.
@main
struct HydrateWidgetBundle: WidgetBundle {
    var body: some Widget {
        HydrateProgressWidget()
        HydrateReminderWidget()
    }
}
