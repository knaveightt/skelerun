# SKELERUN — The Sunken Keep

A standalone LÖVE 11.x game prototype: falling blocks power a knight's battle through a five-enemy dungeon. All art and sound are generated in the game; there are no external assets or dependencies.

## Play

Install [LÖVE](https://love2d.org/), then run from this folder:

```sh
love .
```

You start in your dungeon cell. Press **Enter** or click **Leave for the dungeon** to begin a run. Death or victory brings you back to the cell with your gathered materials. During a run, **R** returns early and keeps your materials.

The large lower board controls the battle above. Clear rows to damage the current enemy and regain ground. Monsters attack on a timer, pushing the knight left. Reach the left edge or fill the board and the run ends. Defeat the Iron Warden to clear the keep.

| Clear | Damage | Ground regained |
| --- | --- | --- |
| Single | 1 | 3.5% |
| Double | 3 | 7% |
| Triple | 5 | 10.5% |
| Tetris / critical | 9 | 14% |

The red bar is enemy health; the gold bar below the dungeon is your remaining ground. The small gold meter beside enemy health shows time until the next attack. Defeating an enemy grants a short travel break. The board carries through the entire run.

## Resources

Each block removed in a cleared line grants **10 resources**, according to its original piece type. Each row is counted separately, including multi-line clears. Placing a piece without clearing a line gives no resources. The HUD tracks your total stash, including materials from earlier runs. Materials persist after death, victory, returning early, and closing the game.

| Piece type | Resource |
| --- | --- |
| T-piece | Tin |
| S-piece / Z-piece | Iron |
| L-piece / J-piece | Copper |
| O-piece | Orichalcum |
| I-piece | Platinum |

A completed row always awards 100 total resources, split by its ten blocks. For example, six J-piece blocks and four I-piece blocks yield 60 Copper and 40 Platinum.

## Dungeon cell and Blacksmith

The cell contains a locked **Blacksmith** workshop. Collect **500 Iron and 500 Copper**, then press **B** or click the workshop card to unlock it. Unlocking spends exactly 500 of each material and is permanent. Both costs must be met; an unsuccessful attempt spends nothing. The restored forge lights up, but weapon and armor refining are reserved for a later update.

Your stash and Blacksmith unlock save automatically in LÖVE's `skelerun` save directory (`progress.dat`). Each run starts with a fresh board and enemies while retaining your stash. The cell shows the last run's result and gathered materials.

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
| R during run | Return to cell with materials |
| M | Mute / unmute |
| Enter / Space in cell | Start dungeon run |
| B in cell | Unlock / inspect Blacksmith |
| Mouse in cell | Click workshop or dungeon button |

The board uses a seven-piece bag, four visible previews, a landing ghost, wall kicks, and a short lock delay. Consecutive line-clearing placements earn bonus points. Losing focus pauses play.

## Files and checks

- `main.lua`: rendering, pixel art, keyboard input, effects, and synthesized sound.
- `game.lua`: board rules, piece movement, scoring, and dungeon combat.
- `session.lua`: cell/run transitions, persistent inventory, workshop unlock, and save format.
- `conf.lua`: window and LÖVE configuration.
- `tests/game_test.lua`: deterministic gameplay checks; run with `lua tests/game_test.lua`.
- `tests/session_test.lua`: cell, inventory, unlock, and persistence checks; run with `lua tests/session_test.lua`.

Tuning lives in `game.lua`: enemy health, attack interval, retreat strength, line damage, and gravity. Rotation uses a compact wall-kick system rather than the full guideline SRS tables.
