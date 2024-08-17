@tool
@icon("res://addons/butler_export_plugin/icon.svg")
class_name ButlerExportPlugin
extends EditorExportCommand

## An export plugin used to run Itch.io 's [code]butler[/code] utility.
##
## An export plugin used to run Itch.io 's [code]butler[/code] utility,
## allowing for a automatic publishing to itch.io after export right form the Godot engine.
## Requires a local copy of [code]butler[/code] dowloaded to the system,
## as well as a known path to it, in order to operate.
## All options in this plugin are modifiable in the export, project, and editor settings,
## with the [code]export settings[/code] overriding the [ProjectSettings],
## which overide the [EditorSettings], if availible.
## Most option provided by this plugin corlate to their counterpart in the butler cli,
## excluding the [code]publish[/code] and [code]exe path[/code] options.
## The [code]publish[/code] option simply enables or disables publishing at all.
## The [code]exe path[/code] option is the path to the butler exe.
## Otherwise all option corlate to [code]butler[/code].

## This is simply manually mirroring the name set in the plugin.cfg,
## since its not automatically queryable in engine at the time of writing this
const PLUGIN_NAME := "butler_export_plugin"
const __PUBLISH_SETTING_EXPORT_PATH := "butler/publish"
const __EXE_PATH_SETTING_EDITOR_PATH := "export/butler/exe_path"
const __EXE_PATH_SETTING_PROJECT_PATH := "application/export/butler/exe_path"
const __USER_SETTING_EDITOR_PATH := "export/butler/user"
const __USER_SETTING_PROJECT_PATH := "application/export/butler/user"
const __USER_SETTING_EXPORT_PATH := "butler/user"
const __GAME_SETTING_PROJECT_PATH := "application/export/butler/game"
const __GAME_SETTING_EXPORT_PATH := "butler/game"
const __CHANNEL_SETTING_PROJECT_PATH := "application/export/butler/channel"
const __CHANNEL_SETTING_EXPORT_PATH := "butler/channel"
const __VERSION_SETTING_PROJECT_PATH := "application/export/butler/version"
const __VERSION_SETTING_EXPORT_PATH := "butler/version"
const __IGNORE_PATTERNS_SETTING_EDITOR_PATH := "export/butler/ignore_patterns"
const __IGNORE_PATTERNS_SETTING_PROJECT_PATH := "application/export/butler/ignore_patterns"
const __IGNORE_PATTERNS_SETTING_EXPORT_PATH := "butler/ignore_patterns"
const __DEFERENCE_SETTING_EDITOR_PATH := "export/butler/dereference"
const __DEFERENCE_SETTING_PROJECT_PATH := "application/export/butler/dereference"
const __ONLY_IF_CHANGED_SETTING_EDITOR_PATH := "export/butler/only_if_changed"
const __ONLY_IF_CHANGED_SETTING_PROJECT_PATH := "application/export/butler/only_if_changed"
const __ONLY_IF_CHANGED_SETTING_EXPORT_PATH := "butler/only_if_changed"

var __export_options:Array = []

func _get_export_options(platform):
	return __export_options

func _get_name():
	return PLUGIN_NAME

func _supports_platform(platform):
	return true

func _init_options():
	pass #TODO

func _export_end_command(features:PackedStringArray, is_debug:bool, path:String, flags:int):
	push_warning("Please note, web publishing will not automatically set the uploaded files as \
	playbale in browser. Make sure to do this manually!")
	butler_launch(get_exe_path(),
				  ProjectSettings.globalize_path("res://" + path),
				  get_user(),
				  get_game(),
				  get_channel(),
				  get_version(),
				  get_ignore_patterns(),
				  get_dereference(),
				  get_only_if_changed()
				)

## Launches butler in a external command window.
## [param exe_path] must be the system path to the butler executable file.
## [param path] must be the path to the file / folder to upload
## [param user], [param game] and [param channel] all directly corlate to the
## [code]user/game:channel[/code] section of the normal butler command.
## all other params corelate to their counterparts in the butler cli.
## Returns a [Dictionary] like [method EditorExportCommand.launch_external_command].
static func butler_launch(exe_path:String,
						  path:String,
						  user:String,
						  game:String,
						  channel:String,
						  version:String = "",
						  ignore_patterns:Array = [],
						  dereference:bool = false,
						  only_if_changed:bool = false
						 ) -> Dictionary:
	assert (exe_path != "" and exe_path != null)
	assert (path != "" and path != null)
	assert (user != "" and user != null)
	assert (game != "" and game != null)
	assert (channel != "" and channel != null)
	
	var args := ["push"]
	if only_if_changed:
		args.append("--if-changed")
	if dereference:
		args.append("--dereference")
	for pattern in ignore_patterns:
		args.append("--ignore")
		args.append(pattern)
	args.append(path)
	args.append("%s/%s:%s" % [user, game, channel])
	if version and not version.is_empty():
		args.append("--userversion")
		args.append(version)
	return EditorExportCommand.launch_external_command(exe_path, args)

## Retrieves the editor setting [param path] only if its possible,
## otherwise returning the [param default].
static func get_editor_setting_default(path:String, default:Variant) -> Variant:
	var ed = EditorInterface.get_editor_settings()
	if ed.has_setting(path):
		return ed.get_setting(__USER_SETTING_PROJECT_PATH)
	else:
		return default

## Retrieves the export setting [param path] only if its possible,
## otherwise returning the [param default].
func get_option_with_default(path:String, default:Variant) -> Variant:
	if __export_options.any(func (x): return "name" in x.keys() and x["name"] == path):
		return get_option(path)
	else:
		return default

## Used to initialise the settings used for this plugin.
## Not nessicary to call manually, as this is used internally.
func init_settings():
	__init_channel_settings()
	__init_dereference_settings()
	__init_exe_path_settings()
	__init_game_settings()
	__init_ignore_patterns_settings()
	__init_only_if_changed_settings()
	__init_publish_settings()
	__init_user_settings()
	__init_version_settings()

## Gets the [code]publish[/code] setting from the export options.
## Publishing will only be possible if enabled in the export options.
func get_publish() -> bool:
	return get_option_with_default(__PUBLISH_SETTING_EXPORT_PATH, false)

## Gets the [code]exe_path[/code] setting by searching the [EditorSettings] and [ProjectSettings].
## If set, [ProjectSettings] takes precedent over [EditorSettings].
func get_exe_path() -> String:
	return "echo butler" #TODO change back after testing
	var pj = ProjectSettings.get_setting(__EXE_PATH_SETTING_PROJECT_PATH, "").strip_edges()
	var ed = get_editor_setting_default(__EXE_PATH_SETTING_EDITOR_PATH, "").strip_edges()
	
	if pj != null and pj != "":
		return pj
	return ed if ed != null else ""

## Gets the [code]user[/code] setting by searching the [EditorSettings], [ProjectSettings]
## and export options.
## When set, the export options takes precedent over [ProjectSettings],
## which takes precedent over [EditorSettings].
func get_user() -> String:
	var pj = ProjectSettings.get_setting(__USER_SETTING_EDITOR_PATH, "").strip_edges()
	var ed = get_editor_setting_default(__USER_SETTING_PROJECT_PATH, "").strip_edges()
	var ex = get_option_with_default(__USER_SETTING_EXPORT_PATH, "").strip_edges()
	
	if ex != null and ex != "":
		return ex
	elif pj != null and pj != "":
		return pj
	return ed if ed != null else ""

## Gets the [code]game[/code] setting by searching the [ProjectSettings] and export options.
## When set, the export options takes precedent over [ProjectSettings].
func get_game() -> String:
	var pj = ProjectSettings.get_setting(__GAME_SETTING_PROJECT_PATH, "").strip_edges()
	var ex = get_option_with_default(__GAME_SETTING_EXPORT_PATH, "").strip_edges()
	
	if ex != null and ex != "":
		return ex
	return pj if pj != null else ""

## Gets the [code]channel[/code] setting by searching the [ProjectSettings] and export options.
## When set, the export options takes precedent over [ProjectSettings].
func get_channel() -> String:
	var pj = ProjectSettings.get_setting(__CHANNEL_SETTING_PROJECT_PATH, "").strip_edges()
	var ex = get_option_with_default(__CHANNEL_SETTING_EXPORT_PATH, "").strip_edges()
	
	if ex != null and ex != "":
		return ex
	return pj if pj != null else ""

## Gets the [code]channel[/code] setting by searching the [ProjectSettings],
## export options and project metadata.
## When set, the export options takes precedent over [ProjectSettings],
## which takes precedent over the [code]version[/code] set in the project metadata.
func get_version() -> String:
	var pj = ProjectSettings.get_setting(__VERSION_SETTING_PROJECT_PATH, "").strip_edges()
	var ex = get_option_with_default(__VERSION_SETTING_EXPORT_PATH, "").strip_edges()
	var meta = ProjectSettings.get_setting("application/config/version", "").strip_edges()
	
	if ex != null and ex != "":
		return ex
	elif pj != null and pj != "":
		return pj
	return meta

## Gets the [code]ignore patterns[/code] setting by searching the [EditorSettings],
## [ProjectSettings] and export options.
## When set, the export options takes precedent over [ProjectSettings],
## which takes precedent over [EditorSettings].
## Formated as a list of wildcard patterns, each pattern is ignored when uploading.
func get_ignore_patterns() -> Array:
	var pj = ProjectSettings.get_setting(__IGNORE_PATTERNS_SETTING_EDITOR_PATH, [])
	var ed = get_editor_setting_default(__IGNORE_PATTERNS_SETTING_PROJECT_PATH, [])
	var ex = get_option_with_default(__IGNORE_PATTERNS_SETTING_EXPORT_PATH, [])
	
	var found = []
	if ex != null and ex.size() > 0:
		found = ex
	elif pj != null and pj.size() > 0:
		found = pj
	elif ed != null and ed.size() > 0:
		found = ed
	
	var ret = []
	for pattern in found.map(func (x): return str(x).strip_edges()):
		if pattern != "" and pattern != null and not pattern in ret:
			ret.append(pattern)
	
	return ret

## Gets the [code]deference[/code] setting by searching the [EditorSettings] and [ProjectSettings].
## When set, the [ProjectSettings] takes precedent over [EditorSettings].
## When set, symlinks will be followed by butler instead of being sent as is.
func get_dereference() -> bool:
	var pj = ProjectSettings.get_setting(__DEFERENCE_SETTING_EDITOR_PATH, false)
	var ed = get_editor_setting_default(__DEFERENCE_SETTING_PROJECT_PATH, false)
	
	return ed || pj

## Gets the [code]only if changed[/code] setting by searching the
## [EditorSettings] and [ProjectSettings] and export options.
## When set, the export options takes precedent over [ProjectSettings],
## which takes precedent over [EditorSettings].
## When set, butler will only publish if the exported files have changed at all.
func get_only_if_changed() -> bool:
	var pj = ProjectSettings.get_setting(__ONLY_IF_CHANGED_SETTING_EDITOR_PATH, false)
	var ed = get_editor_setting_default(__ONLY_IF_CHANGED_SETTING_PROJECT_PATH, false)
	var ex = get_option_with_default(__ONLY_IF_CHANGED_SETTING_EXPORT_PATH, false)
	
	return ed || pj || ex

func __init_publish_settings():
	const default = false
	const exp_option = {
		"option": {
			"name" : __PUBLISH_SETTING_EXPORT_PATH,
			"type" : TYPE_BOOL,
		},
		"default_value": default
	}
	if exp_option not in __export_options:
		__export_options.append(exp_option)

func __init_exe_path_settings():
	const default = ""
	var edit_settings = EditorInterface.get_editor_settings()
	if not edit_settings.has_setting(__EXE_PATH_SETTING_EDITOR_PATH):
		edit_settings.set_setting(__EXE_PATH_SETTING_EDITOR_PATH, default)
		edit_settings.add_property_info({
			"name" : __EXE_PATH_SETTING_EDITOR_PATH,
			"type" : TYPE_STRING,
		})
	if not ProjectSettings.has_setting(__EXE_PATH_SETTING_PROJECT_PATH):
		ProjectSettings.set_setting(__EXE_PATH_SETTING_PROJECT_PATH, default)
		ProjectSettings.set_as_basic(__EXE_PATH_SETTING_PROJECT_PATH, true)
		ProjectSettings.add_property_info({
			"name" : __EXE_PATH_SETTING_PROJECT_PATH,
			"type" : TYPE_STRING,
		})

func __init_user_settings():
	const default = ""
	var edit_settings = EditorInterface.get_editor_settings()
	if not edit_settings.has_setting(__USER_SETTING_EDITOR_PATH):
		edit_settings.set_setting(__USER_SETTING_EDITOR_PATH, default)
		edit_settings.add_property_info({
			"name" : __USER_SETTING_EDITOR_PATH,
			"type" : TYPE_STRING,
		})
	if not ProjectSettings.has_setting(__USER_SETTING_PROJECT_PATH):
		ProjectSettings.set_setting(__USER_SETTING_PROJECT_PATH, default)
		ProjectSettings.set_as_basic(__USER_SETTING_PROJECT_PATH, true)
		ProjectSettings.add_property_info({
			"name" : __USER_SETTING_PROJECT_PATH,
			"type" : TYPE_STRING,
		})
	const exp_option = {
		"option": {
			"name" : __USER_SETTING_EXPORT_PATH,
			"type" : TYPE_STRING,
		},
		"default_value": default
	}
	if exp_option not in __export_options:
		__export_options.append(exp_option)

func __init_game_settings():
	const default = ""
	if not ProjectSettings.has_setting(__GAME_SETTING_PROJECT_PATH):
		ProjectSettings.set_setting(__GAME_SETTING_PROJECT_PATH, default)
		ProjectSettings.set_as_basic(__GAME_SETTING_PROJECT_PATH, true)
		ProjectSettings.add_property_info({
			"name" : __GAME_SETTING_PROJECT_PATH,
			"type" : TYPE_STRING,
		})
	const exp_option = {
		"option": {
			"name" : __GAME_SETTING_EXPORT_PATH,
			"type" : TYPE_STRING,
		},
		"default_value": default
	}
	if exp_option not in __export_options:
		__export_options.append(exp_option)

func __init_channel_settings():
	const default = ""
	if not ProjectSettings.has_setting(__CHANNEL_SETTING_PROJECT_PATH):
		ProjectSettings.set_setting(__CHANNEL_SETTING_PROJECT_PATH, default)
		ProjectSettings.set_as_basic(__CHANNEL_SETTING_PROJECT_PATH, true)
		ProjectSettings.add_property_info({
			"name" : __CHANNEL_SETTING_PROJECT_PATH,
			"type" : TYPE_STRING,
		})
	const exp_option = {
		"option": {
			"name" : __CHANNEL_SETTING_EXPORT_PATH,
			"type" : TYPE_STRING,
		},
		"default_value": default
	}
	if exp_option not in __export_options:
		__export_options.append(exp_option)

func __init_version_settings():
	const default = ""
	if not ProjectSettings.has_setting(__VERSION_SETTING_PROJECT_PATH):
		ProjectSettings.set_setting(__VERSION_SETTING_PROJECT_PATH, default)
		ProjectSettings.set_as_basic(__VERSION_SETTING_PROJECT_PATH, true)
		ProjectSettings.add_property_info({
			"name" : __VERSION_SETTING_PROJECT_PATH,
			"type" : TYPE_STRING,
		})
	const exp_option = {
		"option": {
			"name" : __VERSION_SETTING_EXPORT_PATH,
			"type" : TYPE_STRING,
		},
		"default_value": default
	}
	if exp_option not in __export_options:
		__export_options.append(exp_option)

func __init_ignore_patterns_settings():
	const default = []
	var edit_settings = EditorInterface.get_editor_settings()
	if not edit_settings.has_setting(__IGNORE_PATTERNS_SETTING_EDITOR_PATH):
		edit_settings.set_setting(__IGNORE_PATTERNS_SETTING_EDITOR_PATH, default)
		edit_settings.add_property_info({
			"name" : __IGNORE_PATTERNS_SETTING_EDITOR_PATH,
			"type" : TYPE_ARRAY,
			"hint" : PROPERTY_HINT_ARRAY_TYPE,
			"hint_string" : "%d:" % [TYPE_STRING]
	})
	if not ProjectSettings.has_setting(__IGNORE_PATTERNS_SETTING_PROJECT_PATH):
		ProjectSettings.set_setting(__IGNORE_PATTERNS_SETTING_PROJECT_PATH, default)
		ProjectSettings.set_as_basic(__IGNORE_PATTERNS_SETTING_PROJECT_PATH, true)
		ProjectSettings.add_property_info({
			"name" : __IGNORE_PATTERNS_SETTING_PROJECT_PATH,
			"type" : TYPE_ARRAY,
			"hint" : PROPERTY_HINT_ARRAY_TYPE,
			"hint_string" : "%d:" % [TYPE_STRING]
		})
	var exp_option = {
		"option": {
			"name" : __IGNORE_PATTERNS_SETTING_EXPORT_PATH,
			"type" : TYPE_ARRAY,
			"hint" : PROPERTY_HINT_ARRAY_TYPE,
			"hint_string" : "%d:" % [TYPE_STRING]
		},
		"default_value": default
	}
	if exp_option not in __export_options:
		__export_options.append(exp_option)

func __init_dereference_settings():
	const default = false
	var edit_settings = EditorInterface.get_editor_settings()
	if not edit_settings.has_setting(__DEFERENCE_SETTING_EDITOR_PATH):
		edit_settings.set_setting(__DEFERENCE_SETTING_EDITOR_PATH, default)
		edit_settings.add_property_info({
			"name" : __DEFERENCE_SETTING_EDITOR_PATH,
			"type" : TYPE_BOOL,
		})
	if not ProjectSettings.has_setting(__DEFERENCE_SETTING_PROJECT_PATH):
		ProjectSettings.set_setting(__DEFERENCE_SETTING_PROJECT_PATH, default)
		ProjectSettings.set_as_basic(__DEFERENCE_SETTING_PROJECT_PATH, true)
		ProjectSettings.add_property_info({
			"name" : __DEFERENCE_SETTING_PROJECT_PATH,
			"type" : TYPE_BOOL,
		})

func __init_only_if_changed_settings():
	const default = false
	var edit_settings = EditorInterface.get_editor_settings()
	if not edit_settings.has_setting(__ONLY_IF_CHANGED_SETTING_EDITOR_PATH):
		edit_settings.set_setting(__ONLY_IF_CHANGED_SETTING_EDITOR_PATH, default)
		edit_settings.add_property_info({
			"name" : __ONLY_IF_CHANGED_SETTING_EDITOR_PATH,
			"type" : TYPE_BOOL,
		})
	if not ProjectSettings.has_setting(__ONLY_IF_CHANGED_SETTING_PROJECT_PATH):
		ProjectSettings.set_setting(__ONLY_IF_CHANGED_SETTING_PROJECT_PATH, default)
		ProjectSettings.set_as_basic(__ONLY_IF_CHANGED_SETTING_PROJECT_PATH, true)
		ProjectSettings.add_property_info({
			"name" : __ONLY_IF_CHANGED_SETTING_PROJECT_PATH,
			"type" : TYPE_BOOL,
		})
	const exp_option = {
		"option": {
			"name" : __ONLY_IF_CHANGED_SETTING_EXPORT_PATH,
			"type" : TYPE_BOOL,
		},
		"default_value": default
	}
	if exp_option not in __export_options:
		__export_options.append(exp_option)
