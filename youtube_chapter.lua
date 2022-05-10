
obs = obslua

start_time = nil
work_scene = nil
work_count = 0
output_path = ""

function get_chapter_text(time, scene_name, count)
	local seconds       = math.floor(time % 60)
	local minutes       = math.floor(time / 60)
	local hours         = math.floor(time / 3600)
	if count == 0 then
		return string.format("%02d:%02d:%02d %s", hours, minutes, seconds, scene_name)
	else
		return string.format("%02d:%02d:%02d %s #%d", hours, minutes, seconds, scene_name, count)
	end
end

function print_chapter(time)
	local scene = obs.obs_frontend_get_current_scene()
	local scene_name = obs.obs_source_get_name(scene)

	if scene_name == work_scene then
		work_count = work_count + 1
	end

	local line = get_chapter_text(time, scene_name, work_count)
	io.write(line, "\n")
	print(line)
end

function on_event(event)
	-- 配信開始時
	if event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
		start_time = os.time()
		work_count = 0

		if output_path ~= "" then
			io.output(output_path)
		end

		print_chapter(0)
	end

	-- 配信終了時
	if event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED then
		start_time = nil
		if output_path ~= "" then
			io.close()
		end
	end

	-- 配信中のシーン変更時、開始時刻との差分秒数とシーン名を書き出す
	if event == obs.OBS_FRONTEND_EVENT_SCENE_CHANGED and start_time ~= nil then
		local now = os.time()
		local diff = os.difftime(now, start_time)

		print_chapter(diff)
	end
end


-- A function named script_properties defines the properties that the user
-- can change for the entire script module itself
function script_properties()
	local props = obs.obs_properties_create()

	-- workシーン選択
	local p = obs.obs_properties_add_list(props, "work_scene", "Work scene", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local scenes = obs.obs_frontend_get_scenes()
	if scenes ~= nil then
		for _, scene in ipairs(scenes) do
			local name = obs.obs_source_get_name(scene);
			obs.obs_property_list_add_string(p, name, name)
		end
	end

	-- 保存先選択
	obs.obs_properties_add_path(props, "output_path", "Output path", obs.OBS_PATH_FILE,  "text file (*.txt)", nil)

	return props
end

-- A function named script_update will be called when settings are changed
function script_update(settings)
	work_scene = obs.obs_data_get_string(settings, "work_scene")
	output_path = obs.obs_data_get_string(settings, "output_path")
end


-- a function named script_load will be called on startup
function script_load(settings)
	obs.obs_frontend_add_event_callback(on_event)
end
