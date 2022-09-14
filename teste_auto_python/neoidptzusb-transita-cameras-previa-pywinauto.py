# fazer: pip install pywinauto
import obspython as S
import pywinauto

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

def script_load(settings):
  S.script_log(S.LOG_INFO, "script_load")
  #S.obs_frontend_add_event_callback(handle_event)
  S.obs_frontend_add_event_callback(on_event)

def script_unload():
	S.script_log(S.LOG_INFO, "script_unload")

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

settings = {}

def splitnum(str):
	res = str.split("/")
	try:
		cam = int(res[0])
	except:
		cam = 0
	try:
		preset = int(res[1])
	except:
		preset = 0
	return [cam,preset]

def script_update(_settings):
  global settings
  settings = {}
  scenes = S.obs_frontend_get_scenes()
  if scenes:
    for scene in scenes:
      scene_name = S.obs_source_get_name(scene)
      scene_camera = S.obs_data_get_string(_settings, "scene_camera_" + scene_name)
      scene_camera_split = splitnum(scene_camera)
      settings[scene_name] = scene_camera_split
  S.source_list_release(scenes)

def handle_scene_change():
  scene_prev = S.obs_frontend_get_current_preview_scene()
  scene_prev_name = S.obs_source_get_name(scene_prev)
  scene_prev_camera_split = settings[scene_prev_name]
  S.obs_source_release(scene_prev)

  scene_current = S.obs_frontend_get_current_scene()
  scene_current_name = S.obs_source_get_name(scene_current)
  scene_current_camera_split = settings[scene_current_name]
  S.obs_source_release(scene_current)

  if scene_prev_camera_split[1] == 0:
    S.script_log(S.LOG_INFO, "Ativando " + scene_prev_name + ". Faz nada: Câmera sem preset")
  elif scene_prev_camera_split[0] == scene_current_camera_split[0]:
    S.script_log(S.LOG_INFO, "Ativando " + scene_prev_name + ". Faz nada: Câmera ativa não pode mover")
  else:
    valuecmd = str(scene_prev_camera_split[0]) + "/" + str(scene_prev_camera_split[1])
    S.script_log(S.LOG_INFO, "Ativando " + scene_prev_name + ". Executando comando:  " + valuecmd)
    dlg = pywinauto.Desktop(backend="win32")["NEOiD Câmera PRO"]
    dlg.child_window(auto_id='button'+str(scene_prev_camera_split[2])).click()
