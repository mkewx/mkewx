# Thursday's Child — asynchronous starfield laboratory

This experiment is compiled separately from the no-star production fallback.

## Visual target

- ten one-scanline, one-color-clock white points;
- five horizontal positioning anchors distributed through the room;
- four staggered animation offsets;
- a 16-frame bright/bright/bright/dark cycle, advanced every four frames;
- no synchronized all-star blink.

The laboratory intentionally uses temporal bright/dark shimmer instead of
writing gray values to `COLUP0`. Missile 0 and Major Tom share that color
register; changing it on a visible line could tint the astronaut. Protecting
Major Tom takes precedence over a multistep gray fade.

## Isolation

`make thursday` builds the production fallback with empty star tables.
`make starfield-lab` builds `build/thursdays-child-starfield-lab.bin` with
`STARFIELD_LAB=1`. The experiment therefore cannot become the production
choice merely by being compiled.

## Verification

All five room kernels, F4 banks, motion tiers, mission objects, audio paths,
stage descriptors and terrain footprints pass. The astronaut, star and
busiest mission-object paths each remain at or below 75 CPU cycles.

## Director acceptance test

1. The points read as stars rather than blocks or debris.
2. Their dark phases appear staggered instead of synchronized.
3. Major Tom never changes color, loses pixels or gains a horizontal line.
4. The picture remains vertically locked during free flight and orbiting.
5. The atmosphere is worth the additional kernel complexity.
