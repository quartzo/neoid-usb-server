import obspython as S
import urllib.request

def script_description():
	return """ Esse Script enviar comando para câmera quando no PreView

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
	"""

settings = {}

def script_load(_settings):
  #S.script_log(S.LOG_INFO, "script_load")
  global settings
  settings = _settings
  S.obs_frontend_add_event_callback(on_event)

def script_unload():
  pass
	#S.script_log(S.LOG_INFO, "script_unload")

def on_event(event):
  if event == S.OBS_FRONTEND_EVENT_PREVIEW_SCENE_CHANGED:
    handle_scene_change()

def script_properties():
  props = S.obs_properties_create()
  scenes = S.obs_frontend_get_scenes()
  if scenes:
    for scene in scenes:
      scene_name = S.obs_source_get_name(scene)
      S.obs_properties_add_text(props, "scene_camera_" + scene_name, scene_name + " Valor", S.OBS_TEXT_DEFAULT)
  S.source_list_release(scenes)
  return props

def script_update(_settings):
  global settings
  settings = _settings

def get_scene_camera_split(scene):
  scene_name = S.obs_source_get_name(scene)
  scene_camera = S.obs_data_get_string(settings, "scene_camera_" + scene_name)
  split = scene_camera.split("/")
  res = { "cam": 0, "preset": 0, "scene_name": scene_name }
  try: 
    res["cam"] = int(split[0])
    res["preset"] = int(split[1])
  except:
    pass
  return res

def handle_scene_change():
  scene_prev = S.obs_frontend_get_current_preview_scene()
  prev_cam_data = get_scene_camera_split(scene_prev)
  S.obs_source_release(scene_prev)

  scene_current = S.obs_frontend_get_current_scene()
  current_cam_data = get_scene_camera_split(scene_current)
  S.obs_source_release(scene_current)

  log = "Ativando " + prev_cam_data["scene_name"] + ". "
  if prev_cam_data["preset"] == 0:
    S.script_log(S.LOG_INFO, log+"Faz nada: Câmera sem preset")
  elif prev_cam_data["cam"] == current_cam_data["cam"]:
    S.script_log(S.LOG_INFO, log + "Faz nada: Câmera ativa não pode mover")
  else:
    valuecmd = str(prev_cam_data["cam"]) + "/" + str(prev_cam_data["preset"])
    S.script_log(S.LOG_INFO, log + "Executando comando:  " + valuecmd)
    url = "http://localhost:7777/api/neoid/Preset%20"+str(prev_cam_data["preset"])
    try:
      urllib.request.urlopen(url).read()
    except:
      S.script_log(S.LOG_INFO, log + "Falha requisição web NEOID: " + url)

