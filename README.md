<a id="readme-top"></a>

# 💪 FinApp — Personal Health & Fitness Tracker

FinApp started as a simple gym tracker and has grown into a full **personal fitness companion**.  
I began this project with **zero Swift experience**, a lot of **Googling**, and **ChatGPT**, and built it into a full HealthKit-powered tracker.

---

## 🧭 About the Project

FinApp helps you log workouts, track strength progression, record cardio sessions, monitor sleep, view steps, and track daily health metrics from Apple Health.

It’s designed to be:
- **Fast** (minimal typing)
- **Friendly** (clean UI)
- **Personal** (your goals, your data)
- **Apple-native** (SwiftUI + HealthKit + Widgets)

---

## 🧑‍💻 Tech Stack

- **Language:** Swift  
- **Framework:** SwiftUI  
- **Storage:** UserDefaults *(future: Core Data / CloudKit)*  
- **APIs:** Apple HealthKit  
- **Extras:** WidgetKit, ActivityKit  
- **IDE:** Xcode  

---

## 📱 Current Features

### 🏋️ Strength Workouts
- Multi-exercise workouts  
- Sets, reps, weight, RPE  
- **Exercise suggestions**  
- **Auto-fill last session’s sets**  
- **Copy all sets** for fast repeat workouts  
- Inline category auto-fill  
- Exercise editor with warmups / backoff sets  
- Workout summaries with volume, sets, duration  

**Screenshots:**  
![Workouts](images/workouts.png)  
![Exercise Editor](images/exercise-editor.png)

---

### 🏃 Cardio Tracking
- Track runs, rows, cycles, HIIT, walks  
- Distance, pace, heart rate, calories  
- **PR detection** (fastest pace, longest run, best hour)  
- PR badges + “New PR!” popup  
- Session history with sorting  

**Screenshots:**  
![Cardio](images/cardio.png)  
![PRs](images/prs.png)

---

### 📊 Trends & Insights
- Weekly trends for steps, sleep, resting HR, weight  
- Strength progression charts *(coming)*  
- PR history for running  
- Personal records for distance & pace  
- Health tiles refreshed daily via HealthKit  

**Screenshot:**  
![Trends](images/trends.png)

---

### 😴 Health Dashboard
- Sleep duration (noon-anchored for watch accuracy)  
- Sleep stage breakdown (REM, Deep, Core)  
- Resting heart rate  
- Steps today  
- Weight (from HealthKit)  
- Daily sync & automatic widget updates  

---

### ⏱️ Rest Timer
- Minimal full-screen timer  
- Haptic countdown  
- Optional beep sounds  
- Perfect for between sets  
- Future: Live Activity  

---

### 🧱 Widgets
- Dashboard snapshot  
- Steps, sleep, HR, weight  
- Weekly rings  
- Quick access to FinApp  
- iPhone home screen & Lock Screen support  

**Screenshot:**  
![Widgets](images/widgets.png)

---

## 🛣️ Roadmap

### Strength
- [x] Multi-exercise workflows  
- [x] Autofill from last session  
- [x] Exercise library  
- [ ] Super sets  
- [ ] Warm-up templates  
- [ ] Strength PR system  
- [ ] 1RM estimation  
- [ ] Exercise Images  

### Cardio
- [x] Run logging  
- [x] PR detection  
- [ ] Import runs from HealthKit  
- [ ] Pace zones  
- [ ] Heart rate graphs  
- [ ] Auto-categorised sessions  

### Health
- [x] Sleep tracking  
- [x] RHR / Steps / Weight  
- [ ] Hydration tracking  
- [ ] Mood tracking  
- [ ] Nightly notes / Sleep efficiency  

### App-Wide
- [x] Widgets  
- [ ] Apple Watch app  
- [ ] CloudKit sync  
- [ ] Achievement system ("trophies")  
- [ ] Streak system  
- [ ] "Coach Mode"  
- [ ] AI: auto-generate workouts, analyse trends  

---

## 📦 Versions

### **v1.5 – Strength Expansion & Cardio PR System (current)**
- Exercise suggestions  
- Autofill last sets  
- Copy-all-sets  
- Full exercise editor rewrite  
- Cardio PR dropdown + detail screen  
- Cardio history sorting  
- “New PR!” modal  
- Trends placeholders  
- Workout detail redesign (streaks coming)

### **v1.4 – Widgets**
- Today widget + dashboard  
- Weekly rings widget  
- Background sync  
- Fake-data testing support

### **v1.3 – Sleep & Settings**
- Fixed sleep accuracy  
- Noon-anchored sleep analysis  
- Settings toggle screen  
- Workout UI improvements

### **v1.2 – HealthKit Integration**
- Sync steps, sleep, RHR, weight  
- Daily health entry model  
- Dashboard updates

### **v1.1 – Timer**
- Full-screen rest timer  
- Haptics & beep option

### **v1.0 – Workouts & Goals**
- First version  
- Add workouts, exercises, reps, sets  
- Goals screen

---

[Back to top ↑](#readme-top)

---
