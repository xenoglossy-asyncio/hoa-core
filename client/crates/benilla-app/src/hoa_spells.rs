//! Display rows for HoA's custom spells, which the installed 1.12.1 `Spell.dbc` cannot hold.
//!
//! The rows are generated from `shared/content/spells/spells.yaml`; the account language picked
//! here is the one the addon stores in `hoaLanguage`, not the install's locale.

use std::collections::HashMap;

use benilla_formats::SpellDisplay;

use crate::hoa_spells_generated::{GeneratedSpell, SPELLS};

fn display(row: &GeneratedSpell, language: &str) -> SpellDisplay {
    let chinese = language.eq_ignore_ascii_case("zhCN");
    let (name, description) = if chinese {
        (row.name_zh_cn, row.description_zh_cn)
    } else {
        (row.name_en, row.description_en)
    };
    let mut display = SpellDisplay::default();
    display.id = row.id;
    display.name = name.to_string();
    display.icon = Some(row.icon.to_string());
    display.description = Some(description.to_string());
    display.aura_description = Some(description.to_string());
    display
}

/// Every custom HoA spell row the client may be asked to render, in `language`.
pub(crate) fn overlay(language: &str) -> HashMap<u32, SpellDisplay> {
    SPELLS
        .iter()
        .map(|row| (row.id, display(row, language)))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use benilla_formats::SpellCatalog;

    #[test]
    fn custom_rows_are_visible_through_the_catalog() {
        let catalog = SpellCatalog::from_displays(HashMap::new()).with_overlay(overlay("enUS"));
        let determination = catalog.get(60001).expect("custom spell");
        assert_eq!(determination.name, "Determination");
        assert!(determination.icon.is_some());
        assert!(catalog.get(1).is_none());
    }

    #[test]
    fn rows_follow_the_account_language() {
        let english = overlay("enUS");
        let chinese = overlay("zhCN");
        assert_eq!(english[&60001].name, "Determination");
        assert_eq!(chinese[&60001].name, "决心");
        assert_eq!(overlay("zhTW")[&60001].name, "Determination");
    }
}
