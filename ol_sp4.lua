local extension = Package("ol_sp4")
extension.extensionName = "ol"
local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_sp4"] = "OL专属4",
}

local mawan = General(extension, "mawan", "qun", 4)
local hunjiang = fk.CreateActiveSkill{
  name = "hunjiang",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 999,
  prompt = "#hunjiang-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return Self:inMyAttackRange(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    local targets = table.map(effect.tos, function(id) return room:getPlayerById(id) end)
    for _, p in ipairs(targets) do
      local choices = {"hunjiang1", "hunjiang2"}
      p.request_data = json.encode({choices, choices, self.name, "#hunjiang-choice:"..player.id})
    end
    room:notifyMoveFocus(room.alive_players, self.name)
    room:doBroadcastRequest("AskForChoice", targets)

    for _, p in ipairs(targets) do
      if not p.reply_ready then
        p.client_reply = "hunjiang2"
      end
    end

    local n = 0
    for _, p in ipairs(targets) do
      local choice = p.client_reply
      if choice == "hunjiang1" then
        room:setPlayerMark(p, "@@hunjiang-phase", 1)
      else
        n = n + 1
      end
    end
    if n == #targets then
      for _, p in ipairs(targets) do
        room:setPlayerMark(p, "@@hunjiang-phase", 1)
      end
    end
    if n > 0 then
      player:drawCards(n, self.name)
    else
      player:drawCards(#targets, self.name)
    end
  end,
}
local hunjiang_trigger = fk.CreateTriggerSkill{
  name = "#hunjiang_trigger",
  mute = true,
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("hunjiang", Player.HistoryPhase) > 0 and data.card.trueName == "slash" and
      table.find(player.room:getOtherPlayers(player), function(p)
        return p:getMark("@@hunjiang-phase") > 0 and table.contains(U.getUseExtraTargets(player.room, data, true), p.id) end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(
      table.filter(room:getOtherPlayers(player), function(p)
        return p:getMark("@@hunjiang-phase") > 0 and table.contains(U.getUseExtraTargets(room, data, true), p.id)
      end),
    Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, #targets, "#hunjiang-choose:::"..data.card:toLogString(), "hunjiang", true)
    if #tos > 0 then
      for _, pid in ipairs(tos) do
        table.insert(data.tos, {pid})
      end
      room:sendLog{
        type = "#AddTargetsBySkill",
        from = player.id,
        to = tos,
        arg = "hunjiang",
        arg2 = data.card:toLogString()
      }
    end
  end,
}
hunjiang:addRelatedSkill(hunjiang_trigger)
mawan:addSkill("mashu")
mawan:addSkill(hunjiang)
Fk:loadTranslationTable{
  ["mawan"] = "马玩",
  --["#mawan"] = "",
  --["designer:mawan"] = "",
  --["illustrator:mawan"] = "",

  ["hunjiang"] = "浑疆",
  [":hunjiang"] = "出牌阶段限一次，你可以令攻击范围内任意名其他角色同时选择一项：1.令你本阶段使用【杀】可以指定其为额外目标；2.令你摸一张牌。"..
  "若这些角色均选择了同一项，也须执行另一项。",
  ["#hunjiang-active"] = "浑疆：令任意角色选择你可以使用【杀】额外指定其为目标或令你摸牌",
  ["@@hunjiang-phase"] = "浑疆",
  ["hunjiang1"] = "你成为【杀】的额外目标",
  ["hunjiang2"] = "其摸一张牌",
  ["#hunjiang-choice"] = "浑疆：%src 令你选择一项",
  ["#hunjiang-choose"] = "浑疆：你可以为%arg额外指定任意有“浑疆”标记的角色为目标",
}


return extension
