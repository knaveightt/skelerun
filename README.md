# SKELERUN — The Sunken Keep

A standalone LÖVE 11.x game prototype: falling blocks power a knight's battle through a five-enemy dungeon. All art and sound are generated in the game; there are no external assets or dependencies.

## Play

Install [LÖVE](https://love2d.org/), then run from this folder:

```sh
love .
```

The large lower board controls the battle above. Clear rows to damage the current enemy and regain ground. Monsters attack on a timer, pushing the knight left. Reach the left edge or fill the board and the run ends. Defeat the Iron Warden to clear the keep.

| Clear | Damage | Ground regained |
| --- | --- | --- |
| Single | 1 | 3.5% |
| Double | 3 | 7% |
| Triple | 5 | 10.5% |
| Tetris / critical | 9 | 14% |

The red bar is enemy health; the gold bar below the dungeon is your remaining ground. The small gold meter beside enemy health shows time until the next attack. Defeating an enemy grants a short travel break. The board carries through the entire run.

## Controls

| Key | Action |
| --- | --- |
| Left / Right or A / D | Move piece |
| Down or S | Soft drop |
| Up / W / X | Rotate clockwise |
| Z | Rotate counterclockwise |
| Space | Hard drop |
| C / Shift | Hold, once per piece |
| P / Escape | Pause / resume |
| R | Restart |
| M | Mute / unmute |
| Enter / Space after run | Play again |

The board uses a seven-piece bag, four visible previews, a landing ghost, wall kicks, and a short lock delay. Consecutive line-clearing placements earn bonus points. Losing focus pauses play.

## Files and checks

- `main.lua`: rendering, pixel art, keyboard input, effects, and synthesized sound.
- `game.lua`: board rules, piece movement, scoring, and dungeon combat.
- `conf.lua`: window and LÖVE configuration.
- `tests/game_test.lua`: deterministic gameplay checks; run with `lua tests/game_test.lua`.

Tuning lives in `game.lua`: enemy health, attack interval, retreat strength, line damage, and gravity. Rotation uses a compact wall-kick system rather than the full guideline SRS tables.
