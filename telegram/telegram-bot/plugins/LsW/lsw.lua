do

-- Hole Infos zum Thema des Monats
local function getDistro(url, attempt)
  attempt = attempt or 0
  attempt = attempt + 1

  local res,status = http.request(url)

  if status ~= 200 then return nil end
  local data = json:decode(res)[1]

  if not data and attempt < 10 then
    print('FEHLER: die Informationen sind momentan nicht verfügbar!')
    return getDistro(url, attempt)
  end

  return 'Distro des Monats ' .. data.distro_month.month .. ' ist: \n' .. data.distro_month.name .. '\n' .. data.distro_month.url
end

-- Hole Infos zum Thema des Monats
local function getTopic(url, attempt)
  attempt = attempt or 0
  attempt = attempt + 1

  local res,status = http.request(url)

  if status ~= 200 then return nil end
  local data = json:decode(res)[1]

  if not data and attempt < 10 then
    print('FEHLER: die Informationen sind momentan nicht verfügbar!')
    return getTopic(url, attempt)
  end

  return 'Thema des Monats ' .. data.topic_month.month .. ' ist: \n' .. data.topic_month.name .. '\n\n' .. data.topic_month.url
end

-- Hole Infos zu unserem Mumble Server
local function getMumble(url, attempt)
  attempt = attempt or 0
  attempt = attempt + 1

  local res,status = http.request(url)

  if status ~= 200 then return nil end
  local data = json:decode(res)[1]

  if not data and attempt < 10 then
    print('FEHLER: die Informationen sind momentan nicht verfügbar!')
    return getTopic(url, attempt)
  end

  return 'Der LsW Mumble Server: ' .. data.mumble.url .. ':' .. data.mumble.port ..'\n' .. data.mumble.direct_url
end

-- Hole Infos zu LsW
local function getLsW(url, attempt)
  attempt = attempt or 0
  attempt = attempt + 1

  local res,status = http.request(url)

  if status ~= 200 then return nil end
  local data = json:decode(res)[1]

  if not data and attempt < 10 then
    print('FEHLER: die Informationen sind momentan nicht verfügbar!')
    return getLsW(url, attempt)
  end

  return data.forum.name .. ': ' ..data.forum.long_url
end

local function run(msg, matches)
  local url = "http://api.linux-statt-windows.org/infos.json"
  local version = "0.1.2"

  if matches[1] == "!lsw" then
    return getLsW(url, 0)
  elseif matches[1] == "Thema" then
    return getTopic(url, 0)
  elseif matches[1] == "Distro" then
    return getDistro(url, 0)
  elseif matches[1] == "Mumble" then
    return getMumble(url, 0)
  elseif matches[1] == "v" or matches[1] == "Version" then
    return 'LsW Telegram-Bot Plugin \n Version: ' .. version
  else
    return 'Das Argument war falsch! Benutze "!help lsw".'
  end
end

return {
  description = "Bekomme Informationen zu Linux statt Windows.",
  usage = {
    "!lsw: Bekomme den Link zu unserer Homepage.",
    "!lsw Thema: Finde heraus, was das aktuelle Thema des Monats ist.",
    "!lsw Distro: Finde heraus, welches die aktuelle Distro des Monats ist.",
    "!lsw Mumble: Bekomme Infos über unsereren Mumble Server.",
    "!lsw Version: Bekomme Infos über das Plugin selbst."
  },
  patterns = {
    "^!lsw$",
    "^!lsw (Thema)$",       -- Thema
    "^!lsw (Distro)$",      -- Distro
    "^!lsw (Mumble)$",      -- Mumble
    "^!lsw (Version)$",     -- Version (lang)
    "^!lsw (v)$"            -- Version (kurz)
  },
  run = run
}

end