-- [[ PLUGIN JIESHUO: RESIDENT EVIL - EL INCIDENTE DE BRIAN ]]
-- Basado en la arquitectura de alexisdaquiga®️©️
-- Ajuste de accesibilidad: Nivel 7 a 2.0s + Audio Multicapa Integrado

local LinearLayout = luajava.bindClass("android.widget.LinearLayout")
local ScrollView = luajava.bindClass("android.widget.ScrollView")
local TextView = luajava.bindClass("android.widget.TextView")
local Button = luajava.bindClass("android.widget.Button")
local View = luajava.bindClass("android.view.View")
local AlertDialog = luajava.bindClass("android.app.AlertDialog")
local Handler = luajava.bindClass("android.os.Handler")
local Runnable = luajava.bindClass("java.lang.Runnable")
local Uri = luajava.bindClass("android.net.Uri")
local Intent = luajava.bindClass("android.content.Intent")
local MediaPlayer = luajava.bindClass("android.media.MediaPlayer")

local _C = service.getContext()
local _A = "alexisdaquiga®️©️" 
local _S = "SINOPSIS: RESIDENT EVIL - EL INCIDENTE DE BRIAN. Una entrega médica urgente se convierte en una pesadilla biológica."

-- [[ RUTA ACTUALIZADA DEL PLUGIN Y AUDIOS ]]
local path = "/storage/emulated/0/解说/Plugins/sombras del residente 2/"

-- [[ CONFIGURACIÓN DE AUDIO INDEPENDIENTE ]]
local audio = {
  ambiente = MediaPlayer(),
  ataque_z = MediaPlayer(),
  cerberus = MediaPlayer(),
  disparo = MediaPlayer(),
  zombies = MediaPlayer(),
  helico = MediaPlayer(),
  c4 = MediaPlayer()
}

function prepararAudio(player, archivo, loop)
  pcall(function()
    player.reset()
    player.setDataSource(path .. archivo)
    player.prepare()
    player.setLooping(loop or false)
  end)
end

-- Carga inicial de librería de sonidos con la nueva ruta
prepararAudio(audio.ambiente, "ambiente.WAV", true)
prepararAudio(audio.ataque_z, "ataque_Z_HEAD.WAV", false)
prepararAudio(audio.cerberus, "cerberys.WAV", false)
prepararAudio(audio.disparo, "disparo.WAV", false)
prepararAudio(audio.zombies, "zombies.WAV", false)
prepararAudio(audio.helico, "helicóptero.mp3", true)
prepararAudio(audio.c4, "c4_explode1.wav", false)

function reproducir(sonido)
  pcall(function()
    if sonido.isPlaying() then sonido.seekTo(0) end
    sonido.start()
  end)
end

local sim = {
  idx = 1, vida = 100, municion = 15, activa = true,
  en_mision = false, victoria = false, amenaza_activa = false,
  tipo_amenaza = "", objetivo_cumplido = 0
}

-- [[ NARRATIVA DE LOS NIVELES ADAPTADA A LA HISTORIA DE BRIAN ]]
local misiones = {
  {id = "EL HOSPITAL INICIAL", meta = 5, guia = "Consigue que firmen el comprobante B7.", trama = "Brian llega tarde al hospital y se ve obligado a falsificar la firma de la asistente para entregar el paquete médico."},
  {id = "CARRETERA A RACCOON CITY", meta = 5, guia = "Atraviesa la niebla y esquiva el peligro.", trama = "Brian acepta un encargo doble hacia Raccoon City. Habla con Michelle por teléfono antes de atropellar a una mujer cubierta de sangre."},
  {id = "EL PATRULLERO Y EL BOSQUE", meta = 5, guia = "Escapa del ataque tras la muerte del oficial.", trama = "El oficial escolta a Brian, pero su patrullero sufre un terrible accidente. El policía muere y la mujer poseída ataca."},
  {id = "CASA ABANDONADA", meta = 6, guia = "Sobrevive al perro mutado y busca munición.", trama = "Brian salta una cerca eléctrica, sobrevive al perro zombi, encuentra una escopeta vacía y deja un mensaje de voz a Michelle."},
  {id = "EL TÚNEL Y EL ENCUENTRO", meta = 6, guia = "Escapa del autobús infantil y de Maxim y Carl.", trama = "En el túnel de autobuses abandonados, Brian es atacado por una niña mutada. Maxim y Carl lo rescatan y revelan el secreto de Umbrella y el antídoto."},
  {id = "LAS ALCANTARILLAS Y CALLES", meta = 6, guia = "Huye de la horda mutante subterránea.", trama = "Maxim desaparece y Carl es devorado por un perro mutante. Brian desciende a las alcantarillas donde se enfrenta a la masa de ratas y mutaciones."},
  {id = "HOSPITAL DE RACCOON CITY: ESCAPE FINAL", meta = 12, guia = "Resiste en el cunero y entrega el paquete.", trama = "Brian escala el hospital, esquiva a los bebés zombis mutantes en el cunero y entrega el paquete para completar la cura definitiva."}
}

local dialog, txt_status, txt_narrador, txt_progreso, subDialog

function decir(t) pcall(function() if service then service.speak(t) end end) end

function actualizarUI()
  if not dialog or not dialog.isShowing() then return end
  local m = misiones[sim.idx] or misiones[#misiones]
  pcall(function()
    txt_status.setText("💉 SALUD: " .. sim.vida .. "% | 🔫 BALAS: " .. sim.municion)
    txt_progreso.setText("🚩 NIVEL " .. sim.idx .. " - " .. m.id .. " [" .. sim.objetivo_cumplido .. "/" .. m.meta .. "]")
    if sim.vida <= 0 and sim.activa then 
      sim.activa = false; mostrarMenuDerrota() 
    end
  end)
end

function mostrarMenuDerrota()
  local l = LinearLayout(_C); l.setOrientation(1); l.setPadding(40,40,40,40); l.setBackgroundColor(0xFF000000)
  local t = TextView(_C); t.setText("BRIAN HA CAÍDO EN MISIÓN"); t.setTextSize(20); t.setTextColor(0xFFFF0000); t.setGravity(1); l.addView(t)
  local b = Button(_C); b.setText("REINTENTAR NIVEL"); b.setOnClickListener(View.OnClickListener({onClick=function() 
    sim.vida = 100; sim.objetivo_cumplido = 0; sim.activa = true; sim.en_mision = false; subDialog.dismiss(); actualizarUI(); decir("Reiniciando nivel.")
  end})); l.addView(b)
  subDialog = AlertDialog.Builder(_C).setTitle(_A).setView(l).setCancelable(false).create(); subDialog.getWindow().setType(2032); subDialog.show()
end

-- [[ VENTANA DE TRANSICIÓN ENTRE NIVELES ]]
function mostrarVentanaSiguienteNivel()
  local m = misiones[sim.idx]
  local l = LinearLayout(_C); l.setOrientation(1); l.setPadding(40,40,40,40); l.setBackgroundColor(0xFF000000)
  
  local t_titulo = TextView(_C); t_titulo.setText("🚀 NIVEL " .. sim.idx .. ": " .. m.id); t_titulo.setTextSize(18); t_titulo.setTextColor(0xFF4CAF50); t_titulo.setGravity(1); l.addView(t_titulo)
  
  local t_desc = TextView(_C); t_desc.setText("\nAsignación:\n" .. m.trama .. "\n\nGuía: " .. m.guia .. "\n\nObjetivo de la misión: Lleva " .. sim.objetivo_cumplido .. " de " .. m.meta .. " completados. Te faltan " .. (m.meta - sim.objetivo_cumplido) .. " para avanzar."); t_desc.setTextColor(0xFFFFFFFF); l.addView(t_desc)
  
  local b = Button(_C); b.setText("CONTINUAR"); b.setBackgroundColor(0xFF1B5E20); b.setTextColor(0xFFFFFFFF)
  local lp = LinearLayout.LayoutParams(-1, -2); lp.setMargins(0,20,0,0); b.setLayoutParams(lp)
  b.setOnClickListener(View.OnClickListener({onClick=function() 
    subDialog.dismiss()
    sim.en_mision = true
    reproducir(audio.ambiente)
    if sim.idx == 7 then reproducir(audio.helico) end
    decir(m.trama .. ". Objetivo actual: llevas " .. sim.objetivo_cumplido .. ", faltan " .. (m.meta - sim.objetivo_cumplido) .. ".")
    txt_narrador.setText(m.trama)
    generarAmenaza()
    actualizarUI()
  end}))
  l.addView(b)
  
  subDialog = AlertDialog.Builder(_C).setTitle("RESIDENT EVIL: EL INCIDENTE DE BRIAN").setView(l).setCancelable(false).create()
  subDialog.getWindow().setType(2032); subDialog.show()
  decir("Nivel superado. Preparando siguiente asignación.")
end

function generarAmenaza()
  if not sim.activa or not sim.en_mision then return end
  
  Handler().postDelayed(Runnable({run = function()
    if not sim.activa or not sim.en_mision then return end
    sim.amenaza_activa = true
    
    local t_reaccion = 4000 
    if sim.idx >= 3 then t_reaccion = 3000 end
    if sim.idx >= 5 then t_reaccion = 2000 end
    if sim.idx >= 7 then t_reaccion = 2000 end 

    local dado = math.random(1, 100)
    if dado <= 35 then
      sim.tipo_amenaza = "ATAQUE"; reproducir(audio.zombies); decir("¡Criatura o zombi detectado!")
    elseif dado <= 65 then
      sim.tipo_amenaza = "ESQUIVA"; reproducir(audio.cerberus); decir("¡Esquiva el ataque!")
    else
      sim.tipo_amenaza = "OBJETIVO"; decir("¡Paquete o pista clave disponible para asegurar!")
    end
    
    Handler().postDelayed(Runnable({run = function()
      if sim.amenaza_activa then
        sim.vida = math.max(0, sim.vida - 25)
        reproducir(audio.ataque_z)
        decir("¡Herido! Salud al " .. sim.vida .. "%")
        sim.amenaza_activa = false; actualizarUI()
      end
      if sim.vida > 0 and sim.activa then generarAmenaza() end
    end}), t_reaccion)
  end}), 5500)
end

function ejecutar(tipo)
  if tipo == "SALIR" then 
    sim.activa = false
    pcall(function() for _, p in pairs(audio) do if p.isPlaying() then p.stop() end; p.release() end end)
    if dialog then dialog.dismiss() end; return 
  end
  if not sim.activa or sim.victoria then return end
  
  if tipo == "INICIAR" then
    if not sim.en_mision then 
      mostrarVentanaSiguienteNivel()
    end
    return
  end

  if tipo == "ATAQUE" and sim.tipo_amenaza == "ATAQUE" and sim.amenaza_activa then
    if sim.municion > 0 then
      reproducir(audio.disparo)
      sim.municion = sim.municion - 1; sim.amenaza_activa = false; decir("¡Disparo exitoso!")
    else decir("¡Sin munición en el arma!") end
  elseif tipo == "ESQUIVA" and sim.tipo_amenaza == "ESQUIVA" and sim.amenaza_activa then
    sim.amenaza_activa = false; decir("¡Esquivado con éxito!")
  elseif tipo == "ACCION" then
    if sim.amenaza_activa and sim.tipo_amenaza == "OBJETIVO" then
      sim.amenaza_activa = false; sim.objetivo_cumplido = sim.objetivo_cumplido + 1
      local m = misiones[sim.idx]
      local faltan = m.meta - sim.objetivo_cumplido
      decir("¡Objetivo asegurado! Llevas " .. sim.objetivo_cumplido .. " de " .. m.meta .. ". Te faltan " .. faltan .. " para completar el nivel.")
    else
      local r = math.random(1, 100)
      if r <= 30 then sim.municion = sim.municion + 5; decir("¡Encontraste munición o un cartucho!")
      elseif r <= 50 then sim.vida = math.min(100, sim.vida + 25); decir("¡Recuperaste energía con suministros!")
      else decir("Área inspeccionada. Sigue buscando pistas.") end
    end
  end

  if sim.objetivo_cumplido >= misiones[sim.idx].meta then
    sim.en_mision, sim.objetivo_cumplido = false, 0
    sim.idx = sim.idx + 1
    if audio.helico.isPlaying() then audio.helico.stop() end

    if sim.idx > #misiones then 
      sim.victoria = true
      if audio.ambiente.isPlaying() then audio.ambiente.stop() end
      reproducir(audio.c4)
      local final_msg = "Brian logra entregar el paquete en el laboratorio, pero es demasiado tarde y comienza a mutar. La muestra cae al vacío y los helicópteros observan su destino. ¡Misión Terminada! Apoya mi contenido en TikTok: @alexisdaquiga"
      decir(final_msg); txt_narrador.setText(final_msg)
    else 
      mostrarVentanaSiguienteNivel()
    end
  end
  actualizarUI()
end

function PantallaMando()
  local sv = ScrollView(_C)
  local root = LinearLayout(_C); root.setOrientation(1); root.setPadding(40,40,40,40); root.setBackgroundColor(0xFF000000)
  sv.addView(root)
  
  txt_status = TextView(_C); txt_status.setTextColor(0xFFFFFFFF); root.addView(txt_status)
  txt_progreso = TextView(_C); txt_progreso.setTextColor(0xFFF44336); root.addView(txt_progreso)
  txt_narrador = TextView(_C); txt_narrador.setText(_S); txt_narrador.setTextColor(0xFF9E9E9E); txt_narrador.setPadding(0,15,0,15); root.addView(txt_narrador)
  
  local function b(t, c, f)
    local btn = Button(_C); btn.setText(t); btn.setBackgroundColor(c); btn.setTextColor(0xFFFFFFFF)
    local lp = LinearLayout.LayoutParams(-1, -2); lp.setMargins(0,10,0,10); btn.setLayoutParams(lp)
    btn.setOnClickListener(View.OnClickListener({onClick=function() f() end})); root.addView(btn)
  end
  
  b("📟 INICIAR / CONTINUAR MISIÓN", 0xFF1B5E20, function() ejecutar("INICIAR") end)
  b("🔥 FUEGO TÁCTICO", 0xFFB71C1C, function() ejecutar("ATAQUE") end)
  b("🛡️ ESQUIVAR", 0xFF0D47A1, function() ejecutar("ESQUIVA") end)
  b("🔦 ACCIÓN / BUSCAR", 0xFFE65100, function() ejecutar("ACCION") end)
  b("📱 APOYAR EN TIKTOK", 0xFF212121, function() 
    _C.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://www.tiktok.com/@alexisdaquiga")).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
  end)
  b("✖️ ABANDONAR MISIÓN", 0xFF455A64, function() ejecutar("SALIR") end)
  
  dialog = AlertDialog.Builder(_C).setTitle("RESIDENT EVIL: EL INCIDENTE DE BRIAN - " .. _A).setView(sv).setCancelable(false).create()
  dialog.getWindow().setType(2032); dialog.show()
  actualizarUI(); decir("Sistemas de audio y combate de Resident Evil: El Incidente de Brian listos.")
end

PantallaMando()