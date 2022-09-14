
obs = obslua
settings = {}
function script_description()
	return [[ Esse Script enviar comando para câmera quando no PreView

Será executato:
  	curl http://localhost:7777/mp/<camera>/<preset>

	Assim você coloca o número da câmera mais o número do preset que deseja carregar.. 
		0,1,3,4 usar o número da camera (0 ou vazio é igual)
		+"/"+ "1" ou "3" ou "4": usar o numero do preset da câmera (se tiver)

	Ele irá gerar um comando 
	http://localhost:7777/mp/5/2
	
	-- vazio: "" -> câmera fixa ou cena sem câmera
	-- câmera fixa: "5" ou "0" -> efeito idêntico ao vazio
	-- câmera com preset: "1/2" -> câmera 1 preset 2 -> envia comando
	]]
end

function script_properties()
	local props = obs.obs_properties_create()
	local scenes = obs.obs_frontend_get_scenes()
	if scenes ~= nil then
		for _, scene in ipairs(scenes) do
			local scene_name = obs.obs_source_get_name(scene)
			obs.obs_properties_add_text(props, "scene_camera_" .. scene_name, scene_name .. " Valor", obs.OBS_TEXT_DEFAULT)
		end
	end
	
	obs.source_list_release(scenes)
	return props
end

function script_update(_settings)	
	settings = _settings
end

function script_load(settings)
	obs.obs_frontend_add_event_callback(handle_event)
end

function handle_event(event)
	if event == obs.OBS_FRONTEND_EVENT_PREVIEW_SCENE_CHANGED then
		handle_scene_change()	
	end
end

local function splitnum(str)
	local result = {}
	for each in str:gmatch("([^/]+)") do
		table.insert(result, tonumber(each) or 0)
	end
	return result
end

function handle_scene_change()
	local scene_prev = obs.obs_frontend_get_current_preview_scene()
	local scene_prev_name = obs.obs_source_get_name(scene_prev)
	local scene_prev_camera = obs.obs_data_get_string(settings, "scene_camera_" .. scene_prev_name)
  local scene_prev_camera_split = splitnum(scene_prev_camera)
	obs.obs_source_release(scene_prev)

	local scene_current = obs.obs_frontend_get_current_scene()
	local scene_current_name = obs.obs_source_get_name(scene_current)
	local scene_current_camera = obs.obs_data_get_string(settings, "scene_camera_" .. scene_current_name)
	local scene_current_camera_split = splitnum(scene_current_camera)
	obs.obs_source_release(scene_current)

	if (scene_prev_camera_split[2] or 0) == 0 then
		obs.script_log(obs.LOG_INFO, "Ativando " .. scene_prev_name .. ". Faz nada: Câmera sem preset")
  elseif scene_prev_camera_split[1] == scene_current_camera_split[1] then
		obs.script_log(obs.LOG_INFO, "Ativando " .. scene_prev_name .. ". Faz nada: Câmera ativa não pode mover")
	else
		local valuecmd = tostring(scene_prev_camera_split[1]) .. "/" .. tostring(scene_prev_camera_split[2])
		local command = "curl http://localhost:7777/mp/"..valuecmd
		obs.script_log(obs.LOG_INFO, "Ativando " .. scene_prev_name .. ". Executando comando:  " .. valuecmd)
		os.execute(command)
	end
end
