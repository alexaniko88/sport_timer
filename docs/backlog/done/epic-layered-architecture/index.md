---
abbr: ARCH
---

# EPIC: Layered application architecture

## Goal

Make the application easier to understand, test, and change by separating feature responsibilities and platform dependencies while preserving the app's existing behavior.

## Agreed scope and decisions

- Refactor the whole application in one coordinated migration. Include every feature and shared concern present in the implementation checkout, including statistics if it exists there. Do not assume unmerged work is available or create features that are absent.
- Organize feature code by feature, then `domain`, `data`, and `presentation` where those responsibilities exist; do not create empty layers for symmetry. Place shared concerns and the composition root appropriately outside individual features.
- Keep domain models and contracts independent of Firebase, SQLite, Flutter widgets, and other platform-specific types. Presentation uses application-facing models and contracts; data implements those contracts and wraps external services. Dependency setup connects the implementations.
- Retain MVVM, `ValueNotifier`, and `get_it`. Add use cases only when they contain meaningful complex or reusable business logic; avoid pass-through classes.
- Preserve behavior, appearance, navigation, authentication, timer operation, and existing stored data. Report unrelated bugs separately unless they block the migration.
- Document dependency rules and add practical automated guardrails. Choose the smallest suitable mechanism during implementation planning.

## Context and references

The current code mixes responsibilities: settings models, contract, and SharedPreferences implementation share a file; the user repository exposes Firebase's `User` type. Verify the checkout afresh before planning. The unfinished statistics database work on another branch is not a prerequisite or evidence of merged functionality.

Flutter recommends distinct UI and data responsibilities, MVVM, repositories, and immutable models; a use-case layer is optional when complexity warrants it. See the [Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide) and [recommendations](https://docs.flutter.dev/app-architecture/recommendations).

## Stories

1. [Refactor the application into layers](stories/done/story-01-refactor-app/index.md) — one coordinated, behavior-preserving migration and its guardrails.

## Delivery order

Plan the migration and guardrails together and deliver them as one coordinated change. Each task includes its own verification; neither adds product functionality.
