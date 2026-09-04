# Proof Depth

Proof Depth is Last Inkwarden's post-ending mastery ladder. It layers on top of
difficulty, contract, route, starting weapon, and build choices instead of
replacing them. Proof 0 remains the authored baseline, and clearing the highest
available depth unlocks exactly one next depth. A failed run never skips a rung.

## Ladder

| Depth | Name | New cumulative clause |
| ---: | --- | --- |
| 0 | Open Proof | Baseline; no Proof clause |
| 1 | Blood Ink | Masks deal 4% more damage |
| 2 | Heavy Stock | Masks gain 6% health |
| 3 | Crowded Margins | Hordes arrive 6% faster and hold 8% more masks |
| 4 | Marked Copies | Elite affixes appear 8% more often |
| 5 | Sealed Remedies | Recovery drops are 15% scarcer |
| 6 | Running Type | Masks move 6% faster |
| 7 | The Red Pen | Bosses gain 12% health |
| 8 | Broken Gutter | Dash recovery is 10% slower |
| 9 | Last Deadline | Pages turn 8% sooner |
| 10 | Author's Proof | Masks gain another 6% health and 4% damage; bosses gain another 8% health |

Every nonzero rung also multiplies score by 1.08 and Memory by 1.05. Because the
clauses compound, Author's Proof pays approximately ×2.16 score and ×1.63 Memory.
Depth 10 can be cleared repeatedly and records a terminal mastery clear without
attempting to unlock a nonexistent next rung.

## Access and persistence

The title-screen Proof Ledger opens with `P` or left-stick click. Arrow keys,
D-pad, or the left stick move between its two columns; Enter or A/Cross selects
an unlocked depth, and Escape or B/Circle closes it. Continue restores the exact
Proof Depth attached to the current-draft checkpoint.

Profile schema 12 stores the maximum unlocked depth, preferred depth, and highest
cleared depth. A schema-10 profile that already completed an ending migrates to
Proof 1 with Proof 0 recorded as its highest clear; other old profiles begin at
Proof 0. Recent-run history and result summaries retain the attempted Proof name
and number.

## Validation

`proof_depth_test.gd` verifies all eleven unique definitions, cumulative rules,
sequential unlocks, terminal completion, rewards, keyboard/gamepad bindings,
checkpoint restoration, and schema-10 migration. `capture_proof_ledger.gd`
checks the real 6+5 card renderer. The balance matrix exercises four complete
twelve-technique builds across Proof 0 and Proof 10 for all three difficulties,
six contracts, and three final routes: 432 measured rows.
