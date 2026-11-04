import UIKit
import Capacitor

/// Registers the app's own native plugins. Set as the custom class of the
/// Bridge View Controller in Main.storyboard (Module: App).
class AppViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(HealthWorkoutPlugin())
    }
}
