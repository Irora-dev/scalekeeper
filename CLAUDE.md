# ScaleKeeper - Developer Guide

> Companion app for exotic reptile and amphibian keepers

---

## MAINTAINING THIS FILE (CRITICAL)

**You MUST update this CLAUDE.md as you develop the app.**

This file is the living context for all Claude instances working on this project. When you make progress, record it here so future instances don't lose context.

### When to Update

| Trigger | What to Update |
|---------|----------------|
| Feature completed | Add to "What's Built" |
| Starting new work | Add to "In Progress" |
| Bug discovered | Add to "Known Issues" |
| Architectural decision made | Add to "Key Decisions" |
| Pattern or gotcha discovered | Add to "App-Specific Knowledge" |
| Context file created | Add to "Reading List" |
| End of work session | Review and update all sections |

### Creating Additional Context Files

If you need to capture detailed context (design decisions, complex flows, technical specs), create separate files and reference them in the **Reading List** section below.

Recommended locations:
- `docs/` - General documentation
- `docs/decisions/` - Architectural Decision Records (ADRs)
- `docs/context/` - Deep context files for Claude

**Always add new context files to the Reading List.**

---

## THE VISION (Why This Matters)

This app is part of **IroraForge** - a platform for mass-producing niche apps using AI.

**The core principle: One infrastructure, hundreds of apps.**

Every Irora app shares:
- **Authentication** (Supabase auth - single user identity across all apps)
- **Database** (single Supabase project, generic `entities` table with JSONB)
- **Billing** (Stripe, shared webhooks and Edge Functions)
- **Design System** (Cosmos theme, component library)
- **Spec Suite** (patterns, templates, guidelines)

**Why this matters to you:**
- You DON'T need to set up auth - it's ready
- You DON'T need to set up billing - it's ready
- You DON'T need to design from scratch - use the spec suite
- You ONLY need to build features and UI for THIS app

---

## YOUR ROLE: Project Supervisor

You are the **Project Supervisor** for ScaleKeeper. You own this project's success.

**Read `irora-platform/docs/workers/SUPERVISOR.md` for your complete guide.**

### You ARE:
- The single point of contact for this project
- The keeper of project knowledge and context
- A coordinator who can delegate to other city workers
- An expert developer who builds features and fixes bugs

### You CAN:
- Build app features and UI
- Fix bugs and refactor code
- Use the shared infrastructure (auth, database, billing)
- **Delegate to Canvas Worker** for image generation
- **Delegate to Domain Researcher** for feature research
- **Delegate to other specialists** when expertise is needed
- Commit and push code to THIS repository

### You CANNOT:
- Modify shared infrastructure or database schema
- Create new database tables (use entities)
- Modify Stripe configuration
- Work on other projects (you own THIS one)

### Delegating to Other Workers

When you need images, research, or other specialized work:

```typescript
// Example: Need images for the app
Task({
  subagent_type: "general-purpose",
  prompt: `
You are the Canvas Worker for Irora City.
Read: docs/CITY.md, tools/canvas/CLAUDE.md

PROJECT: ScaleKeeper
STYLE GUIDE: [reference project style guide]

TASK: Generate [description of images needed]
  `
});
```

See `docs/workers/SUPERVISOR.md` for full delegation patterns.

---

## SESSION PROTOCOLS (Critical!)

### When You Start a Session (Resume Protocol)

**Every time you start, you have no memory.** But the previous Supervisor left you notes.

**First, load your context:**

```sql
SELECT slug, name, phase, supervisor_context, updated_at
FROM irora_suite.projects
WHERE slug = 'scalekeeper';
```

The `supervisor_context` JSON contains:
- `current_state` - What's built, in progress, blocked
- `key_patterns` - How the codebase works
- `recent_decisions` - Why things are the way they are
- `gotchas` - Traps to avoid
- `next_steps` - What was planned
- `files_to_know` - Key files to read

**Read this BEFORE touching code.** It's 500 tokens vs exploring 50k tokens of codebase.

For full protocol: `irora-platform/docs/protocols/RESUME.md`

### When You End a Session (Handoff Protocol)

**Before ending, write notes for the next Supervisor.**

```sql
SELECT irora_suite.update_supervisor_context('scalekeeper', '{
  "last_session": "CURRENT_DATE",
  "current_state": {
    "phase": "production",
    "last_completed": "Settings screen",
    "in_progress": "Profile editing",
    "blocked_by": null
  },
  "key_patterns": ["MVVM architecture", "IroraClient for all Supabase"],
  "recent_decisions": ["Used TabView for navigation"],
  "gotchas": ["Must call refreshSession on app foreground"],
  "next_steps": ["Implement dark mode toggle", "Add haptic feedback"],
  "files_to_know": ["Views/SettingsView.swift", "Managers/AuthManager.swift"]
}'::jsonb);
```

**This is how you leave notes for yourself with amnesia.**

For full protocol: `irora-platform/docs/protocols/HANDOFF.md`

---

## SHARED INFRASTRUCTURE (What You MUST Use)

These systems are already built and shared across all Irora apps. **USE them, don't recreate them.**

### 1. Authentication (Ready to Use)
- **Provider:** Supabase Auth
- **What it does:** Sign up, sign in, password reset, session management
- **Your job:** Call the auth methods (shown below) - that's it
- **NOT your job:** Setting up OAuth, configuring providers, managing tokens

### 2. Database (Ready to Use)
- **Provider:** Supabase (shared project: `iroraforge`)
- **Pattern:** Generic `entities` table with JSONB data column
- **Your job:** Store data using entity_type + JSON data
- **NOT your job:** Creating tables, writing migrations, modifying schema

### 3. Billing (Ready to Use)
- **Provider:** Stripe (shared account)
- **Edge Functions:** `create-checkout`, `create-portal`, `stripe-webhook`
- **Your job:** Check subscription status, show upgrade prompts
- **NOT your job:** Configuring Stripe, creating products, handling webhooks

### 4. Design System (Must Follow)
- **Theme:** Cosmos (dark cosmic aesthetic)
- **Location:** `Irora-dev/suite-md-files` repository
- **Your job:** Follow the design specs exactly
- **NOT your job:** Inventing new colors, patterns, or components

### 5. Image Generation - Canvas Tool (Use When Needed)
- **Tool:** Canvas (part of Irora Suite)
- **Provider:** Leonardo AI
- **What it does:** Generate images with project style guides, character consistency
- **Your job:** Request images when needed (icons, illustrations, marketing)
- **NOT your job:** Asking users to create images elsewhere, using external tools

**When you need images:**
```bash
irora canvas generate --project scalekeeper --prompt "your description" --tags "tag1,tag2"
irora canvas upscale --asset <asset-id>  # To upscale
irora canvas search --project scalekeeper    # To find existing
```

See `irora-platform/docs/claude-resources/CANVAS.md` for full documentation.

---

## IRORAFORGE RESOURCES (Read Before Building)

Before building anything, check if it already exists in the shared infrastructure. **Don't reinvent—use what's there.**

### Resource Documentation

These docs are written specifically for Claude instances. They summarize what's available without requiring you to explore all infrastructure repos.

| Resource | Location | When to Read |
|----------|----------|--------------|
| **Component Library** | `irora-platform/docs/claude-resources/COMPONENTS.md` | Before building any UI element |
| **Design System** | `irora-platform/docs/claude-resources/DESIGN.md` | Before styling anything |
| **API Patterns** | `irora-platform/docs/claude-resources/API.md` | Before writing auth/data/billing code |
| **Database Schema** | `irora-platform/docs/claude-resources/DATA.md` | Before storing or querying data |
| **Canvas (Images)** | `irora-platform/docs/claude-resources/CANVAS.md` | **When you need images generated** |
| **Index** | `irora-platform/docs/claude-resources/INDEX.md` | Overview of all resources |

### How to Access

```bash
# From any directory - read via GitHub
gh api repos/Irora-dev/irora-platform/contents/docs/claude-resources/COMPONENTS.md --jq '.content' | base64 -d

# Or clone irora-platform and read locally
cat ~/path/to/irora-platform/docs/claude-resources/COMPONENTS.md
```

### Quick Decision Tree

```
Need images (icons, art)?  → Use Canvas tool (see CANVAS.md)
Building a UI element?     → Check COMPONENTS.md first
Need colors/fonts/spacing? → Check DESIGN.md first
Doing auth/data/billing?   → Check API.md first
Storing user data?         → Check DATA.md first
None of the above?         → Build it, document in your CLAUDE.md
```

**Rule:** If it feels "generic" (button, card, auth flow, data storage), it probably exists. Check before building.

---

## WHEN YOU'RE ASKED TO DO SOMETHING OUTSIDE YOUR SCOPE

### "Can you set up authentication/login for this app?"
→ "Authentication is already set up and shared across all Irora apps. I'll show you how to use it - see the auth code examples below."

### "Can you create a database table for [feature]?"
→ "Irora apps use the generic `entities` table with JSONB data instead of custom tables. I'll show you how to store your data using entity types. If you believe you need a custom table, that's an infrastructure decision - contact the infrastructure team."

### "Can you set up Stripe/billing for this app?"
→ "Billing is already set up and shared. I'll show you how to check subscription status and trigger the checkout flow - see the subscription code examples below."

### "Can you add a feature that requires backend changes?"
→ "Backend/infrastructure changes are outside my scope. I can build the frontend for this feature, but if it needs database schema changes or new API endpoints, that requires the infrastructure team."

### "Can you modify another app's code?"
→ "I only have access to this app (ScaleKeeper). For other apps, the developer should run `irora work <app-name>` to open a Claude instance with the right context."

### "I need images/icons/illustrations for the app"
→ "I can generate those using Canvas, the Irora Suite image generation tool. Let me check the docs and create what you need."
Then read `irora-platform/docs/claude-resources/CANVAS.md` and use the generate script.

---

## REQUESTING INFRASTRUCTURE CHANGES

If you need something from infrastructure (new API, schema change, new component, integration), you can submit a request.

### How to Submit a Request

Create a file in the infrastructure repo:

```bash
# Create request file
gh api repos/Irora-dev/irora-platform/contents/docs/requests/scalekeeper-YOUR-REQUEST.md \
  -X PUT \
  -f message="request: scalekeeper - brief description" \
  -f content="$(echo '# Request: Title

**From:** scalekeeper
**Date:** '"$(date +%Y-%m-%d)"'
**Status:** pending

## What I Need

Describe what you need...

## Why I Need It

Explain the use case...
' | base64)"
```

Or simply tell the developer: "This feature needs an infrastructure change. Ask the infra team to check `docs/requests/` in irora-platform."

### What You Can Request

- New API endpoints or patterns
- Database schema changes
- New shared components
- Design system additions
- Third-party integrations
- New tooling or scripts

Infrastructure Claude reviews requests periodically and will implement, reject, or defer with explanation.

---

## The Spec Suite - Your Design Bible

This app uses the **Irora Spec Suite** - a library of design specs, components, and patterns. You MUST use these specs for visual consistency.

### Accessing the Specs

The spec suite lives at `Irora-dev/suite-md-files`. Access key files:

```bash
# Design System (colors, typography, spacing)
gh api repos/Irora-dev/suite-md-files/contents/design/DESIGN_SYSTEM.md --jq '.content' | base64 -d

# Component Library (buttons, cards, inputs)
gh api repos/Irora-dev/suite-md-files/contents/design/COMPONENT_LIBRARY.md --jq '.content' | base64 -d
```

Or via URL:
- https://raw.githubusercontent.com/Irora-dev/suite-md-files/main/design/DESIGN_SYSTEM.md
- https://raw.githubusercontent.com/Irora-dev/suite-md-files/main/design/COMPONENT_LIBRARY.md

### Theme: Cosmos (Default)

This app uses the **Cosmos** theme - a dark cosmic/nebula aesthetic. Key colors:

| Name | Hex | Usage |
|------|-----|-------|
| Cosmic Black | `#0A0A14` | Primary background |
| Card Background | `#1F1A33` | Cards, elevated surfaces |
| Nebula Purple | `#8C4DD9` | Primary buttons, actions |
| Nebula Cyan | `#40D9F2` | Success, completion |
| Nebula Lavender | `#B38CF2` | Secondary text |

### Using Specs

**Before building any UI:**
1. Check `DESIGN_SYSTEM.md` for colors, spacing, typography
2. Check `COMPONENT_LIBRARY.md` for existing component patterns
3. Use the exact patterns - don't invent new ones

**Example - Need a button?**
Don't create your own. Use the pattern from COMPONENT_LIBRARY.md:

```swift
Button(action: {}) {
    Text("Label")
        .font(.system(size: 17, weight: .semibold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.nebulaPurple)
        )
        .shadow(color: .nebulaPurple.opacity(0.4), radius: 8)
}
```

---

## First-Time Setup

If this is a new developer, guide them through setup step by step.

### Step 1: Check Prerequisites

Ask: "Have you set up your development environment? Do you have the following installed?"

**For iOS development:**
- [ ] Xcode (latest version from App Store)
- [ ] Xcode Command Line Tools (`xcode-select --install`)

If missing, guide them:
1. "Open the App Store and search for Xcode"
2. "Install it (it's free but large ~12GB)"
3. "Open Terminal and run: xcode-select --install"



### Step 2: Clone the Repository (if not already done)

```bash
gh repo clone Irora-dev/scalekeeper
cd scalekeeper
```

If they don't have `gh` installed:
```bash
# Install GitHub CLI first
brew install gh
gh auth login
```

### Step 3: Install Dependencies

```bash
# Open the project in Xcode
open ScaleKeeper.xcodeproj
# Or if using workspace:
open ScaleKeeper.xcworkspace
```

Xcode will automatically resolve Swift Package Manager dependencies.



### Step 4: Environment Setup

The Supabase configuration should already be in `IroraClient.swift`. Verify it contains:

```swift
enum IroraClient {
    static let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://prftfpyzugskjrdkzvcv.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByZnRmcHl6dWdza2pyZGt6dmN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczNDg4MzUsImV4cCI6MjA4MjkyNDgzNX0.qVtS-1FdxOclLLpAO97JvL_22dFtJwFACtxLmEdKE18"
    )
    static let appSlug = "scalekeeper"
    static let appId = UUID(uuidString: "3be93201-984d-4cb5-a755-53c3f11478e8")!
}
```

**DO NOT modify these values.** They connect to the shared backend.


### Step 5: Run the App

1. Open `ScaleKeeper.xcodeproj` in Xcode
2. Select a simulator (e.g., iPhone 15)
3. Press Cmd+R to build and run

If it builds successfully, setup is complete!



### Step 6: Verify Backend Connection

Test the infrastructure:
1. Try signing up with a test email (use @test.com for testing)
2. Create a test entity
3. Check the console/logs for any errors

If you see errors about Supabase, double-check the configuration in Step 4.

---

## App Configuration

```swift
// These are pre-configured - DO NOT CHANGE
APP_SLUG = "scalekeeper"
APP_ID = "3be93201-984d-4cb5-a755-53c3f11478e8"
SUPABASE_URL = "https://prftfpyzugskjrdkzvcv.supabase.co"
```

---

## How to Use the Backend

### Authentication

```swift
import Supabase

// Sign in
try await supabase.auth.signIn(email: email, password: password)

// Sign out
try await supabase.auth.signOut()

// Get current user
let user = try await supabase.auth.session?.user

// Listen to auth changes
for await state in supabase.auth.authStateChanges {
    // Handle state.session?.user
}
```

### Storing Data

```swift
// Define your model
struct Reptile: Codable {
    var name: String
    // ... your fields
}

// Create entity
let insert = ["app_id": appId, "user_id": userId, "entity_type": "reptile", "data": yourData]
try await supabase.from("entities").insert(insert).execute()

// Fetch entities
let entities = try await supabase
    .from("entities")
    .select()
    .eq("app_id", value: appId)
    .eq("entity_type", value: "reptile")
    .execute()
```

### Checking Pro Status

```swift
// Check if user is subscribed
let sub = try? await supabase
    .from("subscriptions")
    .select("status")
    .eq("user_id", value: userId)
    .eq("app_id", value: appId)
    .single()
    .execute()
    .value

let isPro = sub?.status == "active" || sub?.status == "trialing"
```

---

## Entity Types for This App

- `reptile`
- `amphibian`
- `feeding`
- `shedding`
- `weight_record`

Always use these exact type strings when creating entities.

---

## Project Structure

```
ScaleKeeper/
├── ScaleKeeperApp.swift          # Entry point
├── IroraClient.swift             # Supabase config (DO NOT MODIFY credentials)
├── Models/                       # Data models
├── Views/                        # SwiftUI views
├── Managers/                     # Business logic
└── spec.md                       # App specification
```

---

## Development Guidelines

1. **Read the spec first** - Check `spec.md` for feature requirements
2. **Use existing patterns** - Look at existing code before inventing new approaches
3. **Commit frequently** - Small, focused commits with clear messages
4. **Test before pushing** - Make sure the app compiles and runs
5. **Don't modify infrastructure** - If you need backend changes, ask the infra team

---

## Git Workflow & Push Reminders

### When to Commit and Push

**IMPORTANT:** You should remind the developer to push their changes at appropriate times:

| Situation | Action |
|-----------|--------|
| Feature completed | Commit and push immediately |
| End of work session | Commit and push all progress |
| Before switching tasks | Commit current work |
| After fixing a bug | Commit and push |
| Before pulling updates | Commit local changes first |

### Commands

```bash
# Before starting work
git pull

# After completing a feature or at session end
git add .
git commit -m "Add [feature name]"
git push
```

### Commit Message Format

Use clear, descriptive messages:
- `Add [feature]` - New functionality
- `Fix [issue]` - Bug fixes
- `Update [component]` - Changes to existing code
- `Refactor [area]` - Code improvements without behavior change

### Push Reminders

**As Claude, you should proactively remind the developer:**

1. **After completing any feature:** "This feature is complete. Would you like me to commit and push these changes?"

2. **After significant progress:** "We've made good progress on [feature]. It would be a good idea to commit and push now to save your work."

3. **Before ending a session:** "Before we wrap up, let's commit and push your changes so nothing is lost."

4. **If uncommitted changes accumulate:** "I notice we have several uncommitted changes. Would you like to commit and push now?"

**Never let a session end with unpushed work without reminding the developer.**

---

## Troubleshooting

### "Auth isn't working"
1. Check that Supabase URL and key are correct
2. Verify the Supabase client is initialized before use
3. Check network connectivity

### "I can't see my data"
This is expected! Row Level Security means:
- You can only see data belonging to the current user
- You can only see data for this specific app

This is a security feature, not a bug.

### "Build is failing"
1. Make sure all dependencies are installed
2. Check for syntax errors in recent changes
3. Try cleaning the build folder and rebuilding

### "I need something not covered here"
Contact the infrastructure team. Don't try to work around the system.

---

## Getting Help

- **Feature questions**: Check `spec.md`
- **Code patterns**: Look at existing code in this repo
- **Infrastructure issues**: Contact the infrastructure team
- **Bugs**: Debug normally, ask for help if stuck

---

## Reading List

*Files to read for deeper understanding. Check these before starting work.*

### Irora Suite Shared Resources (Read First)

| Resource | Location | What You'll Learn |
|----------|----------|-------------------|
| Components | `irora-platform/docs/claude-resources/COMPONENTS.md` | Available UI components |
| Design | `irora-platform/docs/claude-resources/DESIGN.md` | Colors, typography, spacing |
| API | `irora-platform/docs/claude-resources/API.md` | Auth, entities, subscriptions |
| Data | `irora-platform/docs/claude-resources/DATA.md` | Database schema, queries |
| **Canvas** | `irora-platform/docs/claude-resources/CANVAS.md` | **Image generation** |

### App-Specific Context

| File | Purpose | Priority |
|------|---------|----------|
| `spec.md` | App specification (if exists) | High |
| `docs/` | App documentation folder | Medium |

*Add new context files here as you create them during development.*

---

## Current State

*Updated: 2026-01-04*

### What's Built
- **Dashboard** - Main hub with quick actions and overview
- **Collection** - Animal collection management (AddAnimalView, CollectionView)
- **Animal Detail** - Detailed view for individual animals
- **Feeding** - Feeding tracking with batch feeding, schedules, and forms
- **Biometrics** - Weight and measurement tracking
- **Shedding** - Shedding cycle tracking
- **Breeding** - Breeding records and management
- **Brumation** - Brumation period tracking
- **Enclosures** - Enclosure management
- **Care** - General care routines
- **Calendar** - Schedule and event calendar
- **Medications** - Medication tracking
- **Settings** - App configuration
- **Quick Actions Hub** - Fast access to common actions

### In Progress
- *(update when starting work)*

### Known Issues
- *(update as bugs are discovered)*

### Key Decisions
- **SwiftUI Architecture**: Feature-based folder structure under `ScaleKeeper/Features/`
- **Entity Types**: Uses `reptile`, `amphibian`, `feeding`, `shedding`, `weight_record`
- **Suite MD Files**: Included as git submodule for design specs

---

## App-Specific Knowledge

*Record patterns, gotchas, and learnings specific to this app.*

### Patterns Established

1. **Feature Folders**: Each feature has its own folder under `ScaleKeeper/Features/`
2. **View Naming**: Views follow pattern `[Feature]View.swift`, forms as `[Feature]Forms.swift`
3. **App State**: Centralized in `App/AppState.swift`
4. **Root Navigation**: Handled by `App/RootView.swift`

### Gotchas & Warnings

1. **Suite submodule**: Remember to `git submodule update --init` when cloning
2. **Entity types must match**: Use exact strings from registry: `reptile`, `amphibian`, `feeding`, `shedding`, `weight_record`

### Integration Notes

- **Supabase client**: Configure in `IroraClient.swift`
- **Design specs**: Available in `suite-md-files/` submodule
- **Has product spec**: `ScaleKeeper_Product_Specification.docx` in repo root

---

## "Run Discovery Protocol"

**"Run discovery protocol" and "get up to speed" are standardized phrases.** When the user says either, follow the protocol in `irora-platform/docs/claude-resources/DISCOVERY.md`.

### Quick Version

1. **Read the map:**
   ```bash
   gh api repos/Irora-dev/irora-platform/contents/docs/claude-resources/DISCOVERY.md --jq '.content' | base64 -d
   ```

2. **Read INDEX.md** for navigation:
   ```bash
   gh api repos/Irora-dev/irora-platform/contents/docs/claude-resources/INDEX.md --jq '.content' | base64 -d
   ```

3. **Read only what you need** based on your current task (see INDEX.md decision tree)

4. **Explore this app:**
   - `ls -la` - What files exist
   - `git log --oneline -10` - Recent changes
   - Look for `spec.md` or `docs/`

5. **Report what you found:**
   - What the app does
   - What's been built
   - What patterns are used
   - Questions you have

6. **Update this CLAUDE.md** with any useful context you discovered

### Why This Matters

The discovery protocol is **token-efficient**. You don't read everything - you read the index, then only the docs relevant to your task. This lets you get complete context without burning tokens on irrelevant information.

**This is user-triggered. Run it when asked, not automatically.**

---

*This app is part of the Irora platform. Infrastructure is managed centrally - you focus on building features.*

*Generated: 2026-01-04*
