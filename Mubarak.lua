-- Mubarak Scripts loader (GameGuardian)
-- Downloads authorized devices and encrypted script from this repository.
local base = "https://raw.githubusercontent.com/salahadoroobi/Mubarak-Scripts/main/"
local function request(name)
  local r = gg.makeRequest(base .. name)
  if not r or r.code ~= 200 then
    gg.alert("تعذر تحميل " .. name .. " من GitHub")
    return nil
  end
  return r.content
end
local function device_id()
  local f = io.open("/proc/sys/kernel/random/boot_id", "r")
  if not f then return nil end
  local id = f:read("*l")
  f:close()
  return id and id:gsub("%s+", "") or nil
end
local id = device_id()
if not id then gg.alert("تعذر قراءة معرّف الجهاز"); return end
local users = request("users.txt")
if not users then return end
local allowed = false
for line in users:gmatch("[^\r\n]+") do
  if line:match("^%s*(.-)%s*$") == id then allowed = true; break end
end
if not allowed then
  gg.copyText(id)
  gg.alert("الجهاز غير مصرح له. تم نسخ المعرّف: " .. id)
  return
end
local encrypted = request("script_encrypted.txt")
if not encrypted then return end
if #encrypted % 2 ~= 0 or encrypted:find("[^%x]") then
  gg.alert("صيغة السكربت المشفر غير صحيحة")
  return
end
local parts = {}
for i = 1, #encrypted, 2 do
  parts[#parts+1] = string.char((tonumber(encrypted:sub(i,i+1),16) ~ 117))
end
local source = table.concat(parts)
local compile = loadstring or load
local chunk, err = compile(source)
if not chunk then gg.alert("خطأ في السكربت: " .. tostring(err)); return end
local ok, runerr = pcall(chunk)
if not ok then gg.alert("فشل التنفيذ: " .. tostring(runerr)) end
