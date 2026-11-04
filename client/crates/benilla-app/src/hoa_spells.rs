//! Display rows for HoA's custom spells, which the installed 1.12.1 `Spell.dbc` cannot hold.
//!
//! Transitional: this static table is the first slice of the shared content pack. The ids and the
//! English text will move to `shared/content` once the content compiler lands; the client lookup
//! path (`SpellCatalog::with_overlay`) stays the same.

use std::collections::HashMap;

use benilla_formats::SpellDisplay;

pub(crate) const DETERMINATION: u32 = 60001;
pub(crate) const DASH: u32 = 60002;
pub(crate) const WOUNDS: u32 = 60003;
pub(crate) const DARKMOON_SURGE: u32 = 60004;
pub(crate) const SHIELD: u32 = 60005;
pub(crate) const CARD_HASTE: u32 = 60006;
pub(crate) const CARD_SWIFT: u32 = 60007;
pub(crate) const CARD_IMMUNE: u32 = 60008;
pub(crate) const SOULSTONE: u32 = 60009;
pub(crate) const CARD_THORNS: u32 = 60010;
pub(crate) const DASH_RECHARGE: u32 = 60011;
pub(crate) const TIGERS_FURY: u32 = 60012;
pub(crate) const ARCANE_POWER: u32 = 60013;
pub(crate) const SHADOW_DANCE: u32 = 60014;
pub(crate) const ENVENOM: u32 = 60015;
pub(crate) const DARK_PACT: u32 = 60016;
pub(crate) const SOUL_HARVEST: u32 = 60017;
pub(crate) const GLYPH_HASTE: u32 = 60018;
pub(crate) const ICE_BLOCK: u32 = 60019;
pub(crate) const NOMAD: u32 = 60020;

fn display(id: u32, name: &str, icon: &str, description: &str) -> SpellDisplay {
    let mut row = SpellDisplay::default();
    row.id = id;
    row.name = name.to_string();
    row.icon = Some(icon.to_string());
    row.description = Some(description.to_string());
    row.aura_description = Some(description.to_string());
    row
}

/// Every custom HoA spell row the client may be asked to render.
pub(crate) fn overlay() -> HashMap<u32, SpellDisplay> {
    [
        (
            DETERMINATION,
            display(
                DETERMINATION,
                "Determination",
                r"Interface\Icons\Spell_Holy_DevotionAura",
                "Each stack increases your damage. Stacks fall off when you leave combat or fall.",
            ),
        ),
        (
            DASH,
            display(
                DASH,
                "Dash",
                r"Interface\Icons\Ability_Rogue_Sprint",
                "Charges of your movement ability.",
            ),
        ),
        (
            WOUNDS,
            display(
                WOUNDS,
                "Wounded",
                r"Interface\Icons\Ability_Creature_Poison_02",
                "Reduces the healing you receive.",
            ),
        ),
        (
            DARKMOON_SURGE,
            display(
                DARKMOON_SURGE,
                "Darkmoon Surge",
                r"Interface\Icons\INV_Misc_Ticket_Darkmoon_01",
                "A Darkmoon card grants a burst of power.",
            ),
        ),
        (
            SHIELD,
            display(
                SHIELD,
                "Shield",
                r"Interface\Icons\Spell_Holy_PowerWordShield",
                "Absorbs incoming damage.",
            ),
        ),
        (
            CARD_HASTE,
            display(
                CARD_HASTE,
                "Haste Burst",
                r"Interface\Icons\Spell_Nature_Slow",
                "A Darkmoon card grants a burst of haste.",
            ),
        ),
        (
            CARD_SWIFT,
            display(
                CARD_SWIFT,
                "Swiftness",
                r"Interface\Icons\Ability_Rogue_Sprint",
                "A Darkmoon card grants movement speed at low health.",
            ),
        ),
        (
            CARD_IMMUNE,
            display(
                CARD_IMMUNE,
                "Immune",
                r"Interface\Icons\Spell_Holy_DivineIntervention",
                "A Darkmoon card briefly makes you immune to damage.",
            ),
        ),
        (
            SOULSTONE,
            display(
                SOULSTONE,
                "Soulstone",
                r"Interface\Icons\INV_Misc_Orb_03",
                "A Darkmoon card saves you from death.",
            ),
        ),
        (
            CARD_THORNS,
            display(
                CARD_THORNS,
                "Thorns",
                r"Interface\Icons\Spell_Nature_Thorns",
                "A Darkmoon card reflects damage back at attackers.",
            ),
        ),
        (
            DASH_RECHARGE,
            display(
                DASH_RECHARGE,
                "Dash Recharge",
                r"Interface\Icons\Spell_Nature_Slow",
                "Your next dash charge is recharging.",
            ),
        ),
        (
            TIGERS_FURY,
            display(
                TIGERS_FURY,
                "Tiger's Fury",
                r"Interface\Icons\Ability_Druid_TigersRoar",
                "Your attacks are faster for a short time.",
            ),
        ),
        (
            ARCANE_POWER,
            display(
                ARCANE_POWER,
                "Arcane Power",
                r"Interface\Icons\Spell_Nature_StarFall",
                "Your spells deal more damage for a short time.",
            ),
        ),
        (
            SHADOW_DANCE,
            display(
                SHADOW_DANCE,
                "Shadow Dance",
                r"Interface\Icons\Spell_Shadow_Shadowform",
                "Your stealth abilities are usable for a short time.",
            ),
        ),
        (
            ENVENOM,
            display(
                ENVENOM,
                "Envenom",
                r"Interface\Icons\Ability_Rogue_Eviscerate",
                "Your poisons strike harder for a short time.",
            ),
        ),
        (
            DARK_PACT,
            display(
                DARK_PACT,
                "Dark Pact",
                r"Interface\Icons\Spell_Shadow_ShadowBolt",
                "Your demons deal more damage for a short time.",
            ),
        ),
        (
            SOUL_HARVEST,
            display(
                SOUL_HARVEST,
                "Soul Harvest",
                r"Interface\Icons\Spell_Shadow_SoulGem",
                "Your hits deal more damage for a short time.",
            ),
        ),
        (
            GLYPH_HASTE,
            display(
                GLYPH_HASTE,
                "Bloodlust",
                r"Interface\Icons\Spell_Nature_BloodLust",
                "A glyph grants a burst of haste.",
            ),
        ),
        (
            ICE_BLOCK,
            display(
                ICE_BLOCK,
                "Ice Block",
                r"Interface\Icons\Spell_Frost_FrostNova",
                "You are protected from damage for a short time.",
            ),
        ),
        (
            NOMAD,
            display(
                NOMAD,
                "Nomad",
                r"Interface\Icons\Spell_Nature_Slow",
                "The Nomad glyph's drawback: less power for a short time.",
            ),
        ),
    ]
    .into_iter()
    .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use benilla_formats::SpellCatalog;

    #[test]
    fn custom_rows_are_visible_through_the_catalog() {
        let catalog = SpellCatalog::from_displays(HashMap::new()).with_overlay(overlay());
        let determination = catalog.get(DETERMINATION).expect("custom spell");
        assert_eq!(determination.name, "Determination");
        assert!(determination.icon.is_some());
        assert!(catalog.get(1).is_none());
    }
}
