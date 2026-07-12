extends PanelContainer

@onready var list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/List
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton


func _ready() -> void:
	visible = false
	close_button.pressed.connect(func(): visible = false)
	FactionManager.faction_relation_changed.connect(func(_faction_id: String): refresh())
	FactionManager.faction_information_learned.connect(func(_faction_id: String, _information: String): refresh())
	refresh()


func refresh() -> void:
	for child in list.get_children():
		child.queue_free()
	for faction in FactionManager.get_all_factions():
		_add_faction(faction)


func _add_faction(faction: Dictionary) -> void:
	var faction_id := str(faction.get("faction_id", ""))
	var relation := FactionManager.get_relation(faction_id)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)

	var title := Label.new()
	title.text = str(faction.get("name_cn", faction_id))
	title.add_theme_font_size_override("font_size", 21)
	box.add_child(title)

	var relation_label := Label.new()
	relation_label.text = "声望：%d｜信任：%d｜敌意：%d" % [
		int(relation.get("reputation", 0)),
		int(relation.get("trust", 0)),
		int(relation.get("hostility", 0)),
	]
	box.add_child(relation_label)

	_add_wrapped(box, str(faction.get("description", "")))
	_add_wrapped(box, "优势：%s" % str(faction.get("benefit_note", "")))
	_add_wrapped(box, "风险：%s" % str(faction.get("risk_note", "")))

	var information: Array = FactionManager.get_known_information(faction_id)
	if not information.is_empty():
		_add_wrapped(box, "已知情报：%s" % "；".join(information))

	var job_names: Array[String] = []
	for job in FactionManager.get_faction_jobs(faction_id):
		job_names.append(str(job.get("name_cn", job.get("job_id", ""))))
	if not job_names.is_empty():
		_add_wrapped(box, "可用工作：%s" % "、".join(job_names))

	var market_lines: Array[String] = []
	for market_id in faction.get("available_markets", []):
		var market := DataManager.get_market(str(market_id))
		var entries := MarketManager.get_market_entries(str(market_id))
		var sample_price := ""
		for entry in entries:
			if str(entry.get("item_id", "")) == "mat_purified_water":
				sample_price = "纯水 %s" % EconomyManager.format_pence(int(entry.get("price_pence", 0)))
				break
		market_lines.append("%s（%s）" % [str(market.get("name_cn", market_id)), sample_price if sample_price != "" else "特殊渠道"])
	if not market_lines.is_empty():
		_add_wrapped(box, "交易渠道：%s" % "、".join(market_lines))

	var separator := HSeparator.new()
	box.add_child(separator)
	list.add_child(box)


func _add_wrapped(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
