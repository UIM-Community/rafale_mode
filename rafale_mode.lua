
-------------------------------------------
-- Extract rafal parameters from the alarm message
-------------------------------------------
function getRafale(text)
    local firstSplit = split(text, "]")
    local secondSplit = split(firstSplit[#firstSplit], "[")
    if secondSplit[2] == nil then
      return split(split(firstSplit [#firstSplit - 1], "[")[2],",")
    end
  return split(secondSplit[2],",")
end

-- Chunk optimization (processing up to 10%+ over memory)
al  = alarm
db  = database
bus = nimbus
act = action

-- Get alarm
a = al.get()

if a ~= nil then
  rafale = getRafale(a.message)

  -- Reprend les parametres de la rafale entre crochet
  local scope = rafale[1]
  local occur = rafale[2]
  local level = rafale[3]
  local intsc = tonumber(scope)
  local intts = a.nimts - intsc

  -- Retire la rafale
  local msgSplit = split(a.message,"[")
  local tmpmsg = ""
  for i = 1, #msgSplit-1 do
    tmpmsg = tostring(tmpmsg) .. tostring(msgSplit[i])
  end

  -- permet de remplacer les apostrophe par une double pipe (le SQLite ne support pas : ' )
  local newmsg = string.gsub(tmpmsg, "'" , "||")
  if a.supp_key ~= nil and a.subsys ~= nil then
    db.open("rafale-mode.db")
    local result
    do
      local select = "SELECT * FROM events WHERE source='".. a.source .."' and suppkey='".. a.supp_key .."' and sid='".. a.sid .."' and nimts>='".. intts .."'"
      result = db.query(select)
    end
    if result ~= nil then
      -- si le nombre de résultat identique dans la base de donnée est supérieur au nombre d'occurence de la rafale
      -- on lance une alarme via nimalame.exe en commande et on supprime les résultat identique en base.
      -- sinon on ajoute l'alarme en base
      if #result>=tonumber(occur) then

        -- Récupération du robotname dans la base de donnée
        local hostname
        for k, v in pairs(result[1]) do
          if tostring(k) == "hostname" then
            hostname = tostring(v)
            break
          end
        end
        local alarme = "nimalarm.exe -i -l ".. level .." -S ".. a.source .." \"".. tmpmsg .." - nb: ".. #result ..">=" ..occur.. " in "..scope.."sec.\""
        local temp,rc = act.command(alarme)
        
        -- if nimAlarm return NimOK we delete the entry in the database!
        if temp ~= nil and rc == 0 then
          local delete = "DELETE FROM events WHERE source='".. a.source .."' AND suppkey='".. a.supp_key .."' AND sid='".. a.sid .."'"
          db.query(delete)
          act.close(a.nimid)
        else
          bus.alarm(level,"Message d'Alarme pour indiquer que le code a planté")
        end
        else
          do
            local insert = "INSERT INTO events(nimid,nimts,source,hostname,origin,sid,message,scope,occur,level,suppkey) "
            local values = "VALUES ('".. a.nimid .."','".. a.nimts .."','".. a.source .."','".. a.hostname .."','".. a.origin .."','".. a.sid .."','".. newmsg .."','".. scope .."','".. occur .."','".. level .."','"..a.supp_key.."')"
            db.query (insert..values)
          end
          act.close(a.nimid)
          local delete = "DELETE FROM events WHERE source='".. a.source .."' and suppkey='".. a.supp_key .."' and sid='".. a.sid .."' and nimts<'".. intts .."'"
          db.query(delete)
      end
    else
      local insert = "INSERT INTO events(nimid,nimts,source,hostname,origin,sid,message,scope,occur,level,suppkey) "
      local values = "VALUES ('".. a.nimid .."','".. a.nimts .."','".. a.source .."','".. a.hostname .."','".. a.origin .."','".. a.sid .."','".. newmsg .."','".. scope .."','".. occur .."','".. level .."','"..a.supp_key.."')"
      db.query (insert..values)
      act.close(a.nimid)
    end
    db.close()
  else
    -- If we have no supp_key or subsystem_id(number)
    local alarme = "nimalarm.exe -i -l ".. level .." -S ".. a.source .." \"don't find supp_key or sid : ".. a.message.." \""
    act.command(alarme)
  end
end
