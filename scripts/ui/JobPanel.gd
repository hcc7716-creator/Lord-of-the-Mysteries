extends PanelContainer

const RISK_LABELS := {"low": "低风险", "medium": "中风险", "high": "高风险"}

@onready var summary_label: Label = $MarginContainer/VBoxContainer/SummaryLabel
@onready var jobs_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/Jobs
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton


func _ready() -> void:
	visible = false
	close_button.pressed.connect(func(): visible = false)
	JobManager.job_completed.connect(_on_job_completed)
	JobManager.job_event_triggered.connect(_on_job_event_triggered)
	refresh()


func refresh() -> void:
	for child in jobs_container.get_children():
		child.queue_free()
	var region_name := "廷根原型"
	var region := DataManager.get_region(OriginManager.starting_region_id)
	if not region.is_empty():
		region_name = str(region.get("name_cn", region_name))
	summary_label.text = "当前地区：%s｜%s" % [region_name, CalendarManager.get_display_text()]
	for job in JobManager.get_available_jobs():
		_add_job_row(job)


func _add_job_row(job: Dictionary) -> void:
	var job_id := str(job.get("job_id", ""))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var title := Label.new()
	title.text = "%s｜%s｜%s" % [
		str(job.get("name_cn", job_id)),
		EconomyManager.format_pence(int(job.get("reward_pence", 0))),
		RISK_LABELS.get(str(job.get("risk_level", "low")), "未知风险"),
	]
	box.add_child(title)
	var description := Label.new()
	description.text = "%s\n耗时：%d 小时" % [str(job.get("description", "")), int(job.get("time_cost_hours", 0))]
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var button := Button.new()
	button.text = "开始工作"
	button.pressed.connect(_perform_job.bind(job_id))
	box.add_child(button)
	jobs_container.add_child(box)


func _perform_job(job_id: String) -> void:
	var result := JobManager.perform_job(job_id)
	if not bool(result.get("success", false)):
		GameManager.show_status_message("当前无法开始这份工作。")
		return
	var message := "工作完成：获得 %s，时间推进至 %s" % [
		EconomyManager.format_pence(int(result.get("reward_pence", 0))),
		CalendarManager.get_display_text(),
	]
	if not result.get("triggered_events", []).is_empty():
		message += "｜触发了新的事件线索"
	if not result.get("gained_materials", []).is_empty():
		message += "｜额外获得：%s" % "、".join(result.get("gained_materials", []))
	GameManager.show_status_message(message)
	refresh()


func _on_job_completed(_job_id: String, _reward_pence: int) -> void:
	refresh()


func _on_job_event_triggered(_job_id: String, _event_id: String) -> void:
	refresh()
