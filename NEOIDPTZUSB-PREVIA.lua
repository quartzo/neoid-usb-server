-- MIT License
--
-- Copyright (c) Geert Eikelboom, Mark Lagendijk
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- O SOFTWARE É FORNECIDO "COMO ESTÁ", SEM GARANTIA DE QUALQUER TIPO, EXPRESSA OU
-- IMPLÍCITA, INCLUINDO, MAS NÃO SE LIMITANDO ÀS GARANTIAS DE COMERCIALIZAÇÃO,
-- ADEQUAÇÃO A UMA FINALIDADE ESPECÍFICA E NÃO VIOLAÇÃO. EM NENHUMA HIPÓTESE O
-- AUTORES OU TITULARES DOS DIREITOS AUTORAIS SERÃO RESPONSÁVEIS POR QUALQUER RECLAMAÇÃO, DANOS OU OUTROS
-- RESPONSABILIDADE, SEJA EM AÇÃO DE CONTRATO, DELITO OU DE OUTRA FORMA, DECORRENTE DE,
-- FORA DE OU EM CONEXÃO COM O SOFTWARE OU O USO OU OUTRAS NEGOCIAÇÕES NO
-- PROGRAMAS.
-- Original script by Geert Eikelboom

obs = obslua
settings = {}
function script_description()
	return [[ Esse Script enviar comando para carama quando no PreView

A Ideie é execute um comando CLI sempre que uma cena for ativada, "isso para teste".

Como Configurar: 
	Em  comando:
  	curl  http://localhost:11655/mp/5/SCENE_VALUE

	Assim você coloca o numero do preset que deseja carregar.. 
		1,3,4 usar o numero do preset da camera

	Ele ira gerar um comando 
	http://localhost:11655/mp/5/2

	5 numero da camera, 2 nuemro preset
	http://localhost:11655/mp/{Camera}/{preset}
]]
end

function script_properties()
	local props = obs.obs_properties_create()

	obs.obs_properties_add_text(props, "comando", "Comando", obs.OBS_TEXT_DEFAULT)
	
	local scenes = obs.obs_frontend_get_scenes()
	
	if scenes ~= nil then
		for _, scene in ipairs(scenes) do
			local scene_name = obs.obs_source_get_name(scene)
			obs.obs_properties_add_bool(props, "scene_enabled_" .. scene_name, "Execute quando '" .. scene_name .. "' se Ativo")
			obs.obs_properties_add_text(props, "scene_value_" .. scene_name, scene_name .. " Valor", obs.OBS_TEXT_DEFAULT)
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

function handle_scene_change()
	local scene = obs.obs_frontend_get_current_preview_scene()
	local scene_name = obs.obs_source_get_name(scene)
	local scene_enabled = obs.obs_data_get_bool(settings, "scene_enabled_" .. scene_name)
	if scene_enabled then
		local command = obs.obs_data_get_string(settings, "comando")
		local scene_value = obs.obs_data_get_string(settings, "scene_value_" .. scene_name)
		local scene_command = string.gsub(command, "SCENE_VALUE", scene_value)
		obs.script_log(obs.LOG_INFO, "Ativando " .. scene_name .. ". Execultando comando:\n  " .. scene_command)
		os.execute(scene_command)
	else
		obs.script_log(obs.LOG_INFO, "Ativando " .. scene_name .. ". A execução está desabilitada para esta cena.")
	end
	obs.obs_source_release(scene);
end
