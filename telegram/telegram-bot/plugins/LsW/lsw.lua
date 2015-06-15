do

local function getText(attempt, topic)
  local url = "http://api.linux-statt-windows.org/infos.json"
  local version = "0.1.3"
  local dev_url = "http://git.io/vLI6T"
  local output = ""

  -- Get the data
  attempt = attempt or 0
  attempt = attempt + 1

  local res,status = http.request(url)

  if status ~= 200 then return nil end
  local data = json:decode(res)[1]

  if not data and attempt < 10 then
    print('FEHLER: die Informationen sind momentan nicht verfügbar!')
    return getText(attempt, topic)
  end

  -- Handle the data
  if topic == "!lsw" then
    output = data.forum.name .. ': ' ..data.forum.long_url
  elseif topic == "Thema" then
    output = 'Thema des Monats ' .. data.topic_month.month .. ' ist: \n' .. data.topic_month.name .. '\n\n' .. data.topic_month.url
  elseif topic == "Distro" then
    output = 'Distro des Monats ' .. data.distro_month.month .. ' ist: \n' .. data.distro_month.name .. '\n\n' .. data.distro_month.url
  elseif topic == "Mumble" then
    output = 'Der LsW Mumble Server: ' .. data.mumble.url .. ':' .. data.mumble.port ..'\n' .. data.mumble.direct_url
  elseif topic == "FAQ" or topic == "faq" then
    output = data.faq.name .. '\n' .. data.faq.url
  elseif topic == "Facebook" or topic == "fb" then
    output = 'Facebook Gruppe: ' .. data.fb.group_url .. '\n\n Facebook Seite: ' .. data.fb.site_url
  elseif topic == "v" or topic == "Version" then
    output = 'LsW Telegram-Bot Plugin ' .. version .. '\n Projekt: ' .. dev_url .. '\n Lizenz: GNU GPL v2'
  else
    output = 'Das Argument war falsch! Benutze "!help lsw".'
  end

  return output
end

local function run(msg, matches)
  return getText(0, matches[1])
end

return {
  description = "Bekomme Informationen zu Linux statt Windows.",
  usage = {
    "!lsw: Bekomme den Link zu unserer Homepage.",
    "!lsw Thema: Finde heraus, was das aktuelle Thema des Monats ist.",
    "!lsw Distro: Finde heraus, welches die aktuelle Distro des Monats ist.",
    "!lsw Mumble: Bekomme Infos über unsereren Mumble Server.",
    "!lsw FAQ: Sie unsere Antworten auf beliebte Fragen.",
    "!lsw Facebook: Bekomme die Links zu unserer Facebook Gruppe und Seite.",
    "!lsw Version: Bekomme Infos über das Plugin selbst."
  },
  patterns = {
    "^!lsw$",
    "^!lsw (Thema)$",       -- Thema
    "^!lsw (Distro)$",      -- Distro
    "^!lsw (Mumble)$",      -- Mumble
    "^!lsw (FAQ)$",         -- FAQ
    "^!lsw (faq)$",         -- faq
    "^!lsw (Facebook)$",    -- Facebook (lang)
    "^!lsw (fb)$",          -- Facebook (kurz)
    "^!lsw (Version)$",     -- Version (lang)
    "^!lsw (v)$"            -- Version (kurz)
  },
  run = run
}

end
