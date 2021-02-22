#undef		REQUIRE_EXTENSIONS
#include	<tf2_stocks>

#pragma		semicolon	1
#pragma		newdecls	required

#define		PLUGIN_VERSION	"2.2.0"
ConVar		addcond_chat;

#include	"include/sm_addcond"

public	Plugin	myinfo	=	{
	name		=	"[TF2] Add/Remove Condition on Specific Players",
	author		=	"Tk /id/Teamkiller324",
	description	=	"Give specific targets a specific condition id number with optional time",
	version		=	PLUGIN_VERSION,
	url			=	"https://steamcommunity.com/id/Teamkiller324"
}

public	void	OnPluginStart()	{
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
	RegAdminCmd("sm_addcond",		condition_add,		ADMFLAG_SLAY,	"Add a condition id on a target, optionally in seconds of duration.");
	RegAdminCmd("sm_removecond",	condition_remove,	ADMFLAG_SLAY,	"Remove a condition id from a target.");
	

	//Cvars
	addcond_chat = CreateConVar("sm_addcond_chat", "1", "Determine wheter to show for client only or everyone. \n0 = Off \n1 = Show only for Client \n2 = Show for everyone", _, true, 0.0, true, 2.0);
	CreateConVar("sm_addcond_version", PLUGIN_VERSION, "[TF2] Add/Remove Condition Version");
	
	AutoExecConfig(true, "sm_addcond");
}

bool IsValidClient(int client)	{
	if(!IsClientInGame(client))
		return	false;
	if(client < 1 || client > MaxClients)
		return	false;
	if(IsClientReplay(client))
		return	false;
	if(IsClientSourceTV(client))
		return	false;
	return	true;
}

Action condition_add(int client, int args)	{
	if(!IsValidClient(client))	{
		ReplyToCommand(client, "[SM] This may only be used ingame");
		return Plugin_Handled;
	}

	if(args < 2 || args > 3)	{
		PrintToChat(client, "[SM] Usage: sm_addcond <target> <condition id> (optionally <time/seconds>)");
		return Plugin_Handled;
	}
	
	char	arg1[64], arg2[64], arg3[64], target_name[MAX_TARGET_LENGTH], description[256];
	int		target_list[MAXPLAYERS], target_count;
	bool	tn_is_ml;
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	
	int value	= StringToInt(arg2);
	float time	= StringToFloat(arg3);
	
	TF2_GetConditionString(value, description, sizeof(description));
	
	if((target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_CONNECTED,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	if(value < 0)	{
		PrintToChat(client, "[SM] The addcond number must be 0 or greater");
		return Plugin_Handled;
	}
	if(value > 128)	{
		PrintToChat(client, "[SM] The condition %d you specified seems to not exist, giving no effect", value, target_name);
		return Plugin_Handled;
	}
	if(time < 1)	{
		PrintToChat(client, "[SM] The time must be greater than 0 seconds");
		return Plugin_Handled;
	}
	if(time > 5000)	{
		PrintToChat(client, "[SM] You may apply without time specification for infinite time");
		return Plugin_Handled;
	}
	
	if(StrEqual(arg3, ""))	{
		for(int i = 1; i < target_count; i++)	{
			TF2_AddCondition(target_list[i], view_as<TFCond>(value), TFCondDuration_Infinite, 0);
		}
		
		switch(addcond_chat)	{
			case	1:	PrintToChat(client, "[SM] Gave condition %d (%s) to %s.", value, description, target_name);
			case	2:	PrintToChatAll("[SM] %N has given the condition %d (%s) to %s.", client, value, description, target_name);
		}
		
		PrintToServer("Log: %N Added condition %d (%s) to %s.", client, value, description, target_name);
	}
	else if(!StrEqual(arg3, ""))	{
		for(int i = 1; i < target_count; i++)	{
			TF2_AddCondition(target_list[i], view_as<TFCond>(value), time, 0);
		}
		
		switch(addcond_chat)	{
			case	1:	PrintToChat(client, "[SM] Gave the condition %d (%s) to %s for %d seconds.", value, description, target_name, time);
			case	2:	PrintToChatAll("[SM] %N has given the condition %d (%s) to %s for %d seconds", client, value, description, target_name, time);
		}
		
		PrintToServer("Log: %N Added condition %d (%s) to %s for %d seconds.", client, value, description, target_name, time);
	}
	
	
	return Plugin_Handled;
}

Action condition_remove(int client, int args)	{
	if(!IsValidClient(client))	{
		ReplyToCommand(client, "[SM] This may only be used ingame");
		return Plugin_Handled;
	}

	if(args < 2)	{
		PrintToChat(client, "[SM] Usage: sm_removecond <target> <condition id>");
		return Plugin_Handled;
	}
	
	char	arg1[64], arg2[64], target_name[64], description[256];
	int		target_list[MAXPLAYERS], target_count;
	bool	tn_is_ml;
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int value = StringToInt(arg2);
	
	TF2_GetConditionString(value, description, sizeof(description));
	
	if((target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_CONNECTED,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	
	if(value < 0)	{
		ReplyToCommand(client, "[SM] The condition number must be 0 or greater");
		return Plugin_Handled;
	}
	if(value > 128)	{
		PrintToChat(client, "[SM] The condition %d you specified seems to not exist, giving no effect", value, target_name);
		return Plugin_Handled;
	}
	
	for(int i = 1; i < target_count; i++)	{
		if(!TF2_IsPlayerInCondition(target_list[i], view_as<TFCond>(value)))	{
			PrintToChat(client, "[SM] The target %s does not have the condition you specified");
			return Plugin_Handled;
		}
		
		TF2_RemoveCondition(target_list[i], view_as<TFCond>(value));		
	}
	
	switch(addcond_chat)	{
		case	1:	PrintToChat(client, "[SM] %N Removed the condition %d (%s) from %s", value, value, description, target_name);
		case	2:	PrintToChatAll("[SM] %N has removed the condition %d (%s) from %s", client, value, description, target_name);
	}
	
	PrintToServer("Log: %N Removed condition %d (%s) from %s", client, value, description, target_name);
	return Plugin_Handled;
}