#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0
#define _tklib_only_tf2
#include <tklib>
#include <multicolors>
#define PLUGIN_VERSION "2.3.1"
#define Tag "{purple}[TF Addcond]{default}"
ConVar addcond_chat;

public Plugin myinfo = {
	name = "[TF2] Add/Remove Condition on Specific Players",
	author = "Tk /id/Teamkiller324",
	description = "Give specific targets a specific condition id number with optional time",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/Teamkiller324"
}

public void OnPluginStart()	{
	if(GetEngineVersion() != Engine_TF2)
		SetFailState("[TF2] Add/Remove Condition has returned an error: ERR_GAME_IS_NOT_TF2 - This may only work in Team Fortress 2");
	
	LoadTranslations("tf_addcond.phrases");
	
	//Detect TF2 Versions
	char game[64];
	GetGameFolderName(game,	sizeof(game));
	GetGameName(game, sizeof(game));
	PrintToServer("[TF2] Add/Remove Condition has detected %s", game);
	
	//Load Main Part
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_addcond", condition_add, ADMFLAG_SLAY, "Add a condition id on a target, optionally in seconds of duration.");
	RegAdminCmd("sm_removecond", condition_remove, ADMFLAG_SLAY, "Remove a condition id from a target.");

	//Cvars
	addcond_chat = CreateConVar("tf_addcond_chat", "1", "Determine wheter to show for client only or everyone. \n0 = Off \n1 = Show only for Client \n2 = Show for everyone", _, true, 0.0, true, 2.0);
	CreateConVar("tf_addcond_version", PLUGIN_VERSION, "[TF2] Add/Remove Condition Version");
	
	AutoExecConfig(true, "tf_addcond");
	
	Tklib_PrepareTFCondName();
}

Action condition_add(int client, int args) {
	if(IsClientConsole(client)) {
		CReplyToCommand(client, "%s This may only be used ingame", Tag);
		return Plugin_Handled;
	}

	if(args < 2 || args > 3) {
		CPrintToChat(client, "%s %t", Tag, "Addcond Usage");
		return Plugin_Handled;
	}
	
	char arg1[64], arg2[64], arg3[64], target_name[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	
	ArrayList list = FindClientsByPlayername(arg1, client);
	int value = StringToAny(arg2);
	float time = StringToFloat(arg3);
	
	if(list.Length < 1) {
		delete list;
		CPrintToChat(client, "%s %t", Tag, "No User Found Matching Search Criteria", arg1);
		return Plugin_Handled;
	}
	
	if(list.Length > 1) {
		delete list;
		CPrintToChat(client, "%s %t", Tag, "More Than One Matching Search Criteria", arg1);
		return Plugin_Handled;
	}
	
	int target = list.Get(0);
	delete list;
	
	if(!Tklib_IsValidClient(target, _, true)) {
		CPrintToChat(client, "%s %t", Tag, "Invalid Target", arg1);
		return Plugin_Handled;
	}
	
	if(value < 0) {
		CPrintToChat(client, "%s %t", Tag, "Condition ID Less than 0");
		return Plugin_Handled;
	}
	
	if(TF2_IsPlayerInCondition(target, view_as<TFCond>(value))) {
		CPrintToChat(client, "%s %t", Tag, "Target Already Have Condition", value, TFCond_Name[value]);
		return Plugin_Handled;
	}
	
	if(value > MAX_TF2_CONDITION_ID) {
		CPrintToChat(client, "%s %t", Tag, "Condition ID Invalid", value);
		return Plugin_Handled;
	}
	
	GetClientNameTeamString(target, target_name, sizeof(target_name));
	
	switch(!IsValidString(arg3)) {
		case true: {
			TF2_AddCondition(target, view_as<TFCond>(value), TFCondDuration_Infinite, 0);
			
			switch(addcond_chat.BoolValue) {
				case 1: CPrintToChat(client, "%s %t", Tag, "Addcond Give Condition 1", value, TFCond_Name[value], target_name);
				case 2: CPrintToChatAll("%s %t", Tag, "Addcond Give Condition 2", client, value, TFCond_Name[value], target_name);
			}
			
			CPrintToServer("Log: %N Added condition %d (%s) to %s.", client, value, TFCond_Name[value], target_name);
		}
		case false: {
			if(time < 1) {
				CPrintToChat(client, "%s %t", Tag, "Time Less Than 1");
				return Plugin_Handled;
			}
			if(time > 5000) {
				CPrintToChat(client, "%s %t", Tag, "Timer More Than 5000");
				return Plugin_Handled;
			}
			
			TF2_AddCondition(target, view_as<TFCond>(value), time, 0);
			
			switch(addcond_chat.BoolValue) {
				case 1: CPrintToChat(client, "%s %t", Tag, "Addcond Give Condition 3", value, TFCond_Name[value], target_name, arg3);
				case 2: CPrintToChatAll("%s %t", Tag, "Addcond Give Condition 4", client, value, TFCond_Name[value], target_name, arg3);
			}
			
			CPrintToServer("Log: %N Added condition id %d (%s) to %s for %d seconds.", client, value, TFCond_Name[value], target_name, arg3);
		}
	}
	
	return Plugin_Handled;
}

Action condition_remove(int client, int args) {
	if(IsClientConsole(client)) {
		CReplyToCommand(client, "%s This may only be used ingame", Tag);
		return Plugin_Handled;
	}

	if(args < 2) {
		CPrintToChat(client, "%s Usage: sm_removecond <target> <condition id>", Tag);
		return Plugin_Handled;
	}
	
	char arg1[64], arg2[64], target_name[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	ArrayList list = FindClientsByPlayername(arg1, client);
	int value = StringToAny(arg2);
	
	if(list.Length < 1) {
		delete list;
		CPrintToChat(client, "%s %t", Tag, "No User Found Matching Search Criteria", arg1);
		return Plugin_Handled;
	}
	if(list.Length > 1) {
		delete list;
		CPrintToChat(client, "%s %t", Tag, "More Than One Matching Search Criteria", arg1);
		return Plugin_Handled;
	}
	
	int target = list.Get(0);
	delete list;
	
	if(!Tklib_IsValidClient(target, _, true)) {
		CPrintToChat(client, "%s %t", Tag, "Invalid Target", arg1);
		return Plugin_Handled;
	}
	
	GetClientNameTeamString(target, target_name, sizeof(target_name));
	
	if(value < 0) {
		CPrintToChat(client, "%s %t", Tag, "Condition ID Than 1");
		return Plugin_Handled;
	}
	if(value > MAX_TF2_CONDITION_ID) {
		CPrintToChat(client, "%s %t", Tag, "Condition ID Invalid", value, target_name);
		return Plugin_Handled;
	}
	
	if(!TF2_IsPlayerInCondition(target, view_as<TFCond>(value))) {
		CPrintToChat(client, "%s %t", Tag, "Target Does Not Have Condition", target_name, value, TFCond_Name[value]);
		return Plugin_Handled;
	}
	
	TF2_RemoveCondition(target, view_as<TFCond>(value));		
	
	switch(addcond_chat.BoolValue) {
		case 1:	CPrintToChat(client, "%s %t", Tag, "Removecond Remove Condition 1", value, TFCond_Name[value], target_name);
		case 2:	CPrintToChatAll("%s %t", Tag, "Removecond Remove Condition 2", client, value, TFCond_Name[value], target_name);
	}
	
	CPrintToServer("Log: %N Removed condition id %d (%s) from %s", client, value, TFCond_Name[value], target_name);
	return Plugin_Handled;
}