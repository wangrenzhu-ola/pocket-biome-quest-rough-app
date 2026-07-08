# Pocket Biome Quest v0.0.2 Product Design Iteration

## Status readback

- Current implemented build: v0.0.1 rough app build passed.
- Source repo: `/Users/wangrenzhu/work/PocketBiomeQuest`.
- Public repo: `https://github.com/wangrenzhu-ola/pocket-biome-quest-rough-app`.
- Baseline commit used for this iteration: `e1730350d7acf30502f039d46943c099a2c0ab3a`.
- Baseline requirements already implemented: create/edit/delete Field Postcards, local persistence, domain-specific visual treatment, empty/error/privacy/IAP/local cue assistant/en-US locale.

## Next-version thesis

v0.0.2 should move Pocket Biome Quest from **“one delightful field postcard”** to **“a repeatable neighborhood micro-safari habit.”** The version should keep the local-first, no-login, no-species-certainty boundary while adding richer creative prompts, route memory, and reflection loops that make users return after the first saved postcard.

## Pain synthesis

| Pain signal | Current v0.0.1 answer | Remaining pain after v0.0.1 | v0.0.2 design response |
| --- | --- | --- | --- |
| “I do not know what to notice.” | Seed quest cards tell users what to inspect. | Quests are isolated cards; users do not get a walk-shaped plan or next-step variety. | Add **Micro-Safari Trail Plan**: 3-card local quest chains with time budget, habitat mix, and “next tiny stop” guidance. |
| “Species identification feels too exacting.” | Local cue assistant gives editable texture/color chips without certainty claims. | Users still may wonder what a “good observation” looks like. | Add **Noticing Rubric**: examples of texture, edge, motion, color, and sound clues; no species names required. |
| “Walk discoveries disappear.” | Field Postcards persist in Trail Archive. | Archive is memory storage, not yet a reflective reward loop. | Add **Trail Almanac**: weekly habitat recap, swatch palette, and “unexplored habitats” prompts based on saved postcards. |
| Parent-child use needs low friction. | Simple capture screen and postcard reward. | Child-friendly turn-taking and shared prompt language are not explicit. | Add **Two-Person Quest Mode**: one person spots, one person describes; prompts remain local and en-US. |
| Premium packs need clearer value. | StoreKit entry, purchase/restore/unavailable states. | Packs are storefront-visible but not narratively differentiated. | Add **Seasonal Field Packs** with named quest chains, visual territories, and preview postcards before purchase. |

## Product direction selected

**Selected direction: “Neighborhood Almanac.”**

A walker builds a personal, local-only almanac of small habitats. Each walk becomes a short trail plan; each saved postcard contributes to a visible habitat map, weekly recap, and seasonal quest pack preview. The app remains playful and observational, not scientific identification software.

Rejected alternatives:

1. **Identifier-lite assistant** — rejected because it drifts toward species certainty and reference-app imitation.
2. **Social challenge feed** — rejected because it violates no-backend/no-community v0 boundary and creates moderation/privacy risk.
3. **Generic streak tracker** — rejected because it would weaken the micro-safari/postcard differentiation and become a habit checklist.

## v0.0.2 feature set

### NVT-001 Micro-Safari Trail Plan

A pre-walk composer that bundles 3 quest cards into a 10–20 minute plan.

- User chooses time budget: 10, 15, or 20 minutes.
- App suggests a habitat mix such as moss + bark + puddle.
- Each quest card includes a “next tiny stop” line.
- Free core plan always available; premium packs may add seasonal chains.
- No map, GPS, live routing, backend, or location tracking.

### NVT-002 Noticing Rubric

A lightweight guidance panel available in Observation Capture.

- Shows examples: texture, edge, motion, color, sound, pattern.
- Converts vague text into editable local cue chips.
- Reminds users: “You are describing clues, not identifying a species.”
- Must work offline and manually.

### NVT-003 Trail Almanac

A richer archive view that turns saved postcards into memory and next action.

- Weekly recap: saved postcards count, habitat mix, color swatches.
- “Unexplored nearby habitats” is generated from local quest types, not live location.
- Archive filter gains “This week,” “Habitat,” and “Color palette.”
- Empty almanac state points to Micro-Safari Trail Plan.

### NVT-004 Two-Person Quest Mode

A family-friendly mode for parent-child or walking buddy use.

- Role cards: “Spotter” and “Storyteller.”
- Observation Capture labels fields with role prompts.
- Saves normal Field Postcards; no account or shared identity.
- Accessibility: all prompts are plain English, short, and VoiceOver-readable.

### NVT-005 Seasonal Field Pack Preview

Premium pack presentation becomes experiential before purchase.

- Shows preview quest chain, sample postcard treatment, and locked seasonal glyphs.
- StoreKit purchase/restore remains implemented; unavailable state keeps free core usable.
- Preview copy must not promise live recommendations, community, species ID, or cloud AI.

## Data model changes

```swift
struct TrailPlan: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var estimatedMinutes: Int
    var questIds: [UUID]
    var habitatMix: [HabitatTag]
    var createdAt: Date
    var completedQuestIds: [UUID]
}

struct AlmanacWeek: Identifiable, Codable, Equatable {
    var id: String // ISO week
    var postcardIds: [UUID]
    var habitatCounts: [HabitatTag: Int]
    var colorSwatches: [String]
    var suggestedNextHabitats: [HabitatTag]
}

struct QuestRolePrompt: Codable, Equatable {
    var spotterPrompt: String
    var storytellerPrompt: String
}
```

## Acceptance criteria

| ID | Requirement | Evidence required |
| --- | --- | --- |
| REQ-NVT-PLAN-001 | User can create and complete a 3-card Micro-Safari Trail Plan without GPS or backend. | Unit tests for plan creation/completion; SwiftUI path from Quest Deck to plan detail; runtime evidence. |
| REQ-NVT-RUBRIC-001 | Observation Capture includes a Noticing Rubric with editable local cue outputs and manual fallback. | Source readback for rubric component and cue state; tests for suggestion/skip/edit. |
| REQ-NVT-ALMANAC-001 | Trail Archive shows weekly almanac recap from persisted postcards. | Persistence tests; archive UI evidence; relaunch readback. |
| REQ-NVT-FAMILY-001 | Two-Person Quest Mode changes prompt framing without requiring accounts. | Source readback for role prompts; accessibility labels; no login/backend scan. |
| REQ-NVT-PACK-001 | Premium seasonal pack previews show value before purchase and keep free core flow available. | StoreKit UI source evidence; unavailable-state runtime; no paywall on free plan. |
| REQ-NVT-PRIVACY-001 | No GPS, backend, cloud AI, community, or species certainty claims are introduced. | Static copy scan; Info.plist/capability scan; privacy copy runtime evidence. |
| REQ-NVT-LOCALE-001 | All user-visible copy remains English (United States). | CJK/static locale scan over Swift sources and metadata. |

## Implementation order

1. Add TrailPlan and AlmanacWeek model/store tests.
2. Add Micro-Safari Trail Plan UI from Quest Deck.
3. Add Noticing Rubric component to Observation Capture.
4. Upgrade Trail Archive into Trail Almanac.
5. Add Two-Person Quest Mode prompt toggle.
6. Enrich Premium Packs with seasonal preview cards.
7. Run Xcode tests, simulator install/launch, locale/privacy/static scans.

## Scope boundaries

- Do not add GPS, location permissions, backend, login, online community, cloud AI, species identification claims, or social sharing as required flows.
- Keep manual capture complete and local-first.
- Premium content may expand quest variety but cannot block the free Micro-Safari core flow.
