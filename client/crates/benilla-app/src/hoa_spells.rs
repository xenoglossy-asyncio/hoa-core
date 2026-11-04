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
