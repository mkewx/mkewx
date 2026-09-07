# Thursday's Child 0.9C — starfield proof audit

## Production intent

Add restrained life to the black playfield without borrowing Player 1 from
mission objects, changing Major Tom, or altering the approved physics.

## Rendering architecture

- Missile 0 draws four two-scanline white star points.
- Stars occupy fixed rows 26, 68, 118 and 142.
- A shared slow phase turns the points on and off every 16 frames.
- Stars are disabled whenever Major Tom's Player 0 graphic is drawn.
- Satellite service rows reposition Missile 0 outside the visible critical
  path, distributing the four points horizontally.
- Each room bank keeps its star-enable table at virtual address `$FC00`.

## Automated evidence

All five assembled room kernels pass the cycle tracer:

- ordinary path: 42–43 cycles;
- Major Tom path: 74 cycles;
- star path: 72 cycles;
- busiest mission-object service row: 75 cycles (Stage 3).

No visible path exceeds the 76-cycle Atari scanline. The standard F4 bank,
descriptor, geometry, progression, object, motion and audio suites must also
pass before release.

## Director playtest

Check both Stella and 8bitworkshop environments:

1. The picture remains vertically locked during free flight and orbiting.
2. Four subtle white points slowly twinkle; they do not scroll or streak.
3. Major Tom never acquires a white line, missing pixel or altered silhouette.
4. Satellites, collectibles and the exit retain their approved colors/shapes.
5. Physics, collisions, sound and five-stage progression remain unchanged.
