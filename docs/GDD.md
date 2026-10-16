# Game Design Document (lean draft)

**Working title:** *Ashfrost: The Last Warden*

## Pitch

3D **isometric low-poly** action-adventure: rune temples, contracts, light combat, puzzles, and class-based god legacies. **V1 prototype** (target scope):

- Isometric movement and camera
- **One temple dungeon:** *Tomb of the First God*
- Light melee vs. one enemy type; one puzzle room (switches, blocks, door)
- **Warrior** as placeholder class (other legacies stubbed or TBD)

Visual target: flat-colored low-poly models on a fixed scale, readable sun shadows, subtle mood lighting (warm/cool).

## World & story

### Setting

A **northern land** locked in an **endless winter**. The old **gods are dead**; their **corpses became rune temples**—each corpse a sanctum whose runes still bleed warmth and hold the frost at bay. As temples **go dark**, winter advances and the map changes.

### Tone

Blend of:

- **Skyrim** — northern myth, runes, mountains, frontier survival
- **The Witcher** — morally grey **contracts**; no clean heroes
- **God of War** — intimate **parent–child** story inside epic myth

### Premise

The player is a **disgraced, exiled warden** who **broke his oath**. He travels with his **teenage daughter**. Temples are failing one by one. The daughter is **slowly absorbing a dead god’s power**; the father must decide whether to **hide it or let it grow** (long-arc TBD).

### Open questions (TBD)

- Warden’s oath and the act that broke it
- Which god’s power the daughter carries; cost of growth
- End state when all temples are dark (or saved)

## Classes / roles

Classes are **inherited god legacies**—not job picks, but fragments of dead divinity.

| Class | Role (draft) | V1 |
|-------|----------------|-----|
| **Warrior** | Frontline melee, shield/oath motifs | **Yes** (prototype) |
| **Rune-reader** | Signs, wards, puzzle affordances | Post-V1 |
| **Hunter** | Ranged, tracks, traps | Post-V1 |

Ability kits, stamina, and tuning: TBD.

## Combat

- Real-time, light melee; readable telegraphs; no complex combos in V1.
- Temple **guardians** as contract bosses; kill/spare choice at end (system post-V1; one guardian TBD for slice).
- Damage, stamina, and enemy tuning: TBD.

## Quests & core loop

### Core loop

1. **Travel** the winter frontier to a failing temple.
2. **Enter** the corpse-temple (puzzle dungeon + combat).
3. **Complete a contract** (objective + optional clues; Witcher-grey framing).
4. **Face the guardian** — **moral choice:** kill or spare.
5. **World reacts** (temple state, NPC attitudes, winter creep — full reactivity post-V1).
6. **Return / press on** to the next darkening temple (more temples post-V1).

### Prototype slice

- **One temple:** *Tomb of the First God*
- Warrior placeholder; one puzzle room; one enemy type; contract + guardian choice **stubbed or single beat** (implementation TBD)

### Open questions (TBD)

- Contract text format (journal vs. NPC briefings)
- How kill/spare flags propagate (per-temple, faction, daughter arc)
- Hub vs. linear temple order

## Out of scope for V1

Multiplayer, crafting, full skill trees, **daughter companion gameplay**, **full moral-choice system**, **rune-reader / hunter** kits, **multiple temples**, final art/audio.
