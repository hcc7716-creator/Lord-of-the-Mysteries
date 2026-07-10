extends PanelContainer

@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var requests_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/Requests
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton


func _ready() -> void:
	visible = false
	close_button.pressed.connect(func(): visible = false)
	TarotClubManager.tarot_club_unlocked.connect(refresh)
	TarotClubManager.tarot_club_available.connect(_on_tarot_club_available)
	TarotClubManager.tarot_request_completed.connect(func(_request_id: String): refresh())
	CalendarManager.date_changed.connect(func(_week: int, _day: String, _hour: int): refresh())
	refresh()


func refresh() -> void:
	for child in requests_container.get_children():
		child.queue_free()
	if not TarotClubManager.is_unlocked:
		status_label.text = "尚未解锁。完成“成为占卜家”后，才会接触灰雾之上的邀请。"
		return
	if not CalendarManager.is_sunday():
		status_label.text = "塔罗会已解锁，但本周会议尚未开始。当前：%s。会议固定在每周日。" % CalendarManager.get_display_text()
		return
	status_label.text = "灰雾之上已开启。以下是本周可提交的等价交换请求。"
	for request in TarotClubManager.get_available_requests():
		_add_request(request)
	if requests_container.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "本周没有新的交换请求。"
		requests_container.add_child(empty_label)


func _add_request(request: Dictionary) -> void:
	var request_id := str(request.get("request_id", ""))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var title := Label.new()
	title.text = str(request.get("title_cn", request_id))
	box.add_child(title)
	var detail := Label.new()
	detail.text = "提供：%s\n请求：%s%s" % [
		", ".join(request.get("offered_items", [])),
		", ".join(request.get("requested_items", [])),
		"\n情报：%s" % ", ".join(request.get("requested_info", [])) if not request.get("requested_info", []).is_empty() else "",
	]
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(detail)
	var button := Button.new()
	button.text = "提交等价交换（占位）"
	button.pressed.connect(_submit_request.bind(request_id))
	box.add_child(button)
	requests_container.add_child(box)


func _submit_request(request_id: String) -> void:
	var result := TarotClubManager.submit_exchange_request(request_id)
	if bool(result.get("success", false)):
		GameManager.show_status_message("交换请求已提交。当前阶段仅记录结果，奖励将在后续内容中兑现。")
	else:
		GameManager.show_status_message("无法提交交换：%s" % str(result.get("reason", "unknown")))
	refresh()


func _on_tarot_club_available(_week: int) -> void:
	GameManager.show_status_message("周日已至：灰雾之上的塔罗会可以进入。")
	refresh()
