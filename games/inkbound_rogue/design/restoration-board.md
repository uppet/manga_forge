# Restoration Board

The Restoration Board is the long-term build layer between drafts. Memory is
earned inside a run, banked only when that run is finalized, and spent from the
title screen. It must offer meaningful goals beyond the first ending without
making a fresh profile feel deliberately weak.

## Economy and pacing

Each branch has five ranks costing 8, 16, 24, 32, and 40 Memory. One mastered
branch costs 120 Memory; the complete board contains thirty ranks and costs 720.
That total sits below Archive Rank 10 at 830 lifetime Memory, leaving room for
players to spend while rank progress continues to reflect everything recovered.

| Branch | Unlock | Per rank | Rank-five mastery |
| --- | ---: | --- | --- |
| Heartbind | Rank 1 | +1 maximum health | Start with 2 Ward |
| Honed Nib | Rank 1 | +0.2 blade damage | +10% boss damage |
| Lucky Misprint | Rank 1 | +5% luck | +10% Ink value |
| Quick Margin | Rank 2 | +3 movement speed | Dash recovers 10% faster |
| Deep Inkwell | Rank 4 | Ink Art recovers 4% faster | +15% Ink Art damage |
| Reader's Thread | Rank 6 | +18 pickup reach | +45 additional reach |

The first three choices are visible immediately. Later paths unlock at Archive
Ranks 2, 4, and 6 so an existing profile receives access from its lifetime
Memory rather than needing to repeat an arbitrary new task.

## Interaction contract

- Open from the title with `M`, right-stick click, or the visible board button.
- Navigate the 2×3 grid with arrows, D-pad, or left stick.
- Purchase with Enter, `A`/Cross, `X`/Square, or right trigger.
- Close with Escape, Start, `B`/Circle, or the original board shortcut.
- Locked, unaffordable, and mastered branches remain readable but cannot spend.
- Purchasing refreshes the open board in place and atomically saves the profile.

## Persistence and compatibility

Profile schema 12 stores all six branch ranks in `meta_upgrades`. Schema-9
profiles preserve Heartbind, Honed Nib, and Lucky Misprint and initialize the
three new paths at zero; schema-10 profiles carry every branch forward. Unknown
and over-cap ranks are sanitized on load.

`restoration_board_test.gd` proves catalog cost, rank gates, all six mastery
effects, keyboard/controller bindings, in-place purchases, schema-12 round trips,
and schema-9 migration. `capture_restoration_ui.gd` checks and captures the real
Windows-rendered card grid.
