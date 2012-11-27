#if defined _plugincvars_included
 #endinput
#endif
#define _plugincvars_included

/**
 * Retrieves the description of a console variable.
 *
 * @param convar            Handle to the convar.
 * @param description       Buffer to store the description of the convar.
 * @param maxlength         Maximum length of string buffer.
 * @noreturn
 * @error                   Invalid or corrupt Handle.
 */
native GetConVarDescription(Handle:convar, String:description[], maxlength);


/**
 * Returns a handle to the list of convars for a plugin
 *
 * @param hPlugin           Handle to the plugin.
 * @return                  Handle to the convar list or invalid handle
 *                          if it does not exist.
 * @error                   Invalid plugin.
 */
native Handle:GetConVarList(Handle:hPlugin);


/**
 * Returns the size of a convar list
 *
 * @param hList             Handle to the convar list.
 * @return                  Size of the convar list or -1 on error.
 * @error                   Invalid convar list.
 */
native GetConVarListSize(Handle:hList);


/**
 * Returns an iterator that can used to search through a convar list
 *
 * @param hList             Handle to the convar list.
 * @return                  Handle to iterate with. Must be closed via
 *                          CloseHandle():
 * @error                   Invalid convar list.
 */
native Handle:GetConVarListIterator(Handle:hList);


/**
 * Returns whether there are more convars available in the iterator.
 *
 * @param hIterator         Handle to the convar iterator.
 * @return                  True on more convars, false otherwise.
 * @error                   Invalid convar iterator.
 */
native bool:MoreConvars(Handle:hIterator);


/**
 * Returns the current convar in the iterator and advances the iterator.
 *
 * @param hIterator         Handle to the convar iterator.
 * @return                  Current convar the iterator is at, before
 *                          the iterator is advanced.
 * @error                   Invalid convar iterator.
 */
native Handle:ReadConvar(Handle:hIterator);




/** Do Not Edit Below This Line **/

public Extension:__ext_plugincvars =
{
	name = "plugincvars",
	file = "plugincvars.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_EXTENSIONS
public __ext_plugincvars_SetNTVOptional()
{
	MarkNativeAsOptional("GetConVarDescription");
	MarkNativeAsOptional("GetConVarList");
	MarkNativeAsOptional("GetConVarListSize");
	MarkNativeAsOptional("GetConVarListElement");
}
#endif
