/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Sample Extension
 * Copyright (C) 2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include "extension.h"
#include <sh_list.h>
/**
 * @file extension.cpp
 * @brief Implement extension code here.
 */
typedef SourceHook::List<ConVar *> ConVarList;
PluginCvar g_PluginCvar;		/**< Global singleton for extension's main interface */

ConVarListHandler g_ConVarListHandler;
ConVarIteratorHandler g_ConVarIteratorHandler;

HandleType_t htConVar;
HandleType_t htConvarList;
HandleType_t htConvarIterator;


static cell_t GetConVarDescription(IPluginContext *pContext, const cell_t *params) {
	Handle_t hndl = static_cast<Handle_t>(params[1]);
	HandleError err;

	ConVarInfo *pConVar;

	if ((err=g_pHandleSys->ReadHandle(hndl, htConVar, NULL, (void **)&pConVar)) != HandleError_None) {
		return pContext->ThrowNativeError("Invalid ConVar handle %x (error %d)", hndl, err);
	}

	pContext->StringToLocal(params[2], params[3], pConVar->pVar->GetHelpText());

	return 1;
}

static cell_t GetConVarList(IPluginContext *pContext, const cell_t *params) {
	HandleError err;
	IPlugin *pl = plsys->PluginFromHandle(params[1], &err);
	// Todo: check for errors in retrieving the plugin from handle

	ConVarList *pConVarList;

	if(pl->GetProperty("ConVarList", (void **)&pConVarList)) {
		Handle_t hndl = g_pHandleSys->CreateHandle(htConvarList, pConVarList, pContext->GetIdentity(), myself->GetIdentity(), NULL);

		if(hndl == BAD_HANDLE) {
			pContext->ThrowNativeError("Could not create Handle for ConVarList of plugin %s", pl->GetFilename());
		}

		return hndl;
	}

	return BAD_HANDLE;
}

static cell_t GetConVarListSize(IPluginContext *pContext, const cell_t *params)
{
	Handle_t hndl = (Handle_t)params[1];
	HandleError err;
	ConVarList *pConVarList;

	HandleSecurity sec;
	sec.pIdentity = pContext->GetIdentity();
	sec.pOwner = NULL;

	if ((err=g_pHandleSys->ReadHandle(hndl, htConvarList, &sec, (void **)&pConVarList)) != HandleError_None)
	{
		pContext->ThrowNativeError("Could not read Handle %x (error %d)", hndl, err);
		return -1;
	}

	return pConVarList->size();
}

static cell_t GetConVarListIterator(IPluginContext *pContext, const cell_t *params)
{
	Handle_t hndl = (Handle_t)params[1];
	HandleError err;
	ConVarList *pConVarList;

	HandleSecurity sec;
	sec.pIdentity = pContext->GetIdentity();
	sec.pOwner = NULL;

	if ((err=g_pHandleSys->ReadHandle(hndl, htConvarList, &sec, (void **)&pConVarList)) != HandleError_None)
	{
		pContext->ThrowNativeError("Could not read Handle %x (error %d)", hndl, err);
		return -1;
	}

	if(pConVarList->size() > 0) {
		CConVarIterator *iter = new CConVarIterator(pConVarList);
		Handle_t hndl = g_pHandleSys->CreateHandle(htConvarIterator, iter, pContext->GetIdentity(), myself->GetIdentity(), NULL);

		if(hndl == BAD_HANDLE) {
			pContext->ThrowNativeError("Could not create Handle for ConVarList iterator");
		}

		return hndl;
	}

	return BAD_HANDLE;
}

static cell_t MoreConvars(IPluginContext *pContext, const cell_t *params)
{
	Handle_t hndl = (Handle_t)params[1];
	HandleError err;

	HandleSecurity sec;
	sec.pIdentity = pContext->GetIdentity();
	sec.pOwner = NULL;

	CConVarIterator *iter;

	if ((err=g_pHandleSys->ReadHandle(hndl, htConvarIterator, &sec, (void **)&iter)) != HandleError_None)
	{
		pContext->ThrowNativeError("Could not read Handle %x (error %d)", hndl, err);
		return -1;
	}

	return iter->MoreConVars();
}

static cell_t ReadConvar(IPluginContext *pContext, const cell_t *params)
{
	Handle_t hndl = (Handle_t)params[1];
	HandleError err;

	HandleSecurity sec;
	sec.pIdentity = pContext->GetIdentity();
	sec.pOwner = NULL;

	CConVarIterator *iter;

	if ((err=g_pHandleSys->ReadHandle(hndl, htConvarIterator, &sec, (void **)&iter)) != HandleError_None)
	{
		pContext->ThrowNativeError("Could not read Handle %x (error %d)", hndl, err);
		return -1;
	}

	ConVar *pConVar = iter->GetConVar();
	cell_t result;

	INativeInvoker *inv = ninvoke->CreateInvoker();
	inv->Start(pContext, "FindConVar");
	inv->PushString(pConVar->GetName());
	inv->Invoke(&result);
	delete(inv);

	iter->NextConVar();
	return result;
}


bool PluginCvar::SDK_OnLoad(char *error, size_t err_max, bool late)
{
	sharesys->AddNatives(myself, cvar_natives);
	sharesys->RegisterLibrary(myself, "plugincvars");

	g_pHandleSys->FindHandleType("ConVar", &htConVar);

	g_pShareSys->RequestInterface("INativeInterface", 0, myself, (SMInterface**)&ninvoke);

	/* Set up access rights for the 'ConVarList' handle type */
	HandleAccess sec;
	sec.access[HandleAccess_Read] = 0;
	sec.access[HandleAccess_Delete] = HANDLE_RESTRICT_IDENTITY | HANDLE_RESTRICT_OWNER;
	sec.access[HandleAccess_Clone] = HANDLE_RESTRICT_IDENTITY | HANDLE_RESTRICT_OWNER;

	htConvarList = g_pHandleSys->CreateType("ConVarList", &g_ConVarListHandler, 0, NULL, &sec, myself->GetIdentity(), NULL);
	htConvarIterator = g_pHandleSys->CreateType("ConVarIterator", &g_ConVarListHandler, 0, NULL, &sec, myself->GetIdentity(), NULL);

	return true;
}

void ConVarIteratorHandler::OnHandleDestroy(HandleType_t type, void *object) {
		IPluginIterator *iter = (IPluginIterator *)object;
		iter->Release();
}

void ConVarListHandler::OnHandleDestroy(HandleType_t type, void *object) {}


const sp_nativeinfo_t cvar_natives[] =
{
	{"GetConVarDescription", GetConVarDescription},

	{"GetConVarList", GetConVarList},
	{"GetConVarListSize", GetConVarListSize},

	{"GetConVarListIterator", GetConVarListIterator},
	{"MoreConvars", MoreConvars},
	{"ReadConvar", ReadConvar},

	// TODO: ResetConVarListIterator native

	{NULL,			NULL}
};
SMEXT_LINK(&g_PluginCvar);







CConVarIterator::CConVarIterator(SourceHook::List<ConVar *> *_mylist)
{
	mylist = _mylist;
	Reset();
}

ConVar *CConVarIterator::GetConVar()
{
	return (*current);
}

bool CConVarIterator::MoreConVars()
{
	return (current != mylist->end());
}

void CConVarIterator::NextConVar()
{
	current++;
}

void CConVarIterator::Release()
{
	delete(this);
}

CConVarIterator::~CConVarIterator()
{
}

void CConVarIterator::Reset()
{
	current = mylist->begin();
}