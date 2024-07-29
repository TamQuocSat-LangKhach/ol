local extension = Package("ol_sp4")
extension.extensionName = "ol"
local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_sp4"] = "OL专属4",
}

local mawan = General(extension, "mawan", "qun", 4)
Fk:loadTranslationTable{
  ["mawan"] = "马玩",
  ["#mawan"] = "驱率羌胡",
  ["designer:mawan"] = "大宝",
  ["~mawan"] = "",
}

mawan:addSkill("mashu")

local hunjiang = fk.CreateActiveSkill{
  name = "hunjiang",
  anim_type = "offensive",
  prompt = "#hunjiang-active",
  min_target_num = 1,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return Self:inMyAttackRange(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.simpleClone(effect.tos)
    room:sortPlayersByAction(targets)
    targets = table.map(targets, function(pId) return room:getPlayerById(pId) end)
    for _, p in ipairs(targets) do
      local choices = { "hunjiang_extra_target:" .. player.id, "hunjiang_draw::" .. player.id }
      p.request_data = json.encode({
        choices,
        choices,
        self.name,
        "#hunjiang-others_choose",
      })
    end
    room:notifyMoveFocus(targets, self.name)
    room:doBroadcastRequest("AskForChoice", targets)

    local firstChosen
    for _, p in ipairs(targets) do
      local choice
      if p.reply_ready then
        choice = p.client_reply
      else
        choice = "hunjiang_extra_target:" .. player.id
      end

      if firstChosen == nil then
        firstChosen = choice
      elseif firstChosen ~= choice then
        firstChosen = false
      end

      if choice:startsWith("hunjiang_extra_target") then
        local hunjiangUsers = U.getMark(p, "@@hunjiang-phase")
        table.insertIfNeed(hunjiangUsers, player.id)
        room:setPlayerMark(p, "@@hunjiang-phase", hunjiangUsers)
      else
        player:drawCards(1, self.name)
      end
    end

    if firstChosen then
      for _, p in ipairs(targets) do
        if firstChosen:startsWith("hunjiang_extra_target") then
          player:drawCards(1, self.name)
        else
          local hunjiangUsers = U.getMark(p, "@@hunjiang-phase")
          table.insertIfNeed(hunjiangUsers, player.id)
          room:setPlayerMark(p, "@@hunjiang-phase", hunjiangUsers)
        end
      end
    end
  end,
}
local hunjiangTarget = fk.CreateTriggerSkill{
  name = "#hunjiang_target",
  events = {fk.AfterCardTargetDeclared},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    return
      target == player and
      data.card.trueName == "slash" and
      table.find(
        room.alive_players,
        function(p)
          return
            table.contains(U.getMark(p, "@@hunjiang-phase"), player.id) and
            not table.contains(TargetGroup:getRealTargets(data.tos), p.id) and
            U.canUseCardTo(room, player, p, data.card, true)
        end
      )
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(
      room.alive_players,
      function(p)
        return
          table.contains(U.getMark(p, "@@hunjiang-phase"), player.id) and
          not table.contains(TargetGroup:getRealTargets(data.tos), p.id) and
          U.canUseCardTo(room, player, p, data.card, true)
      end
    )

    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, #targets, "#hunjiang-choose", self.name)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    for _, pId in ipairs(self.cost_data) do
      TargetGroup:pushTargets(data.tos, pId)
    end

    player.room:sendLog{
      type = "#AddTargetsBySkill",
      from = player.id,
      to = self.cost_data,
      arg = "hunjiang",
      arg2 = data.card:toLogString()
    }
  end,
}
Fk:loadTranslationTable{
  ["hunjiang"] = "浑疆",
  [":hunjiang"] = "出牌阶段限一次，你可以令攻击范围内至少一名角色同时选择一项：1.令你于本阶段内使用【杀】可指定其为额外目标；" ..
  "2.令你摸一张牌。若这些角色均选择同一项，则依次执行另一项。",
  ["#hunjiang-active"] = "浑疆：令任意角色选择你可以使用【杀】额外指定其为目标或令你摸牌",
  ["#hunjiang_target"] = "浑疆",
  ["@@hunjiang-phase"] = "浑疆",
  ["hunjiang_extra_target"] = "本阶段 %src 使用【杀】可指定你为额外目标",
  ["hunjiang_draw"] = "令 %dest 摸一张牌",
  ["#hunjiang-others_choose"] = "浑疆：请选择一项，若你与其他目标均选择同一项，则你执行另一项",
  ["#hunjiang-choose"] = "浑疆：你可选择其中至少一名角色成为此【杀】的额外目标",
}

hunjiang:addRelatedSkill(hunjiangTarget)
mawan:addSkill(hunjiang)

local budugen = General(extension, "budugen", "qun", 4)
local kouchao = fk.CreateViewAsSkill{
  name = "kouchao",
  prompt = "#kouchao-viewas",
  pattern = ".",
  interaction = function()
    local all_names = U.getMark(Self, "@$kouchao")
    local names = {}
    for i = 1, 3, 1 do
      local card_name = all_names[i]
      all_names[i] = "kouchao_index:::"..i..":"..card_name
      if Self:getMark("kouchao"..i.."-round") == 0 then
        if Fk.currentResponsePattern == nil or Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard(card_name)) then
          table.insert(names, all_names[i])
        end
      end
    end
    if #names > 0 then
      return UI.ComboBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and self.interaction.data
  end,
  view_as = function(self, cards)
    if #cards == 0 or not self.interaction.data then return end
    local card = Fk:cloneCard(string.split(self.interaction.data, ":")[5])
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    player.room:setPlayerMark(player, "kouchao"..string.split(self.interaction.data, ":")[4].."-round", 1)
  end,
  after_use = function(self, player, use)
    local room = player.room
    local name = ""
    U.getEventsByRule(room, GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId, true)
            if card.type == Card.TypeBasic or card:isCommonTrick() then
              name = card.name
              return true
            end
          end
        end
      end
    end, 0)
    if name ~= "" then
      local mark = U.getMark(player, "@$kouchao")
      mark[tonumber(string.split(self.interaction.data, ":")[4])] = name
      if table.every(mark, function(str)
        return Fk:cloneCard(str).type == Card.TypeBasic
      end) then
        mark = {"snatch", "snatch", "snatch"}
      end
      room:setPlayerMark(player, "@$kouchao", mark)
    end
  end,
  enabled_at_response = function(self, player, resp)
    if not resp and not player:isNude() and Fk.currentResponsePattern then
      local mark = U.getMark(Self, "@$kouchao")
      for i = 1, 3, 1 do
        if player:getMark("kouchao"..i.."-round") == 0 then
          if Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard(mark[i])) then
            return true
          end
        end
      end
    end
  end,
}
local kouchao_trigger = fk.CreateTriggerSkill{
  name = "#kouchao_trigger",

  refresh_events = {fk.EventLoseSkill, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    return target == player and data == kouchao
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventAcquireSkill then
      room:setPlayerMark(player, "kouchao1", "slash")
      room:setPlayerMark(player, "kouchao2", "fire_attack")
      room:setPlayerMark(player, "kouchao3", "dismantlement")
      room:setPlayerMark(player, "@$kouchao", {"slash", "fire_attack", "dismantlement"})
    else
      room:setPlayerMark(player, "kouchao1", 0)
      room:setPlayerMark(player, "kouchao2", 0)
      room:setPlayerMark(player, "kouchao3", 0)
      room:setPlayerMark(player, "@$kouchao", 0)
    end
  end,
}
kouchao:addRelatedSkill(kouchao_trigger)
budugen:addSkill(kouchao)
Fk:loadTranslationTable{
  ["budugen"] = "步度根",
  ["#budugen"] = "秋城雁阵",

  ["kouchao"] = "寇钞",
  [":kouchao"] = "每轮每项限一次，你可以将一张牌当【杀】/【火攻】/【过河拆桥】使用，然后将此项改为最后不因使用而置入弃牌堆的基本牌或普通锦囊牌，" ..
  "然后若所有项均为基本牌，将所有项改为【顺手牵羊】。",
  ["#kouchao-viewas"] = "寇钞：将一张牌当一种“寇钞”牌使用，每轮每项限一次",
  ["@$kouchao"] = "寇钞",
  ["kouchao_index"] = "[%arg] "..Fk:translate("%arg2"),

  ["~budugen"] = "",
}

local caoteng = General(extension, "caoteng", "qun", 3)
local function DoYongzu(player, choices, all_choices)
  local room = player.room
  local choice = room:askForChoice(player, choices, "yongzu", "#yongzu-choice", false, all_choices)
  if choice == "draw2" then
    player:drawCards(2, "yongzu")
  elseif choice == "recover" then
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = "yongzu",
    })
  elseif choice == "reset" then
    player:reset()
  elseif choice == "maxcards1" then
    room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
    room:broadcastProperty(player, "MaxCards")
  else
    local skill = string.sub(choice, 16)
    if not player:hasSkill(skill, true) then
      room:setPlayerMark(player, "yongzu", skill)
      room:handleAddLoseSkills(player, skill, nil, true, false)
    end
  end
  return choice
end
local yongzu = fk.CreateTriggerSkill{
  name = "yongzu",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and #player.room.alive_players > 1
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1,
      "#yongzu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local all_choices = {"draw2", "recover", "reset"}
    if player.kingdom == to.kingdom then
      local prompt = "yongzu_skill:::"
      if player.kingdom == "wei" then
        prompt = prompt.."ex__jianxiong"
      elseif player.kingdom == "qun" then
        prompt = prompt.."tianming"
      else
        prompt = prompt.."skill"
      end
      table.insertTable(all_choices, {"maxcards1", prompt})
    end
    local choices = table.simpleClone(all_choices)
    if not player:isWounded() then
      table.remove(choices, 2)
    end
    if #all_choices == 5 and player.kingdom ~= "wei" and player.kingdom ~= "qun" then
      table.remove(choices, -1)
    end
    local choice = DoYongzu(player, choices, all_choices)
    if to.dead then return end
    if choices[2] ~= "recover" and to:isWounded() then
      table.insert(choices, 2, "recover")
    end
    table.removeOne(choices, choice)
    DoYongzu(to, choices, all_choices)
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(self.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local skill = player:getMark(self.name)
    room:setPlayerMark(player, self.name, 0)
    room:handleAddLoseSkills(player, "-"..skill, nil, true, false)
  end,
}
local qingliu = fk.CreateTriggerSkill{
  name = "qingliu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.AfterDying},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif event == fk.AfterDying then
        return target == player and #player.room.logic:getEventsOfScope(GameEvent.Dying, 2, function(e)
          return e.data[1].who == player.id
        end, Player.HistoryGame) == 1
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local kingdoms = {"qun", "wei"}
    if event == fk.AfterDying then
      table.removeOne(kingdoms, player.kingdom)
    end
    local kingdom = room:askForChoice(player, kingdoms, self.name, "AskForKingdom")
    if kingdom ~= player.kingdom then
      room:changeKingdom(player, kingdom, true)
    end
  end,
}
caoteng:addSkill(yongzu)
caoteng:addSkill(qingliu)
caoteng:addRelatedSkill("ex__jianxiong")
caoteng:addRelatedSkill("tianming")
Fk:loadTranslationTable{
  ["caoteng"] = "曹腾",
  ["#caoteng"] = "魏高帝",

  ["yongzu"] = "拥族",
  [":yongzu"] = "准备阶段，你可以选择一名其他角色，你与其依次选择不同的一项：<br>1.摸两张牌；<br>2.回复1点体力；<br>3.复原武将牌。<br>"..
  "若选择的角色与你势力相同，则增加选项：<br>4.手牌上限+1；<br>5.根据势力获得技能直到下回合开始：<br>"..
  "<font color=\"blue\">魏〖奸雄〗</font><font color=\"grey\">群〖天命〗</font>。",
  ["qingliu"] = "清流",
  [":qingliu"] = "锁定技，游戏开始时，你选择变为群或魏势力。你首次脱离濒死状态被救回后，你变更为另一个势力。",

  ["#yongzu-choose"] = "拥族：你可以选择一名角色，与其依次执行一项（若双方势力相同则增加选项）",
  ["yongzu_skill"] = "获得%arg",
  ["#yongzu-choice"] = "拥族：选择执行的一项",
  ["skill"] = "技能",  --很难想象这个居然没有翻译
  ["reset"] = "复原武将牌",  --很难想象这个居然没有翻译×2
  ["maxcards1"] = "手牌上限+1",  --这个感觉可以有翻译

  ["$yongzu1"] = "既拜我为父，咱家当视汝为骨肉。",
  ["$yongzu2"] = "天地君亲师，此五者最须尊崇。",
  ["$qingliu1"] = "谁说这宦官，皆是大奸大恶之人？",
  ["$qingliu2"] = "咱家要让这天下人知道，宦亦有贤。",
  ["$ex__jianxiong_caoteng"] = "躬行禁闱，不敢争一时之气。",
  ["$tianming_caoteng"] = "天命在彼，事莫强为。",
  ["~caoteng"] = "种暠害我，望陛下明鉴！",
}

local sunru = General(extension, "ol__sunru", "wu", 3, 3, General.Female)
local chishi = fk.CreateTriggerSkill{
  name = "chishi",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
      and player.room.current and not player.room.current.dead then
      for _, move in ipairs(data) do
        if move.from and move.from == player.room.current.id then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand and player.room.current:isKongcheng()) or
              (info.fromArea == Card.PlayerEquip and #player.room.current:getCardIds("e") == 0) or
              (info.fromArea == Card.PlayerJudge and #player.room.current:getCardIds("j") == 0) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#chishi-invoke::"..player.room.current.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {room.current.id})
    room:addPlayerMark(room.current, MarkEnum.AddMaxCardsInTurn, 2)
    room.current:drawCards(2, self.name)
  end,
}
local weimian = fk.CreateActiveSkill{
  name = "weimian",
  anim_type = "support",
  card_num = 0,
  target_num = 0,
  prompt = "#weimian",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      #player:getAvailableEquipSlots() > 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local choice = room:askForChoices(player, player:getAvailableEquipSlots(), 1, 3, self.name, "#weimian-abort", false)
    room:abortPlayerArea(player, choice)
    if player.dead then return end
    local n = #choice
    local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1,
      "#weimian-choose:::"..n, self.name, false)
    to = room:getPlayerById(to[1])
    local selected = {}
    for i = 1, n, 1 do
      if to.dead then return end
      local choices = {}
      if #to.sealedSlots > 0 and not table.contains(selected, "weimian1") then
        table.insert(choices, "weimian1")
      end
      if to:isWounded() and not table.contains(selected, "recover") then
        table.insert(choices, "recover")
      end
      if not table.contains(selected, "weimian3") then
        --假设可以不弃手牌
        table.insert(choices, "weimian3")
      end
      table.insert(choices, "Cancel")
      if #choices == 0 then return end
      choice = room:askForChoice(to, choices, self.name, nil, false, {"weimian1", "recover", "weimian3", "Cancel"})
      if choice == "Cancel" then return end
      table.insert(selected, choice)
      if choice == "weimian1" then
        local slots = table.simpleClone(to.sealedSlots)
        table.removeOne(slots, Player.JudgeSlot)
        local weimian_resume = room:askForChoice(player, slots, self.name, "#weimian-resume")
        room:resumePlayerArea(player, {weimian_resume})
      elseif choice == "recover" then
        room:recover{
          who = to,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      elseif choice == "weimian3" then
        to:throwAllCards("h")
        if not to.dead then
          to:drawCards(4, self.name)
        end
      end
    end
  end,
}
sunru:addSkill(chishi)
sunru:addSkill(weimian)
Fk:loadTranslationTable{
  ["ol__sunru"] = "孙茹",
  ["#ol__sunru"] = "",

  ["chishi"] = "持室",
  [":chishi"] = "每回合限一次，当前回合角色失去其一个区域内最后一张牌后，你可以令其摸两张牌且本回合手牌上限+2。",
  ["weimian"] = "慰勉",
  [":weimian"] = "出牌阶段限一次，你可以废除至多三个装备栏，然后令一名角色选择等量项：1.恢复一个被废除的装备栏；2.回复1点体力；"..
  "3.弃置所有手牌，摸四张牌。",
  ["#chishi-invoke"] = "持室：是否令 %dest 摸两张牌且本回合手牌上限+2？",
  ["#weimian"] = "慰勉：废除至多三个装备栏，令一名角色执行等量效果",
  ["#weimian-abort"] = "慰勉：请选择要废除的至多三个装备栏",
  ["#weimian-choose"] = "慰勉：选择一名角色执行%arg项效果",
  ["weimian1"] = "恢复一个装备栏",
  ["weimian3"] = "弃置所有手牌，摸四张牌",
  ["#weimian-resume"] = "慰勉：选择要恢复的装备栏",
}

return extension
