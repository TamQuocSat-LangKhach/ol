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
      if #to.sealedSlots > 0 and table.find(to.sealedSlots, function (slot)
        return slot ~= Player.JudgeSlot
      end) and not table.contains(selected, "weimian1") then
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
  ["#ol__sunru"] = "淑慎温良",

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

  ["$chishi1"] = "柴米油盐之细，不逊兵家之谋。",
  ["$chishi2"] = "治大家如烹小鲜，须面面俱到。",
  ["$weimian1"] = "不过二三小事，夫君何须烦恼。",
  ["$weimian2"] = "宦海疾风大浪，家为避风之塘。",
  ["~ol__sunru"] = "从来无情者，皆出帝王家……",
}

local kebineng = General(extension, "ol__kebineng", "qun", 4)
local pingduan = fk.CreateActiveSkill{
  name = "pingduan",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#pingduan",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local all_names = U.getAllCardNames("b")
    local names = table.filter(all_names, function (name)
      local card = Fk:cloneCard(name)
      return target:canUse(card, {bypass_times = true}) and not target:prohibitUse(card)
    end)
    local use = room:askForUseCard(target, self.name, table.concat(names, ","), "#pingduan-use", true, {bypass_times = true})
    if use then
      use.extraUse = true
      room:useCard(use)
      if not target.dead then
        target:drawCards(1, self.name)
      else
        return
      end
    end
    if target:isNude() then return end
    local card = room:askForCard(target, 1, 1, false, self.name, true, ".|.|.|.|.|trick", "#pingduan-recast")
    if #card > 0 then
      room:recastCard(card, target, self.name)
      if not target.dead then
        target:drawCards(1, self.name)
      else
        return
      end
    end
    if player.dead or #target:getCardIds("e") == 0 then return end
    if room:askForSkillInvoke(target, self.name, nil, "#pingduan-equip:"..player.id) then
      card = room:askForCardChosen(player, target, "e", self.name, "#pingduan-prey::"..target.id)
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
      if not target.dead then
        target:drawCards(1, self.name)
      end
    end
  end,
}
kebineng:addSkill(pingduan)
Fk:loadTranslationTable{
  ["ol__kebineng"] = "轲比能",
  ["#ol__kebineng"] = "",

  ["pingduan"] = "平端",
  [":pingduan"] = "出牌阶段限一次，你可以令一名角色依次执行：1.使用一张基本牌；2.重铸一张锦囊牌；3.令你获得其装备区一张牌。其每执行一项"..
  "便摸一张牌。",
  ["#pingduan"] = "平端：令一名角色依次执行选项，其每执行一项摸一张牌",
  ["#pingduan-use"] = "平端：你可以使用一张基本牌，摸一张牌",
  ["#pingduan-recast"] = "平端：你可以重铸一张锦囊牌，摸一张牌",
  ["#pingduan-equip"] = "平端：你可以令 %src 获得你装备区一张牌，你摸一张牌",
  ["#pingduan-prey"] = "平端：获得 %dest 装备区一张牌",
}

local yuanji = General(extension, "ol__yuanji", "wu", 3, 3, General.Female)
local jieyan = fk.CreateTriggerSkill{
  name = "jieyan",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1,
      "#jieyan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:damage({
      from = player,
      to = to,
      damage = 1,
      skillName = self.name,
    })
    if to.dead then return end
    local choice = room:askForChoice(to, {"jieyan1", "jieyan2"}, self.name)
    room:setPlayerMark(to, "@@"..choice, 1)
    if choice == "jieyan2" then
      if to:isWounded() then
        room:recover{
          who = to,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      end
      if not player.dead and not to.dead then
        local mark = U.getMark(player, self.name)
        table.insertIfNeed(mark, to.id)
        room:setPlayerMark(player, self.name, mark)
      end
    end
  end,

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Discard and player:getMark("@@jieyan1") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@jieyan1", 0)
    player:skip(Player.Discard)
  end,
}
local jieyan_delay = fk.CreateTriggerSkill{
  name = "#jieyan_delay",
  mute = true,
  events = {fk.EventPhaseChanging, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseChanging then
      return target == player and data.to == Player.Discard and player:getMark("@@jieyan1") > 0
    elseif target.phase == Player.Discard then
      if target == player then
        return player:getMark("@@jieyan2") > 0
      else
        return table.contains(U.getMark(player, "jieyan"), target.id)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseChanging then
      room:setPlayerMark(player, "@@jieyan1", 0)
      return true
    else
      if target == player then
        room:setPlayerMark(player, "@@jieyan2", 0)
      else
        local mark = U.getMark(player, "jieyan")
        table.removeOne(mark, target.id)
        room:setPlayerMark(player, "jieyan", mark)
        local cards = {}
        local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase, true)
        if phase_event ~= nil then
          local end_id = phase_event.id
          U.getEventsByRule(room, GameEvent.MoveCards, 1, function (e)
            for _, move in ipairs(e.data) do
              if move.from == target.id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
                for _, info in ipairs(move.moveInfo) do
                  if room:getCardArea(info.cardId) == Card.DiscardPile then
                    table.insertIfNeed(cards, info.cardId)
                  end
                end
              end
            end
            return false
          end, end_id)
          if #cards > 0 then
            player:broadcastSkillInvoke("jieyan")
            room:notifySkillInvoked(player, "jieyan", "support")
            local choice = U.askforViewCardsAndChoice(player, cards, {"OK", "Cancel"}, "jieyan", "#jieyan-choice")
            if choice == "OK" then
              local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(target), Util.IdMapper), 1, 1,
                "#jieyan-give", "jieyan", false)
              to = room:getPlayerById(to[1])
              room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, "jieyan", nil, true, player.id)
            end
          end
        end
      end
    end
  end,
}
local jieyan_maxcards = fk.CreateMaxCardsSkill{
  name = "#jieyan_maxcards",
  correct_func = function(self, player)
    if player:getMark("@@jieyan2") > 0 and player.phase == Player.Discard then
      return -2
    else
      return 0
    end
  end,
}
local jinghua = fk.CreateTriggerSkill{
  name = "jinghua",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      self.cost_data = 0
      for _, move in ipairs(data) do
        if move.from == player.id then
          if move.to and move.to ~= player.id and move.toArea == Card.PlayerHand and not player.room:getPlayerById(move.to).dead then
            if player:getMark("@@jinghua") > 0 or player.room:getPlayerById(move.to):isWounded() then
              self.cost_data = move.to
              return true
            end
          end
          if player:isKongcheng() and player:getMark("@@jinghua") == 0 then
            return true
          end
        end
        if move.skillName == "jieyan" and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand and
          not player.room:getPlayerById(move.to).dead then
          if player:getMark("@@jinghua") > 0 or player.room:getPlayerById(move.to):isWounded() then
            self.cost_data = move.to
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if self.cost_data ~= 0 then
      return true
    else
      return player.room:askForSkillInvoke(player, self.name, nil, "#jinghua-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if self.cost_data ~= 0 then
      room:doIndicate(player.id, {self.cost_data})
      if player:getMark("@@jinghua") == 0 then
        room:notifySkillInvoked(player, self.name, "support")
        room:recover({
          who = room:getPlayerById(self.cost_data),
          num = 1,
          recoverBy = player,
          skillName = self.name,
        })
      else
        room:notifySkillInvoked(player, self.name, "offensive")
        room:loseHp(room:getPlayerById(self.cost_data), 1, self.name)
      end
      if player:isKongcheng() and player:getMark("@@jinghua") == 0 then
        self.cost_data = 0
        self:trigger(event, target, player, data)
      end
    else
      room:notifySkillInvoked(player, self.name, "special")
      room:setPlayerMark(player, "@@jinghua", 1)
    end
  end,
}
local shuiyue = fk.CreateTriggerSkill{
  name = "shuiyue",
  events = {fk.Damaged, fk.EnterDying},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.Damaged then
        if target ~= player and data.from and data.from == player and not target.dead then
          if player:getMark("@@shuiyue") == 0 then
            return true
          else
            return not target:isNude()
          end
        end
      elseif event == fk.EnterDying and player:getMark("@@shuiyue") == 0 then
        return target ~= player and data.damage and data.damage.from and data.damage.from == player
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.Damaged then
      return true
    else
      return player.room:askForSkillInvoke(player, self.name, nil, "#shuiyue-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.Damaged then
      room:doIndicate(player.id, {target.id})
      if player:getMark("@@shuiyue") == 0 then
        room:notifySkillInvoked(player, self.name, "support")
        target:drawCards(1, self.name)
      else
        room:notifySkillInvoked(player, self.name, "control")
        room:askForDiscard(target, 1, 1, true, self.name, false)
      end
    else
      room:notifySkillInvoked(player, self.name, "special")
      room:setPlayerMark(player, "@@shuiyue", 1)
    end
  end,
}
jieyan:addRelatedSkill(jieyan_delay)
jieyan:addRelatedSkill(jieyan_maxcards)
yuanji:addSkill(jieyan)
yuanji:addSkill(jinghua)
yuanji:addSkill(shuiyue)
Fk:loadTranslationTable{
  ["ol__yuanji"] = "袁姬",
  ["#ol__yuanji"] = "",

  ["jieyan"] = "节言",
  [":jieyan"] = "准备阶段，你可以对一名角色造成1点伤害，然后其选择一项：1.跳过其下个弃牌阶段；2.回复1点体力，其下个弃牌阶段手牌上限-2，此阶段"..
  "结束时，你可以将其此阶段弃置的牌交给除其以外的一名角色。",
  ["jinghua"] = "镜花",
  [":jinghua"] = "其他角色获得你的牌或你发动〖节言〗交给其的牌后，其回复1点体力。当你失去最后一张手牌后，你可以将此技能的“回复”改为“失去”。",
  ["shuiyue"] = "水月",
  [":shuiyue"] = "其他角色受到你的伤害后，其摸一张牌。当你令其他角色进入濒死状态后，你可以将此技能的“摸”改为“弃”。",
  ["#jieyan-choose"] = "节言：对一名角色造成1点伤害，令其选择跳过下个弃牌阶段或回复体力",
  ["jieyan1"] = "跳过你下个弃牌阶段",
  ["jieyan2"] = "回复1点体力，下个弃牌阶段手牌上限-2，弃牌交给其他角色",
  ["@@jieyan1"] = "跳过弃牌",
  ["@@jieyan2"] = "节言",
  ["#jieyan_delay"] = "节言",
  ["#jieyan-choice"] = "节言：你可以将这些牌交给一名角色",
  ["#jieyan-give"] = "节言：选择获得这些牌的角色",
  ["@@jinghua"] = "镜花",
  ["#jinghua-invoke"] = "镜花：是否将本技能的“回复1点体力”改为“失去1点体力”？",
  ["@@shuiyue"] = "水月",
  ["#shuiyue-invoke"] = "水月：是否将本技能的“摸一张牌”改为“弃一张牌”？",
}

local kongshu = General(extension, "kongshu", "qun", 3, 3, General.Female)
local leiluan = fk.CreateViewAsSkill{
  name = "leiluan",
  pattern = ".|.|.|.|.|basic",
  prompt = function ()
    return "#leiluan:::"..math.max(Self:getMark("leiluan_count"), 1)
  end,
  interaction = function()
    local names = {}
    local mark = U.getMark(Self, "leiluan-round")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if ((Fk.currentResponsePattern == nil and Self:canUse(card)) or
      (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        if card.type == Card.TypeBasic and not table.contains(mark, card.trueName) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function (self, to_select, selected)
    return #selected < math.max(Self:getMark("leiluan_count"), 1)
  end,
  view_as = function(self, cards)
    if not self.interaction.data or #cards ~= math.max(Self:getMark("leiluan_count"), 1) then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
  before_use = function (self, player, use)
    player.room:setPlayerMark(player, "leiluan_use-turn", 1)
  end,
  enabled_at_play = function(self, player)
    return not player:isNude() and player:getMark("leiluan_use-turn") == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:isNude() and player:getMark("leiluan_use-turn") == 0
  end,
}
local leiluan_trigger = fk.CreateTriggerSkill{
  name = "#leiluan_trigger",
  mute = true,
  main_skill = leiluan,
  events = {fk.RoundEnd},
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(leiluan) then
      if #player.room.logic:getEventsOfScope(GameEvent.UseCard, 99, function(e)
        local use = e.data[1]
        return use.from == player.id and use.card.type == Card.TypeBasic
      end, Player.HistoryRound) >= math.max(player:getMark("leiluan_count"), 1) then
        return true
      elseif player:usedSkillTimes("leiluan", Player.HistoryRound) == 0 then
        player.room:setPlayerMark(player, "leiluan_count", 0)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, "leiluan") then
      return true
    end
    if player:usedSkillTimes("leiluan", Player.HistoryRound) == 0 then
      room:setPlayerMark(player, "leiluan_count", 0)
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = math.max(player:getMark("leiluan_count"), 1)
    if player:usedSkillTimes("leiluan", Player.HistoryRound) == 0 then
      room:addPlayerMark(player, "leiluan_count", 1)
    end
    player:drawCards(n, "leiluan")
    if player.dead then return end
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):isCommonTrick() and table.contains(room.discard_pile, info.cardId) then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
      return false
    end, Player.HistoryRound)
    if #cards == 0 then return end
    U.askForUseRealCard(room, player, cards, ".", "leiluan", "#leiluan-use", {expand_pile = cards})
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.EventAcquireSkill, fk.RoundEnd},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return target == player and player:hasSkill("leiluan", true)
    elseif event == fk.EventAcquireSkill then
      return target == player and data == leiluan and player.room:getTag("RoundCount")
    elseif event == fk.RoundEnd then
      return player:usedSkillTimes("leiluan", Player.HistoryRound) > 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      local mark = U.getMark(player, "leiluan-round")
      table.insert(mark, data.card.trueName)
      room:setPlayerMark(player, "leiluan-round", mark)
    elseif event == fk.EventAcquireSkill then
      if room.logic:getCurrentEvent() then
        local names = {}
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data[1]
          if use.from == player.id then
            table.insertIfNeed(names, use.card.trueName)
          end
          return false
        end, Player.HistoryRound)
        room:setPlayerMark(player, "leiluan-round", names)
      end
    elseif event == fk.RoundEnd then
      room:addPlayerMark(player, "leiluan_count", 1)
    end
  end,
}
local fuchao = fk.CreateTriggerSkill{
  name = "fuchao",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.responseToEvent and data.responseToEvent.from ~= player.id and
      data.responseToEvent.card
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use_event = nil
    U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
      local u = e.data[1]
      if u.from == data.responseToEvent.from and u.card == data.responseToEvent.card then
        use_event = e
        return true
      end
    end, 1)
    if use_event == nil then return end
    local use = use_event.data[1]
    local to = room:getPlayerById(use.from)
    local all_choices = {"fuchao1::"..to.id, "fuchao2"}
    --[[if to.dead or to:isNude() or player:isNude() then
      table.remove(choices, 1)
    end]]--  盲猜可以空发
    local choice = room:askForChoice(player, all_choices, self.name,
      "#fuchao-choice::"..to.id..":"..use.card:toLogString(), false, all_choices)
    if choice == "fuchao2" then
      if use.tos then  --抵消无懈
        use.nullifiedTargets = table.map(room:getOtherPlayers(player), Util.IdMapper)
        use.additionalEffect = (use.additionalEffect or 0) + 1
      end
    else
      if not player:isNude() then
        room:askForDiscard(player, 1, 1, true, self.name, false)
      end
      if not player.dead and not to.dead and not to:isNude() then
        local card = room:askForCardChosen(player, to, "he", self.name, "#fuchao-discard::"..to.id)
        room:throwCard(card, self.name, to, player)
      end

      use.disresponsiveList = use.disresponsiveList or {}
      table.insertTableIfNeed(use.disresponsiveList, table.map(room:getOtherPlayers(player), Util.IdMapper))
    end
  end,
}
leiluan:addRelatedSkill(leiluan_trigger)
kongshu:addSkill(leiluan)
kongshu:addSkill(fuchao)
Fk:loadTranslationTable{
  ["kongshu"] = "孔淑",
  ["#kongshu"] = "",

  ["leiluan"] = "累卵",
  [":leiluan"] = "每回合限一次，你可以将X张牌当一张你本轮未使用过的基本牌使用。每轮结束时，若你此轮至少使用过X张基本牌，你可以摸X张牌并视为使用"..
  "一张本轮进入弃牌堆的普通锦囊牌（X为你连续发动此技能的轮数，至少为1）。",
  ["fuchao"] = "覆巢",
  [":fuchao"] = "锁定技，你响应其他角色使用的牌后，你选择一项：1.弃置你与其各一张牌，然后其他角色不能响应此牌；2.令此牌对其他角色无效，然后对你"..
  "额外结算一次。",
  ["#leiluan"] = "累卵：你可以将%arg张牌当基本牌使用",
  ["#leiluan_trigger"] = "累卵",
  ["#leiluan-use"] = "累卵：你可以使用其中一张牌",
  ["#fuchao-choice"] = "覆巢：你抵消了 %dest 使用的%arg，请选择一项",
  ["fuchao1"] = "弃置你与%dest各一张牌，其他角色不能响应此牌",
  ["fuchao2"] = "此牌对其他角色无效，对你额外结算一次",
  ["#fuchao-discard"] = "覆巢：弃置 %dest 一张牌",
}

local wangkuang = General(extension, "wangkuang", "qun", 4)
local renxia = fk.CreateActiveSkill{
  name = "renxia",
  anim_type = "drawcard",
  min_card_num = 0,
  msx_card_num = 2,
  target_num = 0,
  prompt = function (self, selected_cards, selected_targets)
    return "#"..self.interaction.data
  end,
  interaction = function(self)
    return UI.ComboBox { choices = {"renxia1", "renxia2"} }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (self, to_select, selected)
    if self.interaction.data == "renxia1" then
      return #selected < 2 and not Self:prohibitDiscard(to_select)
    else
      return false
    end
  end,
  feasible = function (self, selected, selected_cards)
    if self.interaction.data == "renxia1" then
      return #selected_cards == 2
    else
      return #selected_cards == 0
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local mark = player:getTableMark("renxia-phase")
    table.insert(mark, self.interaction.data[7])
    room:setPlayerMark(player, "renxia-phase", mark)
    if self.interaction.data == "renxia1" then
      if effect.cards then
        room:throwCard(effect.cards, self.name, player, player)
      else
        room:askForDiscard(player, 2, 2, true, self.name, false)
      end
      while not player.dead and table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).is_damage_card
      end) do
        room:askForDiscard(player, 2, 2, true, self.name, false)
      end
    else
      player:drawCards(2, self.name)
      while not player.dead and not table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).is_damage_card
      end) do
        player:drawCards(2, self.name)
      end
    end
  end,
}
local renxia_delay = fk.CreateTriggerSkill{
  name = "#renxia_delay",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("renxia-phase") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("renxia")
    room:notifySkillInvoked(player, "renxia", "drawcard")
    local mark = player:getTableMark("renxia-phase")
    for _, n in ipairs(mark) do
      if player.dead then return end
      local i = 1
      if n == "1" then
        i = 2
      end
      renxia.interaction = renxia.interaction or {}
      renxia.interaction.data = "renxia"..i
      renxia:onUse(room, {
        from = player.id,
      })
    end
  end,
}
renxia:addRelatedSkill(renxia_delay)
wangkuang:addSkill(renxia)
Fk:loadTranslationTable{
  ["wangkuang"] = "王匡",
  ["#wangkuang"] = "",

  ["renxia"] = "任侠",
  [":renxia"] = "出牌阶段限一次，你可以执行一项，然后本阶段结束时执行另一项：1.弃置两张牌，重复此流程，直到手牌中没有【杀】或伤害锦囊牌；"..
  "2.摸两张牌，重复此流程，直到手牌中有【杀】或伤害锦囊牌。",
  ["#renxia1"] = "任侠：弃两张牌，重复直到手牌中没有伤害牌，本阶段结束时执行另一项",
  ["#renxia2"] = "任侠：摸两张牌，重复直到手牌中有伤害牌，本阶段结束时执行另一项",
  ["renxia1"] = "弃两张牌",
  ["renxia2"] = "摸两张牌",
}

return extension
