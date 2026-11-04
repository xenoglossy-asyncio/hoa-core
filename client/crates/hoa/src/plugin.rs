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
const HOA_RUN_STATE: &str = "HOA_RUN_STATE";
const HOA_RUN_START: &str = "HOA_RUN_START";
const HOA_RUN_END: &str = "HOA_RUN_END";
const HOA_RUN_PAUSED: &str = "HOA_RUN_PAUSED";
const HOA_COOP_NO_PAUSE: &str = "HOA_COOP_NO_PAUSE";
const HOA_RUN_XP: &str = "HOA_RUN_XP";
const HOA_WAVE_BEAT: &str = "HOA_WAVE_BEAT";
const HOA_RUN_SUPPORT: &str = "HOA_RUN_SUPPORT";
const HOA_RUN_GLYPH_METER: &str = "HOA_RUN_GLYPH_METER";
const HOA_RUN_OTHER_METER: &str = "HOA_RUN_OTHER_METER";
const HOA_RUN_PARTY_METER: &str = "HOA_RUN_PARTY_METER";
const HOA_OBJECTIVE: &str = "HOA_OBJECTIVE";
const HOA_OBJECTIVE_CLEAR: &str = "HOA_OBJECTIVE_CLEAR";
const HOA_OBJECTIVE_PING: &str = "HOA_OBJECTIVE_PING";
const HOA_MOB: &str = "HOA_MOB";
const HOA_MOB_DEAD: &str = "HOA_MOB_DEAD";
const HOA_MOB_CLEAR: &str = "HOA_MOB_CLEAR";
const HOA_ALLY: &str = "HOA_ALLY";
const HOA_ALLY_DONE: &str = "HOA_ALLY_DONE";
const HOA_AFFIX_INFO: &str = "HOA_AFFIX_INFO";
const HOA_OFFER_OPEN: &str = "HOA_OFFER_OPEN";
const HOA_OFFER_OPTION: &str = "HOA_OFFER_OPTION";
const HOA_OFFER_STAT: &str = "HOA_OFFER_STAT";
const HOA_OFFER_END: &str = "HOA_OFFER_END";
const HOA_OFFER_CLOSED: &str = "HOA_OFFER_CLOSED";
const HOA_LEY_OPEN: &str = "HOA_LEY_OPEN";
const HOA_LEY_OPTION: &str = "HOA_LEY_OPTION";
const HOA_LEY_END: &str = "HOA_LEY_END";
const HOA_LEY_CLOSED: &str = "HOA_LEY_CLOSED";

fn lua_table(fields: Vec<(&str, ScriptValue)>) -> ScriptValue {
    ScriptValue::Table(fields.into_iter().map(|(key, value)| (key.to_string(), value)).collect())
}

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
                HoaMessage::OfferOpen(offer) => {
                    script.fire_event(
                        HOA_OFFER_OPEN,
                        vec![lua_table(vec![
                            ("level", ScriptValue::Int(i64::from(offer.level))),
                            ("count", ScriptValue::Int(i64::from(offer.count))),
                            ("source", ScriptValue::Str(offer.source)),
                            ("rerolls", ScriptValue::Int(i64::from(offer.rerolls))),
                            ("banishes", ScriptValue::Int(i64::from(offer.banishes))),
                            ("skips", ScriptValue::Int(i64::from(offer.skips))),
                        ])],
                    );
                }
                HoaMessage::OfferOption(option) => {
                    script.fire_event(
                        HOA_OFFER_OPTION,
                        vec![lua_table(vec![
                            ("index", ScriptValue::Int(i64::from(option.index))),
                            ("kind", ScriptValue::Str(option.kind)),
                            ("new_level", ScriptValue::Int(i64::from(option.new_level))),
                            ("max_level", ScriptValue::Int(i64::from(option.max_level))),
                            ("name", ScriptValue::Str(option.name)),
                            ("icon", ScriptValue::Str(option.icon)),
                            ("description", ScriptValue::Str(option.description)),
                            ("rarity", ScriptValue::Str(option.rarity)),
                            ("locked", ScriptValue::Bool(option.locked)),
                            ("damage_before", ScriptValue::Str(option.damage_before)),
                            ("damage_after", ScriptValue::Str(option.damage_after)),
                            ("damage_label", ScriptValue::Str(option.damage_label)),
                            ("banishable", ScriptValue::Bool(option.banishable)),
                        ])],
                    );
                }
                HoaMessage::OfferStat(stat) => {
                    script.fire_event(
                        HOA_OFFER_STAT,
                        vec![lua_table(vec![
                            ("index", ScriptValue::Int(i64::from(stat.index))),
                            ("label", ScriptValue::Str(stat.label)),
                            ("before", ScriptValue::Str(stat.before)),
                            ("after", ScriptValue::Str(stat.after)),
                        ])],
                    );
                }
                HoaMessage::OfferEnd(_) => {
                    script.fire_event(HOA_OFFER_END, Vec::new());
                }
                HoaMessage::OfferClosed(_) => {
                    script.fire_event(HOA_OFFER_CLOSED, Vec::new());
                }
                HoaMessage::LeyOpen(open) => {
                    script.fire_event(
                        HOA_LEY_OPEN,
                        vec![lua_table(vec![("count", ScriptValue::Int(i64::from(open.count)))])],
                    );
                }
                HoaMessage::LeyOption(option) => {
                    script.fire_event(
                        HOA_LEY_OPTION,
                        vec![lua_table(vec![
                            ("index", ScriptValue::Int(i64::from(option.index))),
                            ("name", ScriptValue::Str(option.name)),
                            ("icon", ScriptValue::Str(option.icon)),
                            ("description", ScriptValue::Str(option.description)),
                            ("rarity", ScriptValue::Int(i64::from(option.rarity))),
                            ("kind", ScriptValue::Str(option.kind)),
                            ("new_level", ScriptValue::Int(i64::from(option.new_level))),
                            ("max_level", ScriptValue::Int(i64::from(option.max_level))),
                        ])],
                    );
                }
                HoaMessage::LeyEnd(_) => {
                    script.fire_event(HOA_LEY_END, Vec::new());
                }
                HoaMessage::LeyClosed(_) => {
                    script.fire_event(HOA_LEY_CLOSED, Vec::new());
                }
                HoaMessage::Mob(mob) => {
                    script.fire_event(
                        HOA_MOB,
                        vec![lua_table(vec![
                            ("kind", ScriptValue::Int(i64::from(mob.kind))),
                            ("name", ScriptValue::Str(mob.name)),
                            ("icons", ScriptValue::Str(mob.icons)),
                            ("plate_id", ScriptValue::Int(i64::from(mob.plate_id))),
                            ("guid", ScriptValue::Str(mob.guid)),
                        ])],
                    );
                }
                HoaMessage::MobDead(dead) => {
                    script.fire_event(
                        HOA_MOB_DEAD,
                        vec![lua_table(vec![
                            ("name", ScriptValue::Str(dead.name)),
                            ("plate_id", ScriptValue::Int(i64::from(dead.plate_id))),
                            ("guid", ScriptValue::Str(dead.guid)),
                        ])],
                    );
                }
                HoaMessage::MobClear(_) => {
                    script.fire_event(HOA_MOB_CLEAR, Vec::new());
                }
                HoaMessage::Ally(ally) => {
                    script.fire_event(
                        HOA_ALLY,
                        vec![lua_table(vec![
                            ("name", ScriptValue::Str(ally.name)),
                            ("plate_id", ScriptValue::Int(i64::from(ally.plate_id))),
                            ("guid", ScriptValue::Str(ally.guid)),
                        ])],
                    );
                }
                HoaMessage::AllyDone(done) => {
                    script.fire_event(
                        HOA_ALLY_DONE,
                        vec![lua_table(vec![
                            ("plate_id", ScriptValue::Int(i64::from(done.plate_id))),
                            ("guid", ScriptValue::Str(done.guid)),
                        ])],
                    );
                }
                HoaMessage::AffixInfo(info) => {
                    script.fire_event(
                        HOA_AFFIX_INFO,
                        vec![lua_table(vec![
                            ("name", ScriptValue::Str(info.name)),
                            ("icon", ScriptValue::Str(info.icon)),
                            ("description", ScriptValue::Str(info.description)),
                        ])],
                    );
                }
                HoaMessage::Objective(objective) => {
                    script.fire_event(
                        HOA_OBJECTIVE,
                        vec![lua_table(vec![
                            ("id", ScriptValue::Int(i64::from(objective.id))),
                            ("kind", ScriptValue::Str(objective.kind)),
                            ("x", ScriptValue::Number(f64::from(objective.x))),
                            ("y", ScriptValue::Number(f64::from(objective.y))),
                            ("map_id", ScriptValue::Int(i64::from(objective.map_id))),
                            ("label", ScriptValue::Str(objective.label)),
                            ("seconds", ScriptValue::Int(i64::from(objective.seconds))),
                            ("icon", ScriptValue::Str(objective.icon)),
                            ("description", ScriptValue::Str(objective.description)),
                        ])],
                    );
                }
                HoaMessage::ObjectiveClear(clear) => {
                    script.fire_event(
                        HOA_OBJECTIVE_CLEAR,
                        vec![lua_table(vec![("id", ScriptValue::Int(i64::from(clear.id)))])],
                    );
                }
                HoaMessage::ObjectivePing(ping) => {
                    script.fire_event(
                        HOA_OBJECTIVE_PING,
                        vec![lua_table(vec![("id", ScriptValue::Int(i64::from(ping.id)))])],
                    );
                }
                HoaMessage::RunSupport(support) => {
                    script.fire_event(HOA_RUN_SUPPORT, vec![lua_table(vec![("text", ScriptValue::Str(support.text))])]);
                }
                HoaMessage::RunGlyphMeter(meter) => {
                    script.fire_event(HOA_RUN_GLYPH_METER, vec![lua_table(vec![("text", ScriptValue::Str(meter.text))])]);
                }
                HoaMessage::RunOtherMeter(meter) => {
                    script.fire_event(HOA_RUN_OTHER_METER, vec![lua_table(vec![("text", ScriptValue::Str(meter.text))])]);
                }
                HoaMessage::RunPartyMeter(meter) => {
                    script.fire_event(HOA_RUN_PARTY_METER, vec![lua_table(vec![("text", ScriptValue::Str(meter.text))])]);
                }
                HoaMessage::RunPaused(paused) => {
                    script.fire_event(
                        HOA_RUN_PAUSED,
                        vec![lua_table(vec![("paused", ScriptValue::Bool(paused.paused))])],
                    );
                }
                HoaMessage::CoopNoPause(no_pause) => {
                    script.fire_event(
                        HOA_COOP_NO_PAUSE,
                        vec![lua_table(vec![("no_pause", ScriptValue::Bool(no_pause.no_pause))])],
                    );
                }
                HoaMessage::RunXp(xp) => {
                    script.fire_event(
                        HOA_RUN_XP,
                        vec![lua_table(vec![
                            ("level", ScriptValue::Int(i64::from(xp.level))),
                            ("xp", ScriptValue::Int(i64::from(xp.xp))),
                            ("next", ScriptValue::Int(i64::from(xp.next))),
                            ("orbs", ScriptValue::Int(i64::from(xp.orbs))),
                        ])],
                    );
                }
                HoaMessage::WaveBeat(beat) => {
                    script.fire_event(
                        HOA_WAVE_BEAT,
                        vec![lua_table(vec![
                            ("name", ScriptValue::Str(beat.name)),
                            ("beat", ScriptValue::Int(i64::from(beat.beat))),
                            ("seconds", ScriptValue::Int(i64::from(beat.seconds))),
                        ])],
                    );
                }
                HoaMessage::RunStart(start) => {
                    script.fire_event(
                        HOA_RUN_START,
                        vec![lua_table(vec![
                            ("map_name", ScriptValue::Str(start.map_name)),
                            ("difficulty", ScriptValue::Str(start.difficulty)),
                            ("duration_s", ScriptValue::Int(i64::from(start.duration_s))),
                            ("stage", ScriptValue::Int(i64::from(start.stage))),
                            ("first_miniboss_s", ScriptValue::Int(i64::from(start.first_miniboss_s))),
                            ("timeline_marks", ScriptValue::Str(start.timeline_marks)),
                            ("mythic", ScriptValue::Bool(start.mythic)),
                            ("stages", ScriptValue::Int(i64::from(start.stages))),
                            ("level_name", ScriptValue::Str(start.level_name)),
                            ("finale", ScriptValue::Bool(start.finale)),
                            ("sandbox", ScriptValue::Bool(start.sandbox)),
                        ])],
                    );
                }
                HoaMessage::RunEnd(end) => {
                    script.fire_event(
                        HOA_RUN_END,
                        vec![lua_table(vec![
                            ("went_home", ScriptValue::Bool(end.went_home)),
                            ("seconds", ScriptValue::Int(i64::from(end.seconds))),
                            ("kills", ScriptValue::Int(i64::from(end.kills))),
                            ("gold", ScriptValue::Int(i64::from(end.gold))),
                            ("player_level", ScriptValue::Int(i64::from(end.player_level))),
                            ("stage", ScriptValue::Int(i64::from(end.stage))),
                            ("shards", ScriptValue::Int(i64::from(end.shards))),
                            ("victory", ScriptValue::Bool(end.victory)),
                            ("mythic", ScriptValue::Bool(end.mythic)),
                            ("best_level", ScriptValue::Int(i64::from(end.best_level))),
                            ("best_before", ScriptValue::Int(i64::from(end.best_before))),
                            ("level_name", ScriptValue::Str(end.level_name)),
                            ("finale_seconds", ScriptValue::Int(i64::from(end.finale_seconds))),
                        ])],
                    );
                }
                HoaMessage::RunState(state) => {
                    script.fire_event(
                        HOA_RUN_STATE,
                        vec![ScriptValue::Table(vec![
                            ("elapsed_s".into(), ScriptValue::Int(i64::from(state.elapsed_s))),
                            ("duration_s".into(), ScriptValue::Int(i64::from(state.duration_s))),
                            ("kills".into(), ScriptValue::Int(i64::from(state.kills))),
                            ("gold_earned".into(), ScriptValue::Int(i64::from(state.gold_earned))),
                            ("player_level".into(), ScriptValue::Int(i64::from(state.player_level))),
                            ("boss_spawned".into(), ScriptValue::Bool(state.boss_spawned)),
                            ("coins".into(), ScriptValue::Int(i64::from(state.coins))),
                            ("chest_price".into(), ScriptValue::Int(i64::from(state.chest_price))),
                            ("stage".into(), ScriptValue::Int(i64::from(state.stage))),
                            ("portal".into(), ScriptValue::Bool(state.portal)),
                            ("shards_earned".into(), ScriptValue::Int(i64::from(state.shards_earned))),
                            ("weapon_stats".into(), ScriptValue::Str(state.weapon_stats)),
                            ("total_s".into(), ScriptValue::Int(i64::from(state.total_s))),
                            ("damage_types".into(), ScriptValue::Str(state.damage_types)),
                        ])],
                    );
                }
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
        add_in_game_event(HOA_RUN_STATE);
        add_in_game_event(HOA_RUN_START);
        add_in_game_event(HOA_RUN_END);
        add_in_game_event(HOA_RUN_PAUSED);
        add_in_game_event(HOA_COOP_NO_PAUSE);
        add_in_game_event(HOA_RUN_XP);
        add_in_game_event(HOA_WAVE_BEAT);
        add_in_game_event(HOA_RUN_SUPPORT);
        add_in_game_event(HOA_RUN_GLYPH_METER);
        add_in_game_event(HOA_RUN_OTHER_METER);
        add_in_game_event(HOA_RUN_PARTY_METER);
        add_in_game_event(HOA_OBJECTIVE);
        add_in_game_event(HOA_OBJECTIVE_CLEAR);
        add_in_game_event(HOA_OBJECTIVE_PING);
        add_in_game_event(HOA_MOB);
        add_in_game_event(HOA_MOB_DEAD);
        add_in_game_event(HOA_MOB_CLEAR);
        add_in_game_event(HOA_ALLY);
        add_in_game_event(HOA_ALLY_DONE);
        add_in_game_event(HOA_AFFIX_INFO);
        add_in_game_event(HOA_OFFER_OPEN);
        add_in_game_event(HOA_OFFER_OPTION);
        add_in_game_event(HOA_OFFER_STAT);
        add_in_game_event(HOA_OFFER_END);
        add_in_game_event(HOA_OFFER_CLOSED);
        add_in_game_event(HOA_LEY_OPEN);
        add_in_game_event(HOA_LEY_OPTION);
        add_in_game_event(HOA_LEY_END);
        add_in_game_event(HOA_LEY_CLOSED);
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

    #[test]
    fn the_run_state_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        body.extend_from_slice(&7u32.to_le_bytes());
        body.extend_from_slice(&60u32.to_le_bytes());
        body.extend_from_slice(&12u32.to_le_bytes());
        body.extend_from_slice(&340u32.to_le_bytes());
        body.push(60);
        body.push(1);
        body.extend_from_slice(&5u32.to_le_bytes());
        body.extend_from_slice(&25u32.to_le_bytes());
        body.extend_from_slice(&3u32.to_le_bytes());
        body.push(0);
        body.extend_from_slice(&2u32.to_le_bytes());
        let weapon_stats = "1:2,3:4";
        body.extend_from_slice(&(weapon_stats.len() as u16).to_le_bytes());
        body.extend_from_slice(weapon_stats.as_bytes());
        body.extend_from_slice(&90u32.to_le_bytes());
        let damage_types = "fire,ice";
        body.extend_from_slice(&(damage_types.len() as u16).to_le_bytes());
        body.extend_from_slice(damage_types.as_bytes());

        let Some(HoaMessage::RunState(state)) = protocol_generated::decode(protocol_generated::MSG_RUN_STATE, &body) else {
            panic!("run state did not decode");
        };
        assert_eq!(state.elapsed_s, 7);
        assert_eq!(state.duration_s, 60);
        assert_eq!(state.player_level, 60);
        assert!(state.boss_spawned);
        assert_eq!(state.weapon_stats, "1:2,3:4");
        assert_eq!(state.total_s, 90);
        assert_eq!(state.damage_types, "fire,ice");
    }

    #[test]
    fn the_run_start_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        for text in ["Deadmines", "Normal"] {
            body.extend_from_slice(&(text.len() as u16).to_le_bytes());
            body.extend_from_slice(text.as_bytes());
        }
        body.extend_from_slice(&600u32.to_le_bytes());
        body.extend_from_slice(&2u32.to_le_bytes());
        body.extend_from_slice(&45u32.to_le_bytes());
        let timeline_marks = "first pull";
        body.extend_from_slice(&(timeline_marks.len() as u16).to_le_bytes());
        body.extend_from_slice(timeline_marks.as_bytes());
        body.push(0);
        body.extend_from_slice(&5u32.to_le_bytes());
        let level_name = "Hero";
        body.extend_from_slice(&(level_name.len() as u16).to_le_bytes());
        body.extend_from_slice(level_name.as_bytes());
        body.push(1);
        body.push(0);

        let Some(HoaMessage::RunStart(start)) = protocol_generated::decode(protocol_generated::MSG_RUN_START, &body) else {
            panic!("run start did not decode");
        };
        assert_eq!(start.map_name, "Deadmines");
        assert_eq!(start.difficulty, "Normal");
        assert_eq!(start.duration_s, 600);
        assert_eq!(start.timeline_marks, "first pull");
        assert_eq!(start.stages, 5);
        assert!(start.finale);
        assert!(!start.sandbox);
    }

    #[test]
    fn the_run_end_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        body.push(1);
        body.extend_from_slice(&120u32.to_le_bytes());
        body.extend_from_slice(&9u32.to_le_bytes());
        body.extend_from_slice(&300u32.to_le_bytes());
        body.push(60);
        body.extend_from_slice(&4u32.to_le_bytes());
        body.extend_from_slice(&2u32.to_le_bytes());
        body.push(1);
        body.push(0);
        body.extend_from_slice(&7u32.to_le_bytes());
        body.extend_from_slice(&3u32.to_le_bytes());
        body.extend_from_slice(&(4u16).to_le_bytes());
        body.extend_from_slice(b"Hero");
        body.extend_from_slice(&30u32.to_le_bytes());

        let Some(HoaMessage::RunEnd(end)) = protocol_generated::decode(protocol_generated::MSG_RUN_END, &body) else {
            panic!("run end did not decode");
        };
        assert!(end.went_home);
        assert_eq!(end.seconds, 120);
        assert_eq!(end.gold, 300);
        assert_eq!(end.player_level, 60);
        assert!(end.victory);
        assert_eq!(end.level_name, "Hero");
        assert_eq!(end.finale_seconds, 30);
    }

    #[test]
    fn the_run_xp_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        body.extend_from_slice(&61u32.to_le_bytes());
        body.extend_from_slice(&1000u32.to_le_bytes());
        body.extend_from_slice(&2000u32.to_le_bytes());
        body.extend_from_slice(&3u32.to_le_bytes());

        let Some(HoaMessage::RunXp(xp)) = protocol_generated::decode(protocol_generated::MSG_RUN_XP, &body) else {
            panic!("run xp did not decode");
        };
        assert_eq!(xp.level, 61);
        assert_eq!(xp.xp, 1000);
        assert_eq!(xp.next, 2000);
        assert_eq!(xp.orbs, 3);
    }

    #[test]
    fn the_wave_beat_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        let name = "Boss";
        body.extend_from_slice(&(name.len() as u16).to_le_bytes());
        body.extend_from_slice(name.as_bytes());
        body.extend_from_slice(&2u32.to_le_bytes());
        body.extend_from_slice(&15u32.to_le_bytes());

        let Some(HoaMessage::WaveBeat(beat)) = protocol_generated::decode(protocol_generated::MSG_WAVE_BEAT, &body) else {
            panic!("wave beat did not decode");
        };
        assert_eq!(beat.name, "Boss");
        assert_eq!(beat.beat, 2);
        assert_eq!(beat.seconds, 15);
    }

    #[test]
    fn the_objective_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        body.extend_from_slice(&7u32.to_le_bytes());
        let kind = "shrine";
        body.extend_from_slice(&(kind.len() as u16).to_le_bytes());
        body.extend_from_slice(kind.as_bytes());
        body.extend_from_slice(&1.5f32.to_le_bytes());
        body.extend_from_slice(&2.5f32.to_le_bytes());
        body.extend_from_slice(&1u32.to_le_bytes());
        let label = "Shrine";
        body.extend_from_slice(&(label.len() as u16).to_le_bytes());
        body.extend_from_slice(label.as_bytes());
        body.extend_from_slice(&30u32.to_le_bytes());
        for text in ["icon", "desc"] {
            body.extend_from_slice(&(text.len() as u16).to_le_bytes());
            body.extend_from_slice(text.as_bytes());
        }

        let Some(HoaMessage::Objective(objective)) = protocol_generated::decode(protocol_generated::MSG_OBJECTIVE, &body) else {
            panic!("objective did not decode");
        };
        assert_eq!(objective.id, 7);
        assert_eq!(objective.kind, "shrine");
        assert_eq!(objective.x, 1.5);
        assert_eq!(objective.y, 2.5);
        assert_eq!(objective.label, "Shrine");
        assert_eq!(objective.seconds, 30);
        assert_eq!(objective.icon, "icon");
        assert_eq!(objective.description, "desc");
    }

    #[test]
    fn an_empty_message_decodes_without_fields() {
        let Some(HoaMessage::MobClear(_)) = protocol_generated::decode(protocol_generated::MSG_MOB_CLEAR, &[]) else {
            panic!("empty mob clear did not decode");
        };
        assert!(protocol_generated::decode(protocol_generated::MSG_MOB_CLEAR, &[1]).is_none());
    }

    #[test]
    fn the_offer_option_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        body.extend_from_slice(&2u32.to_le_bytes());
        let kind = "w";
        body.extend_from_slice(&(kind.len() as u16).to_le_bytes());
        body.extend_from_slice(kind.as_bytes());
        body.extend_from_slice(&3u32.to_le_bytes());
        body.extend_from_slice(&5u32.to_le_bytes());
        for text in ["Arcane Orb", "icon", "desc", "2"] {
            body.extend_from_slice(&(text.len() as u16).to_le_bytes());
            body.extend_from_slice(text.as_bytes());
        }
        body.push(1);
        for text in ["10", "20", "damage"] {
            body.extend_from_slice(&(text.len() as u16).to_le_bytes());
            body.extend_from_slice(text.as_bytes());
        }
        body.push(0);

        let Some(HoaMessage::OfferOption(option)) = protocol_generated::decode(protocol_generated::MSG_OFFER_OPTION, &body) else {
            panic!("offer option did not decode");
        };
        assert_eq!(option.index, 2);
        assert_eq!(option.kind, "w");
        assert_eq!(option.new_level, 3);
        assert_eq!(option.max_level, 5);
        assert_eq!(option.name, "Arcane Orb");
        assert_eq!(option.rarity, "2");
        assert!(option.locked);
        assert!(!option.banishable);
    }
}
