-- ============================================================
-- AUDITORIO CC BUENAVISTA — JMD SALAMANCA
-- Q-SYS Core 8 Flex — Script de Control Principal
-- Q-SYS Designer 9.12
-- Versión: 1.0  |  2026-03-19
-- ============================================================
--
-- CONTROLES QUE DEBE EXPONER EL COMPONENTE SCRIPT:
--   Tipo Button  (trigger): btn_conferencia, btn_musica, btn_cine,
--                            btn_streaming, btn_standby,
--                            btn_freeze, btn_blank,
--                            btn_cam, btn_pc_cabina,
--                            btn_aux_cabina, btn_aux_escenario
--   Tipo Text    (output) : estado_escena, proj_estado,
--                            batt_rf1, batt_rf2, batt_rf3, batt_rf4
--   Tipo Integer (output) : batt_rf1_num, batt_rf2_num,
--                            batt_rf3_num, batt_rf4_num
--   Tipo Boolean (output) : freeze_activo, blank_activo
-- ============================================================


-- ------------------------------------------------------------
-- CONFIGURACIÓN DE RED
-- ------------------------------------------------------------
local CFG = {
  proyector = { ip = "192.168.1.101", port = 3629  },
  roland    = { ip = "192.168.1.130", port = 8023  },
  m32       = { ip = "192.168.1.110", port = 10023 },  -- OSC / UDP
  shure = {
    { id = "rf1", ip = "192.168.1.121", port = 2202 },
    { id = "rf2", ip = "192.168.1.122", port = 2202 },
    { id = "rf3", ip = "192.168.1.123", port = 2202 },
    { id = "rf4", ip = "192.168.1.124", port = 2202 },
  }
}


-- ------------------------------------------------------------
-- SOCKETS TCP/UDP
-- ------------------------------------------------------------
local sock_proj   = TcpSocket.New()
local sock_roland = TcpSocket.New()
local sock_m32    = UdpSocket.New()
local sock_shure  = {}
for i = 1, #CFG.shure do
  sock_shure[i] = TcpSocket.New()
end


-- ------------------------------------------------------------
-- HELPER: PROYECTOR EPSON (ESC/VP.net)
-- ------------------------------------------------------------
local function ProyectorCmd(cmd)
  sock_proj:Connect(CFG.proyector.ip, CFG.proyector.port)
  sock_proj:Write(cmd .. "\r")
end


-- ------------------------------------------------------------
-- HELPER: ROLAND V-80HD
-- Entradas HDMI:  1=Cámara | 2=PC cabina | 3=Aux cabina | 4=Aux escenario
-- ------------------------------------------------------------
local function RolandCmd(cmd)
  sock_roland:Connect(CFG.roland.ip, CFG.roland.port)
  sock_roland:Write(cmd .. "\r\n")
end

local function RolandInput(n)
  -- Selecciona entrada en bus PGM/A del V-80HD
  RolandCmd(string.format("BUSA_CH %d", n))
end


-- ------------------------------------------------------------
-- HELPER: MIDAS M32 — CARGAR SNAPSHOT VIA OSC (UDP)
-- Snapshots del M32:
--   1 = Conferencia | 2 = Música | 3 = Cine | 4 = Streaming | 5 = Standby
-- ------------------------------------------------------------
local function osc_pad(s)
  s = s .. "\0"
  while #s % 4 ~= 0 do s = s .. "\0" end
  return s
end

local function osc_int32(n)
  n = math.floor(n) % 0x100000000
  return string.char(
    math.floor(n / 0x1000000) % 256,
    math.floor(n / 0x10000)   % 256,
    math.floor(n / 0x100)     % 256,
    n % 256
  )
end

local function M32Snapshot(index)
  local addr    = "/,-snap/load"
  local typetag = ",i"
  local msg = osc_pad(addr) .. osc_pad(typetag) .. osc_int32(index)
  sock_m32:Send(CFG.m32.ip, CFG.m32.port, msg)
  print(string.format("[M32] Cargando snapshot %d", index))
end


-- ------------------------------------------------------------
-- ESCENAS
-- Secuencia:
--   t=0s  → encender proyector / cargar snapshot M32
--   t=2s  → cambiar entrada Roland (el V-80HD responde rápido)
--   t=8s  → confirmación proyector listo (Epson PU2010 tarda ~8 s)
-- ------------------------------------------------------------
local function EscenaConferencia()
  Controls["estado_escena"].String = "Conferencia"
  print("[Escena] Conferencia")
  ProyectorCmd("PWR ON")
  M32Snapshot(1)
  Timer.CallAfter(function() RolandInput(2) end, 2)   -- PC cabina
end

local function EscenaMusica()
  Controls["estado_escena"].String = "Música / Espectáculo"
  print("[Escena] Música")
  ProyectorCmd("PWR ON")
  M32Snapshot(2)
  Timer.CallAfter(function() RolandInput(1) end, 2)   -- Cámara
end

local function EscenaCine()
  Controls["estado_escena"].String = "Cine / Proyección"
  print("[Escena] Cine")
  ProyectorCmd("PWR ON")
  M32Snapshot(3)
  Timer.CallAfter(function() RolandInput(2) end, 2)   -- PC cabina
end

local function EscenaStreaming()
  Controls["estado_escena"].String = "Streaming"
  print("[Escena] Streaming — iniciar OBS en PC cabina")
  ProyectorCmd("PWR ON")
  M32Snapshot(4)
  Timer.CallAfter(function() RolandInput(1) end, 2)   -- Cámara
end

local function EscenaStandby()
  Controls["estado_escena"].String = "Standby"
  print("[Escena] Standby")
  M32Snapshot(5)
  Timer.CallAfter(function() ProyectorCmd("PWR OFF") end, 2)
  -- Asegurar que freeze y blank quedan desactivados
  Controls["freeze_activo"].Boolean = false
  Controls["blank_activo"].Boolean  = false
end


-- ------------------------------------------------------------
-- CONTROL DIRECTO VÍDEO: FREEZE y BLANK (pantalla negra)
-- ------------------------------------------------------------
local function FreezeToggle()
  if Controls["freeze_activo"].Boolean then
    ProyectorCmd("FREEZE OFF")
    Controls["freeze_activo"].Boolean = false
    print("[Proyector] Freeze OFF")
  else
    ProyectorCmd("FREEZE ON")
    Controls["freeze_activo"].Boolean = true
    print("[Proyector] Freeze ON")
  end
end

local function BlankToggle()
  if Controls["blank_activo"].Boolean then
    ProyectorCmd("MSEL 00")
    Controls["blank_activo"].Boolean = false
    print("[Proyector] Pantalla negra OFF")
  else
    ProyectorCmd("MSEL 10")
    Controls["blank_activo"].Boolean = true
    print("[Proyector] Pantalla negra ON")
  end
end


-- ------------------------------------------------------------
-- ESTADO PROYECTOR — polling cada 10 segundos
-- Respuestas ESC/VP.net:
--   00 = OFF | 01 = ON | 02 = Calentando | 03 = Enfriando | 04 = Error
-- ------------------------------------------------------------
sock_proj.EventHandler = function(sock, evt, err)
  if evt == TcpSocket.Events.Data then
    local resp = sock:Read(64)
    if     resp:find("=01") then
      Controls["proj_estado"].String = "Encendido"
      Controls["proj_estado"].Color  = "green"
    elseif resp:find("=00") then
      Controls["proj_estado"].String = "Apagado"
      Controls["proj_estado"].Color  = "gray"
    elseif resp:find("=02") then
      Controls["proj_estado"].String = "Calentando..."
      Controls["proj_estado"].Color  = "yellow"
    elseif resp:find("=03") then
      Controls["proj_estado"].String = "Enfriando..."
      Controls["proj_estado"].Color  = "yellow"
    elseif resp:find("=04") then
      Controls["proj_estado"].String = "ERROR"
      Controls["proj_estado"].Color  = "red"
    end
  elseif evt == TcpSocket.Events.Error then
    Controls["proj_estado"].String = "Sin conexión"
    Controls["proj_estado"].Color  = "red"
    print("[Proyector] Error TCP: " .. (err or "?"))
  end
end

local function ProyectorPoll()
  sock_proj:Connect(CFG.proyector.ip, CFG.proyector.port)
  sock_proj:Write("PWR?\r")
end

local proj_timer = Timer.New()
proj_timer.EventHandler = ProyectorPoll
proj_timer:Start(10)


-- ------------------------------------------------------------
-- BATERÍAS SHURE QLXD4 — polling cada 30 segundos
-- Protocolo: enviar < GET 0 BATT_BARS >
-- Respuesta: < REP 0 BATT_BARS XX >  (0-5 barras)
-- ------------------------------------------------------------
local batt_icons = { "●●●●●", "●●●●○", "●●●○○", "●●○○○", "●○○○○", "○○○○○" }

local function ShurePoll(i)
  local rf = CFG.shure[i]
  local s  = sock_shure[i]

  s.EventHandler = function(sock, evt, err)
    if evt == TcpSocket.Events.Data then
      local data = sock:Read(256)
      local bars = tonumber(data:match("BATT_BARS%s+(%d+)"))
      if bars then
        bars = math.max(0, math.min(5, bars))
        Controls["batt_rf" .. i].String  = batt_icons[6 - bars]
        Controls["batt_rf" .. i .. "_num"].Integer = bars
        -- Color según nivel
        if bars >= 3 then
          Controls["batt_rf" .. i].Color = "green"
        elseif bars == 2 then
          Controls["batt_rf" .. i].Color = "yellow"
        else
          Controls["batt_rf" .. i].Color = "red"
        end
      end
    elseif evt == TcpSocket.Events.Error then
      Controls["batt_rf" .. i].String = "Sin señal"
      Controls["batt_rf" .. i].Color  = "gray"
    end
  end

  s:Connect(rf.ip, rf.port)
  s:Write("< GET 0 BATT_BARS >\r\n")
end

local function ShurePollAll()
  for i = 1, #CFG.shure do
    ShurePoll(i)
  end
end

local batt_timer = Timer.New()
batt_timer.EventHandler = ShurePollAll
batt_timer:Start(30)


-- ------------------------------------------------------------
-- VINCULACIÓN CONTROLES UCI → FUNCIONES
-- ------------------------------------------------------------

-- Escenas
Controls["btn_conferencia"].EventHandler   = function(c) if c.Boolean then EscenaConferencia() end end
Controls["btn_musica"].EventHandler        = function(c) if c.Boolean then EscenaMusica()      end end
Controls["btn_cine"].EventHandler          = function(c) if c.Boolean then EscenaCine()        end end
Controls["btn_streaming"].EventHandler     = function(c) if c.Boolean then EscenaStreaming()   end end
Controls["btn_standby"].EventHandler       = function(c) if c.Boolean then EscenaStandby()     end end

-- Vídeo directo
Controls["btn_freeze"].EventHandler        = function(c) if c.Boolean then FreezeToggle() end end
Controls["btn_blank"].EventHandler         = function(c) if c.Boolean then BlankToggle()  end end

-- Selección de entrada Roland (acceso directo desde UCI)
Controls["btn_cam"].EventHandler           = function(c) if c.Boolean then RolandInput(1) end end
Controls["btn_pc_cabina"].EventHandler     = function(c) if c.Boolean then RolandInput(2) end end
Controls["btn_aux_cabina"].EventHandler    = function(c) if c.Boolean then RolandInput(3) end end
Controls["btn_aux_escenario"].EventHandler = function(c) if c.Boolean then RolandInput(4) end end


-- ------------------------------------------------------------
-- ARRANQUE
-- ------------------------------------------------------------
print("============================================")
print("[Auditorio Buenavista] Script iniciado OK")
print("[Q-SYS] " .. os.date("%Y-%m-%d %H:%M:%S"))
print("============================================")

ShurePollAll()
ProyectorPoll()
