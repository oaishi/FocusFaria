# FocusFaria 📵✨

A free iPhone app that nudges you off Instagram, TikTok and YouTube with your own to-dos.

It does three things:

1. **To-Dos** – type what you need to do, tap to tick off, swipe left to delete, swipe right to edit.
2. **Tracked Time** – how long you spent in your scrolling apps (Instagram, TikTok, YouTube…), per app and per hour, today and yesterday.
3. **Nudges** – after every 10 minutes (adjustable) in those apps you get a notification that either picks one of your unfinished to-dos —
   *"Sam, don't waste time scrolling 📵 — Have you done this? 👉 Finish the report"* (with your own name) —
   or a motivation quote.

**Costs nothing.** No paid Apple Developer account needed. It uses Apple's free **Shortcuts** app to know when you open and close your scrolling apps.

> 💻 **Don't have a Mac?** Skip to [Option B](#option-b--no-mac-needed-shortcuts-only) at the bottom. It does the same three things with only built-in iPhone apps.

---

## Option A — install the app with a free Apple ID (needs a Mac)

### What you need
- A **Mac** with **Xcode** (free in the Mac App Store).
- Your **iPhone** (iOS 16 or newer; iOS 17+ recommended) and its cable.
- Your normal **Apple ID**. That's it, no payment.

### Install (about 10 minutes)
1. Unzip this folder and double-click **`FariaFocus.xcodeproj`**.
2. Open **`Config.xcconfig`** (left sidebar) and change `com.faria.focus` to something unique, e.g. `com.fariasmith2026.focus`.
3. Xcode menu **Xcode › Settings › Accounts** → **+** → **Apple ID** → sign in.
4. Click the blue **FariaFocus** project icon (top of sidebar) → target **FariaFocus** → **Signing & Capabilities** → tick **Automatically manage signing** → **Team**: choose *“Your Name (Personal Team)”*.
5. Plug in your iPhone, unlock it, tap **Trust This Computer**. Choose your iPhone at the top of Xcode (next to ▶).
6. On the iPhone: **Settings › Privacy & Security › Developer Mode → On** (it restarts).
7. Press **▶ Run** in Xcode.
8. If the iPhone says *“Untrusted Developer”*: **Settings › General › VPN & Device Management** → tap your Apple ID → **Trust**. Press ▶ again.

### ⚠️ The one catch with a free account: re-install every 7 days
Apps installed with a free Apple ID stop opening after **7 days**. When that happens, plug the phone into the Mac and press **▶ Run** again (1 minute). **Your to-dos and history are kept.**
(Tip: set a weekly reminder. If the app has expired, the automations below fail silently until you re-run it.)

### Set up tracking + nudges (one time, ~3 minutes)
The app walks you through this step by step with pictures on first launch (and any time from **Nudges tab › Set up app tracking**). On first launch it also asks your name, which is used in the nudges. You can change it in the Nudges tab.

**Automation 1, app opened**
1. Open **Shortcuts** → **Automation** tab → **+** / **New Automation** → **App**.
2. **Choose** your scrolling apps (Instagram, TikTok, YouTube…) → **Done**.
3. Tick **Is Opened** (not Is Closed) → **Run Immediately** → turn off *Notify When Run* → **Next**.
4. **New Blank Automation** → **Add Action** → search **Scrolling** → **Scrolling App Opened** → **Done**.

**Automation 2, app closed**
5. **+** → **App** → the **same apps** → tick **Is Closed** only → **Run Immediately** → **Next**.
6. **New Blank Automation** → add **Scrolling App Closed** → **Done**.

**Check it:** open Instagram, come back to FocusFaria → **Nudges** tab → *Last signal from Shortcuts* should say *“… opened”*. For a quick test set **Nudge every → 1 minute**, stay in the app a minute, then wait for your nudge. Set it back to 10 afterwards.

**Optional, time per app:** in each automation tap the blue **Social apps** word and type the app name (e.g. *Instagram*). Make one Opened + one Closed automation per app, and the Tracked Time tab will list each app separately.

### How it behaves
- The minutes **add up when you hop between your chosen apps** (Instagram → TikTok) and continue if you come back within 90 seconds.
- Every 10 minutes you keep going, you get another nudge. Leaving the app cancels the waiting nudge.
- **Whole-phone screen time**: your iPhone already tracks every app for free in **Settings › Screen Time › See All App & Website Activity**. FocusFaria tracks the apps you connected, and the nudges come from there.
- One thing to check on your phone: lock the screen while you're in Instagram, then look at *Last signal* when you come back. I'm not sure whether iOS reports that as “closed”. If it doesn't, you may get a nudge while the phone is locked. Tell me and I'll adjust it.

### Customise
| Want to… | Change… |
|---|---|
| Edit the quotes | `FariaFocus/NudgeScheduler.swift` → `quotes` |
| Change the notification wording | `NudgeScheduler.swift` → `makeContent` |
| Change the 90-second "continue" window | `FariaFocus/ScrollTracker.swift` → `continueWindow` |

### Troubleshooting
| Problem | Fix |
|---|---|
| *“Failed to register bundle identifier”* / *“not available”* | Change the ID in `Config.xcconfig` to something more unique, then re-pick your Team. |
| *“Your maximum App ID limit has been reached”* | Free accounts can create 10 app IDs a week. Wait a few days, or reuse the same ID. |
| *“Unable to launch … could not be verified”* | Do step 8 (Trust) above. |
| App won't open after a week | Normal for free accounts. Plug in and press ▶ Run again. |
| No “Scrolling App …” actions in Shortcuts | Open the app once after installing, then search again in Shortcuts. |
| No nudges | Nudges toggle on? Notifications allowed? Focus/Do Not Disturb off? Does *Last signal* update when you open Instagram? |
| Project won't open | `brew install xcodegen`, then run `xcodegen` in this folder. It rebuilds the project from `project.yml`. |

---

## Option B — no Mac needed (Shortcuts only)

This uses only apps already on your iPhone. Nothing to install, and it never expires.

| Feature | How |
|---|---|
| **1. To-dos** | In **Reminders**, create a list called **Faria Todos** and add your to-dos there. |
| **2. Tracking** | **Settings › Screen Time** (turn on if needed) → **See All App & Website Activity**. It shows every app and how long you used it. |
| **3. Nudges** | Two Shortcuts automations (below) that use a reminder as a 10-minute timer with your message. |

First, in **Reminders**, also create an empty list called **Faria Nudges**.

**Automation 1, when a scrolling app opens**
1. **Shortcuts › Automation › + › App** → choose your scrolling apps → **Is Opened** → **Run Immediately** → **Next** → **New Blank Automation**.
2. Add these actions in order:
   1. **Find Reminders**, *where* **List is Faria Todos** and **Is Not Completed**. Sort by **Random**, turn on **Limit**, **Get 1 Reminder**.
   2. **Text**: `<Your name>, don't waste time scrolling 📵 Have you done this? 👉 ` then tap and insert the **Reminders** variable.
   3. **Adjust Date**: **Add 10 minutes** to **Current Date**.
   4. **Add New Reminder**: title = the **Text** from step 2, list = **Faria Nudges**, turn on the **alert** and set its time to the **Adjusted Date**.
   *(For motivation quotes instead: use a **List** action with your quotes + **Get Random Item from List**, and put that in the Text.)*

**Automation 2, when the app closes (cancels the nudge)**
1. **+ › App** → same apps → **Is Closed** → **Run Immediately** → **New Blank Automation**.
2. Add **Find Reminders** where **List is Faria Nudges** and **Is Not Completed** → then **Remove Reminders**.

If you stay in the app for 10 minutes, the reminder pops up with your message. If you leave sooner, it's deleted before it fires.

> I couldn't try Option B on an actual iPhone. If **Remove Reminders** asks *“Remove?”* every time, replace it with **Edit Reminder → Is Completed: On** (completed reminders don't alert). Tell me which iOS version you're on and I'll adjust the steps.

---

## Files (Option A)
```
FariaFocus/
  FariaFocusApp.swift      app start
  ContentView.swift        the 3 tabs
  TodoStore / TodoListView     to-dos
  UsageStore / ScreenTimeView  tracked time
  NudgeSettingsView / SetupGuideView   nudge settings + in-app setup guide
  AppIntents.swift         the two actions Shortcuts uses
  ScrollTracker.swift      timing logic (adds up across apps, ignores app-switch blips)
  NudgeScheduler.swift     messages, quotes, notifications
  Storage.swift            saves everything on the phone
Config.xcconfig            your app ID
project.yml                backup recipe to regenerate the Xcode project
```
