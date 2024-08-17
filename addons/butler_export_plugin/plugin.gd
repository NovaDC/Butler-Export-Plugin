@tool
@icon("res://addons/butler_export_plugin/icon.svg")
extends EditorPlugin

func _get_plugin_icon():
	return preload("res://addons/butler_export_plugin/icon.svg")

func _get_plugin_name():
	return ButlerExportPlugin.PLUGIN_NAME

func _enter_tree():
	init_plugin()

func _exit_tree():
	deinit_plugin()

func _enable_plugin():
	init_plugin()

func _disable_plugin():
	deinit_plugin() 


var _current_inst:ButlerExportPlugin = null

## This method is safe to be called multiple times, and even when the plugin is not enabled, as it checks this internally
## This method is mostly for convience, making it easy to ensure the plugin is initlised whevere its reasoably possible
## This is not expected to be usefull outside of its own script, as this behaviour is already registered to be handeled on load / enable
func init_plugin():
	#We only need to register the plugin once, and only when its enabled
	if _current_inst == null and EditorInterface.is_plugin_enabled(ButlerExportPlugin.PLUGIN_NAME):
		_current_inst = ButlerExportPlugin.new()
		_current_inst._init_options()
		add_export_plugin(_current_inst)
	
	if not EditorInterface.is_plugin_enabled(EditorExportCommand.EEC_PLUGIN_NAME):
		push_warning("In order for the %s plugin to work, you must inport and enable EditorExportCommand plugin first." % [ButlerExportPlugin.PLUGIN_NAME])

## This method is safe to be called multiple times, and even when the plugin is not enabled, though it will deregister the export plugin regardless of the plugins enable state. NOTE this behaviour, as it is explicitly divergent from [[init_plugin]] in this specific sense! 
## This method is mostly for convience, making it easy to ensure the plugin is destoryed whevere its reasoably possible
## This is not expected to be usefull outside of its own script, as this behaviour is already registered to be handeled on unload / disable
func deinit_plugin():
	#We only have to worry about removing the export plugin is we added one in the first place...
	if _current_inst != null:
		remove_export_plugin(_current_inst)
		_current_inst = null
