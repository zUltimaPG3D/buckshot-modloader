class Global extends Node:
	static var instance : Global
	var menu_manager : MenuManager

	var last_button:ButtonClass
	var f_mod_button:ButtonClass
	var return_button:ButtonClass

	var fake_receipt:Font = preload("res://fonts/fake receipt.otf")

	class ModNode extends Node:
		var tied_mod:Mod
		func set_mod(m:Mod):
			self.tied_mod = m
		func get_mod(id:String = "") -> Mod:
			return tied_mod if id == "" else Global.instance.loaded_mods[id]
		func get_mod_node(id:String = "") -> ModNode:
			return self if id == "" else get_mod(id).tied_node

		func _process(delta):
			pass
		func _physics_process(delta):
			pass

	class Mod:
		var id:String
		var name:String
		var author:String
		var version:String
		var description:String
		var path:String
		var dependencies:Array
		var tied_node:ModNode
		func _init(path:String, data:Dictionary):
			self.path = path
			self.id = data.get("id", "")
			self.name = data.get("name", "UNNAMED MOD")
			self.author = data.get("author", "NO AUTHOR SPECIFIED")
			self.version = data.get("version", "v1.0")
			self.description = data.get("desc", "")
			self.dependencies = data.get("dependencies", [])
		func init_mod():
			var node = ModNode.new()
			Global.instance.add_child(node)
			node.name = self.name
			node.set_script(ResourceLoader.load(path + "/main.gd"))

			self.tied_node = node
			node.set_mod(self)

			#TO PLAY IT SAFE.
			await Global.instance.get_tree().process_frame

			if node.has_method("_enter_tree"):
				node._enter_tree()
			if node.has_method("_ready"):
				node._ready()

	var menu_ui:Control
	var mods_vbox:VBoxContainer

	var screen_mods : Array[Control]
	func ActivateModButton(c:ButtonClass):
		#DO THIS BECAUSE OF INTRO() CALL.
		await get_tree().create_timer(9.5, false).timeout
		c.isActive = true

	var loaded_mods:Dictionary

	func CreateModUI():
		var buttons_offset:int = 26
		menu_ui = menu_manager.buttons[0].ui.get_parent() as Control
		last_button = menu_manager.buttons[2]
		return_button = menu_manager.buttons[3]

		#MOVE EXIT BUTTON DOWN
		var exit_button:Label = last_button.ui
		var true_exit_button:Button = last_button.get_parent()
		exit_button.position.y += buttons_offset
		true_exit_button.position.y += buttons_offset

		#CREATE MODS BUTTON
		var mods_button:Label = exit_button.duplicate()
		var true_mods_button:Button = true_exit_button.duplicate()
		var mods_buttonclass:ButtonClass = true_mods_button.get_child(0) as ButtonClass

		mods_button.name = "button_mods"
		true_mods_button.name = "true button_mods"
		mods_buttonclass.name = "button class_mods"

		mods_button.text = "MODS"
		ActivateModButton(mods_buttonclass)
		f_mod_button = mods_buttonclass
		mods_buttonclass.alias = "mods"
		mods_buttonclass.ui = mods_button

		menu_ui.add_child(mods_button)
		menu_ui.add_child(true_mods_button)

		menu_manager.buttons.append(mods_buttonclass)
		menu_manager.screen_main.append_array([mods_button, true_mods_button])

		mods_button.position.y -= buttons_offset
		true_mods_button.position.y -= buttons_offset

		#CREATE MODS SCREEN
		var temp_ui:Control = Control.new()
		temp_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
		temp_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
		get_tree().root.add_child(temp_ui)

		menu_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
		menu_ui.size = temp_ui.size
		screen_mods.append_array([menu_manager.buttons[3].ui])
		mods_buttonclass.connect("is_pressed", OpenMods)

		var mod_ui:Control = Control.new()
		mod_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mod_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
		var mod_center:CenterContainer = CenterContainer.new()
		mod_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mod_center.set_anchors_preset(Control.PRESET_FULL_RECT)
		var panel_container:PanelContainer = PanelContainer.new()
		panel_container.custom_minimum_size = Vector2(724, 423)

		var scroll:ScrollContainer = ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(724, 423)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var vbox:VBoxContainer = VBoxContainer.new()
		vbox.custom_minimum_size = Vector2(724, 423)

		menu_ui.add_child(mod_ui)
		mod_ui.add_child(mod_center)
		mod_center.add_child(panel_container)
		panel_container.add_child(scroll)
		scroll.add_child(vbox)

		screen_mods.append(mod_ui)

		mods_vbox = vbox
		UpdateModList()

		for mod in loaded_mods:
			loaded_mods[mod].init_mod()

		mod_ui.visible = false

		return_button.connect("is_pressed", ReturnMod)
		menu_manager.buttons[5].connect("is_pressed", ReturnMod) #OPTIONS RETURN BUTTON
		menu_manager.buttons[1].connect("is_pressed", CreditsFix) #CREDITS BUTTON


	func HasModByID(id:String) -> bool:
		var dir = DirAccess.open("user://mods/")
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					if not FileAccess.file_exists("user://mods/" + file_name + "/info.json"):
						pass
					elif not FileAccess.file_exists("user://mods/" + file_name + "/main.gd"):
						pass
					else:
						var info:FileAccess = FileAccess.open("user://mods/" + file_name + "/info.json", FileAccess.READ)
						var d:Dictionary = JSON.parse_string(info.get_as_text()) as Dictionary
						if not d.has("id"):
							pass
						else:
							if d["id"] == id:
								return true
				file_name = dir.get_next()
		else:
			printerr("Could not access user://mods/.")
			return false
		return false

	func GetCurrentMods() -> Array[Mod]:
		var mods:Array[Mod]
		var dir = DirAccess.open("user://mods/")
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					if not FileAccess.file_exists("user://mods/" + file_name + "/info.json"):
						printerr("The mod " + file_name + " is invalid. Reason: info.json does not exist.")
					elif not FileAccess.file_exists("user://mods/" + file_name + "/main.gd"):
						printerr("The mod " + file_name + " is invalid. Reason: main.gd does not exist.")
					else:
						var info:FileAccess = FileAccess.open("user://mods/" + file_name + "/info.json", FileAccess.READ)
						var d:Dictionary = JSON.parse_string(info.get_as_text()) as Dictionary
						var can_finish:bool = true
						if not d.has("id"):
							printerr("The mod " + file_name + " is invalid. Reason: id field in info.json does not exist.")
							can_finish = false
						if can_finish:
							if d.has("dependencies"):
								for dep in d["dependencies"]:
									if dep == d["id"]:
										printerr("The mod " + file_name + " is invalid. Reason: The mod has itself as a dependency.")
										can_finish = false
									if not HasModByID(dep):
										printerr("The mod " + file_name + " is invalid. Reason: You do not have the required dependency: " + dep)
										can_finish = false
						if can_finish: mods.append(Mod.new("user://mods/" + file_name, d))
				file_name = dir.get_next()
		else:
			printerr("Could not access user://mods/.")
			return []
		return mods

	func UpdateModList():
		var user:DirAccess = DirAccess.open("user://")
		if not user.dir_exists("mods"):
			user.make_dir("mods")
		var mods:Array[Mod] = GetCurrentMods()
		for mod in mods:
			var mod_holder:VBoxContainer = VBoxContainer.new()
			var lab1:Label = Label.new()
			lab1.name = "NameLabel"
			lab1.text = "\"{name}\" by {author} - {version}".format({"name": mod.name, "author": mod.author, "version": mod.version})
			lab1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			mod_holder.add_child(lab1)

			var lab2:Label = Label.new()
			lab2.name = "DescriptionLabel"
			lab2.text = mod.description
			lab2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			mod_holder.add_child(lab2)

			lab1.add_theme_font_override("font", preload("res://fonts/fake receipt.otf"))
			lab2.add_theme_font_override("font", preload("res://fonts/fake receipt.otf"))
			lab1.add_theme_font_size_override("font_size", 24)
			lab2.add_theme_font_size_override("font_size", 24)

			loaded_mods[mod.id] = mod

			var separator:HSeparator = HSeparator.new()
			separator.name = "Separator"
			mod_holder.add_child(separator)

			mod_holder.name = mod.name
			mods_vbox.add_child(mod_holder)

	func CreditsFix():
		return_button.isActive = true
		return_button.SetFilter("stop")

	func ShowMods():
		menu_manager.title.visible = false
		for i in menu_manager.screen_main: i.visible = false
		for i in menu_manager.screen_creds: i.visible = false
		for i in menu_manager.screen_options: i.visible = false
		for i in screen_mods: i.visible = false
		for i in screen_mods: i.visible = true

	func ReturnMod():
		for i in screen_mods: i.visible = false
		f_mod_button.isActive = true
		f_mod_button.SetFilter("stop")

	func OpenMods():
		menu_manager.ResetButtons()
		ShowMods()
		menu_manager.Buttons(false)
		return_button.isActive = true
		return_button.SetFilter("stop")
		menu_manager.ResetButtons()

func CreateModAutoload():
	if not is_instance_valid(Global.instance):
		var persistent = Global.new()
		persistent.name = "Modloader"
		persistent.menu_manager = self
		get_tree().root.add_child.call_deferred(persistent)
		persistent.CreateModUI.call_deferred()
		Global.instance = persistent
	else:
		Global.instance.CreateModUI()

func _ready():
	CreateModAutoload()
