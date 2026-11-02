# SKELERUN — The Sunken Keep

A native **Godot 4.7.2** project. This is the active version of the prototype going forward. The original LÖVE source, tests, documentation, and `.love` build are preserved in [`old_project/`](old_project/). Godot ignores that directory during resource imports. The engine-independent design notes remain in `doc/design.org`.

## Open and play

Import `project.godot` in Godot **4.7.2**, open the project, and press **F5**. No plugins, .NET, asset downloads, or LÖVE installation are needed. All pixel art and sounds are generated with Godot's native drawing and audio APIs.

With a Godot executable on your command line:

```sh
godot --path .
```

The portrait window resizes with a 500×800 logical canvas, keeping the full board visible at narrow phone aspect ratios. Mobile orientation is locked to portrait. The Compatibility renderer supports OpenGL 3.3 hardware.

## The loop

You begin in your dungeon cell. Tap **Choose a Dungeon** (or press **Enter**) to choose a destination. All six dungeons are open. Select with **1–6**, **Up/Down**, or a mouse click, then press **Enter** or click **Begin Run**. **Escape** or **Back to Cell** cancels selection.

Play the large falling-block board to fight enemies in the dungeon strip above it. Runs are **endless until you lose**: each defeated enemy is replaced, with no final boss victory or fixed kill limit. Monster attacks push the knight left, and continuous retreat pressure gradually pulls you left even between enemies. Cleared lines restore ground. Reaching the left edge or filling the board ends the run.

Death or an early return brings you back to your cell with all materials collected. Your board and enemies reset for the next run; your stash and workshop unlock remain.

| Clear | Enemy damage | Ground regained |
| --- | --- | --- |
| Single | 1 | 3.5% |
| Double | 3 | 7% |
| Triple | 5 | 10.5% |
| Tetris / critical | 9 | 14% |

The red bar shows enemy health. The gold meter next to it fills toward the next monster attack. The gold bar under the dungeon shows your remaining ground. Defeated enemies grant a short travel break.

The board retains the original seven-piece bag, hold, four visible previews, landing ghost, soft/hard drop, compact wall kicks, 0.45-second lock delay, and combo score bonus. The wall kicks match the prototype rather than full guideline SRS.

## Dungeons (easiest to hardest)

| Destination | Battle-panel theme | Native enemies |
| --- | --- | --- |
| Dungeon Halls | Original torchlit stone keep | Crypt Rat, Bone Guard, Mire Slime, Keep Wraith, The Iron Warden |
| Dungeon Crypts | Underground burial niches, headstones, and drifting mist | Grave Ghoul, Shambling Corpse, Bonewing Bat, Tomb Keeper |
| Dungeon Lava Pits | Lava channels, stalactites, embers, and scorched rock | Ember Imp, Cinder Hound, Magma Ooze, Furnace Golem |
| Dungeon Sewers | Corroded pipes, dripping acid, and green runoff | Acid Crawler, Caustic Leech, Bile Toad, Sludge Brute |
| Dungeon Courtyard | Moonlit outdoor ruins, snow-covered trees, and falling snow | Frost Moth, Rime Wolf, Snow Revenant, Glacier Giant |
| Dungeon Throne Room | Gold pillars, royal banners, and crimson carpet | Gilded Sentinel, Court Hexer, Crown Mimic, The Fallen Regent |

Each destination opens by showing every native enemy. Later, every fifth encounter can draw a visitor from an easier dungeon. Harder enemies never appear in easier destinations. Each enemy has a distinct name and pixel-art sprite. Fire, acid, ice, and royal themes currently affect appearance and base encounter difficulty; resistance/status systems remain future work.

### Endless pressure and tuning

Later destinations start with stronger enemies, shorter attack intervals, stronger knockback, and faster continuous retreat. Within a run, elapsed active playtime increases retreat speed without a fixed cap. Enemy health also grows with time and encounter count; attack intervals shorten (to a 2.2-second floor), and hits push harder (to a 35% maximum). Pausing freezes the run clock and all pressure. A new run resets its clock, encounter count, enemies, and board.

The header shows destination, active run time, and the continuous retreat multiplier relative to the starting Halls rate. **Foe** counts encounters; **Slain** is an unrestricted total. Returning to the cell records the dungeon, time, enemies slain, and gathered materials.

Balance is deliberately exposed in `scripts/run.gd`: base retreat is `(0.0015 + elapsed_seconds × 0.000025) × (1 + dungeon_index × 0.22)` ground per second. Enemy data and dungeon order live in `scripts/dungeons.gd`. The board and resource rules are identical across destinations. No dungeon progression gates are implemented yet.

## Materials and Blacksmith

Every cleared block grants **10 materials**, according to its original tetromino. Each individual cleared row records its composition, including multi-line clears. Placement alone gives no materials.

| Piece | Material |
| --- | --- |
| T-piece | Tin |
| S-piece / Z-piece | Iron |
| L-piece / J-piece | Copper |
| O-piece | Orichalcum |
| I-piece | Platinum |

The Blacksmith starts locked. In your cell, press **B** or click its workshop card to spend **500 Iron AND 500 Copper** and permanently unlock it. Failed attempts spend nothing; it cannot charge a second time. Its forge lights up when restored. Weapon and armor refinement are intentionally reserved for later.

## Touch and mobile controls

Every action can be performed without a keyboard. Tap buttons and cards to navigate; actions trigger on finger release, and dragging between menu buttons does not activate them. The same interactions work with a mouse on desktop.

| Touch interaction | Action |
| --- | --- |
| Swipe left / right on the board | Move by one column per block-width of finger travel; drag farther for multiple columns |
| Swipe down on the board | Hard drop immediately, once per swipe |
| Swipe up on the board | Rotate clockwise once per swipe |
| Tap **Hold** | Store / swap the held piece, once per placement |
| Tap **Rotate <** | Rotate counterclockwise |
| Press and hold **Soft Drop** | Lower the piece faster until released or slid away |
| Tap **Pause** | Open the pause menu |
| Tap **Continue** / **Abandon Run** | Resume / return to cell with collected materials |
| Tap **Sound** in pause or cell settings | Mute / unmute |
| Tap the Blacksmith scene or card | Unlock / inspect workshop |
| Tap the stairs or **Choose a Dungeon** | Open dungeon selection |
| Tap a dungeon card, then **Begin Run** | Start the selected dungeon |
| Tap **Back to Cell** | Cancel selection or close settings |
| Tap **Settings** in the cell | Access sound and **Reset All Progress** |
| Tap **Reset All** / **Cancel** in the confirmation | Confirm / cancel a full progress reset |

You can hold **Soft Drop** with one finger and move the piece with another. Only one board gesture owns the falling piece at a time. Horizontal swipes stay horizontal, small jitter is ignored, and a gesture cannot act on the next piece if the previous piece locks. Losing focus clears held inputs and pauses. Android's Back action dismisses dialogs/selection or opens pause during a run.

Touch and mouse emulation are disabled to prevent a single physical touch from triggering duplicate actions. Native touch events and mouse events use the same gesture handler. Touch controls are always visible; touching the screen switches keyboard hints to touch hints.

These are controls and project settings, not an Android/iOS export package. Validation uses synthesized native touch events and phone-sized render viewports; physical-device testing is still to be done.

## Keyboard controls

| Key | Action |
| --- | --- |
| Enter / Space in cell | Open dungeon selection |
| 1–6 / Up / Down in selection | Select destination |
| Enter / Space in selection | Begin selected run |
| Escape / Backspace in selection | Return to cell |
| B in cell | Unlock / inspect Blacksmith |
| R in cell | Ask to reset all progress (Y confirms; N / Escape cancels) |
| Mouse | Click cell actions, dungeon cards, Begin Run, or Back to Cell |
| Left / Right or A / D | Move piece |
| Down or S | Soft drop |
| Up / W / X | Rotate clockwise |
| Z | Rotate counterclockwise |
| Space during run | Hard drop |
| C / Shift | Hold, once per placement |
| P / Escape | Pause / resume |
| R during run | Return to cell with materials |
| M | Mute / unmute |

The pause menu has touch/clickable **Continue**, **Abandon Run**, and **Sound** options. Click **Abandon Run** or press **R** to return to the cell with your gathered resources.

Losing window focus pauses a run. Keyboard repeat is handled by the game, independently of operating-system repeat settings.

## Reset progress

In the dungeon cell, tap **Settings → Reset All Progress**, or press **R**, to open **Reset all progress?**. Press **Y** or click **Reset All** to confirm; press **N**, **Escape**, or click **Cancel** to keep your progress. The prompt blocks other cell actions. Confirming clears all five resources, the Blacksmith unlock, and the last run summary, then saves the fresh state. This cannot be undone. If saving fails, the previous progress is retained. During a run, **R** still returns to the cell.

## Saved progress

Inventory and the Blacksmith unlock save after line clears, workshop unlocks, returns, focus loss, and normal window closure. The board itself is temporary: opening the game always starts in your cell.

Godot stores `progress.json` in its `user://` directory, normally:

- Linux: `~/.local/share/godot/app_userdata/SKELERUN/`
- Windows: `%APPDATA%/Godot/app_userdata/SKELERUN/`
- macOS: `~/Library/Application Support/Godot/app_userdata/SKELERUN/`

On first launch, if no Godot save exists, the game checks for the original `love/skelerun/progress.dat` (or `LOVE/skelerun/progress.dat`) under the operating system's application-data directory. It imports resources and the Blacksmith flag once and leaves the LÖVE save untouched. Invalid inventory values are sanitized. Saves use JSON, never executable code, and replace the previous file only after writing a temporary file. A failed save displays a message.

## Project structure

- `project.godot` — active project configuration and starting scene.
- `scenes/main.tscn` — entry scene, running the cell and dungeon views.
- `scripts/main.gd` — input, scene transitions, touch menus, HUD, effects, and synthesized audio.
- `scripts/touch_input.gd` — touch/mouse tracking, axis-locked swipes, multi-touch soft drop, canceled gestures, and safe tap activation.
- `scripts/pixel_art.gd` — reusable native drawing helpers and pixel characters.
- `scripts/run.gd` — board, bag, movement, row composition, scoring, endless combat, and pressure scaling.
- `scripts/dungeons.gd` — six ordered destinations, native rosters, and easier-dungeon visitors.
- `scripts/enemy_art.gd` — twenty new themed creature sprites; original five remain in `pixel_art.gd`.
- `scripts/session.gd` — persistent stash, Blacksmith unlock, save/import, and run lifecycle.
- `tests/` — native Godot rule and interaction tests.
- `doc/design.org` — retained game design notes; future concepts are not automatically implemented.

Tune rosters and base enemy stats in `scripts/dungeons.gd`; tune time scaling, retreat pressure, line damage, and gravity in `scripts/run.gd`.

## Validation

Validated with **Godot 4.7.2.stable.official.ed1daf0bf**.

```sh
# 850 deterministic checks: board, endless combat, all six rosters,
# difficulty ordering, pressure, resources, cell, resets, and persistence.
godot --headless --path . --script res://tests/run_tests.gd

# Interaction flow, selection/cancel, all 25 sprites and six themes,
# reset confirmation, focus pause, and resized mouse input.
# Uses an in-memory session for play and test screenshots in user://.
godot --path . --script res://tests/smoke_test.gd

# Same interaction checks without a display; screenshot capture is skipped.
godot --headless --path . --script res://tests/smoke_test.gd

# 68 native-touch checks covering all menu actions, swipes, hold, multi-touch,
# cancellation, focus loss, and scaled hit testing at phone resolutions.
# With a display, writes touch_*.png phone previews in user://.
godot --path . --script res://tests/touch_test.gd
godot --headless --path . --script res://tests/touch_test.gd
```

For fully isolated test saves on Linux, prefix commands with `XDG_DATA_HOME=/tmp/skelerun-test-data XDG_CONFIG_HOME=/tmp/skelerun-test-config`. Tests create and remove only `test_progress.json`; they never overwrite `progress.json`.
