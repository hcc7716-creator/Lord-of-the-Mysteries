# Pathway Data

This folder contains gameplay-ready data extracted and adapted from the current project Markdown documents. All 22 pathways are currently implemented: `fool`, `error`, `door`, `visionary`, `sun`, `tyrant`, `white_tower`, `hanged_man`, `darkness`, `death`, `twilight_giant`, `demoness`, `red_priest`, `hermit`, `paragon`, `wheel_of_fortune`, `mother`, `moon`, `abyss`, `chained`, `black_emperor`, and `justiciar`.

## Files

| File | Purpose |
| --- | --- |
| `pathways.json` | One record per pathway. Currently contains all 22 pathways. |
| `sequences.json` | One record per sequence. Currently contains 220 records across all 22 pathways from Sequence 9 to Sequence 0. |
| `materials.json` | Potion materials, auxiliary materials, special requirements, and unknown placeholders related to the implemented pathways. |
| `items.json` | Unified game item table generated from materials, sealed artifacts, and manual MVP seed items. Use this for inventory, shops, equipment, quests, potion crafting, and containment UI. |
| `abilities.json` | Gameplay ability data for investigation, combat, escape, identity, summon, miracle, and authority systems. |
| `rituals.json` | Advancement rituals for sequences that have explicit ritual requirements. Low sequences without rituals use `advancement_ritual: null` in `sequences.json`. |
| `characteristics.json` | Beyonder characteristic records for each implemented pathway sequence. |
| `sealed_artifacts.json` | Pathway-related sealed artifacts, magical items, or special spaces. |

## ID Naming Rules

All IDs use lowercase English plus underscores. Do not use spaces, Chinese characters, camelCase, or punctuation.

| Type | Pattern | Example |
| --- | --- | --- |
| Pathway | `{pathway}` | `fool`, `error`, `door` |
| Sequence | `{pathway}_{sequence_number}_{sequence_en}` | `fool_09_seer`, `fool_08_clown` |
| Material | `mat_{material_en}` | `mat_lavos_squid_blood` |
| Item | Reuse source ID for converted records, `item_{short_name}` for manual seed records | `mat_lavos_squid_blood`, `artifact_2_049_antigonus_family_puppet`, `item_broken_pocket_watch` |
| Ability | `skill_{sequence_or_pathway}_{ability_en}` | `skill_seer_spiritual_vision` |
| Ritual | `ritual_{pathway}_{sequence_number}_{short_name}` | `ritual_fool_05_marionettist` |
| Characteristic | `char_{pathway}_{sequence_number}_{sequence_en}` | `char_fool_09_seer` |
| Artifact | `artifact_{code_or_short_name}` | `artifact_2_049_antigonus_family_puppet` |

## Canon Status

Every record must include `canon_status`.

| Value | Meaning |
| --- | --- |
| `novel_confirmed` | Explicitly appears in the first novel. |
| `book2_confirmed` | Appears in *Circle of Inevitability*. |
| `official_supplement` | From author interviews, official encyclopedia, or official supplements. |
| `wiki_only` | From Wiki or current collected notes, not yet independently verified against the text. |
| `game_adapted` | Adapted for gameplay, UI, tasks, or systems. |
| `original_placeholder` | Original temporary placeholder used to keep data complete. |

When uncertain, do not use `novel_confirmed`. Prefer `wiki_only`, `game_adapted`, or `original_placeholder`, and explain the uncertainty in `source_note`.

## Source Note

Every record must include `source_note` as a string array.

Examples:

```json
["当前 Markdown 文档 3.1", "Lord of the Mysteries Wiki", "游戏化改编"]
```

```json
["原资料未公开", "项目占位"]
```

Use `source_note` to keep canon data separate from gameplay adaptation. If a value is an invented UI behavior, cost, cooldown, quest hook, or system tag, include `游戏化改编`.

## Chinese Fields vs English IDs

Chinese fields such as `sequence_name_cn`, `ability_name_cn`, and `description` are for player-facing UI, editor readability, and design review.

English IDs such as `sequence_id`, `ability_id`, and `material_id` are for code, database joins, saves, quest references, inventory references, and UI binding.

Never join records by Chinese display names. Always join by stable IDs.

## Adding the Next Pathway

1. Add one new pathway record to `pathways.json`.
2. Add all 10 sequence records to `sequences.json`.
3. Add materials referenced by those sequences to `materials.json`.
4. Add only gameplay-ready abilities to `abilities.json`; mark all adapted UI values as `game_adapted`.
5. Add rituals only when the source or design notes explicitly provide them. Do not invent rituals for low sequences.
6. Add one characteristic record per sequence.
7. Add only pathway-related artifacts to `sealed_artifacts.json`.
8. Validate every JSON file before using it in code.

## Avoiding Canon Confusion

- Do not mark gameplay costs, cooldowns, UI hints, quest IDs, or animation hints as canon.
- Do not mark uncertain Wiki-derived formulas as `novel_confirmed` unless they have been checked against the novel text.
- Keep source-derived names and descriptions in the relevant record, but put gameplay transformations in `game_adaptation_note` or `source_note`.
- Use `unknown`, `null`, empty arrays, or `original_placeholder` when source data is missing.
