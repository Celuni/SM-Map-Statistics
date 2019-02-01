#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

Database g_Database = null;
float g_fDelay = 0.0;
int g_iPlayerCount = 0;

public Plugin myinfo = 
{
	name = "Match Stats", 
	author = "DN.H | The Doggy", 
	description = "Sends match stats for the current match to a database", 
	version = "1.0.0",
	url = "DistrictNine.Host"
};

public void OnPluginStart()
{
	CreateTimer(1.0, AttemptMySQLConnection);
}

public void OnMapStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);

	CreateTimer(1.0, InsertMapQuery);
}

public Action InsertMapQuery(Handle timer)
{
	if(g_Database == null)
	{
		CreateTimer(1.0, InsertMapQuery);
		return Plugin_Handled;
	}

	char sQuery[1024], sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	int iCount = 0;
	for(int i = 1; i <= MaxClients; i++)
		if(IsValidClient(i)) iCount++;

	Format(sQuery, sizeof(sQuery), "INSERT INTO map_stats_total (map_name, total_players, map_count) VALUES ('%s', %i, 1) ON DUPLICATE KEY UPDATE total_players=total_players+%i, map_count=map_count+1;", sMap, iCount, iCount);
	g_Database.Query(SQL_GenericQuery, sQuery);
	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int Client)
{
	if(!IsValidClient(Client)) return;

	char sQuery[1024], sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	Format(sQuery, sizeof(sQuery), "UPDATE map_stats_total SET total_players=total_players+1 WHERE map_name='%s'", sMap);
	g_Database.Query(SQL_GenericQuery, sQuery);
}

public Action AttemptMySQLConnection(Handle timer)
{
	if (g_Database != null)
	{
		delete g_Database;
		g_Database = null;
	}
	
	char sFolder[32];
	GetGameFolderName(sFolder, sizeof(sFolder));
	if (SQL_CheckConfig("mapstats"))
	{
		PrintToServer("Initalizing Connection to MySQL Database");
		Database.Connect(SQL_InitialConnection, "mapstats");
	}
	else
		LogError("Database Error: No Database Config Found! (%s/addons/sourcemod/configs/databases.cfg)", sFolder);

	return Plugin_Handled;
}

public void SQL_InitialConnection(Database db, const char[] sError, int data)
{
	if (db == null)
	{
		LogMessage("Database Error: %s", sError);
		CreateTimer(10.0, AttemptMySQLConnection);
		return;
	}
	
	char sDriver[16];
	db.Driver.GetIdentifier(sDriver, sizeof(sDriver));
	if (StrEqual(sDriver, "mysql", false)) LogMessage("MySQL Database: connected");
	
	g_Database = db;
	CreateAndVerifySQLTables();
}

public void CreateAndVerifySQLTables()
{
	char sQuery[1024] = "";
	StrCat(sQuery, 1024, "CREATE TABLE IF NOT EXISTS map_stats (");
	StrCat(sQuery, 1024, "match_id INTEGER NOT NULL AUTO_INCREMENT, ");
	StrCat(sQuery, 1024, "timestamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, ");
	StrCat(sQuery, 1024, "players_start INTEGER, ");
	StrCat(sQuery, 1024, "players_end INTEGER, ");
	StrCat(sQuery, 1024, "map VARCHAR(64) NOT NULL, ");
	StrCat(sQuery, 1024, "PRIMARY KEY(match_id));");
	g_Database.Query(SQL_GenericQuery, sQuery);

	sQuery = "";
	StrCat(sQuery, 1024, "CREATE TABLE IF NOT EXISTS map_stats_players (");
	StrCat(sQuery, 1024, "match_id INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "name VARCHAR(64) NOT NULL, ");
	StrCat(sQuery, 1024, "steamid64 VARCHAR(64) NOT NULL, ");
	StrCat(sQuery, 1024, "kills INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "deaths INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "mvps INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "PRIMARY KEY(match_id, steamid64), ");
	StrCat(sQuery, 1024, "FOREIGN KEY(match_id) REFERENCES map_stats(match_id));");
	g_Database.Query(SQL_GenericQuery, sQuery);

	sQuery = "";
	StrCat(sQuery, 1024, "CREATE TABLE IF NOT EXISTS map_stats_total (");
	StrCat(sQuery, 1024, "map_name VARCHAR(64) NOT NULL, ");
	StrCat(sQuery, 1024, "total_players INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "map_count INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "PRIMARY KEY(map_name));");
	g_Database.Query(SQL_GenericQuery, sQuery);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(GetGameTime() - g_fDelay <= 1.0 || GameRules_GetProp("m_bWarmupPeriod") == 1) return; //fix for round_start being called twice consecutively for some reason
	g_fDelay = GetGameTime();

	char sQuery[1024], sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	int iCount = 0;
	for(int i = 1; i <= MaxClients; i++)
		if(IsValidClient(i) && (GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_CT)) iCount++;

	Format(sQuery, sizeof(sQuery), "INSERT INTO map_stats (players_start, map) VALUES (%i, '%s');", iCount, sMap);
	g_Database.Query(SQL_GenericQuery, sQuery);

	UnhookEvent("round_start", Event_RoundStart);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	UpdatePlayerStats();
	int iCount = 0;
	for(int i = 1; i <= MaxClients; i++)
		if(IsValidClient(i) && (GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_CT)) iCount++;
	g_iPlayerCount = iCount;
}

public void UpdatePlayerStats()
{
	char sQuery[1024], sName[64], sSteamID[64];
	int iEnt, iKills, iDeaths, iMVPs;

	iEnt = FindEntityByClassname(-1, "cs_player_manager");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) && IsClientObserver(i)) continue;

		iKills = GetEntProp(iEnt, Prop_Send, "m_iKills", _, i);
		iDeaths = GetEntProp(iEnt, Prop_Send, "m_iDeaths", _, i);
		iMVPs = GetEntProp(iEnt, Prop_Send, "m_iMVPs", _, i);

		GetClientName(i, sName, sizeof(sName));
		g_Database.Escape(sName, sName, sizeof(sName));

		GetClientAuthId(i, AuthId_SteamID64, sSteamID, sizeof(sSteamID));

		int len = 0;
		len += Format(sQuery[len], sizeof(sQuery) - len, "INSERT INTO map_stats_players (match_id, name, steamid64, kills, deaths, mvps) ");
		len += Format(sQuery[len], sizeof(sQuery) - len, "VALUES (LAST_INSERT_ID(), '%s', '%s', %i, %i, %i) ", sName, sSteamID, iKills, iDeaths, iMVPs);
		len += Format(sQuery[len], sizeof(sQuery) - len, "ON DUPLICATE KEY UPDATE name='%s', kills=%i, deaths=%i, mvps=%i;", sName, iKills, iDeaths, iMVPs);
		g_Database.Query(SQL_GenericQuery, sQuery);
	}
}

public void OnMapEnd()
{
	if(g_Database == null) return;

	char sQuery[1024];
	Format(sQuery, sizeof(sQuery), "UPDATE map_stats SET players_end=%i WHERE match_id=LAST_INSERT_ID();", g_iPlayerCount);
	g_Database.Query(SQL_GenericQuery, sQuery);
}

//generic query handler
public void SQL_GenericQuery(Database db, DBResultSet results, const char[] sError, any data)
{
	if(results == null)
	{
		PrintToServer("MySQL Query Failed: %s", sError);
		LogError("MySQL Query Failed: %s", sError);
	}
}

stock bool IsValidClient(int client)
{
	return client >= 1 && 
	client <= MaxClients && 
	IsClientConnected(client) && 
	IsClientAuthorized(client) && 
	IsClientInGame(client) &&
	!IsFakeClient(client);
}