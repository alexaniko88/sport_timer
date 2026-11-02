# STORY 1: Refactor the application into layers

Epic: [Layered application architecture](../../../index.md)

Status: Done — both tasks delivered together on `improve/layered-architecture` (commit `76a95f5`).

## User outcome

As a maintainer, I can find feature code by responsibility and change or test application logic without coupling it to platform implementations, while users retain the current experience and data.

## Scope

Apply the [epic's decisions](../../../index.md) to every feature and shared concern present when implementation begins. Migrate the whole app in one coordinated change, including feature-specific views, ViewModels, state, models, contracts, data implementations, composition, navigation, and affected tests. Keep shared UI and infrastructure appropriately shared. Do not add absent features or change user-facing behavior.

## Acceptance criteria

- Features present in the implementation checkout follow the agreed layered structure and dependency direction; platform types do not leak into domain contracts and models.
- Existing behavior, navigation, appearance, authentication, timer operation, and persisted settings and data remain intact.
- Architecture guidance and practical automated checks describe and protect the resulting boundaries.
- Relevant tests, snapshots, analysis, and native checks pass or any environment limitation is explicitly reported.

## Tasks

1. [Migrate the existing application](done/01-migrate-application.md).
2. [Document and protect layer boundaries](done/02-document-and-protect-boundaries.md).

## Dependencies and open decisions

No dependency on the unfinished statistics branch. At implementation time inspect the actual checkout, select shared-code placement and a suitable guardrail, and adapt all existing features. Both tasks form one coordinated delivery; the guardrail must match the final migrated structure.
