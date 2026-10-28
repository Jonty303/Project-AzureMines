# Project Azure Mines — Loot, Treasure and Town Economy v0.1

**Status:** Design contract only. No reward generator, inventory, shop, purchasing, loot UI or economic balance has been implemented in the current combat build.

## Core philosophy

Combat awards **experience and usually modest gold**, with an occasional consumable. An encounter can award no monetary loot at all. Most defeated creatures never yield equippable items.

We explicitly **do not present ordinary gear as loot**: tattered leather armour, standard swords, weapons taken from goblins, and routine vendor trash are not collected into the party inventory or monetized by stripping corpses. That does not prohibit purchasing mundane equipment when required by the adventure or receiving quest-critical items.

**Magical items are scarce, recognisable and meaningful**, not a continuous stream of incremental upgrades. Their presentation is a distinctive name; their inspection sheet still reveals the exact mechanical benefits, item type and any restrictions. A magic item may be:

1. **Authored and fixed:** a named enemy, quest, cache or story event grants a specified item (possibly conditionally).
2. **Generated but constrained:** a rare generated drop uses a compatible base item, limited mechanics, naming tables and a deterministic generation seed.
3. **Merchant stock:** a curated shop may sell an authored item or occasionally receive a generated one, subject to campaign pacing and availability conditions.

Magic items are **never guaranteed** by defeating routine encounters, and vendors should not offer broad catalogues of powerful equipment at low levels.

## Typical rewards

- **XP:** determined by encounter/quest rules; display in the victory summary. XP is not an inventory item and cannot be sold.
- **Gold:** pooled party money, expressed in gp with accounting for any other denominations only if the broader economy requires them. Reward amount can be zero.
- **Consumables:** limited quantities of useful items such as potions, scrolls or ammunition where appropriate; only if mechanically usable. Most fights drop none.
- **Significant items:** authored quest tokens, named magic equipment, or a deliberately rare generated item. These appear separately from currency.

Suggested victory screen:

```text
Victory
  Experience gained: 100 XP
  Coins recovered: 12 gp
  Useful supplies: Healing Potion ×1
  Notable equipment: — none —

  [Continue]
```

This is a **format example**, not a balance commitment or a guaranteed goblin reward. If nothing besides XP or coin is awarded, the UI should not render an empty equipment table.

No random equipment loot should be added to the current tutorial encounter before reward rules and persistent inventory exist.

## Item identities and names

Naming patterns are data-driven and should match an item's actual mechanical traits, not merely roll unrelated fantasy words:

- **Name, Item of Theme:** `Icefang, Sword of Winter` — example longsword, +1 to attack and damage, extra 1d4 Cold on a hit.
- **The Epithet:** `The Pride of the North` — example enchanted leather armour providing Cold Resistance.
- **Name, the Epithet:** `Grimwake, the Oathbreaker` — example battleaxe with a narrow bonus against Undead.

These are sample designs only. At levels 1–5, multiple simultaneous enhancement effects may be too strong and should be rarer still.

Name generation must enforce **semantic compatibility**:
- Frost/cold vocabulary only with relevant cold effects or provenance; fire-themed weapons need appropriate fire mechanics.
- Weapon-specific nouns agree with the generated base item; armour names need not expose their item type.
- Templates, prefixes, epithets, effect affixes and lore origins are separate pools with compatibility tags.
- The generator must reject duplicate names already created in the same campaign, or apply a deterministic alternate.
- A generated item has a permanent unique instance ID, a stable rolled definition, a provenance and seed. **Never reroll an item on loading a save**.

Avoid displaying `Longsword +1` as the main name. A detailed inspection can report `Longsword; +1 attack and damage; 1d4 Cold` so the player understands exactly what it does.

## Shops and gold sinks

Gold is chiefly useful in **towns and settlements**. Spending should create meaningful choices, not mandatory grind.

### Ordinary services (always or widely available)

- Inns, rations, modest travel costs and ordinary supplies.
- Healing and restoration at a temple or healer where the adventure permits them. Such services should be priced, accessible and not act as a substitute for every class ability.
- Ammunition, limited consumables, identification/appraisal and basic utility purchases.
- Potential later gold sinks: transport, safehouses, civic fees, property or camp upgrades, special training or commissions (only if they suit our class-progression design).

### Occasional magical stock

- Named magic weapons, armour, jewellery, scrolls and other suitable items may **appear from time to time** in specific shops.
- Give shops identities: a frontier outfitter sells supplies, a temple sells restorative services, a specialist trader/curio dealer may acquire unusual magical items.
- Availability is controlled by **in-game time, local events, reputation, inventory history and campaign progression**, not external clock time.
- Shop inventory is generated or selected **when a restock event occurs**, then persisted. Reopening the merchant cannot reroll stock.
- Rare items should command significant gold and sometimes depend on a quest or reputation requirement; prices and restock intervals are not locked yet.
- No daily-login pressure, real-money mechanics, infinite random rerolls or MMO-style item flood.

Money sinks should keep currency relevant even when no special item is currently available. The party should also be able to save towards a remarkable purchase, rather than needing to buy incremental upgrades.

## Separating rules, adventure and runtime

The **ruleset** owns generic definitions and effects (damage bonuses, resistances, charges, attunement/requirements where applicable).

The **adventure** owns reward opportunities, authored item placement, merchant locations, stock pools, prices and restock triggers, and any story-specific item provenance.

The **runtime** validates an award, creates a fixed item instance, records party gold/XP, produces the victory summary, stores merchants' current stocks and executes purchase/sell transactions.

Do not execute code from adventure data. Use versioned JSON, stable IDs and typed effects/conditions. For authored magic treasure, prefer explicit IDs; for generated treasure, persist the exact resolved result, not just an instruction to reroll.

## Example future content schema (illustrative, not yet loadable)

```json
{
  "schema_version": 1,
  "id": "frontier_bandit_camp",
  "rewards": {
    "xp_source": "encounter_budget",
    "gold": {"mode": "fixed", "gp": 12},
    "consumables": [
      {"item_id": "classic_5e:item/potion_of_healing", "chance": 0.15, "quantity": 1}
    ],
    "magic": {
      "authored_item_ids": [],
      "generated_table_id": null
    }
  }
}
```

```json
{
  "schema_version": 1,
  "id": "frontier_curio_dealer",
  "location_id": "frontier_town",
  "services": ["identify", "appraise"],
  "stock": {
    "everyday_item_ids": [],
    "authored_magic_item_ids": [],
    "rare_magic_table_id": "regional_minor_treasures",
    "restock_event_id": "merchant_new_shipment"
  }
}
```

These are examples to define boundaries, not commitments to those exact data fields or probabilities. The 0.15 example is **not** a global consumable drop rate.

## Economy acceptance criteria for a future milestone

1. Ordinary goblins award XP and perhaps coin; no shabby equipment appears in loot.
2. Routine victories can result in **XP only**, or XP + gold, without an empty equipment list.
3. Some rewards can include consumables; a scripted named foe can grant a fixed unique magic item.
4. Defeat/reload cannot award the same encounter rewards repeatedly.
5. Gold/XP awards, item instance generation and inventory operations are deterministic under a fixed seed and persist across saves.
6. A shop has ordinary goods/services and can occasionally offer named magic stock; reopening it does not change the items.
7. Buying services and items reduces party gold and updates stock atomically; overdraw and duplicate-purchase bugs are prevented.
8. Generated item name and effects agree, and inspection reports the full mechanics.
9. Balance tests track gold gained versus mandatory/optional expenses at levels 1–5, rather than depending on arbitrary loot inflation.
10. The authored adventure can override drops, restocking and pricing without changing the rules engine.

## Not decided yet

Precise gold/XP amounts, restock cadence, magic-item availability, buying/selling ratios, gold caps, item rarity weights, crafting and upgrade systems. Define these using playtest data and story pacing rather than inventing economy numbers now.
