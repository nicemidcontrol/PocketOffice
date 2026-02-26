# 🏢 Pocket Office — Game Scaffold

> A Kairosoft-inspired 2D pixel art corporate simulation game for iOS & Android  
> Built with **Unity 2D (LTS)** · **C#** · Portrait Mode

---

## 📁 Folder Structure

```
PocketOffice/
├── Assets/
│   ├── Scripts/
│   │   ├── Core/
│   │   │   ├── GameManager.cs          ← Central game loop, time, tier upgrades
│   │   │   ├── EmployeeManager.cs      ← Hire/fire, salary totals, motivation ticks
│   │   │   └── SaveSystem.cs           ← JSON save/load to persistentDataPath
│   │   ├── Employees/
│   │   │   └── Employee.cs             ← Employee data model, stats, leveling
│   │   ├── Office/
│   │   │   └── OfficeManager.cs        ← Grid tiles, floors, room buffs, rent
│   │   ├── Projects/
│   │   │   └── ProjectManager.cs       ← Client projects, assignment, deadlines
│   │   ├── Events/
│   │   │   └── EventManager.cs         ← Corporate random events, choices
│   │   ├── Economy/
│   │   │   └── EconomyManager.cs       ← Cash, revenue, costs, loans, ledger
│   │   ├── UI/                         ← (To build: HUD, panels, popups)
│   │   ├── Data/                       ← ScriptableObjects for static game data
│   │   └── Utils/
│   │       └── SaveSystem.cs
│   ├── Data/
│   │   └── projects_data.json          ← Project templates, room configs, tier data
│   ├── Scenes/
│   │   ├── MainMenu.unity
│   │   ├── GameScene.unity
│   │   └── TransitionScene.unity
│   ├── Sprites/                        ← 16x16 / 32x32 pixel art assets
│   │   ├── Employees/
│   │   ├── Rooms/
│   │   ├── UI/
│   │   └── Icons/
│   ├── Audio/
│   │   ├── BGM/
│   │   └── SFX/
│   └── Resources/                      ← Assets loaded via Resources.Load()
└── Packages/
    └── manifest.json
```

---

## 🏗️ Architecture Overview

```
GameManager (MonoBehaviour Singleton)
    ├── EconomyManager     — Cash, revenue, expenses, loans
    ├── EmployeeManager    — Hire/fire, motivation, salary
    ├── ProjectManager     — Client work, deadlines, rewards
    ├── EventManager       — Random corporate events + choices
    └── OfficeManager      — Grid tiles, floors, room buffs
```

All managers are attached to the same **GameManager GameObject** via `AddComponent<>()`.

Static events (`Action<T>`) power loose coupling between systems and UI.

---

## 🔗 Key Event Bus (Static Events)

| Event | When Fired | Payload |
|---|---|---|
| `GameManager.OnDayPassed` | Every in-game day | `int day` |
| `GameManager.OnMonthPassed` | Every in-game month | `int month` |
| `GameManager.OnTierUpgraded` | Company tier changes | `CompanyTier` |
| `GameManager.OnGameMessage` | Notification popup | `string message` |
| `EconomyManager.OnCashChanged` | Any $ change | `long cash` |
| `EconomyManager.OnBankrupt` | Cash goes negative | — |
| `ProjectManager.OnProjectCompleted` | Project done | `ClientProject` |
| `ProjectManager.OnProjectFailed` | Deadline missed | `ClientProject` |
| `EventManager.OnEventTriggered` | Random event fires | `CorporateEvent` |

---

## 🎮 Milestone Roadmap

### M1 — Prototype (Week 1–4)
- [ ] Unity project setup, folder structure, package manifest
- [ ] GameManager + sub-manager scaffold
- [ ] Employee data model + basic hire UI
- [ ] Day/month time loop
- [ ] Cash counter + basic spend/earn calls

### M2 — Core Loop (Week 5–8)
- [ ] Project generation + assignment UI
- [ ] Deadline timer + complete/fail logic
- [ ] Office grid renderer (basic quads/tilemaps)
- [ ] Save/load JSON system
- [ ] Basic HUD: cash, reputation, date

### M3 — Content & Polish (Week 9–14)
- [ ] Pixel art sprites for employees, rooms, UI
- [ ] Random event popups (Kairosoft-style modal)
- [ ] Company tier upgrade flow + unlock gates
- [ ] Sound effects + 8-bit BGM
- [ ] Motivation/burnout visual feedback

### M4 — Beta & Launch (Week 15–20)
- [ ] Game balance pass (salary curves, project rewards)
- [ ] Tutorial / onboarding flow
- [ ] IAP integration (cosmetic only)
- [ ] Firebase Analytics
- [ ] App Store + Google Play submission

---

## 💾 Save Data Schema

Saved to: `Application.persistentDataPath/pocketoffice_save.json`

```json
{
  "CompanyData": { "CompanyName": "...", "Reputation": 42, "Tier": "Startup", ... },
  "Employees": [ { "FirstName": "Alice", "Skill": 65, ... } ],
  "Cash": 8500,
  "ActiveProjects": [ { "ProjectTitle": "...", "DaysElapsed": 5, ... } ],
  "SaveTimestamp": "2024-03-01T12:00:00Z"
}
```

---

## 🛠️ Tech Stack

| Item | Choice | Reason |
|---|---|---|
| Engine | Unity 2D LTS | Best mobile 2D support, huge community |
| Language | C# | Unity native, strong typing |
| Art | Aseprite → 16/32px sprites | Industry standard for pixel art |
| Audio | FMOD or Unity Audio Mixer | Good for adaptive 8-bit BGM |
| Analytics | Firebase | Free, Unity SDK available |
| IAP | Unity IAP | Cross-platform, easy integration |
| Save | Local JSON + PlayerPrefs fallback | Simple, no server needed at launch |

---

## ⚠️ Known Design Risks

1. **Game balance is hard** — project reward curves and salary cost curves must be playtested extensively. Ship with a debug mode that shows all numbers.
2. **Burnout pacing** — if employees burn out too fast, game feels punishing; too slow and the system feels pointless.
3. **Content depth** — Kairosoft games have 100+ events and dozens of room types. Plan for at least 30 events at launch.
4. **Mobile performance** — pixel art sprite atlases must be packed to avoid draw call spikes on mid-range Android devices.
