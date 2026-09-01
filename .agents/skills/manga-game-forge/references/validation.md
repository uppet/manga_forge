# Game validation gates

A Manga Forge game slice is complete only when all applicable gates pass.

## Functional

- The player can move, use the primary interaction/weapon, take damage, fail, and restart.
- Progression changes runtime behavior and presents a meaningful decision.
- Input, pause/overlay behavior, save data, and viewport scaling remain coherent.

## Feel and presentation

- Hits communicate with at least three channels among motion, freeze, flash, sound,
  particles, camera, and typography.
- Player, enemies, pickups, and danger are distinguishable at gameplay scale.
- Pixel assets use nearest filtering and integer-friendly sizes.

## Technical

- Headless editor import exits successfully.
- A smoke test instantiates the main scene and proves one gameplay interaction.
- The Windows host starts the project using the pinned engine.
- The repository contains no generated engine caches or host-specific secrets.
