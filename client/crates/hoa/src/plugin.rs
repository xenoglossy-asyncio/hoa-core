use bevy::log::{info, warn};
use bevy::prelude::*;

use benilla_app::{HoaAuraRow, NetHandlerApp};
use benilla_protocol::{SessionEvent, SessionEventKind};
use benilla_ui::script::{add_in_game_event, ScriptValue};

use crate::controller_lua::deliver_pad_events;
use crate::cursor::{drive_pad_cursor, hide_cursor_for_pad, notice_keyboard_and_mouse};
use crate::interact::{update_interact, SharedInteract};
use crate::keys::{capture_typing, SharedTyping};
use crate::lua_api::{scripted_login_from_env, LuaHosts};
use crate::nameplates::{add_plate_events, track_nameplates, SharedPlates};
use crate::pad::{log_new_pads, poll_pads, SharedController};
use crate::protocol_generated::{self, HoaMessage, CONTENT_HASH, PROTOCOL_VERSION};
use crate::snapshot::{capture_snapshot, SharedSnapshot};
use crate::world_map::SharedMapAreas;
use crate::telegraphs::{expire_telegraphs, follow_marks, project_telegraphs, push_telegraphs, Telegraphs};
use crate::world_fx::{apply_draw_lines, expire_kit_anchors, move_flights, tap_draw_lines, DisplayModels};

const HOA_HELLO: &str = "HOA_HELLO";
const HOA_AURA_VALUE: &str = "HOA_AURA_VALUE";
const HOA_DASH: &str = "HOA_DASH";
const HOA_AURA_PERCENT: &str = "HOA_AURA_PERCENT";

/// Typed HoA packets, drained on the main thread because firing a Lua event needs the VM.
#[derive(Resource, Default)]
struct HoaInbox(Vec<(u16, Vec<u8>)>);

/// A catalog that arrived before the spell catalog existed, retried each frame.
#[derive(Resource, Default)]
struct AuraCatalogBuffer {
    rows: Vec<HoaAuraRow>,
    total: u16,
    active: bool,
    pending: bool,
}

fn apply_pending_catalog(world: &mut World) {
    if !world.resource::<AuraCatalogBuffer>().pending {
        return;
    }
    let rows = {
        let mut buffer = world.resource_mut::<AuraCatalogBuffer>();
        buffer.pending = false;
        std::mem::take(&mut buffer.rows)
    };
    if !benilla_app::set_hoa_aura_catalog(world, &rows) {
        let mut buffer = world.resource_mut::<AuraCatalogBuffer>();
        buffer.rows = rows;
        buffer.pending = true;
    }
}

fn on_hoa_message(In(event): In<SessionEvent>, mut inbox: ResMut<HoaInbox>) {
    if let SessionEvent::HoaMessage { id, body } = event {
        inbox.0.push((id, body));
    }
}

fn deliver_hoa_messages(world: &mut World) {
    let pending = std::mem::take(&mut world.resource_mut::<HoaInbox>().0);
    if pending.is_empty() {
        return;
    }
    let mut value_texts: Vec<(u32, String)> = Vec::new();
    let (mut catalog_rows, mut catalog_total, mut catalog_active) = {
        let buffer = world.resource::<AuraCatalogBuffer>();
        (
            if buffer.active { buffer.rows.clone() } else { Vec::new() },
            buffer.total,
            buffer.active,
        )
    };
    let mut catalog_done = false;
    // The account language arrives with hello. Seat it before the closure fires HOA_HELLO, so the
    // addon's handler and GetLocale already read the new language.
    let account_language = pending.iter().find_map(|(id, body)| {
        match protocol_generated::decode(*id, body) {
            Some(HoaMessage::Hello(hello)) => Some(hello.language),
            _ => None,
        }
    });
    if let Some(language) = account_language {
        benilla_app::set_hoa_account_language(world, &language);
    }
    benilla_app::run_hosted(world, |script| {
        let Some(script) = script else {
            return;
        };
        for (id, body) in pending {
            let Some(message) = protocol_generated::decode(id, &body) else {
                warn!("hoa protocol: unknown message id {id}");
                continue;
            };
            match message {
                HoaMessage::AuraValue(aura) => {
                    script.fire_event(
                        HOA_AURA_VALUE,
                        vec![
                            ScriptValue::Int(i64::from(aura.spell_id)),
                            ScriptValue::Int(i64::from(aura.value)),
                            ScriptValue::Int(i64::from(aura.max_value)),
                        ],
                    );
                }
                HoaMessage::AuraText(text) => {
                    value_texts.push((text.spell_id, text.text));
                }
                HoaMessage::AuraPercent(percent) => {
                    script.fire_event(
                        HOA_AURA_PERCENT,
                        vec![
                            ScriptValue::Int(i64::from(percent.spell_id)),
                            ScriptValue::Number(f64::from(percent.percent)),
                        ],
                    );
                }
                HoaMessage::Dash(dash) => {
                    script.fire_event(
                        HOA_DASH,
                        vec![
                            ScriptValue::Int(i64::from(dash.max_charges)),
                            ScriptValue::Int(i64::from(dash.recharge_ms)),
                            ScriptValue::Int(i64::from(dash.cooldown_ms)),
                            ScriptValue::Bool(dash.blink),
                            ScriptValue::Int(i64::from(dash.charges)),
                        ],
                    );
                }
                HoaMessage::AuraCatalogEntry(entry) => {
                    if entry.index == 0 || !catalog_active {
                        catalog_rows.clear();
                        catalog_active = true;
                    }
                    catalog_total = entry.total;
                    catalog_rows.push(HoaAuraRow {
                        id: entry.spell_id,
                        name: entry.name,
                        icon: entry.icon,
                        description: entry.description,
                        stack_amount: entry.stack,
                        duration_index: entry.duration,
                    });
                }
                HoaMessage::AuraCatalogEnd(end) => {
                    catalog_total = end.total;
                    catalog_done = true;
                }
                HoaMessage::Hello(hello) => {
                    if hello.protocol_version != PROTOCOL_VERSION {
                        warn!(
                            "hoa protocol: server speaks {}, this build speaks {PROTOCOL_VERSION}",
                            hello.protocol_version
                        );
                    }
                    if hello.content_hash != CONTENT_HASH {
                        warn!(
                            "hoa protocol: server content {} does not match this build's {CONTENT_HASH}",
                            hello.content_hash
                        );
                    }
                    script.fire_event(
                        HOA_HELLO,
                        vec![
                            ScriptValue::Int(i64::from(hello.protocol_version)),
                            ScriptValue::Str(hello.content_hash),
                            ScriptValue::Str(hello.language),
                        ],
                    );
                }
            }
        }
    });
    for (spell_id, description) in value_texts {
        benilla_app::set_hoa_spell_description(world, spell_id, description);
    }
    if catalog_done {
        if catalog_rows.len() != usize::from(catalog_total) {
            warn!(
                "hoa protocol: aura catalog has {} rows, expected {catalog_total}",
                catalog_rows.len()
            );
        }
        if benilla_app::set_hoa_aura_catalog(world, &catalog_rows) {
            let mut buffer = world.resource_mut::<AuraCatalogBuffer>();
            buffer.active = false;
            buffer.pending = false;
            buffer.rows.clear();
        } else {
            let mut buffer = world.resource_mut::<AuraCatalogBuffer>();
            buffer.rows = catalog_rows;
            buffer.total = catalog_total;
            buffer.active = false;
            buffer.pending = true;
        }
    } else if catalog_active {
        let mut buffer = world.resource_mut::<AuraCatalogBuffer>();
        buffer.rows = catalog_rows;
        buffer.total = catalog_total;
        buffer.active = true;
    }
    apply_pending_catalog(world);
}

pub struct HordesOfAzerothPlugin;

impl Plugin for HordesOfAzerothPlugin {
    fn build(&self, app: &mut App) {
        add_plate_events();
        add_in_game_event(HOA_HELLO);
        add_in_game_event(HOA_AURA_VALUE);
        add_in_game_event(HOA_DASH);
        add_in_game_event(HOA_AURA_PERCENT);
        let hosts = LuaHosts {
            snapshot: SharedSnapshot::default(),
            areas: SharedMapAreas::from_install(),
            interact: SharedInteract::default(),
            plates: SharedPlates::default(),
            typing: SharedTyping::default(),
            controller: SharedController::default(),
            scripted_login: scripted_login_from_env(),
        };
        app.add_plugins(bevy::gilrs::GilrsPlugin)
            .insert_non_send_resource(hosts.snapshot.clone())
            .insert_non_send_resource(hosts.interact.clone())
            .insert_non_send_resource(hosts.plates.clone())
            .insert_non_send_resource(hosts.typing.clone())
            .insert_non_send_resource(hosts.controller.clone())
            .init_resource::<Telegraphs>()
            .init_resource::<HoaInbox>()
            .init_resource::<AuraCatalogBuffer>()
            .net_handler(SessionEventKind::HoaMessage, on_hoa_message)
            .insert_resource(DisplayModels::from_install())
            .add_systems(Startup, (name_window, announce_addon_folder, tap_draw_lines))
            .add_systems(
                PreUpdate,
                (log_new_pads, notice_keyboard_and_mouse, poll_pads, drive_pad_cursor)
                    .chain()
                    .after(bevy::input::InputSystems),
            )
            .add_systems(
                Update,
                (
                    hide_cursor_for_pad,
                    (
                        apply_draw_lines,
                        move_flights,
                        expire_kit_anchors,
                        expire_telegraphs,
                        follow_marks,
                        project_telegraphs,
                    )
                        .chain(),
                ),
            )
            .add_systems(Last, crate::census::log_census.run_if(crate::census::census_wanted))
            .add_systems(Last, deliver_hoa_messages)
            .add_systems(Last, apply_pending_catalog.after(deliver_hoa_messages))
            .add_systems(
                PostUpdate,
                push_telegraphs.after(benilla_world::particles::buffer::begin_effect_frame),
            )
            .add_systems(
                Last,
                (
                    capture_snapshot,
                    update_interact,
                    track_nameplates,
                    capture_typing,
                    deliver_pad_events,
                )
                    .chain(),
            );
        benilla_app::seed_every_vm(app, move |script| hosts.seed(script));
    }
}

const WINDOW_TITLE: &str = "Hordes of Azeroth";

fn name_window(mut windows: Query<&mut Window>) {
    for mut window in &mut windows {
        window.title = WINDOW_TITLE.to_string();
    }
}

fn announce_addon_folder() {
    let addons = benilla_app::config_dir().map(|dir| dir.join("AddOns"));
    info!("Hordes of Azeroth plugin running; addons load from {addons:?}");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_generated_hello_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        body.extend_from_slice(&PROTOCOL_VERSION.to_le_bytes());
        for text in [CONTENT_HASH, "zhCN"] {
            body.extend_from_slice(&(text.len() as u16).to_le_bytes());
            body.extend_from_slice(text.as_bytes());
        }
        let Some(HoaMessage::Hello(hello)) = protocol_generated::decode(protocol_generated::MSG_HELLO, &body) else {
            panic!("hello did not decode");
        };
        assert_eq!(hello.protocol_version, PROTOCOL_VERSION);
        assert_eq!(hello.content_hash, CONTENT_HASH);
        assert_eq!(hello.language, "zhCN");
    }

    #[test]
    fn the_catalog_entry_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        body.extend_from_slice(&0u16.to_le_bytes());
        body.extend_from_slice(&1u16.to_le_bytes());
        body.extend_from_slice(&60024u32.to_le_bytes());
        for text in ["切割", "Interface\\Icons\\Spell_Shadow_CurseOfTounges", "每层提高急速"] {
            body.extend_from_slice(&(text.len() as u16).to_le_bytes());
            body.extend_from_slice(text.as_bytes());
        }
        body.extend_from_slice(&0u32.to_le_bytes());
        body.extend_from_slice(&28u32.to_le_bytes());

        let Some(HoaMessage::AuraCatalogEntry(entry)) = protocol_generated::decode(protocol_generated::MSG_AURA_CATALOG_ENTRY, &body) else {
            panic!("catalog entry did not decode");
        };
        assert_eq!(entry.spell_id, 60024);
        assert_eq!(entry.name, "切割");
        assert_eq!(entry.stack, 0);
        assert_eq!(entry.duration, 28);
    }
}
