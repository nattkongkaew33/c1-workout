# Native iOS add-on: save workouts to Apple Health

`HealthWorkoutPlugin.swift` is a small Capacitor plugin (JS name `HealthWorkout`) that saves a finished
session as a **Traditional Strength Training** workout in Apple Health (start/end time, estimated
active calories, title). `AppViewController.swift` registers it with the app.

These files are not used by the website. Copy them into the Xcode project in `c1-ios/` once.

## One-time setup in Xcode (on the MacBook)

1. Open `c1-ios/ios/App/App.xcworkspace`.
2. Drag `HealthWorkoutPlugin.swift` and `AppViewController.swift` into the **App** folder (next to
   `AppDelegate.swift`). Tick **Copy items if needed** and target **App**.
3. Open `Main.storyboard`, select **Bridge View Controller**, then in the Identity inspector set
   **Class** to `AppViewController` and **Module** to `App` (untick "Inherit Module From Target" if it's greyed out,
   then pick App).
4. Open `Info.plist` and add **Privacy - Health Update Usage Description**
   (`NSHealthUpdateUsageDescription`), e.g. "C1 Workout saves your finished workouts to Apple Health."
   (The HealthKit capability and the Health Share description are already there for weight/steps.)
5. Press ▶ to build onto the iPhone.

The first time you finish a workout, iOS asks for permission to write **Workouts** and
**Active Energy**. Tap **Turn On All** → **Allow**.

If you ever deny it: Health app → profile → Apps → C1 Workout → turn on Workouts.
