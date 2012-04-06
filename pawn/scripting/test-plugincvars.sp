#pragma semicolon 1
#include <sourcemod>
#include <plugincvars>

#define VERSION 		"0.0.1"

public Plugin:myinfo = {
	name 		= "Test - PluginCvars",
	author 		= "Thrawn",
	description = "",
	version 	= VERSION,
};

public OnPluginStart() {
	new String:sDescCheats[1024];
	GetConVarDescription(FindConVar("sv_cheats"), sDescCheats, sizeof(sDescCheats));
	LogMessage("sv_cheats description is: %s", sDescCheats);


	RegConsoleCmd("sm_dump_plugincvars", ListCvars);
}


public Action:ListCvars(client,args) {
	new Handle:hPlugins = GetPluginIterator();

	while(MorePlugins(hPlugins)) {
		new Handle:hPlugin = ReadPlugin(hPlugins);

		if(hPlugin != INVALID_HANDLE) {
			new String:sPlugin[255];
			if(!GetPluginInfo(hPlugin, PlInfo_Name, sPlugin, sizeof(sPlugin))) {
				GetPluginFilename(hPlugin, sPlugin, sizeof(sPlugin));
			}

			new Handle:hList = GetConVarList(hPlugin);
			if(hList == INVALID_HANDLE)continue;
			if(GetConVarListSize_NoVersions(hList) < 1) {
				CloseHandle(hList);
				continue;
			}

			PrintToServer("----- %s", sPlugin);

			new Handle:hIterator = GetConVarListIterator(hList);
			while(MoreConvars(hIterator)) {
				new Handle:hConVar = ReadConvar(hIterator);
				if(GetConVarFlags(hConVar) & FCVAR_DONTRECORD)continue;

				PrettyLogConvar(hConVar);
			}

			CloseHandle(hIterator);
			CloseHandle(hList);

			PrintToServer("", sPlugin);
		}
	}

	CloseHandle(hPlugins);
}

PrettyLogConvar(Handle:hConVar) {
	new String:sConVarName[64];
	GetConVarName(hConVar, sConVarName, sizeof(sConVarName));

	new String:sConVarDescription[128];
	GetConVarDescription(hConVar, sConVarDescription, sizeof(sConVarDescription));

	PrintToServer(" * %40s (%s)", sConVarName, sConVarDescription);
}

GetConVarListSize_NoVersions(Handle:hList) {
	new iCount = 0;
	new Handle:hIterator = GetConVarListIterator(hList);
	while(MoreConvars(hIterator)) {
		new Handle:hConVar = ReadConvar(hIterator);
		if(GetConVarFlags(hConVar) & FCVAR_DONTRECORD)continue;

		iCount++;
	}

	CloseHandle(hIterator);

	return iCount;
}