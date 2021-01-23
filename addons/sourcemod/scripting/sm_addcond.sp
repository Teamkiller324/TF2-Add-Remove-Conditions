#include	<sourcemod>
#include	<tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define	PLUGIN_VERSION "2.1.0"
ConVar	addcond_chat;

char	arg1	[MAX_NAME_LENGTH];
char	arg2	[MAX_NAME_LENGTH];
char	arg3	[MAX_NAME_LENGTH];

char	target_name	[MAX_TARGET_LENGTH];

int		target_list[MAXPLAYERS];
int		target_count;
bool	tn_is_ml;

char	description[256];

public	Extension	__ext_tf2	= 	{
	name		=	"TF2 Tools",		//This allows the plugin to load even though the TF2 Tools extension is not running
	file		=	"game.tf2.ext",	//To allow other TF2 versions to work with this plugin
	required	=	0,
};

public	Plugin	myinfo	=	{
	name		=	"[TF2] Add/Remove Condition on Specific Players",
	author		=	"Tk /id/Teamkiller324",
	description	=	"Give specific targets a specific condition id number with optional time",
	version		=	PLUGIN_VERSION,
	url			=	"https://steamcommunity.com/id/Teamkiller324"
}

public	void	OnPluginStart()	{
	//If the server is not running Team Fortress 2 or atleast, any kind of Team Fortress 2 game
	if(GetEngineVersion() != Engine_TF2)
		SetFailState("[TF2] Add/Remove Condition has returned an error: ERR_GAME_IS_NOT_TF2 - This may only work in Team Fortress 2");

	//Detect TF2 Versions
	char	game[64];
	GetGameFolderName(game,	sizeof(game));
	if(StrEqual(game,	"tf"))
		PrintToServer("[TF2] Add/Remove Condition has detected Team Fortress 2");
	if(StrEqual(game,	"tf2classic"))
		PrintToServer("[TF2] Add/Remove Condition has detected Team Fortress 2 Classic");
	if(StrEqual(game,	"tf2vintage"))
		PrintToServer("[TF2] Add/Remove Condition has detected Team Fortress 2 Vintage");
	if(StrEqual(game,	"open_fortress"))
		PrintToServer("[TF2] Add/Remove Condition has detected Open Fortress");

	//Load Main Part
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_addcond",		condition_add,		ADMFLAG_SLAY);
	RegAdminCmd("sm_addcond2",		condition_add2,		ADMFLAG_SLAY);
	RegAdminCmd("sm_removecond",	condition_remove,	ADMFLAG_SLAY);
	

	//Cvars
	addcond_chat = CreateConVar("sm_addcond_chat", "1", "Determine wheter to show for client only or everyone. \n0 = Off \n1 = Show only for Client \n2 = Show for everyone", _, true, 0.0, true, 2.0);
	CreateConVar("sm_addcond_version", PLUGIN_VERSION, "[TF2] Add/Remove Condition Version");

	//Add Target Filters
	AddMultiTargetFilter("@random",	Filter_Random,		"a random player",	false);
}

public	void	OnPluginEnd()	{
	//Remove Target Filters
	RemoveMultiTargetFilter("@random",	Filter_Random);
}

//Switch for condition list
public	void	conditionlist(int condition)	{
	switch	(condition)	{
		case 0: description = "Revving Minigun, Sniper Rifle. Gives zoomed/revved pose";
		case 1: description = "Sniper Rifle zooming";	
		case 2: description = "Disguise smoke";
		case 3: description = "Disguise";
		case 4: description = "Cloak Effect";
		case 5: description = "Invulnerability, removed when being healed or by another Über effect";
		case 6: description = "Teleport trail";
		case 7:	description = "Used for taunting, can remove to stop taunting";
		case 8: description = "Invulnerability expiration effect";
		case 9: description = "Cloak flickering effect";
		case 10: description = "Used for teleporting, does nothing applying";
		case 11: description = "Crit boost, removed when being healed or another Über effect";
		case 12: description = "Temporary damage buff, something along with attribute 19";
		case 13: description = "Dead Ringer damage resistance, gives TFCond_Cloaked";
		case 14: description = "Bonk! Atomic Punch effect";
		case 15: description = "Slow effect, can remove to remove stun effects";
		case 16: description = "Buff Banner mini-crits, icon and glow";
		case 17: description = "Forced forward, charge effect";
		case 18: description = "Eyelander eye glow";
		case 19: description = "Mini-crit effect";
		case 20: description = "Ring effect, rings disappear after a taunt ends";
		case 21: description = "Used for healing, does nothing applying";
		case 22: description = "Ignite sound and vocals, can remove to remove afterburn";
		case 23: description = "Used for overheal, does nothing applying";
		case 24: description = "Jarate effect";
		case 25: description = "Bleed effect";
		case 26: description = "Battalion's Backup's defense, icon and glow";
		case 27: description = "Mad Milk effect";
		case 28: description = "Quick-Fix Übercharge's knockback/stun immunity and visual effect";
		case 29: description = "Concheror's speed boost, heal on hit, icon and glow";
		case 30: description = "Fan o'War marked-for-death effect";
		case 31: description = "Mini-crits, blocks healing, glow, no weapon mini-crit effects";
		case 32: description = "Disciplinary Action speed boost";
		case 33: description = "Halloween pumpkin crit-boost";
		case 34: description = "Crit-boost and doubles Sentry Gun fire-rate";
		case 35: description = "Crit glow, adds TFCond_Charging when charge meter is below 75%";
		case 36: description = "Soda popper multi-jump effect";
		case 37: description = "Arena first blood crit-boost";
		case 38: description = "End-of-round crit-boost";
		case 39: description = "Intelligence capture crit-boost";
		case 40: description = "Crit boost from crit-on-kill weapons";
		case 41: description = "Prevents switching once melee is out";
		case 42: description = "MvM Bomb Carrier defense buff (TFCond_DefenseBuff without crit resistance)";
		case 43: description = "No longer functions";
		case 44: description = "Phlogistinator crit-boost";
		case 45: description = "Old Phlogistinator defense buff";
		case 46: description = "Hitman's Heatmaker no-unscope and faster Sniper charge";
		case 47: description = "Enforcer damage bonus removed";
		case 48: description = "Marked-for-death without sound effect";
		case 49: description = "Dispenser disguise when crouching, max movement speed, sentries ignore player";
		case 50: description = "Sapper sparkle effect in MvM";
		case 51: description = "Out-of-bounds robot invulnerability effect";
		case 52: description = "Invulnerability effect and Sentry Gun damage resistance";
		case 53: description = "Bomb head effect (does not explode)";
		case 54: description = "Forced Thriller taunting";
		case 55: description = "Radius Healing, adds TFCond_InHealRadius, TFCond_Healing. Removed when a taunt ends, but this condition stays but does nothing";
		case 56: description = "Miscellaneous crit-boost";
		case 57: description = "Miscellaneous invulnerability";
		case 58: description = "Vaccinator Über bullet resistance";
		case 59: description = "Vaccinator Über blast resistance";
		case 60: description = "Vaccinator Über fire resistance";
		case 61: description = "Vaccinator Über fire resistance";
		case 62: description = "Vaccinator Über healing bullet resistance";
		case 63: description = "Vaccinator Über healing blast resistance";
		case 64: description = "Cloaked until next attack";
		case 65: description = "Medigun debuff";
		case 66: description = "Cloaked, will appear for a few seconds on attack and cloak again";
		case 67: description = "Full bullet immunity";
		case 68: description = "Full blast immunity";
		case 69: description = "Full fire immunity";
		case 70: description = "Survive to 1 health, then the condition is removed";
		case 71: description = "Stuns bots and applies radio effect";
		case 72: description = "Speed boost, non-melee fire rate and reload, infinite air jumps";
		case 73: description = "Healing effect, adds TFCond_Healing along with TFCond_MegaHeal temporarily";
		case 74: description = "Double size, x10 max health increase, ammo regeneration and forced thirdperson";
		case 75: description = "Half size and increased head size";
		case 76: description = "Applies TFCond_HalloweenGhostMode when the player dies";
		case 77: description = "Becomes a ghost unable to attack but can fly";
		case 78: description = "Mini-crits effect, Does nothing, condition does not exist";
		case 79: description = "75% chance to doge an attack";
		case 80: description = "Parachute effect, removed when touching the ground";
		case 81: description = "Player is blast jumping";
		case 82: description = "Player forced into a halloween kart";
		case 83: description = "Player forced into a halloween kart";
		case 84: description = "Big head and lowered gravity";
		case 85: description = "Forced melee, along with TFCond_SpeedBuffAlly and TFCond_HalloweenTiny";
		case 86: description = "Swim in the air with Jarate overlay";
		case 87: description = "Locked and cannot turn, attack or switch weapons but still can taunt";
		case 88: description = "Puts a cage around the player if in TFCond_HalloweenKart, otherwise crashes";
		case 89: description = "Has a powerup";
		case 90: description = "Double damage and no damage falloff";
		case 91: description = "Double fire rate, reload speed, clip and ammo size and 30% faster movement speed";
		case 92: description = "Regen ammo, health and metal";
		case 93: description = "Takes 1/2 damage and critical immunity";
		case 94: description = "Takes 3/4 damage, gain health on damage and 40% increase in max health";
		case 95: description = "Attacker takes damage and knockback on hitting the player and 50% increase in max health";
		case 96: description = "Less bullet spread, no damage falloff, 250% faster projectiles, and double damage, faster charge, and faster re-zoom for Sniper Rifles";
		case 97: description = "Increased movement speed, grappling hook speed, jump height and instant weapon switch";
		case 98: description = "Used when player fires their grappling hook, no effect applying or removing";
		case 99: description = "Used when a player is pulled by their grappling hook, no effect applying or removing";
		case 100: description = "Used when a player latches onto a wall, no effect applying or removing";
		case 101: description = "Used when a player is hit by attacker's grappling hook, does no effect applying or removing";
		case 102: description = "Deadringer afterburn immunity";
		case 103: description = "Melee and grappling hook only, increased max health, knockback immunity, x4 more damage against buildings, and knockbacks a powerup off a victim on hit";
		case 104: description = "Prevents gaining a crit-boost or Über powerups";
		case 105: description = "Crit-boost effect";
		case 106: description = "Used when a player intercepts the Jack/Ball, does nothing applying or removing";
		case 107: description = "Swimming in the air without animations or overlay";
		case 108: description = "Refills max health, short Über, escaped the underworld message on removal";
		case 109: description = "Increased max health and applies TFCond_KingAura";
		case 110: description = "Radius health kit stealing, increased max health, TFCond_Plague on touching a victim";
		case 111: description = "Charge meter passively increasing, when charge activated causes radius Bonk stun";
		case 112: description = "Plague sound effect and message, blocks King powerup health regen";
		case 113: description = "Increased fire rate, reload speed, and health regen to players in a radius";
		case 114: description = "Outline and health meter of teammates (and disguised spies)";
		case 115: description = "Used when a player is airblasted, does nothing when applying or removing";
		case 116: description = "Applied when the player is on the competitive winner's podium, does nothing on applying or removing";
		case 117: description = "Applied when the player is on the loser team in competitive match summary, prevents taunting";
		case 118: description = "Healing debuff from Medics and dispensers";
		case 119: description = "Marked-for-death effect";
		case 120: description = "Prevents taunting and some Grappling Hook actions";
		case 121: description = "Unknown, checked when attempting to set the target for a grappling hook";
		case 122: description = "Parachute deloyed, prevents reopening it";
		case 123: description = "Gas Passer effect";
		case 124: description = "Dragon's Fury afterburn on Pyros";
		case 125: description = "Thermal Thruster launched effects, prevents reusing";
		case 126: description = "Less ground friction";
		case 127: description = "Reduced air control and friction";
		case 128: description = "Used whenever a player gets teleported to Hell, does nothing applied but stops the gradual healing from the teleport when removed";
	}
}

bool	Filter_Random(const char[] pattern,	Handle clients)	{
	int findClients[MAXPLAYERS], count = 0;
	for(int i = 1; i < MaxClients; i++)	{
		if (IsClientInGame(i))
			continue;

		findClients[count] = i;
		count += 1;
	}
	if(count < 1)
		return false;
	PushArrayCell(clients, findClients[GetRandomInt(0, count)]);
	return true;
}

stock	bool	IsValidClient(int client)	{
	if(client == 0)					return false;
	if(!IsClientInGame(client))		return false;
	if(IsFakeClient(client))		return false;
	return true;
}

Action	condition_add(int client,	int args)	{
	if(!IsValidClient(client))	{
		ReplyToCommand(client, "[SM] This may only be used ingame");
		return Plugin_Handled;
	}

	if(args < 2)	{
		PrintToChat(client, "[SM] Usage: sm_addcond <target> <condition id>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, arg1, sizeof(arg1));
	if ((target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	if(client == -1)
		return Plugin_Handled;
	
	GetCmdArg(2, arg2, sizeof(arg2));
	int value = StringToInt(arg2);
	if(value < 0)	{
		PrintToChat(client, "[SM] The addcond number must be 0 or greater");
		return Plugin_Handled;
	}
	else	{
		int	condition = StringToInt(arg2);
		for (int i = 0; i < target_count; i++)
			TF2_AddCondition(target_list[i], view_as<TFCond>(condition), TFCondDuration_Infinite, 0);
		
		if(value > 128)	{
			PrintToChat(client, "[SM] The condition %d you specified seems to not exist, giving no effect", condition, target_name);
			return Plugin_Handled;	//Prevent Invalid TFCond value error
		}
		else
			conditionlist(condition);
		if(addcond_chat.IntValue == 1)
			PrintToChat(client, "[SM] Gave condition %d (%s) to %s.", condition, description, target_name);
		if(addcond_chat.IntValue == 2)
			PrintToChatAll("[SM] %N has given the condition %d (%s) to %s.", client, condition, description, target_name);
		PrintToServer("Log: %N Added condition %d (%s) to %s.", client, condition, description, target_name);
	}
	return Plugin_Handled;
}

Action	condition_add2(int client,	int args)	{
	if(!IsValidClient(client))	{
		ReplyToCommand(client, "[SM] This may only be used ingame");
		return Plugin_Handled;
	}

	if(args < 3)	{
		ReplyToCommand(client, "[SM] Usage: sm_addcond2 <target> <condition id> <time>");
		return Plugin_Handled;
	}

	GetCmdArg(1, arg1, sizeof(arg1));
	if((target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	if(client == -1)
		return Plugin_Handled;

	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	int value = StringToInt(arg2), time = StringToInt(arg3);

	if(value < 0)	{
		PrintToChat(client, "[SM] The condition number must be greater than 0");
		return Plugin_Handled;
	}
	else if(time < 1)	{
		PrintToChat(client, "[SM] The time must be greater than 0 seconds");
		return Plugin_Handled;
	}
	else if(value > 0 && time < 1)	{
		PrintToChat(client, "[SM] The time must be greater than 0 seconds");
		return Plugin_Handled;
	}
	else if(value < 0 && time > 1)	{
		PrintToChat(client, "[SM] The condition number must be 0 or greater");
		return Plugin_Handled;
	}
	else	{
		int condition = StringToInt(arg2), seconds = StringToInt(arg3);
		for (int i = 0; i < target_count; i++)
			TF2_AddCondition(target_list[i], view_as<TFCond>(condition), StringToFloat(arg3), 0);
		
		if(value > 128)
		{
			PrintToChat(client, "[SM] The condition %d you specified seems to not exist, giving no effect", condition, target_name);
			return Plugin_Handled;
		}
		else
			conditionlist(condition);
		if(addcond_chat.IntValue == 1)
			PrintToChat(client, "[SM] Gave the condition %d (%s) to %s for %d seconds.", condition, description, target_name, seconds);
		if(addcond_chat.IntValue == 2)
			PrintToChatAll("[SM] %N has given the condition %d (%s) to %s for %d seconds", client, condition, description, target_name, seconds);
		PrintToServer("Log: %N Added condition %d (%s) to %s for %d seconds.", client, condition, description, target_name, seconds);
	}
	return Plugin_Handled;
}

Action	condition_remove(int client,	int args)	{
	if(!IsValidClient(client))	{
		ReplyToCommand(client, "[SM] This may only be used ingame");
		return Plugin_Handled;
	}

	if(args < 2)	{
		PrintToChat(client, "[SM] Usage: sm_removecond <target> <condition id>");
		return Plugin_Handled;
	}

	GetCmdArg(1, arg1, sizeof(arg1));
	if((target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	if(client == -1)
		return Plugin_Handled;

	GetCmdArg(2, arg2, sizeof(arg2));
	int value = StringToInt(arg2);
	if(value < 0)	{
		ReplyToCommand(client, "[SM] The condition number must be 0 or greater");
		return Plugin_Handled;
	}
	else	{
		int condition = StringToInt(arg2);
		for (int i = 0; i < target_count; i++)	{
			if(TF2_IsPlayerInCondition(target_list[i], view_as<TFCond>(condition)))	{
				PrintToChat(client, "[SM] The target %s does not have the condition you specified");
				return Plugin_Handled;
			}
			TF2_RemoveCondition(target_list[i], view_as<TFCond>(condition));
		}
		if(value > 128)	{
			PrintToChat(client, "[SM] The condition %d you specified seems to not exist, giving no effect", condition, target_name);
			return Plugin_Handled;
		}
		else
			conditionlist(condition);
		if(addcond_chat.IntValue == 1)
			PrintToChat(client, "[SM] %N Removed the condition %d (%s) from %s", condition, description, target_name);
		if(addcond_chat.IntValue == 2)
			PrintToChatAll("[SM] %N has removed the condition %d (%s) from %s", client, condition, description, target_name);
		PrintToServer("Log: %N Removed condition %d (%s) from %s", client, condition, description, target_name);
	}
	return Plugin_Handled;
}