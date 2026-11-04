use bevy::log::warn;
use bevy::prelude::*;

use benilla_app::NetHandlerApp;
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
const SHIELD_SPELL: u32 = 60005;

/// Typed HoA packets, drained on the main thread because firing a Lua event needs the VM.
#[derive(Resource, Default)]
struct HoaInbox(Vec<(u16, Vec<u8>)>);

/// The account language from the last hello, for runtime tooltip text.
#[derive(Resource, Default)]
struct HoaLanguage(String);

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
    let mut language = world.resource::<HoaLanguage>().0.clone();
    let mut shield_text = None;
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
                    if aura.spell_id == SHIELD_SPELL {
                        shield_text = Some(if language.eq_ignore_ascii_case("zhCN") {
                            format!("吸收 {} 点伤害。", aura.value)
                        } else {
                            format!("Absorbs {} damage.", aura.value)
                        });
                    }
                    script.fire_event(
                        HOA_AURA_VALUE,
                        vec![
                            ScriptValue::Int(i64::from(aura.spell_id)),
                            ScriptValue::Int(i64::from(aura.value)),
                            ScriptValue::Int(i64::from(aura.max_value)),
                        ],
                    );
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
                HoaMessage::Hello(hello) => {
                    language = hello.language.clone();
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
    world.resource_mut::<HoaLanguage>().0 = language;
    if let Some(description) = shield_text {
        benilla_app::set_hoa_spell_description(world, SHIELD_SPELL, description);
    }
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
            .init_resource::<HoaLanguage>()
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
}
