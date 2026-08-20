extends RefCounted
class_name SettingsAccess

## Safe read-only access to the SettingsManager autoload.
##
## Godot's `--script` test mode compiles scripts outside the normal main-scene
## lifecycle, so compile-time references to autoload singleton identifiers can
## fail even though the same script is valid during a normal project run.
## Runtime code should use this helper when it only needs setting reads.
## Full application runs resolve `/root/SettingsManager`; isolated tests receive
## the supplied fallback without fabricating an autoload.
static func get_value(key: String, fallback: Variant = null) -> Variant:
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var tree: SceneTree = main_loop as SceneTree
		var root: Window = tree.root
		if root != null:
			var manager: Node = root.get_node_or_null("SettingsManager")
			if manager != null and manager.has_method("get_value"):
				return manager.call("get_value", key, fallback)
	return fallback
