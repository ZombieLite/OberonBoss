/* 
	OberonBoss
	
	http://vk.com/zombielite
	Telegram: @zombielite
*/

#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < xs >

#define NAME 			"OberonBoss"
#define VERSION			"3.3"
#define AUTHOR			"Alexander.3"

#define BOMB_CUSTOM
#define NEW_SEARCH
#define RANDOM_ABILITY
#define PLAYER_HP
#define SUPPORT_ZM
#define ABILITY_CHAIN
//#define HEALTHBAR
#define SPRMIRROR

new const Resource[][] = {
	"models/zl/npc/oberon/oberon_v2.mdl",		// 0 -
	"sprites/zl/npc/oberon/zl_diablobar.spr",	// 1 -
	"sprites/blood.spr",				// 2 +
	"sprites/bloodspray.spr",			// 3 +
	"models/zl/npc/oberon/bomb.mdl",		// 4 -
	"sprites/eexplo.spr",				// 5 +
	"models/zl/npc/oberon/hole.mdl",		// 6 -
	"models/zl/npc/oberon/zl_knife.mdl", 		// 7 -
	"models/zl/npc/oberon/cell.mdl",		// 8 +
	"models/zl/npc/oberon/gibs.mdl",		// 9 +
	"sprites/zl/npc/oberon/poison.spr",		// 10 -
	"sprites/zl/npc/oberon/zl_wave.spr",		// 11 -
	"sprites/zl/npc/oberon/blue.spr",		// 12 -
	"sprites/zl/npc/oberon/skull.spr",		// 13 -
	"sprites/zl/npc/oberon/zl_impulse.spr",		// 14 -
	"sprites/zl/npc/oberon/expl_r.spr",		// 15 -
	"sprites/zl/npc/oberon/zl_chain.spr"		// 16 -
}
static g_Resource[sizeof Resource]
new const SoundList[][] = {
	"zl/npc/oberon/step1.wav",		// 0 
	"zl/npc/oberon/step2.wav",		// 1 
	"zl/npc/oberon/attack1.wav",		// 2 
	"zl/npc/oberon/attack2.wav",		// 3 
	"zl/npc/oberon/attack3.wav",		// 4 
	"zl/npc/oberon/attack1_knife.wav",	// 5 
	"zl/npc/oberon/attack2_knife.wav",	// 6 
	"zl/npc/oberon/bomb.wav",		// 7 
	"zl/npc/oberon/hole.wav",		// 8 
	"zl/npc/oberon/jump.wav",		// 9 
	"zl/npc/oberon/knife.wav",		// 10 
	"zl/npc/oberon/roar.wav",		// 11 
	"zl/npc/oberon/death.wav",		// 12 
	"zl/prepare.mp3"			// 13
}

#define MAX_ZOMBIE	10
#define MAX_BOMB	10
#define OFFSET_GROUND	285.0
#define SPRSIZE		0.6
new const FILE_SETTING[] = "zl_oberonboss.ini"
new boss_heal, Float:bomb_dist, Float:offset_speed, Float:knife_fade_time,
	speed_boss, dmg_attack_max, dmg_attack, bomb_damage, hole_dmg, jump_damage, jump_distance, time_ability,
	speed_boss_agr, bomb_damage_agr, hole_dmg_agr, jump_damage_agr, time_ability_agr, bool:BossPrepare = true

#if defined SUPPORT_ZM
new zm_time, zm_add_time, zm_hp, zm_speed, zm_damage, bool:zm_true
#endif

#if defined BOMB_CUSTOM
new bomb_mind, Float:bomb_poison, bomb_poison_life, Float:bomb_frozen_time, bomb_impulse_num, bomb_impulse_dmg[2], bomb_impulse_time, g_Color
#endif

#define BUFFER_CHAIN	12
#if defined ABILITY_CHAIN
new PlayerOne, PlayerTwo, time_chain[2]
#endif

static g_Oberon, g_Start, g_Bomb[MAX_BOMB], g_Hole
static e_boss, e_zombie[MAX_ZOMBIE]

enum {
	RUN,
	ATTACK,
	BOMB,
	HOLE,
	JUMP,
	AGRESS
}

native zl_boss_map()
native zl_boss_valid(index)
native zl_player_alive()
native zl_player_random()
#if defined SUPPORT_ZM
native zl_zombie_create(Float:Origin[3], Health, Speed, Damage)
#endif
forward zl_timer(timer, prepare)

#define pev_pre				pev_euser1
#define pev_num				pev_euser2
#define pev_ability			pev_euser3
#define pev_victim			pev_euser4

public plugin_init() {
	register_plugin(NAME, VERSION, AUTHOR)
	
	if (zl_boss_map() != 1) {
		pause("ad")
		return
	}	
	RegisterHam(Ham_Spawn, "player", "Hook_Spawn")
	
	register_think("oberon_boss", "Think_Boss")
	register_think("oberon_knife", "Think_Knife")
	register_think("oberon_health", "Think_Health")
	register_think("oberon_gas", "Think_Gase")
	register_think("oberon_impulse", "Think_Impulse")
	register_think("oberon_box", "Think_Box")
	register_think("oberon_chains", "Think_Chain")
	
	register_touch("oberon_boss", "*", "Touch_Boss")
	register_touch("oberon_bomb", "*", "Touch_Bomb")
	register_touch("oberon_box", "player", "Touch_Box")
	
	MapEvent()
}

public EventPrepare() {
	g_Start = random(2)
	
	new Float:Origin[3]
	pev(e_boss, pev_origin, Origin)
	
	if (!g_Start) {
		Origin[2] -= OFFSET_GROUND
		g_Oberon = zl_create_entity(
			Origin, Resource[0], _, 0.1, 
			SOLID_BBOX, MOVETYPE_TOSS, DAMAGE_NO, DEAD_NO, 
			"info_target", "oberon_boss", Float:{-32.0, -32.0, -OFFSET_GROUND}, Float:{32.0, 32.0, 96.0})
		
		Anim(g_Oberon, 17, 0.8)
	} else {
		set_rendering( // Fixed Addtive bug
			zl_create_entity(
				Origin, Resource[8], _, 0.1, 
				SOLID_BBOX, MOVETYPE_NONE, DAMAGE_NO, DEAD_DEAD, 
				"info_target", "oberon_box", Float:{-150.0, -150.0, -1.0}, Float:{150.0, 150.0, 300.0}),
				kRenderNormal, _, _, _, kRenderTransAlpha, 255)
	}
}

public Think_Box(Ent) {
	if (BossPrepare) {
		set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
		return
	}
	static fade, Float:Origin[3], num
	pev(e_boss, pev_origin, Origin)
	switch (num) { // SUCKS -___________-
		case 0: {
			static shake_num
			ScreenShake(0, ((1<<12) * 3), ((2<<12) * 3))
			set_pev(Ent, pev_nextthink, get_gametime() + 5.0)
			if (shake_num >= 2) num++
			shake_num++
		} 
		case 1: {
			Origin[2] = 1350.0
			expl(Origin, 50, {255, 255, 0}, 0, 5, 0)
			set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
			num++
		}
		case 2: {
			Origin[2] = 1450.0
			expl(Origin, 50, {255, 255, 0}, 0, 5, 0)
			set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
			num++
		}
		case 3: {
			Origin[2] = 1600.0
			expl(Origin, 50, {255, 255, 0}, 0, 5, 0)
			set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
			num++
		}
		case 4: {
			Origin[2] = 1750.0
			set_pev(Ent, pev_movetype, MOVETYPE_TOSS)
			expl(Origin, 50, {255, 255, 0}, 0, 5, 0)
			set_pev(Ent, pev_nextthink, get_gametime() + 1.5)
			num++
		}
		case 5: {
			#define BUFFER_THINK 5.0
			pev(Ent, pev_origin, Origin)
			Origin[2] += ( 100.0 + OFFSET_GROUND )
			g_Oberon = zl_create_entity(
			Origin, Resource[0], 1, BUFFER_THINK + 6.2, 
			SOLID_BBOX, MOVETYPE_TOSS, DAMAGE_NO, DEAD_NO, 
			"info_target", "oberon_boss", Float:{-32.0, -32.0, -OFFSET_GROUND}, Float:{32.0, 32.0, 96.0})			
			
			ScreenShake(0, ((1<<12) * 4), ((2<<12) * 4))
			set_pev(Ent, pev_body, 1)
			set_pev(Ent, pev_nextthink, get_gametime() + BUFFER_THINK)
			num++
		}
		case 6: {
			set_pev(Ent, pev_solid, SOLID_NOT)
			fade = 255
			Origin[2] -= ( 100.0 + OFFSET_GROUND )
			Anim(Ent, 1, 2.0)
			Anim(g_Oberon, 0, 1.0)
			Sound(g_Oberon, 11)
			set_pev(Ent, pev_nextthink, get_gametime() + 0.02)
			Wreck(Origin, {160.0, 160.0, 160.0}, {100.0, 100.0, 100.0}, 100, 100, 50, (0x02))
			num++
		}
		case 7 : {
			if (fade <= 5) {
				engfunc(EngFunc_RemoveEntity, Ent)
				return
			}
			fade -= 2 
			set_rendering(Ent, kRenderNormal, _, _, _, kRenderTransAlpha, fade)
			set_pev(Ent, pev_nextthink, get_gametime() + 0.01)
		}
	}
}

public Think_Boss(Ent) {
	if (BossPrepare) {
		set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
		return
	}
	
	if (pev(Ent, pev_deadflag) == DEAD_DYING) {
		#if defined SUPPORT_ZM
		zm_true = false
		#endif
		if (pev_valid(g_Hole)) engfunc(EngFunc_RemoveEntity, g_Hole)
		return
	}
	
	if (g_Start != 100) {
		#if defined PLAYER_HP
		set_pev(Ent, pev_health, float(PlayerHp(boss_heal)))
		#else
		set_pev(Ent, pev_health, float(boss_heal))
		#endif
		set_pev(Ent, pev_takedamage, DAMAGE_YES)
		
		new Float:MaxHp
		pev(Ent, pev_health, MaxHp)
		set_pev(Ent, pev_max_health, MaxHp)
		
		new HealthBar = zl_create_entity(
			Float:{0.0, 0.0, 0.0}, Resource[1], _, 0.1, 
			SOLID_NOT, MOVETYPE_FOLLOW, DAMAGE_NO, DEAD_NO, 
			"info_target", "oberon_health", .invise = true)
			
		set_pev(HealthBar, pev_aiment, Ent) 
		set_pev(HealthBar, pev_scale, SPRSIZE)
		
		//client_cmd(0, "mp3 play ^"sound/%s^"", SoundList[15])
		set_pev(Ent, pev_fuser1, get_gametime() + float(time_ability))
		g_Start = 100
	}
	
	if (!zl_player_alive()) { // Disconnet last alive player
		Anim(Ent, 1, 1.0)
		set_pev(Ent, pev_nextthink, get_gametime() + 6.1) // ZzZ..
		return
	}
	
	static Agr; Agr = pev(Ent, pev_button)
	if (pev(Ent, pev_fuser1) <= get_gametime()) {
		if (pev(Ent, pev_ability) == RUN && pev(Ent, pev_button) != 3) {
			#if defined RANDOM_ABILITY
			switch( random(3) ) {
				case 0: set_pev(Ent, pev_ability, BOMB)
				case 1: set_pev(Ent, pev_ability, HOLE)
				case 2: set_pev(Ent, pev_ability, JUMP)
			}
			#else
			switch( pev(Ent, pev_weaponanim) ) {
				case 0: { set_pev(Ent, pev_ability, BOMB); set_pev(Ent, pev_weaponanim, 1); }
				case 1: { set_pev(Ent, pev_ability, HOLE); set_pev(Ent, pev_weaponanim, 2); }
				case 2: { set_pev(Ent, pev_ability, JUMP); set_pev(Ent, pev_weaponanim, 0); }
			}
			#endif
			set_pev(Ent, pev_num, 0)
			set_pev(Ent, pev_fuser1, get_gametime() + (Agr ? float(time_ability_agr) : float(time_ability)))
		}
	}	
	switch(pev(Ent, pev_ability)) {
		case RUN: {
			new Float:Velocity[3], Float:Angle[3]
			static Target
			if (!is_user_alive(Target)) {
				Target = zl_player_random()
				set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
				return
			}
			if (!pev(Ent, pev_num)) {
				set_pev(Ent, pev_num, 1)
				set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
				Anim(Ent, Agr ? 10 : 2, offset_speed)
			}
			#if defined NEW_SEARCH
			new Len, LenBuff = 99999
			for(new i = 1; i <= get_maxplayers(); i++) {
				if (!is_user_alive(i) || is_user_bot(i))
					continue
						
				Len = zl_move(Ent, i)
				if (Len < LenBuff) {
					LenBuff = Len
					Target = i
				}
			}
			#endif
			zl_move(Ent, Target, pev(g_Oberon, pev_button) ? float(speed_boss_agr) : float(speed_boss), Velocity, Angle)
			Velocity[2] = 0.0
			set_pev(Ent, pev_velocity, Velocity)
			set_pev(Ent, pev_angles, Angle)
			set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
		}
		case ATTACK:{
			static randoms
			switch(pev(Ent, pev_num)) {
				case 0: {
					randoms = random(2)
					set_pev(Ent, pev_num, 1)
					set_pev(Ent, pev_movetype, MOVETYPE_NONE)
					
					if(Agr) {
						Sound(Ent, random_num(5, 6))
						Anim(Ent, randoms ? 11 : 12, 1.0)
						set_pev(Ent, pev_nextthink, get_gametime() + (randoms ? 0.6 : 0.3) )
					} else {
						Sound(Ent, randoms ? 2 : 4)
						Anim(Ent, randoms ? 3 : 4, 1.0)
						set_pev(Ent, pev_nextthink, get_gametime() + (randoms ? 1.5 : 0.8) )
					}
					return
				}
				case 1: {
					new Float:Velocity[3], Len
					new victim = pev(Ent, pev_victim)
					
					Len = zl_move(Ent, victim, 2000.0, Velocity)
					if ( Len <= 165 ) {
						if (Agr)
							ExecuteHamB(Ham_Killed, victim, victim, 2) 
						else {
							Velocity[2] = 500.0
							boss_damage(victim, randoms ? dmg_attack_max : dmg_attack, {255, 0, 0})
							if (!randoms) set_pev(victim, pev_velocity, Velocity)
						}
					}
					if (Agr) AgrEff(0)
				}
			}
			set_pev(Ent, pev_num, 0)
			set_pev(Ent, pev_ability, RUN)
			set_pev(Ent, pev_nextthink, get_gametime() + 1.3)
		}
		case BOMB: {
			static BombTarget[MAX_BOMB], Float:VectorB[3], b_num
			switch(pev(Ent, pev_num)) {
				case 0: {
					b_num = MAX_BOMB
					#if defined BOMB_CUSTOM
					if (Agr) {
						g_Color = random_num(1, 6)
						if (g_Color == 6)
							b_num = bomb_impulse_num
					}
					#endif
					set_pev(Ent, pev_movetype, MOVETYPE_NONE)
					Anim(Ent, Agr ? 14 : 6, 1.0)
					set_pev(Ent, pev_num, 1)
					set_pev(Ent, pev_nextthink, get_gametime() + 3.2)
					
					if (!zl_player_random()) 
						return
					
					for (new i; i < b_num; ++i) BombTarget[i] = zl_player_random()
				}
				case 1: {
					Sound(Ent, 7)
					new Float:Origin[3]; pev(Ent, pev_origin, Origin)
					Origin[2] += ( 100.0 - OFFSET_GROUND )
					for (new i; i < b_num; ++i) {
						
						new Bomb = zl_create_entity(
								Origin, Resource[4], 1, 0.0, 
								SOLID_NOT, MOVETYPE_NOCLIP, DAMAGE_NO, DEAD_NO, 
								"info_target", "oberon_bomb", Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
			
						new Float:Origin2[3], Float:Angles[3]
						get_position(BombTarget[i], random_float(-400.0, -400.0), random_float(-300.0, 300.0), random_float(-1500.0, 1500.0), Origin2)
						g_Bomb[i] = Bomb; Anim(Bomb, 0, 8.0)
						
						#if defined BOMB_CUSTOM
						switch (g_Color) {
							case 1: set_rendering(g_Bomb[i], kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 60)
							case 2: if (i < 3) set_rendering(g_Bomb[i], kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 60)
							case 3: if (i < 3) set_rendering(g_Bomb[i], kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 60)
							case 4: set_rendering(Bomb, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 60)
							case 5: set_rendering(Bomb, kRenderFxGlowShell, 136, 136, 136, kRenderNormal, 200)
							case 6: set_rendering(Bomb, kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 60)
						}
						#endif
						xs_vec_sub(Origin2, Origin, VectorB)
						vector_to_angle(VectorB, Angles)
						xs_vec_normalize(VectorB, VectorB)
						Angles[0] = 0.0
						Angles[2] = 0.0
						VectorB[2] = 1.0
						xs_vec_mul_scalar(VectorB, 400.0, VectorB)
						set_pev(Bomb, pev_velocity, VectorB)
						set_pev(Bomb, pev_angles, Angles)
						set_pev(Ent, pev_num, 2)
						set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
					}
				}
				case 2: {
					static num
					#if defined BOMB_CUSTOM
					new Float:Velocity[3]
					switch (g_Color) {
						case 1, 5, 6: num = 2
					}
					#endif
					for (new i; i < b_num; ++i) {
						new Bomb = g_Bomb[i]
						set_pev(Bomb, pev_movetype, MOVETYPE_BOUNCE)
						set_pev(Bomb, pev_solid, SOLID_BBOX)
						#if defined BOMB_CUSTOM
						if ( g_Color == 1 ) {
							BombTarget[i] = zl_player_random()
							zl_move(Bomb, BombTarget[i], 2000.0, Velocity)
							set_pev(Bomb, pev_velocity, Velocity)
						} else VectorB[2] = 0.0
						#else
						VectorB[2] = 0.0
						#endif
					}
					if (num >= 2) {
						set_pev(Ent, pev_nextthink, get_gametime() + 1.5)
						set_pev(Ent, pev_ability, RUN)
						set_pev(Ent, pev_num, 0)
						num = 0
						return
					} else num++
					set_pev(Ent, pev_num, 1)
					set_pev(Ent, pev_nextthink, get_gametime() + 1.8)
				}
			}		
		}
		case HOLE: {
			new Float:Origin[3]; pev(Ent, pev_origin, Origin); Origin[2] -= OFFSET_GROUND
			switch (pev(Ent, pev_num)) {
				case 0: {
					Sound(Ent, 8)
					set_pev(Ent, pev_movetype, MOVETYPE_NONE)
					
					g_Hole = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
					engfunc(EngFunc_SetModel, g_Hole, Resource[6])
					engfunc(EngFunc_SetOrigin, g_Hole, Origin)
					
					Anim(Ent, Agr ? 15 : 7, 0.8)
					Anim(g_Hole, 0, 0.7)
					set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
					set_pev(Ent, pev_num, 1)
				}
				case 1: {
					static Float:Velocity[3], Len, num
					for(new id = 1; id <= get_maxplayers(); id++) {
						if (!is_user_alive(id) || is_user_bot(id))
							continue
							
						Len = zl_move(id, Ent, 330.0, Velocity)
						if (Len < 800) set_pev(id, pev_velocity, Velocity)
					}
					set_pev(Ent, pev_nextthink, get_gametime() + 0.3)
					if (num >= 23) {
						num = 0
						set_pev(Ent, pev_num, 2)
						return
					}
					num++
				}
				case 2: {
					if (Agr) AgrEff(1)
					engfunc(EngFunc_RemoveEntity, g_Hole)
					static victim = -1
					new Float:p[3], Float:b[3], Float:v[3], weapon
					pev(Ent, pev_origin, b); b[2] -= OFFSET_GROUND
					while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, 200.0)) != 0) {
						if(0 < victim <= get_maxplayers() && is_user_alive(victim)) {							
							client_cmd(victim, "drop")
							
							weapon = get_pdata_cbase(victim, 373, 5)
							if(pev_valid(weapon)) ExecuteHamB(Ham_Weapon_RetireWeapon, weapon)
							client_cmd(victim, "drop")
							
							pev(victim, pev_origin, p)
							xs_vec_sub(p, b, v)
							xs_vec_normalize(v, v)
							xs_vec_mul_scalar(v, 1500.0, v)
							v[2] = 500.0
							set_pev(victim, pev_velocity, v)
							
							boss_damage(victim, pev(g_Oberon, pev_button) ? hole_dmg_agr : hole_dmg, {255, 0, 0})
						}
					}
					set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
					set_pev(Ent, pev_ability, RUN)
					set_pev(Ent, pev_num, 0)
				}
			}
		}
		case JUMP: {
			static Float:Origin2[3], Float:Velocity[3]
			new JumpTarget, Float:j_Origin[3], Float:j_Vector[3], Float:Len, Float:LenSubb
			switch (pev(Ent, pev_num)) {
				case 0: {
					new Float:Origin[3]; pev(Ent, pev_origin, Origin); Origin[2] -= OFFSET_GROUND
					for(new s; s <= get_maxplayers(); s++) {
						if (!is_user_alive(s) || is_user_bot(s))
							continue
							
						pev(s, pev_origin, j_Origin)
						xs_vec_sub(j_Origin, Origin, j_Vector)
						Len = xs_vec_len(j_Vector)
						
						if (Len > LenSubb) {
							LenSubb = Len
							JumpTarget = s
						}
					}
					static Float:Angle[3]; pev(JumpTarget, pev_origin, Origin2)
					zl_move(Ent, JumpTarget, 500.0, Velocity, Angle)
					set_pev(Ent, pev_angles, Angle)
					set_pev(Ent, pev_nextthink, get_gametime() + 0.5)
					set_pev(Ent, pev_num, 1)
					set_pev(Ent, pev_movetype, MOVETYPE_NONE)
					Anim(Ent, Agr ? 13 : 5, 1.0)
					set_pev(Ent, pev_movetype, MOVETYPE_BOUNCE)
				}
				case 1: {
					Sound(Ent, 9)
					Velocity[2] = 1000.0
					set_pev(Ent, pev_velocity, Velocity)
					set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
					set_pev(Ent, pev_num, 2)
				}
				case 2: {
					new Float:Origin[3]; pev(Ent, pev_origin, Origin); Origin[2] -= OFFSET_GROUND
					set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
					xs_vec_sub(Origin2, Origin, Velocity)
					xs_vec_normalize(Velocity, Velocity)
					xs_vec_mul_scalar(Velocity, 1000.0, Velocity)
					set_pev(Ent, pev_velocity, Velocity)
					set_pev(Ent, pev_nextthink, get_gametime() + 0.8)
					set_pev(Ent, pev_num, 3)
					set_pev(Ent, pev_pre, 1)
				}
				case 3: {
					set_pev(Ent, pev_pre, 0)
					set_pev(Ent, pev_movetype, MOVETYPE_NONE)
					set_pev(Ent, pev_nextthink, get_gametime() + 1.6)
					set_pev(Ent, pev_ability, RUN)
					set_pev(Ent, pev_num, 0)
				}
			}
		}
		case AGRESS: {
			switch(pev(Ent, pev_num)) {
				case 0: {
					set_pev(Ent, pev_num, 1)
					set_pev(Ent, pev_takedamage, DAMAGE_NO)
					set_pev(Ent, pev_button, 3)
					set_pev(Ent, pev_movetype, MOVETYPE_NONE)
					set_pev(Ent, pev_nextthink, get_gametime() + 8.6)
					Anim(Ent, 8, 1.0)
					Sound(Ent, 10)
				}
				case 1: {
					set_pev(Ent, pev_takedamage, DAMAGE_YES)
					set_pev(Ent, pev_button, 1)
					set_pev(Ent, pev_ability, RUN)
					set_pev(Ent, pev_num, 0)
					//client_cmd(0, "mp3 play ^"sound/%s^"", SoundList[14])
					set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
					#if defined SUPPORT_ZM
					zm_true = true
					#endif
				}
			}
		}
	}
	// Adding custom ability in version 3.1
	#if defined ABILITY_CHAIN
	static chain_time_ent
	if (!pev_valid(chain_time_ent) && !Agr) {
		chain_time_ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		set_pev(chain_time_ent, pev_classname, "oberon_chains")
		set_pev(chain_time_ent, pev_nextthink, get_gametime() + (float(time_chain[0]) + 1.0))
	}
	#endif
}

public AgrEff(hole) {
	new Float:OriginKnf[3]; pev(g_Oberon, pev_origin, OriginKnf); OriginKnf[2] -= (OFFSET_GROUND - 35.0)
	new Float:AnglesKnf[3]; pev(g_Oberon, pev_angles, AnglesKnf)
	new Eff =  zl_create_entity(
			OriginKnf, Resource[7], 1, 0.7, 
			SOLID_NOT, MOVETYPE_FLY, DAMAGE_NO, DEAD_NO, 
			"info_target", "oberon_knife", Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	
	set_pev(Eff, pev_angles, AnglesKnf)
	set_rendering(Eff, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)
	Anim(Eff, hole ? 2 : 1, 1.0)
}

public Think_Knife(Ent) {
	if (!pev_valid(Ent))
		return
	
	static Float:a
	a = 240.0 / knife_fade_time / 10.0
	
	switch(pev(Ent, pev_button)) {
		case 0: set_pev(Ent, pev_button, 255)
		case 15..255: { set_rendering(Ent, kRenderFxNone, 0, 0, 0, kRenderTransAdd, (pev(Ent, pev_button) - floatround(a)) ); set_pev(Ent, pev_button, pev(Ent, pev_button) - floatround(a)); }
		default: { set_pev(Ent, pev_button, 0); engfunc(EngFunc_RemoveEntity, Ent); return; }
	}
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
}

public Think_Health(e) {
	if (!pev_valid(e))
		return
		
	if (pev(g_Oberon, pev_deadflag) == DEAD_DYING) {
		engfunc(EngFunc_RemoveEntity, e)
		return
	}
	
	static Float:hp_current, Float:hp_maximum, Float:percent
	pev(g_Oberon, pev_max_health, hp_maximum)
	pev(g_Oberon, pev_health, hp_current)
	percent = hp_current * 100.0 / hp_maximum
	
	if (percent < 50.0 && pev(g_Oberon, pev_ability) == RUN && pev(g_Oberon, pev_button) == 0) {
		set_pev(g_Oberon, pev_ability, AGRESS)
		set_pev(g_Oberon, pev_num, 0)
	}
	
	#if defined HEALTHBAR
	message_begin(MSG_BROADCAST, get_user_msgid("BarTime2"))
	write_short(97999)
	write_short(floatround((percent >= 100.0) ? 99.0 : percent, floatround_floor))
	message_end()		
	#else
		#if defined SPRMIRROR
		percent = 100 - percent
		#endif
	set_pev(e, pev_effects, pev(e, pev_effects) & ~EF_NODRAW)
	set_pev(e, pev_frame, percent)
	#endif
	
	set_pev(e, pev_nextthink, get_gametime() + 0.1)
}

#if defined BOMB_CUSTOM
public Think_Gase(Ent) {
	if (!pev_valid(Ent))
		return
	
	if(pev(Ent, pev_weaponanim) > bomb_poison_life) {
		set_pev(Ent, pev_weaponanim, 0)
		engfunc(EngFunc_RemoveEntity, Ent)
		return
	}
	static Float:Origin[3], victim = -1
	set_pev(Ent, pev_nextthink, get_gametime() + 2.0)
	pev(Ent, pev_origin, Origin)
	Smoke(Origin)
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, 200.0)) != 0) {
		if(is_user_alive(victim)) {
			ExecuteHamB(Ham_TakeDamage, victim, 0, victim, bomb_poison, DMG_SONIC)
			DmgMsg(Origin, victim, 131072)
		}
	}
	set_pev(Ent, pev_weaponanim, pev(Ent, pev_weaponanim) + 1)
}
#endif

public zl_timer(timer, prepare) {
	if (!prepare) BossPrepare = false
	#if defined SUPPORT_ZM
	
	if (!zm_true)
		return
	
	static ZombieNum
	if (pev(e_boss, pev_fuser2) < get_gametime()) {
		if (ZombieNum < (MAX_ZOMBIE - 1)) ZombieNum++
		set_pev(e_boss, pev_fuser2, get_gametime() + float(zm_add_time))
	}
	
	if (pev(e_boss, pev_fuser1) < get_gametime()) {
		for (new i; i < ZombieNum; ++i) {
			new Float:Origin[3]
			pev(e_zombie[i], pev_origin, Origin)
			zl_zombie_create(Origin, zm_hp, zm_speed, zm_damage)
			set_pev(e_boss, pev_fuser1, get_gametime() + float(zm_time))
		}
	}
	#endif
}

#if defined ABILITY_CHAIN
public Think_Chain( e ) {		
	if (!is_user_alive(PlayerOne) || !is_user_alive(PlayerTwo)) {
		while (PlayerOne == PlayerTwo) {	
			if (zl_player_alive() <= 1) {
				break
			}
			PlayerOne = zl_player_random()
			PlayerTwo = zl_player_random()
		}	
		set_pev(e, pev_nextthink, get_gametime() + 0.1)
		return
	}
	
	static num
	if (num <= 0)
		oberon_beaments(PlayerOne, PlayerTwo, time_chain[1])

	if (num < (10 * time_chain[1]) ) {
		new PlayerVictim, trace, Float:origin_one[3], Float:origin_two[3], Float:origin_vector[3], Float:vector_len
		pev(PlayerOne, pev_origin, origin_one)
		pev(PlayerTwo, pev_origin, origin_two)
		
		engfunc(EngFunc_TraceLine, origin_one, origin_two, DONT_IGNORE_MONSTERS, PlayerOne, trace)
		get_tr2(trace, TR_vecEndPos, origin_vector)
		
		PlayerVictim = engfunc(EngFunc_FindEntityInSphere, PlayerVictim, origin_vector, 1.0)
		
		vector_len = get_distance_f(origin_one, origin_two)
			
		if ((vector_len < 50.0) && (PlayerVictim != PlayerOne)) {
			message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
			write_byte( TE_KILLBEAM ) 
			write_short( PlayerOne )
			message_end()
			
			chain_clear(e)
			num = 0
			return
		}
		
		if (is_user_alive(PlayerVictim))
			if ((PlayerVictim != PlayerOne) && (PlayerVictim != PlayerTwo))
				ExecuteHamB(Ham_Killed, PlayerVictim, PlayerVictim, 2)
				
		num++
	} else { num = 0; chain_clear(e); return; }
	set_pev(e, pev_nextthink, get_gametime() + 0.1)
}

chain_clear(e) {
	if (pev_valid(e))
		engfunc(EngFunc_RemoveEntity, e)
	
	PlayerOne = -1
	PlayerTwo = -1
}
#endif

public Touch_Boss(Boss, Ent) {
	if (pev(Boss, pev_ability) == ATTACK)
		return
	
	if (pev(Boss, pev_ability) == JUMP && pev(Boss, pev_pre) == 1) {
		static victim =-1
		new Agr = pev(Ent, pev_button)
		
		new Float:Origin[3]; pev(Boss, pev_origin, Origin); Origin[2] -= OFFSET_GROUND
		ShockWave(Origin, 10, 200, float(jump_distance), {255, 0, 0})
		ScreenShake(0, ((1<<12) * 8), ((2<<12) * 7))
		while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, (float(jump_distance) * 4))) != 0) {
			if (!is_user_alive(victim))
				continue

			boss_damage(victim, Agr ? jump_damage_agr : jump_damage, {255, 0, 0})
		}
		if (!is_user_alive(Ent))
			return
			
		ExecuteHamB(Ham_Killed, Ent, Ent, 2)
		return
	}
		
	if (pev(Boss, pev_ability) != RUN)
		return
	
	if (!is_user_alive(Ent))
		return
	
	new Float:origin[3]
	pev(Ent, pev_origin, origin)
	
	if (origin[2] > 900.0) {
		ExecuteHamB(Ham_Killed, Ent, Ent, 2)
		return
	}
	
	set_pev(Boss, pev_victim, Ent)
	set_pev(Boss, pev_ability, ATTACK)
	set_pev(Boss, pev_num, 0)
}

public Touch_Bomb(Ent, Ent2) {
	new Agr = 1, Sprite = 5, Colors[3] = {255, 0, 0}, Float:Origin[3]; pev(Ent, pev_origin, Origin)
	Origin[2] += bomb_dist
	
	// fl0wer love you :*
	// http://amx-x.ru/viewtopic.php?f=9&t=103&start=10#p27400
	new MsgBomb = 0
	
	#if defined BOMB_CUSTOM
	switch (g_Color) {
		case 1: {	// RED Bomb
			Colors = {255, 0, 0}
			MsgBomb = 0
			Agr = 1
		}
		case 2: {
			if (g_Bomb[0] == Ent || g_Bomb[1] == Ent || g_Bomb[2] == Ent) {
				zl_create_entity(
					Origin, Resource[4], 1, 2.0, 
					SOLID_TRIGGER, MOVETYPE_NONE, DAMAGE_NO, DEAD_NO, 
					"info_target", "oberon_gas", Float:{-40.0, -40.0, -40.0}, Float:{40.0, 40.0, 40.0}, true)

				Colors = {0, 255, 0}
				MsgBomb = 131072
				Sprite = 15
				Agr = 1
			}
		}
		case 3: {	// YellowBomb
			static victim = -1
			if (g_Bomb[0] == Ent || g_Bomb[1] == Ent || g_Bomb[2] == Ent) {
				while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, 200.0)) != 0) {
					if (!is_user_alive(victim))
						continue
				
					set_pev(victim, pev_health, 1.0)
				}
				Colors = {255, 255, 0}
				MsgBomb = 32768
				Sprite = 5
				Agr = 1
				ShockWave(Origin, 10, 100, 100.0, {255, 255, 0})
			}
		}
		case 4: {	// FrozenBomb
			static victim = -1
			while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, 200.0)) != 0) {
				if (!is_user_alive(victim))
					continue
				
				set_rendering(victim, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 60)
				ScreenFade(victim, 6, 2, {0, 0, 255}, 90, 1)
				if(~pev(victim, pev_flags) & FL_FROZEN) set_pev(victim, pev_flags, pev(victim, pev_flags) | FL_FROZEN) 
				set_task(bomb_frozen_time, "Bomb_UnFrozen", 7512 + victim)
			}
			Sprite = 12
			Origin[2] += 50.0
			Colors = {0, 0, 255}
			ShockWave(Origin, 10, 100, 100.0, {0, 0, 255})
			MsgBomb = 16384
			Agr = 1
		}
		case 5: {	// GravityBomb
			Colors = {136, 136, 136}
			static v = -1
			while((v = engfunc(EngFunc_FindEntityInSphere, v, Origin, 200.0)) != 0) {
				if (!is_user_alive(v))
					continue
				
				set_rendering(v, kRenderFxGlowShell, 136, 136, 136, kRenderNormal, 200)
				set_pev(v, pev_gravity, 0.1)
				set_pev(v, pev_velocity, {0.0, 0.0, 200.0})
				ScreenFade(v, 3, 1, Colors, 150, 1)
				set_task(3.0, "Bomb_UnGravity", 7612 + v)
			}
			Sprite = 13
			Origin[2] += 30.0
			ShockWave(Origin, 10, 100, 100.0, Colors)
			MsgBomb = 32
			Agr = 1
		}
		case 6: {	// ImpulseBomb
			new Float:o[3]
			pev(Ent, pev_origin, o)
			o[2] += 40.0
			
			new i_spr = zl_create_entity(o, Resource[14], 1, 0.0, SOLID_NOT, MOVETYPE_NONE, DAMAGE_NO, DEAD_NO, "env_sprite", "oberon_impulse")
			set_rendering(i_spr, kRenderNormal, 0, 0, 0, kRenderTransAdd, 255)
			set_pev(i_spr, pev_framerate, 8.0)
			ExecuteHam(Ham_Spawn, i_spr)
			engfunc(EngFunc_RemoveEntity, Ent)
			return
		}
		default: Agr = 0
	}
	#else
	MsgBomb = 8
	Colors = {255, 0, 0}
	Agr = 0
	#endif
	expl(Origin, 40, Colors, MsgBomb, Sprite, Agr)
	engfunc(EngFunc_RemoveEntity, Ent)
}

public Think_Impulse(e) {
	if (!pev_valid(e))
		return
		
	// Fucking SPRITEthink
	static Float:st
	if (st <= get_gametime()) { // Timer for fukings "env_sprite"		
		static num; num++
		if (num >= bomb_impulse_time) {
			for(new id = 1; id <= get_maxplayers(); id++) {
				if (!is_user_alive(id) || is_user_bot(id))
					continue
					
				boss_damage(id, bomb_impulse_dmg[1], {255, 0, 0})
			}
			engfunc(EngFunc_RemoveEntity, e)
			num = 0
		}
		st = get_gametime() + 1.0
	}
	
	static Float: o[3], d = -1
	if (pev_valid(e)) pev(e, pev_origin, o)
	while((d = engfunc(EngFunc_FindEntityInSphere, d, o, 90.0)) != 0) {
		if(!is_user_alive(d))
			continue
		
		boss_damage(d, bomb_impulse_dmg[0], {255, 255, 0})
		
		new Float:o2[3], Float:v[3]
		pev(d, pev_origin, o2)
		
		xs_vec_sub(o2, o, v)
		xs_vec_normalize(v, v)
		xs_vec_mul_scalar(v, 1000.0, v)
		v[2] += 500.0
		set_pev(d, pev_velocity, v)
		engfunc(EngFunc_RemoveEntity, e)
	}
}

public Bomb_UnGravity(taskid) {
	new id = taskid - 7612
	set_rendering(id)
	set_pev(id, pev_gravity, 1.0)
	set_pev(id, pev_velocity, {0.0, 0.0, -1000.0})
}

public Touch_Box(Ent, Player) {
	if (!is_user_alive(Player) || !pev_valid(Ent))
		return
	
	/*
	static Float:v[3]
	pev(Ent, pev_velocity, v)
	
	if (v[2] < 0.0) {
		ExecuteHamB(Ham_Killed, Player, Player, 2)
		set_pev(Ent, pev_velocity, v)
	}
	*/
	ExecuteHamB(Ham_Killed, Player, Player, 2)
	set_pev(Ent, pev_velocity, {0.0, 0.0, 255.0})
}

public plugin_precache() {
	if (zl_boss_map() != 1)
		return
		
	for (new i; i <= charsmax(Resource); i++)
		g_Resource[i] = precache_model(Resource[i])
		
	for(new e; e <= charsmax(SoundList); e++)
		precache_sound(SoundList[e])
}
	
public plugin_cfg()
	config_load()

public Hook_Spawn(id) {	
	if (pev(g_Oberon, pev_button) == 0) {
		if(pev(g_Oberon, pev_takedamage) == DAMAGE_NO)	
			client_cmd(id, "mp3 play ^"sound/%s^"", SoundList[13])
		//else
			//client_cmd(id, "mp3 play ^"sound/%s^"", SoundList[15])
	} //else client_cmd(id, "mp3 play ^"sound/%s^"", SoundList[14])
}

public Bomb_UnFrozen(taskid) {
	new id = taskid - 7512
	set_rendering(id)
	if(pev(id, pev_flags) & FL_FROZEN) set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
}

public MapEvent() {
	for (new i; i < sizeof e_zombie; ++i) {
		static ClassName[10]
		formatex(ClassName, charsmax(ClassName), "zomb%d", i)
		e_zombie[i] = engfunc(EngFunc_FindEntityByString, e_zombie[i], "targetname", ClassName)
	}	
	e_boss = engfunc(EngFunc_FindEntityByString, e_boss, "targetname", "boss")
	EventPrepare()
}

boss_damage(victim, damage, color[3]) {
	if (pev(victim, pev_health) - float(damage) <= 0)
		ExecuteHamB(Ham_Killed, victim, victim, 2)
	else {
		ExecuteHamB(Ham_TakeDamage, victim, 0, victim, float(damage), DMG_BLAST)
		ScreenFade(victim, 1, 1, color, 170, 1)
		ScreenShake(victim, ((1<<12) * 8), ((2<<12) * 7))
	}
}

config_load() {
	if (zl_boss_map() != 1)
		return
		
	new path[64]
	get_localinfo("amxx_configsdir", path, charsmax(path))
	format(path, charsmax(path), "%s/zl/%s", path, FILE_SETTING)
    
	if (!file_exists(path)) {
		new error[100]
		formatex(error, charsmax(error), "Cannot load customization file %s!", path)
		set_fail_state(error)
		return
	}
    
	new linedata[2048], key[64], value[960], section
	new file = fopen(path, "rt")
    
	while (file && !feof(file)) {
		fgets(file, linedata, charsmax(linedata))
		replace(linedata, charsmax(linedata), "^n", "")
       
		if (!linedata[0] || linedata[0] == '/') continue;
		if (linedata[0] == '[') { section++; continue; }
       
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
		trim(key)
		trim(value)
		
		switch (section) { 
			case 1: {
				if (equal(key, "HEALTH"))
					boss_heal = str_to_num(value)
				#if defined SUPPORT_ZM
				else if (equal(key, "ZOMBIE_TIME"))
					zm_time = str_to_num(value)
				else if (equal(key, "ZOMBIE_ADD_TIME"))
					zm_add_time = str_to_num(value)
				else if (equal(key, "ZOMBIE_HP"))
					zm_hp = str_to_num(value)
				else if (equal(key, "ZOMBIE_SPEED"))
					zm_speed = str_to_num(value)
				else if (equal(key, "ZOMBIE_DAMAGE"))
					zm_damage = str_to_num(value)
				#endif
				else if (equal(key, "OFFSET_SPEED"))
					offset_speed = str_to_float(value)
				else if (equal(key, "KNF_FADE_TIME"))
					knife_fade_time = str_to_float(value)
			}
			case 2: {
				if (equal(key, "NORMAL_SPEED"))
					speed_boss = str_to_num(value)
				else if (equal(key, "DMG_MAX"))
					dmg_attack_max = str_to_num(value)  
				else if (equal(key, "DMG_NORMAL"))
					dmg_attack = str_to_num(value)
				else if (equal(key, "DMG_BOMB"))
					bomb_damage = str_to_num(value)
				else if (equal(key, "DMG_HOLE"))
					hole_dmg = str_to_num(value)
				else if (equal(key, "DMG_JUMP"))
					jump_damage = str_to_num(value)
				else if (equal(key, "DIST_JUMP"))
					jump_distance = str_to_num(value)
				else if (equal(key, "NTIME_ABILITY"))
					time_ability = str_to_num(value)
				#if defined ABILITY_CHAIN
				else if (equal(key, "CHAIN_RTIME"))
					time_chain[0] = str_to_num(value)
				else if (equal(key, "CHAIN_TIME"))
					time_chain[1] = str_to_num(value)
				#endif
			}
			case 3: {
				if (equal(key, "AGR_SPEED"))
					speed_boss_agr = str_to_num(value)
				else if (equal(key, "AGR_DMG_BOMB"))
					bomb_damage_agr = str_to_num(value)  
				else if (equal(key, "AGR_DMG_HOLE"))
					hole_dmg_agr = str_to_num(value)
				else if (equal(key, "AGR_DMG_JUMP"))
					jump_damage_agr = str_to_num(value)
				else if (equal(key, "ATIME_ABILITY"))
					time_ability_agr = str_to_num(value)
			}
			case 4: {
				if (equal(key, "BOMB_DIST"))
					bomb_dist = float(str_to_num(value))
				#if defined BOMB_CUSTOM
				else if (equal(key, "BOMB_DMG_MIND"))
					bomb_mind = str_to_num(value)
				else if (equal(key, "BOMB_DMG_POISON"))
					bomb_poison = float(str_to_num(value))
				else if (equal(key, "BOMB_POISON_LIFE"))
					bomb_poison_life = str_to_num(value)
				else if (equal(key, "BOMB_FROZEN_TIME"))
					bomb_frozen_time = float(str_to_num(value))
				else if (equal(key, "BOMB_IMPULSE_NUM"))
					bomb_impulse_num = str_to_num(value)
				else if (equal(key, "BOMB_IMPULSE_DDMG"))
					bomb_impulse_dmg[0] = str_to_num(value)
				else if (equal(key, "BOMB_IMPULSE_EDMG"))
					bomb_impulse_dmg[1] = str_to_num(value)
				else if (equal(key, "BOMB_IMPULSE_TIME"))
					bomb_impulse_time = str_to_num(value)
				#endif
			}
		}
	}
	if (file) fclose(file)
}
 
 /*========================
// STOCK 
========================*/

stock oberon_beaments(s, e, t) {
	if (!is_user_alive(s) || !is_user_alive(e) || s == e) {
		return
	}
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY ) 
	write_byte( TE_BEAMENTS ) 
	write_short( s )
	write_short( e )
	write_short( g_Resource[16] )
	write_byte( 1 )		// framestart 
	write_byte( 1 )		// framerate 
	write_byte( 10 * t )	// life in 0.1's 
	write_byte( 8 )		// width
	write_byte( 0 )		// noise 
	write_byte( 255 )	// r, g, b 
	write_byte( 0 )		// r, g, b 
	write_byte( 0 ) 		// r, g, b 
	write_byte( 200 )	// brightness 
	write_byte( 0 )		// speed 
	message_end()
}

stock zl_create_entity 
	(
		Float:Origin[3], 
		Model[] = "models/player/sas/sas.mdl", 
		HP = 100,
		Float:NextThink = 1.0,
		SOLID_ = SOLID_BBOX, 
		MOVETYPE_ = MOVETYPE_PUSHSTEP, 
		Float:DAMAGE_ = DAMAGE_YES, 
		DEAD_ = DEAD_NO, 
		ClassNameOld[] = "info_target", 
		ClassNameNew[] = "player_entity", 
		Float:SizeMins[3] = {-32.0, -32.0, -36.0}, 
		Float:SizeMax[3] = {32.0, 32.0, 96.0}, 
		bool:invise = false
	) {
	
	new Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, ClassNameOld))
	
	if (!pev_valid(Ent))
		return 0
	
	engfunc(EngFunc_SetModel, Ent, Model)
	engfunc(EngFunc_SetSize, Ent, SizeMins, SizeMax)
	engfunc(EngFunc_SetOrigin, Ent, Origin)
	if (NextThink > 0.0) set_pev(Ent, pev_nextthink, get_gametime() + NextThink)
	if (invise) set_pev(Ent, pev_effects, pev(Ent, pev_effects) | EF_NODRAW)
	set_pev(Ent, pev_classname, ClassNameNew)
	set_pev(Ent, pev_solid, SOLID_)
	set_pev(Ent, pev_movetype, MOVETYPE_)
	set_pev(Ent, pev_takedamage, DAMAGE_)
	set_pev(Ent, pev_deadflag, DEAD_)
	set_pev(Ent, pev_max_health, float(HP))
	set_pev(Ent, pev_health, float(HP))
	
	return Ent
}

stock zl_move(Start, End, Float:speed = 250.0, Float:Velocity[] = {0.0, 0.0, 0.0}, Float:Angles[] = {0.0, 0.0, 0.0}) {
	new Float:Origin[3], Float:Origin2[3], Float:Angle[3], Float:Vector[3], Float:Len
	pev(Start, pev_origin, Origin2)
	pev(End, pev_origin, Origin)
	
	if (!is_user_alive(End)) {
		Origin[2] -= OFFSET_GROUND
	} else {
		Origin2[2] -= OFFSET_GROUND
	}
	
	xs_vec_sub(Origin, Origin2, Vector)
	Len = xs_vec_len(Vector)
	
	vector_to_angle(Vector, Angle)
	
	Angles[0] = 0.0
	Angles[1] = Angle[1]
	Angles[2] = 0.0
	
	xs_vec_normalize(Vector, Vector)
	xs_vec_mul_scalar(Vector, speed, Velocity)
	
	return floatround(Len, floatround_round)
}
		
stock Anim(ent, sequence, Float:speed) {		
	set_pev(ent, pev_sequence, sequence)
	set_pev(ent, pev_animtime, halflife_time())
	set_pev(ent, pev_framerate, speed)
}

stock PlayerHp(hp) {
	new Count, Hp
	for(new id = 1; id <= get_maxplayers(); id++)
		if (is_user_connected(id) && !is_user_bot(id))
			Count++
			
	Hp = hp * Count
	return Hp
}

stock get_position(id, Float:forw, Float:right, Float:up, Float:vStart[]) {
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
    
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_angles, vAngle) // if normal entity ,use pev_angles
    
	engfunc(EngFunc_AngleVectors, ANGLEVECTOR_FORWARD, vForward)
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
    
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock Smoke(Float:Origin[3]) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_FIREFIELD)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] - 25.0)
	write_short(150)
	write_short(g_Resource[10])
	write_byte(100)
	write_byte(TEFIRE_FLAG_PLANAR | TEFIRE_FLAG_ALLFLOAT | TEFIRE_FLAG_ALPHA)
	write_byte(30)
	message_end()
}

expl(Float:Origin[3], scale31, Colors[3], Msg, SprIndex, Agr) {
	static victim = -1
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])  
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_Resource[SprIndex])
	write_byte(scale31)
	write_byte(20)
	write_byte(0)
	message_end()
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, 200.0)) != 0) {
		if(is_user_alive(victim)) {
			#if defined BOMB_CUSTOM
			switch (g_Color) {
				case 1: boss_damage(victim, bomb_mind, Colors)
				case 3, 5: return
				default: boss_damage(victim, pev(g_Oberon, pev_button) ? bomb_damage_agr : bomb_damage, Colors)
			}
			#else
			boss_damage(victim, Agr ? bomb_damage_agr : bomb_damage, Colors)
			#endif
			if (Msg) DmgMsg(Origin, victim, Msg)
		}
	}
	if (Agr) Light(Origin, 6, 40, 60, Colors)
}

stock ScreenShake(id, duration, frequency) {	
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_ALL, get_user_msgid("ScreenShake"), _, id ? id : 0);
	write_short(1<<14)
	write_short(duration)
	write_short(frequency)
	message_end();
}

stock ScreenFade(id, Timer, FadeTime, Colors[3], Alpha, type) {
	if(id) if(!is_user_connected(id)) return

	if (Timer > 0xFFFF) Timer = 0xFFFF
	if (FadeTime <= 0) FadeTime = 4
	
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, get_user_msgid("ScreenFade"), _, id);
	write_short(Timer * 1 << 12)
	write_short(FadeTime * 1 << 12)
	switch (type) {
		case 1: write_short(0x0000)		// IN ( FFADE_IN )
		case 2: write_short(0x0001)		// OUT ( FFADE_OUT )
		case 3: write_short(0x0002)		// MODULATE ( FFADE_MODULATE )
		case 4: write_short(0x0004)		// STAYOUT ( FFADE_STAYOUT )
		default: write_short(0x0001)
	}
	write_byte(Colors[0])
	write_byte(Colors[1])
	write_byte(Colors[2])
	write_byte(Alpha)
	message_end()
}

stock Light(Float:Origin[3], Time, Radius, Rate, Colors[3]) {		
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_DLIGHT) // TE id
	engfunc(EngFunc_WriteCoord, Origin[0]) // x
	engfunc(EngFunc_WriteCoord, Origin[1]) // y
	engfunc(EngFunc_WriteCoord, Origin[2]) // z
	write_byte(Radius) // radius
	write_byte(Colors[0]) // r
	write_byte(Colors[1]) // g
	write_byte(Colors[2]) // b
	write_byte(10 * Time) //life
	write_byte(Rate) //decay rate
	message_end()
}

stock DmgMsg(Float:Origin[3], victim, Msg) {
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Damage"), {0,0,0}, victim)
	write_byte(0)
	write_byte(1)
	write_long(Msg)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	message_end()
}

stock Wreck(Float:Origin[3], Size[3], Velocity[3], RandomVelocity, Num, Life, Flag) {			
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BREAKMODEL)
	engfunc(EngFunc_WriteCoord, Origin[0]) // Pos.X
	engfunc(EngFunc_WriteCoord, Origin[1]) // Pos Y
	engfunc(EngFunc_WriteCoord, Origin[2]) // Pos.Z
	engfunc(EngFunc_WriteCoord, Size[0]) // Size X
	engfunc(EngFunc_WriteCoord, Size[1]) // Size Y
	engfunc(EngFunc_WriteCoord, Size[2]) // Size Z
	engfunc(EngFunc_WriteCoord, Velocity[0]) // Velocity X
	engfunc(EngFunc_WriteCoord, Velocity[1]) // Velocity Y
	engfunc(EngFunc_WriteCoord, Velocity[2]) // Velocity Z
	write_byte(RandomVelocity) // Random velocity
	write_short(g_Resource[9]) // Model/Sprite index
	write_byte(Num) // Num
	write_byte(Life) // Life
	write_byte(Flag) // Flags ( 0x02 )
	message_end()
}

stock ShockWave(Float:Orig[3], Life, Width, Float:Radius, Color[3]) {
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Orig, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, Orig[0]) // x
	engfunc(EngFunc_WriteCoord, Orig[1]) // y
	engfunc(EngFunc_WriteCoord, Orig[2]-40.0) // z
	engfunc(EngFunc_WriteCoord, Orig[0]) // x axis
	engfunc(EngFunc_WriteCoord, Orig[1]) // y axis
	engfunc(EngFunc_WriteCoord, Orig[2]+Radius) // z axis
	write_short(g_Resource[11]) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(Life) // life (4)
	write_byte(Width) // width (20)
	write_byte(0) // noise
	write_byte(Color[0]) // red
	write_byte(Color[1]) // green
	write_byte(Color[2]) // blue
	write_byte(255) // brightness
	write_byte(0) // speed
	message_end()
}

stock Sound(Ent, Sounds) engfunc(EngFunc_EmitSound, Ent, CHAN_AUTO, SoundList[_:Sounds], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
