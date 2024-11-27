local extension = Package("ol_sp4")
extension.extensionName = "ol"
local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_sp4"] = "OL专属4",
}

local mawan = General(extension, "mawan", "qun", 4)
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
    local result = U.askForJointChoice(targets, { "hunjiang_extra_target:"..player.id, "hunjiang_draw::"..player.id }, self.name,
      "#hunjiang-others_choose")

    local firstChosen
    for _, p in ipairs(targets) do
      local choice = result[p.id]

      if firstChosen == nil then
        firstChosen = choice
      elseif firstChosen ~= choice then
        firstChosen = false
      end

      if choice:startsWith("hunjiang_extra_target") then
        local hunjiangUsers = p:getTableMark("@@hunjiang-phase")
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
          local hunjiangUsers = p:getTableMark("@@hunjiang-phase")
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
            table.contains(p:getTableMark("@@hunjiang-phase"), player.id) and
            not table.contains(TargetGroup:getRealTargets(data.tos), p.id) and
            player:canUseTo(data.card, p, {bypass_distances = true, bypass_times = true})
        end
      )
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(
      room.alive_players,
      function(p)
        return
          table.contains(p:getTableMark("@@hunjiang-phase"), player.id) and
          not table.contains(TargetGroup:getRealTargets(data.tos), p.id) and
          player:canUseTo(data.card, p, {bypass_distances = true, bypass_times = true})
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
hunjiang:addRelatedSkill(hunjiangTarget)
mawan:addSkill(hunjiang)
mawan:addSkill("mashu")
Fk:loadTranslationTable{
  ["mawan"] = "马玩",
  ["#mawan"] = "驱率羌胡",
  ["designer:mawan"] = "大宝",

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

  ["$hunjiang1"] = "边野有豪强，敢执干戈动玄黄！",
  ["$hunjiang2"] = "漫天浑雪，弥散八荒。",
  ["~mawan"] = "曹贼势大，唯避其锋芒。",
}

local budugen = General(extension, "budugen", "qun", 4)
local kouchao = fk.CreateViewAsSkill{
  name = "kouchao",
  prompt = "#kouchao-viewas",
  pattern = ".",
  interaction = function()
    local all_names = Self:getTableMark("@$kouchao")
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
    room.logic:getEventsByRule(GameEvent.MoveCards, 1, function(e)
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
      local mark = player:getTableMark("@$kouchao")
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
      local mark = Self:getTableMark("@$kouchao")
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
      "#yongzu-choose", self.name, true, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
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
        if target == player and player:getMark("qingliu_invoked") == 0 then
          local dying_events = player.room.logic:getEventsOfScope(GameEvent.Dying, 1, function(e)
            return e.data[1].who == player.id
          end, Player.HistoryGame)
          return #dying_events > 0 and dying_events[1].data[1] == data
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local kingdoms = {"qun", "wei"}
    if event == fk.AfterDying then
      table.removeOne(kingdoms, player.kingdom)
      room:setPlayerMark(player, "qingliu_invoked", 1)
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
  "<font color='blue'>魏〖奸雄〗</font><font color='grey'>群〖天命〗</font>。",
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
    self.cost_data = {tos = {player.room.current.id}}
    return player.room:askForSkillInvoke(player, self.name, nil, "#chishi-invoke::"..player.room.current.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
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
        local weimian_resume = room:askForChoice(to, slots, self.name, "#weimian-resume")
        room:resumePlayerArea(to, {weimian_resume})
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
  ["#ol__kebineng"] = "瀚海鲸波",
  ["designer:ol__kebineng"] = "CYC",
  ["~ol__kebineng"] = "未驱青马饮于黄河，死难瞑目。",

  ["pingduan"] = "平端",
  [":pingduan"] = "出牌阶段限一次，你可以令一名角色依次执行：1.使用一张基本牌；2.重铸一张锦囊牌；3.令你获得其装备区一张牌。其每执行一项"..
  "便摸一张牌。",
  ["#pingduan"] = "平端：令一名角色依次执行选项，其每执行一项摸一张牌",
  ["#pingduan-use"] = "平端：你可以使用一张基本牌，摸一张牌",
  ["#pingduan-recast"] = "平端：你可以重铸一张锦囊牌，摸一张牌",
  ["#pingduan-equip"] = "平端：你可以令 %src 获得你装备区一张牌，你摸一张牌",
  ["#pingduan-prey"] = "平端：获得 %dest 装备区一张牌",

  ["$pingduan1"] = "草原儿郎，张弓善射，勇不可当。",
  ["$pingduan2"] = "策马逐雄鹰，孤当与尔等共分天下。",
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
        local mark = player:getTableMark(self.name)
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
        return table.contains(player:getTableMark("jieyan"), target.id)
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
        room:removeTableMark(player, "jieyan", target.id)
        local cards = {}
        local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase, true)
        if phase_event ~= nil then
          local end_id = phase_event.id
          room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
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
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(Self, "leiluan", all_names, nil, Self:getTableMark("leiluan-round"))
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
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
    local names = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if card:isCommonTrick() then
              table.insertIfNeed(names, card.name)
            end
          end
        end
      end
      return false
    end, Player.HistoryRound)
    if #names == 0 then return end
    if player:getMark("leiluan_cards") == 0 then
      room:setPlayerMark(player, "leiluan_cards", U.getUniversalCards(room, "t"))
    end
    local cards = table.filter(player:getMark("leiluan_cards"), function (id)
      return table.contains(names, Fk:getCardById(id).name)
    end)
    local use = U.askForUseRealCard(room, player, cards, nil, "leiluan", "#leiluan-use",
      {expand_pile = cards, bypass_times = true, extraUse = true}, true, true)
    if use then
      use = {
        card = Fk:cloneCard(use.card.name),
        from = player.id,
        tos = use.tos,
      }
      use.card.skillName = "leiluan"
      room:useCard(use)
    end
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
      room:addTableMark(player, "leiluan-round", data.card.trueName)
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
    room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
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
  [":leiluan"] = "每回合限一次，你可以将X张牌当一张你本轮未使用过的基本牌使用。每轮结束时，若你此轮至少使用过X张基本牌，你可以摸X张牌并视为"..
  "使用一张本轮进入弃牌堆的普通锦囊牌（X为你连续发动此技能的轮数，至少为1）。",
  ["fuchao"] = "覆巢",
  [":fuchao"] = "锁定技，你响应其他角色使用的牌后，你选择一项：1.弃置你与其各一张牌，然后其他角色不能响应此牌；2.令此牌对其他角色无效，然后"..
  "对你额外结算一次。",
  ["#leiluan"] = "累卵：你可以将%arg张牌当基本牌使用",
  ["#leiluan_trigger"] = "累卵",
  ["#leiluan-use"] = "累卵：你可以视为使用其中一张牌",
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
      while not player.dead do
        if table.find(player:getCardIds("h"), function (id)
          return Fk:getCardById(id).is_damage_card
        end) and table.find(player:getCardIds("he"), function (id)
          return not player:prohibitDiscard(id)
        end) then
          room:askForDiscard(player, 2, 2, true, self.name, false)
        else
          break
        end
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
  ["#wangkuang"] = "任侠纵横",
  ["designer:wangkuang"] = "U",

  ["renxia"] = "任侠",
  [":renxia"] = "出牌阶段限一次，你可以执行一项，然后本阶段结束时执行另一项：1.弃置两张牌，重复此流程，直到手牌中没有【杀】或伤害锦囊牌；"..
  "2.摸两张牌，重复此流程，直到手牌中有【杀】或伤害锦囊牌。",
  ["#renxia1"] = "任侠：弃两张牌，重复直到手牌中没有伤害牌，本阶段结束时执行另一项",
  ["#renxia2"] = "任侠：摸两张牌，重复直到手牌中有伤害牌，本阶段结束时执行另一项",
  ["renxia1"] = "弃两张牌",
  ["renxia2"] = "摸两张牌",

  ["$renxia1"] = "俊毅如风，任胸中长虹惊云。",
  ["$renxia2"] = "侠之大者，为国为民。",
  ["~wangkuang"] = "人心不古，世态炎凉。",
}

local chenggongying = General(extension, "chenggongying", "qun", 4)
local kuangxiang = fk.CreateTriggerSkill{
  name = "kuangxiang",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      table.find(player.room.alive_players, function (p)
        return p:getHandcardNum() ~= 4
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p:getHandcardNum() ~= 4
    end)
    local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#kuangxiang-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local n = to:getHandcardNum() - 4
    if n > 0 then
      room:askForDiscard(to, n, n, false, self.name, false)
    else
      local cards = to:drawCards(-n, self.name, "top", "@@kuangxiang-inhand")
      if not to.dead then
        n = #table.filter(cards, function (id)
          return Fk:getCardById(id).color == Card.Red
        end)
        if n > 0 then
          room:addPlayerMark(to, "@kuangxiang", n)
        end
      end
    end
  end,

  refresh_events = {fk.PreCardUse, fk.DrawNCards},
  can_refresh = function (self, event, target, player, data)
    if target == player then
      if event == fk.PreCardUse then
        return data.card.is_damage_card and data.card:getMark("@@kuangxiang-inhand") > 0 and data.card.color == Card.Black
      elseif event == fk.DrawNCards then
        return player:getMark("@kuangxiang") > 0
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    if event == fk.PreCardUse then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    elseif event == fk.DrawNCards then
      data.n = data.n - player:getMark("@kuangxiang")
      player.room:setPlayerMark(player, "@kuangxiang", 0)
    end
  end,
}
chenggongying:addSkill(kuangxiang)
Fk:loadTranslationTable{
  ["chenggongying"] = "成公英",
  ["#chenggongying"] = "",
  --["designer:chenggongying"] = "",

  ["kuangxiang"] = "匡襄",
  [":kuangxiang"] = "准备阶段，你可以令一名角色将手牌数调整为4，其以此法获得的黑色牌造成伤害+1，其以此法每获得一张红色牌，其下个摸牌阶段摸牌数-1。",
  ["#kuangxiang-choose"] = "匡襄：令一名角色将手牌数调整为4，其摸到的牌具有额外效果",
  ["@@kuangxiang-inhand"] = "匡襄",
  ["@kuangxiang"] = "摸牌数-",
}

local hanfu = General(extension, "ol__hanfu", "qun", 4)
local shuzi = fk.CreateActiveSkill{
  name = "shuzi",
  anim_type = "control",
  card_num = 2,
  target_num = 1,
  prompt = "#shuzi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected < 2
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local names = table.map(effect.cards, function (id)
      return Fk:getCardById(id).trueName
    end)
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id)
    if player.dead or target.dead or target:isKongcheng() then return end
    local card = room:askForCard(target, 1, 1, false, self.name, false, nil, "#shuzi-give:"..player.id)
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, false, target.id)
    if player.dead or target.dead then return end
    if table.contains(names, Fk:getCardById(card[1]).trueName) then
      local choices = {"shuzi_damage", "Cancel"}
      if table.find(room:getOtherPlayers(target), function (p)
        return p:canMoveCardsInBoardTo(target)
      end) then
        table.insert(choices, 2, "shuzi_move")
      end
      local choice = room:askForChoice(player, choices, self.name,
        "#shuzi-choice::"..target.id, false, {"shuzi_damage", "shuzi_move", "Cancel"})
      if choice == "shuzi_damage" then
        room:doIndicate(player.id, {target.id})
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        }
      elseif choice == "shuzi_move" then
        local targets = table.filter(room:getOtherPlayers(target), function (p)
          return p:canMoveCardsInBoardTo(target)
        end)
        local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
          "#shuzi-move::"..target.id, self.name, true)
        if #to > 0 then
          to = room:getPlayerById(to[1])
          room:askForMoveCardInBoard(player, to, target, self.name, nil, to)
        end
      end
    end
  end,
}
local kuangshou = fk.CreateTriggerSkill{
  name = "kuangshou",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, self.name)
    if player.dead or player:isNude() then return end
    local n = {}
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data[1]
      table.insertIfNeed(n, damage.to.id)
    end, Player.HistoryTurn)
    room:askForDiscard(player, #n, #n, true, self.name, false)
  end,
}
hanfu:addSkill(shuzi)
hanfu:addSkill(kuangshou)
Fk:loadTranslationTable{
  ["ol__hanfu"] = "韩馥",
  ["#ol__hanfu"] = "挈瓶之知",
  --["designer:ol__hanfu"] = "",

  ["shuzi"] = "束辎",
  [":shuzi"] = "出牌阶段限一次，你可以交给一名角色两张牌，然后其交给你一张手牌，若此牌牌名与你交给其的牌中有牌名相同，你可以选择一项："..
  "1.对其造成1点伤害；2.将场上一张牌移动至其场上对应的区域。",
  ["kuangshou"] = "㑌守",
  [":kuangshou"] = "锁定技，当你受到伤害后，你摸三张牌，然后弃置X张牌（X为本回合受到过伤害的角色数）。",
  ["#shuzi"] = "束辎：交给一名角色两张牌，然后其交给你一张手牌，若其中有牌名相同，你可以对其执行选项",
  ["#shuzi-give"] = "束辎：请交给 %src 一张手牌，若与其交给你的牌牌名相同，其可以对你执行选项",
  ["#shuzi-choice"] = "束辎：你可以对 %dest 执行一项",
  ["shuzi_damage"] = "对其造成1点伤害",
  ["shuzi_move"] = "将场上一张牌移动至其场上",
  ["#shuzi-move"] = "束辎：你可以选择一名角色，将其场上一张牌移至 %dest 场上",

  ["$shuzi1"] = "本初啊，冀州虽大，却也没有余粮！",
  ["$shuzi2"] = "不是韩某小气，是实在没有一粒米了。",
  ["$kuangshou1"] = "常言道以和为贵，打打杀杀作甚？",
  ["$kuangshou2"] = "诸位都是体面人，不可妄动刀兵。",
  ["~ol__hanfu"] = "本初，我可是请你吃过饭的！",
}

local niufu = General(extension, "ol__niufu", "qun", 4)
local shisuan = fk.CreateTriggerSkill{
  name = "shisuan",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and not player:isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askForDiscard(player, 1, 1, true, self.name, false)
    if not data.from or data.from.dead then return end
    room:doIndicate(player.id, {data.from.id})
    local all_choices = {"loseHp", "shisuan_give:"..player.id, "turnOver"}
    local choices = table.simpleClone(all_choices)
    if player.dead or #data.from:getCardIds("e") == 0 then
      table.remove(choices, 2)
    end
    local choice = room:askForChoice(data.from, choices, self.name, nil, false, all_choices)
    if choice == "loseHp" then
      room:loseHp(data.from, 1, self.name)
    elseif choice == "turnOver" then
      data.from:turnOver()
    else
      local card = room:askForCard(data.from, 1, 1, true, self.name, false, ".|.|.|equip", "#shisuan-give:"..player.id)
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, true, data.from.id)
    end
  end,
}
local zonglue = fk.CreateViewAsSkill{
  name = "zonglue",
  anim_type = "offensive",
  prompt = "#zonglue",
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function (self, player, use)
    player.room:setPlayerMark(player, "zonglue-phase", 1)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("zonglue-phase") == 0
  end,
  enabled_at_response = Util.FalseFunc,
}
local zonglue_trigger = fk.CreateTriggerSkill{
  name = "#zonglue_trigger",
  anim_type = "offensive",
  main_skill = zonglue,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zonglue) and data.card and data.card.trueName == "slash" and
      player.room.logic:damageByCardEffect() and not data.to.dead and not data.to:isAllNude() and
      data.card:isVirtual() and (#data.card.subcards ~= 1 or Fk:getCardById(data.card.subcards[1]).trueName ~= "slash")
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#zonglue-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to.id})
    local cards = U.askforCardsChosenFromAreas(player, data.to, "hej", self.name, nil, nil, false)
    room:obtainCard(player, cards, false, fk.ReasonPrey)
  end,
}
zonglue:addRelatedSkill(zonglue_trigger)
niufu:addSkill(shisuan)
niufu:addSkill(zonglue)
Fk:loadTranslationTable{
  ["ol__niufu"] = "牛辅",
  ["#ol__niufu"] = "",
  --["designer:ol__niufu"] = "",

  ["shisuan"] = "蓍算",
  [":shisuan"] = "锁定技，当你受到伤害后，你弃置一张牌，伤害来源选择一项：1.失去1点体力；2.交给你其装备区内一张牌；3.翻面。",
  ["zonglue"] = "纵掠",
  [":zonglue"] = "出牌阶段限一次，你可以将一张牌当【杀】使用。当你使用【杀】对目标角色造成伤害后，若实体牌不为【杀】或没有实体牌，"..
  "你可以获得其每个区域各一张牌。",
  ["shisuan_give"] = "交给 %src 装备区一张牌",
  ["#shisuan-give"] = "蓍算：请交给 %src 装备区一张牌",
  ["#zonglue"] = "纵掠：你可以将一张牌当【杀】使用",
  ["#zonglue_trigger"] = "纵掠",
  ["#zonglue-invoke"] = "纵掠：是否获得 %dest 每个区域各一张牌？",
}

local dongxie = General(extension, "ol__dongxie", "qun", 3, 5, General.Female)
local jiaoweid = fk.CreateTriggerSkill{
  name = "jiaoweid",
  anim_type = "offensive",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getHandcardNum() > player.hp and
      data.card.color == Card.Black and (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function(p)
      return p.hp <= player.hp
    end)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(targets) do
      table.insertIfNeed(data.disresponsiveList, p.id)
    end
  end,
}
local jiaoweid_maxcards = fk.CreateMaxCardsSkill{
  name = "#jiaoweid_maxcards",
  main_skill = jiaoweid,
  frequency = Skill.Compulsory,
  exclude_from = function(self, player, card)
    return player:hasSkill(jiaoweid) and card.color == Card.Black
  end,
}
local jiaoweid_targetmod = fk.CreateTargetModSkill{
  name = "#jiaoweid_targetmod",
    bypass_distances =  function(self, player, skill, card, target)
    if player:hasSkill(jiaoweid) then
      return card and card.color == Card.Black and target and player.hp >= target.hp
    end
  end,
}
local bianyu = fk.CreateTriggerSkill{
  name = "bianyu",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and
      not data.to.dead and not data.to:isKongcheng() and data.to:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to.id})
    local cards = room:askForCardsChosen(player, data.to, 1, data.to:getLostHp(), "h", self.name,
      "#bianyu-choose::"..data.to.id..":"..data.to:getLostHp())
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), "@@bianyu-inhand", 1)
    end
    data.to:filterHandcards()
    cards = player:getCardIds(Player.Hand)
    if #cards > 0 and table.every(cards, function (id)
      return Fk:getCardById(id).trueName == "slash"
    end) then
      player:drawCards(2, self.name)
    elseif data.to ~= player then
      cards = data.to:getCardIds(Player.Hand)
      if #cards > 0 and table.every(cards, function (id)
        return Fk:getCardById(id).trueName == "slash"
      end) then
        player:drawCards(2, self.name)
      end
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card.type ~= Card.TypeBasic and table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@bianyu-inhand") > 0
    end)
  end,
  on_refresh = function (self, event, target, player, data)
    for _, id in ipairs(player:getCardIds("h")) do
      player.room:setCardMark(Fk:getCardById(id), "@@bianyu-inhand", 0)
    end
    player:filterHandcards()
  end,
}
local bianyu_filter = fk.CreateFilterSkill{
  name = "#bianyu_filter",
  card_filter = function(self, card, player)
    return card:getMark("@@bianyu-inhand") > 0 and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
}
local bianyu_targetmod = fk.CreateTargetModSkill{
  name = "#bianyu_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card:getMark("@@bianyu-inhand") > 0
  end,
}
local fengyao = fk.CreateTriggerSkill{
  name = "fengyao",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return end
    if event == fk.AfterCardsMove and player:isWounded() then
      for _, move in ipairs(data) do
        if move.from then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId).suit == Card.Spade then
              return true
            end
          end
        end
      end
    elseif event == fk.DamageCaused and target == player and data.to ~= player then
      return table.find(player:getCardIds("ej"), function (id)
        return Fk:getCardById(id).suit == Card.Spade and not player:prohibitDiscard(id)
      end) or table.find(data.to:getCardIds("ej"), function (id)
        return Fk:getCardById(id).suit == Card.Spade
      end)
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, self.name, "support")
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
    else
      room:notifySkillInvoked(player, self.name, "offensive")
      local targets = {}
      if table.find(player:getCardIds("ej"), function (id)
        return Fk:getCardById(id).suit == Card.Spade and not player:prohibitDiscard(id)
      end) then
        table.insert(targets, player.id)
      end
      if table.find(data.to:getCardIds("ej"), function (id)
        return Fk:getCardById(id).suit == Card.Spade
      end) then
        table.insert(targets, data.to.id)
      end
      local to = targets
      if #targets > 1 then
        to = room:askForChoosePlayers(player, targets, 1, 1, "#fengyao-choose::"..data.to.id, self.name, false)
      end
      to = room:getPlayerById(to[1])
      local card = table.filter(to:getCardIds("ej"), function (id)
        return Fk:getCardById(id).suit == Card.Spade and not player:prohibitDiscard(id)
      end)
      if #card > 1 then
        card = U.askforChooseCardsAndChoice(player, card, {"OK"}, self.name, "#fengyao-discard")
      end
      room:throwCard(card, self.name, to, player)
      data.damage = data.damage + 1
    end
  end,
}
jiaoweid:addRelatedSkill(jiaoweid_maxcards)
jiaoweid:addRelatedSkill(jiaoweid_targetmod)
bianyu:addRelatedSkill(bianyu_filter)
bianyu:addRelatedSkill(bianyu_targetmod)
dongxie:addSkill(jiaoweid)
dongxie:addSkill(bianyu)
dongxie:addSkill(fengyao)
Fk:loadTranslationTable{
  ["ol__dongxie"] = "董翓",
  ["#ol__dongxie"] = "",
  --["designer:ol__dongxie"] = "",

  ["jiaoweid"] = "狡威",
  [":jiaoweid"] = "锁定技，你的黑色牌不计入手牌上限。若你的手牌数大于体力值，你对体力值不大于你的角色使用黑色牌无距离限制且不能被这些角色响应。",
  ["bianyu"] = "鞭御",
  [":bianyu"] = "锁定技，你使用【杀】造成伤害或受到【杀】的伤害后，你选择受伤角色至多X张手牌，这些牌视为无次数限制的【杀】，直到其使用非基本牌"..
  "（X为其已损失体力值）。若你或其手牌均为【杀】，你摸两张牌。",
  ["fengyao"] = "凤瑶",
  [":fengyao"] = "锁定技，当♠牌离开一名角色装备区后，你回复1点体力。当你对其他角色造成伤害时，你弃置你或其场上一张♠牌，令此伤害+1。",
  ["#bianyu-choose"] = "鞭御：选择 %dest 至多%arg张手牌，这些牌视为【杀】",
  ["#bianyu_filter"] = "鞭御",
  ["@@bianyu-inhand"] = "鞭御",
  ["#fengyao-choose"] = "凤瑶：弃置你或 %dest 场上一张♠牌，令你对其造成的伤害+1",
  ["#fengyao-discard"] = "凤瑶：弃置其中一张♠牌",
}

local caocao = General(extension, "ol_sp__caocao", "qun", 4)
local xixiang = fk.CreateActiveSkill{
  name = "xixiang",
  anim_type = "offensive",
  prompt = "#xixiang",
  min_card_num = 1,
  target_num = 1,
  interaction = function(self)
    return U.CardNameBox { choices = {"slash", "duel"} }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    card:addSubcards(selected)
    return not Self:prohibitUse(card)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected > 0 or to_select == Self.id then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    card:addSubcards(selected_cards)
    return card.skill:targetFilter(to_select, {}, {}, card, {bypass_distances = true, bypass_times = true})
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:useVirtualCard(self.interaction.data, effect.cards, player, target, self.name, true)
    if player.dead then return end
    if target.hp > player:getHandcardNum() then
      player:drawCards(1, self.name)
    end
    if player.dead or target.dead then return end
    if target.hp > player.hp and not target:isNude() then
      local card = room:askForCardChosen(player, target, "he", self.name, "#xixiang-prey::"..target.id)
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
    end
  end,
}
local aige = fk.CreateTriggerSkill{
  name = "aige",
  anim_type = "special",
  events = {fk.EnterDying},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player.room.logic:getEventsOfScope(GameEvent.Dying, 3, Util.TrueFunc, Player.HistoryTurn) == 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-xixiang|zhubei", nil, true, false)
    local n = target.maxHp
    if player:getHandcardNum() < n then
      player:drawCards(n - player:getHandcardNum(), self.name)
    end
    if not player.dead and player.hp < n and player.maxHp <= n then
      room:recover{
        who = player,
        num = n - player.hp,
        recoverBy = player,
        skillName = self.name,
      }
    end
  end,
}
local zhubei = fk.CreateActiveSkill{
  name = "zhubei",
  anim_type = "control",
  prompt = "#zhubei",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local success, dat = room:askForUseActiveSkill(target, "zhubei_active", "#zhubei-use:"..player.id, false)
    if success and dat then
      local card = Fk:cloneCard(dat.interaction)
      card:addSubcards(dat.cards)
      card.skillName = self.name
      local use = {
        from = target.id,
        tos = {{player.id}},
        card = card,
        extraUse = true,
        extra_data = {
          zhubei = player.id
        },
      }
      room:useCard(use)
      if not (use.damageDealt and use.damageDealt[player.id]) then
        if not player.dead and not target.dead and not (player:isKongcheng() and target:isKongcheng()) and
          room:askForSkillInvoke(player, self.name, nil, "#zhubei-swap::"..target.id) then
          U.swapHandCards(room, player, player, target, self.name)
        end
      end
    end
  end,
}
local zhubei_active = fk.CreateActiveSkill{
  name = "zhubei_active",
  min_card_num = 1,
  target_num = 0,
  interaction = function(self)
    return U.CardNameBox { choices = {"slash", "duel"} }
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "zhubei"
    card:addSubcards(selected)
    return not Self:prohibitUse(card)  --盲猜无合法性判定
  end,
}
local zhubei_dalay = fk.CreateTriggerSkill{
  name = "#zhubei_dalay",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and data.card and table.contains(data.card.skillNames, "zhubei") and
      player.room:getCardArea(data.card) == Card.Processing then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not use_event then return end
      local use = use_event.data[1]
      return use.extra_data and use.extra_data.zhubei == player.id
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "zhubei", nil, "#zhubei_dalay-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, "zhubei", nil, true, player.id)
  end,
}
Fk:addSkill(zhubei_active)
zhubei:addRelatedSkill(zhubei_dalay)
caocao:addSkill(xixiang)
caocao:addSkill(aige)
caocao:addRelatedSkill(zhubei)
Fk:loadTranslationTable{
  ["ol_sp__caocao"] = "曹操",
  ["#ol_sp__caocao"] = "",
  --["designer:ol_sp__caocao"] = "",

  ["xixiang"] = "西向",
  [":xixiang"] = "出牌阶段限一次，你可以将任意张牌当无距离限制的【杀】或【决斗】对一名角色使用。此牌结算后，若其体力值：大于你的手牌数，"..
  "你摸一张牌；大于你的体力值，你获得其一张牌。",
  ["aige"] = "哀歌",
  [":aige"] = "觉醒技，一回合内第二次有角色进入濒死状态后，你失去〖西向〗，获得〖逐北〗，然后将手牌摸至X，体力值回复至X（X为该角色体力上限）。",
  ["zhubei"] = "逐北",
  [":zhubei"] = "出牌阶段限一次，你可以选择一名其他角色，令其将任意张牌当【杀】或【决斗】对你使用。若你以此法受到伤害后，你可以获得伤害牌；"..
  "若你未以此法受到伤害，你可以与其交换手牌。",
  ["#xixiang"] = "西向：将任意张牌当无距离限制的【杀】或【决斗】使用",
  ["#xixiang-prey"] = "西向：获得 %dest 一张牌",
  ["#zhubei"] = "逐北：令一名角色将任意张牌当【杀】或【决斗】对你使用",
  ["zhubei_active"] = "逐北",
  ["#zhubei-use"] = "逐北：请将任意张牌当【杀】或【决斗】对 %src 使用",
  ["#zhubei-swap"] = "逐北：是否与 %dest 交换手牌？",
  ["#zhubei_dalay"] = "逐北",
  ["#zhubei_dalay-invoke"] = "逐北：是否获得造成伤害的牌？",
}

local nanhualaoxian = General(extension, "ol__nanhualaoxian", "qun", 4)
local hedao = fk.CreateTriggerSkill{
  name = "hedao",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterDying},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player:getMark("hedao_invoked") == 0 then
      local dying_events = player.room.logic:getEventsOfScope(GameEvent.Dying, 1, function(e)
        return e.data[1].who == player.id
      end, Player.HistoryGame)
      return #dying_events > 0 and dying_events[1].data[1] == data
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "hedao_invoked", 1)
    room:setPlayerMark(player, "tianshu_max", 2)
  end,

  on_acquire = function (self, player, is_start)  --避免和青书同时机询问
    if is_start and player:hasSkill(self) then
      player.room:setPlayerMark(player, "tianshu_max", 1)
    end
  end,
}
local ol__shoushu = fk.CreateActiveSkill{
  name = "ol__shoushu",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#ol__shoushu",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      table.find(player:getTableMark("@[tianshu]"), function (info)
        return player:usedSkillTimes(info.skillName, Player.HistoryGame) == 0
      end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local skills = table.filter(player:getTableMark("@[tianshu]"), function (info)
      return player:usedSkillTimes(info.skillName, Player.HistoryGame) == 0
    end)
    skills = table.map(skills, function (info)
      return info.skillName
    end)
    local args = {}
    for _, s in ipairs(skills) do
      local info = room:getBanner("tianshu_skills")[s]
      table.insert(args, Fk:translate(":tianshu_triggers"..info[1]).."，"..Fk:translate(":tianshu_effects"..info[2]).."。")
    end
    local choice = room:askForChoice(player, args, self.name, "#ol__shoushu-give::"..target.id)
    local skill = skills[table.indexOf(args, choice)]
    if #target:getTableMark("@[tianshu]") > target:getMark("tianshu_max") then
      skills = table.map(target:getTableMark("@[tianshu]"), function (info)
        return info.skillName
      end)
      local to_throw = skills[1]
      if #skills > 1 then
        args = {}
        for _, s in ipairs(skills) do
          local info = room:getBanner("tianshu_skills")[s]
          table.insert(args, Fk:translate(":tianshu_triggers"..info[1]).."，"..Fk:translate(":tianshu_effects"..info[2]).."。")
        end
        choice = room:askForChoice(target, args, self.name, "#ol__shoushu-discard")
        to_throw = skills[table.indexOf(args, choice)]
      end
      room:handleAddLoseSkills(target, "-"..to_throw, nil, true, false)
      local banner = room:getBanner("tianshu_skills")
      banner[to_throw] = nil
      room:setBanner("tianshu_skills", banner)
    end
    room:handleAddLoseSkills(player, "-"..skill, nil, true, false)
    room:handleAddLoseSkills(target, skill, nil, true, false)
  end,
}
local qingshu = fk.CreateTriggerSkill{
  name = "qingshu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif event == fk.EventPhaseStart then
        return target == player and (player.phase == Player.Start or player.phase == Player.Finish)
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    --初始化随机数
    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))

    --时机
    local nums = {}
    for i = 1, 30, 1 do
      table.insert(nums, i)
    end
    nums = table.random(nums, 3)
    local choices = {
      "tianshu_triggers"..nums[1],
      "tianshu_triggers"..nums[2],
      "tianshu_triggers"..nums[3],
    }
    local choice_trigger = room:askForChoice(player, choices, self.name, "#qingshu-choice_trigger", true)
    local trigger = tonumber(string.sub(choice_trigger, 17))

    --效果
    nums = {}
    for i = 1, 30, 1 do
      table.insert(nums, i)
    end
    --排除部分绑定时机效果
    if not table.contains({4, 7, 18, 21, 25, 29, 30}, trigger) then
      table.removeOne(nums, 5)  --获得造成伤害的牌
    end
    if not table.contains({8, 23}, trigger) then
      table.removeOne(nums, 13)  --令此牌对你无效
    end
    if not table.contains({12, 16}, trigger) then
      table.removeOne(nums, 15)  --改判
      table.removeOne(nums, 16)  --获得判定牌
    end
    if not table.contains({29, 30}, trigger) then
      table.removeOne(nums, 26)  --伤害+1
      table.removeOne(nums, 30)  --防止伤害
    end
    nums = table.random(nums, 3)
    choices = {
      "tianshu_effects"..nums[1],
      "tianshu_effects"..nums[2],
      "tianshu_effects"..nums[3],
    }
    local choice_effect = room:askForChoice(player, choices, self.name,
      "#qingshu-choice_effect:::"..Fk:translate(":"..choice_trigger), true)

    --若将超出上限则舍弃一个已有天书
    if #player:getTableMark("@[tianshu]") > player:getMark("tianshu_max") then
      local skills = table.map(player:getTableMark("@[tianshu]"), function (info)
        return info.skillName
      end)
      local args = {}
      for _, s in ipairs(skills) do
        local info = room:getBanner("tianshu_skills")[s]
        table.insert(args, Fk:translate(":tianshu_triggers"..info[1]).."，"..Fk:translate(":tianshu_effects"..info[2]).."。")
      end
      table.insert(args, "Cancel")
      local choice = room:askForChoice(player, args, self.name, "#ol__shoushu-discard")
      if choice == "Cancel" then return false end
      local skill = skills[table.indexOf(args, choice)]
      room:handleAddLoseSkills(player, "-"..skill, nil, true, false)
      local banner = room:getBanner("tianshu_skills")
      banner[skill] = nil
      room:setBanner("tianshu_skills", banner)
    end

    --房间记录技能信息
    local banner = room:getBanner("tianshu_skills") or {}
    local name = "tianshu"
    for i = 1, 30, 1 do
      if banner["tianshu"..tostring(i)] == nil then
        name = "tianshu"..tostring(i)
        break
      end
    end
    banner[name] = {
      tonumber(string.sub(choice_trigger, 17)),
      tonumber(string.sub(choice_effect, 16)),
      player.id
    }
    room:setBanner("tianshu_skills", banner)
    room:handleAddLoseSkills(player, name, nil, true, false)
  end,

  --几个持续一段时间的标记效果
  refresh_events = {fk.TurnStart, fk.AfterTurnEnd},
  can_refresh = function (self, event, target, player, data)
    if target == player then
      if event == fk.TurnStart then
        return player:getMark("@@tianshu11") > 0
      elseif event == fk.AfterTurnEnd then
        return player:getMark("tianshu20") > 0 or player:getMark("tianshu24") ~= 0
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      room:removePlayerMark(player, MarkEnum.UncompulsoryInvalidity, player:getMark("@@tianshu11"))
      room:setPlayerMark(player, "@@tianshu11", 0)
    elseif event == fk.AfterTurnEnd then
      if player:getMark("tianshu20") > 0 then
        room:removePlayerMark(player, MarkEnum.AddMaxCards, 2)
        room:removePlayerMark(player, "tianshu20", 2)
      end
      room:setPlayerMark(player, "tianshu24", 0)
    end
  end,
}
local tianshu_targetmod = fk.CreateTargetModSkill{  --姑且挂在青书上……
  name = "#tianshu_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(player:getTableMark("tianshu24"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(player:getTableMark("tianshu24"), to.id)
  end,
}
qingshu:addRelatedSkill(tianshu_targetmod)
for loop = 1, 30, 1 do  --30个肯定够用
  local tianshu = fk.CreateTriggerSkill{
    name = "tianshu"..loop,
    anim_type = "special",
    events = {fk.CardUseFinished, fk.EventPhaseStart, fk.Damaged, fk.Damage, fk.TargetConfirming,
      fk.EnterDying, fk.AfterCardsMove, fk.CardUsing, fk.CardResponding, fk.AskForRetrial, fk.CardEffectCancelledOut, fk.Deathed,
      fk.FinishJudge, fk.TargetConfirmed, fk.ChainStateChanged, fk.HpChanged, fk.RoundStart, fk.DamageCaused, fk.DamageInflicted},
    times = function (self)
      local room = Fk:currentRoom()
      local info = room:getBanner("tianshu_skills")
      if info and info[self.name] and info[self.name][3] == Self.id then
        return 3 - Self:usedSkillTimes(self.name, Player.HistoryGame)
      else
        return 1 - Self:usedSkillTimes(self.name, Player.HistoryGame)
      end
    end,
    can_trigger = function(self, event, target, player, data)
      if player:hasSkill(self) then
        local room = player.room
        local info = room:getBanner("tianshu_skills")[self.name][1]
        if info == 1 then
          return event == fk.CardUseFinished and target == player
        elseif info == 2 then
          return event == fk.CardUseFinished and target ~= player and data.tos and
            table.contains(TargetGroup:getRealTargets(data.tos), player.id)
        elseif info == 3 then
          return event == fk.EventPhaseStart and target == player and player.phase == Player.Play
        elseif info == 4 then
          return event == fk.Damaged and target == player
        elseif info == 5 then
          return event == fk.EventPhaseStart and target == player and player.phase == Player.Start
        elseif info == 6 then
          return event == fk.EventPhaseStart and target == player and player.phase == Player.Finish
        elseif info == 7 then
          return event == fk.Damage and target == player
        elseif info == 8 then
          return event == fk.TargetConfirming and target == player and data.card.trueName == "slash"
        elseif info == 9 then
          return event == fk.EnterDying
        elseif info == 10 then
          if event == fk.AfterCardsMove then
            for _, move in ipairs(data) do
              if move.from == player.id then
                for _, inf in ipairs(move.moveInfo) do
                  if inf.fromArea == Card.PlayerEquip then
                    return true
                  end
                end
              end
            end
          end
        elseif info == 11 then
          return (event == fk.CardUsing or event == fk.CardResponding) and target == player and data.card.trueName == "jink"
        elseif info == 12 then
          return event == fk.AskForRetrial and data.card
        elseif info == 13 then
          if event == fk.AfterCardsMove then
            for _, move in ipairs(data) do
              if move.from == player.id then
                for _, inf in ipairs(move.moveInfo) do
                  if inf.fromArea == Card.PlayerHand then
                    return true
                  end
                end
              end
            end
          end
        elseif info == 14 then
          return event == fk.CardEffectCancelledOut and data.card
        elseif info == 15 then
          return event == fk.Deathed and target ~= player
        elseif info == 16 then
          return event == fk.FinishJudge and data.card
        elseif info == 17 then
          return event == fk.CardUseFinished and (data.card.trueName == "savage_assault" or data.card.trueName == "archery_attack")
        elseif info == 18 then
          return event == fk.Damage and target == player and data.card and data.card.trueName == "slash"
        elseif info == 19 then
          if event == fk.AfterCardsMove then
            if player.phase == Player.NotActive then
              for _, move in ipairs(data) do
                if move.from == player.id then
                  for _, inf in ipairs(move.moveInfo) do
                    if Fk:getCardById(inf.cardId).color == Card.Red and
                      (inf.fromArea == Card.PlayerHand or inf.fromArea == Card.PlayerEquip) then
                      return true
                    end
                  end
                end
              end
            end
          end
        elseif info == 20 then
          return event == fk.EventPhaseStart and target == player and player.phase == Player.Discard
        elseif info == 21 then
          return event == fk.Damaged and data.card and data.card.trueName == "slash"
        elseif info == 22 then
          return event == fk.EventPhaseStart and target == player and player.phase == Player.Draw
        elseif info == 23 then
          return event == fk.TargetConfirmed and target == player and data.card.type == Card.TypeTrick
        elseif info == 24 then
          return event == fk.ChainStateChanged and target.chained
        elseif info == 25 then
          return event == fk.Damaged and data.damageType ~= fk.NormalDamage
        elseif info == 26 then
          if event == fk.AfterCardsMove then
            for _, move in ipairs(data) do
              if move.from and room:getPlayerById(move.from):isKongcheng() then
                for _, inf in ipairs(move.moveInfo) do
                  if inf.fromArea == Card.PlayerHand then
                    return true
                  end
                end
              end
            end
          end
        elseif info == 27 then
          return event == fk.HpChanged and target == player
        elseif info == 28 then
          return event == fk.RoundStart
        elseif info == 29 then
          return event == fk.DamageCaused and target ~= nil
        elseif info == 30 then
          return event == fk.DamageInflicted
        end
      end
    end,
    on_cost = function(self, event, target, player, data)
      local room = player.room
      local info = room:getBanner("tianshu_skills")[self.name][2]
      local prompt = Fk:translate(":tianshu_effects"..info)
      self.cost_data = nil
      if info == 1 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 2 then
        local targets = table.filter(room:getOtherPlayers(player), function (p)
          return not p:isAllNude()
        end)
        if table.find(player:getCardIds("hej"), function (id)
          return not player:prohibitDiscard(id)
        end) then
          table.insert(targets, player)
        end
        if #targets == 0 then return end
        local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, prompt, self.name, true)
        if #to > 0 then
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 3 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 4 then
        if player:isNude() then return end
        local cards = room:askForDiscard(player, 1, 999, true, self.name, true, nil, prompt, true)
        if #cards > 0 then
          self.cost_data = {cards = cards}
          return true
        end
      elseif info == 5 then
        if data.card and room:getCardArea(data.card) == Card.Processing then
          return room:askForSkillInvoke(player, self.name, nil, prompt)
        end
      elseif info == 6 then
        local use = U.askForUseVirtualCard(room, player, "slash", nil, self.name, prompt, true, true, true, true, nil, true)
        if use then
          self.cost_data = use
          return true
        end
      elseif info == 7 then
        local targets = table.filter(room:getOtherPlayers(player), function (p)
          return not p:isAllNude()
        end)
        if #player:getCardIds("ej") > 0 then
          table.insert(targets, player)
        end
        if #targets == 0 then return end
        local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, prompt, self.name, true)
        if #to > 0 then
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 8 then
        if player:isWounded() then
          return room:askForSkillInvoke(player, self.name, nil, prompt)
        end
      elseif info == 9 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 10 then
        if player:getHandcardNum() < player.maxHp then
          return room:askForSkillInvoke(player, self.name, nil, prompt)
        end
      elseif info == 11 then
        local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, prompt, self.name, true)
        if #to > 0 then
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 12 then
        local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, prompt, self.name, true)
        if #to > 0 then
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 13 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 14 then
        local targets = room:getOtherPlayers(player)
        if #targets == 0 then return end
        local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, prompt, self.name, true)
        if #to > 0 then
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 15 then
        if not player:isKongcheng() and data.card then
          local card = room:askForCard(player, 1, 1, false, self.name, true, nil, prompt)
          if #card > 0 then
            self.cost_data = {cards = card}
            return true
          end
        end
      elseif info == 16 then
        if data.card and room:getCardArea(data.card) == Card.Processing then
          return room:askForSkillInvoke(player, self.name, nil, prompt)
        end
      elseif info == 17 then
        if table.find(room.alive_players, function (p)
          return p.maxHp > player.maxHp
        end) then
          return room:askForSkillInvoke(player, self.name, nil, prompt)
        end
      elseif info == 18 then
        if player:isKongcheng() then return end
        local targets = table.filter(room:getOtherPlayers(player), function (p)
          return p:isWounded() and player:canPindian(p)
        end)
        if #targets == 0 then return end
        local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, prompt, self.name, true)
        if #to > 0 then
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 19 then
        local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 2, prompt, self.name, true)
        if #to > 0 then
          room:sortPlayersByAction(to)
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 20 then
        local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, prompt, self.name, true)
        if #to > 0 then
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 21 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 22 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 23 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 24 then
        local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, prompt, self.name, true)
        if #to > 0 then
          self.cost_data = {tos = to}
          return true
        end
      elseif info == 25 then
        if #player:getCardIds("he") < 2 then return end
        local targets = table.filter(room:getOtherPlayers(player), function (p)
          return p:isWounded()
        end)
        if #targets == 0 then return end
        local ids = table.filter(player:getCardIds("he"), function (id)
          return not player:prohibitDiscard(id)
        end)
        local to, cards = room:askForChooseCardsAndPlayers(player, 2, 2, table.map(targets, Util.IdMapper), 1, 1,
          tostring(Exppattern{ id = ids }), prompt, self.name, true)
        if #to > 0 and #cards > 0 then
          self.cost_data = {tos = to, cards = cards}
          return true
        end
      elseif info == 26 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 27 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      elseif info == 28 then
        local success, dat = room:askForUseActiveSkill(player, "tianshu_active", prompt, true, {tianshu28 = "e"}, false)
        if success and dat then
          room:sortPlayersByAction(dat.targets)
          self.cost_data = {tos = dat.targets}
          return true
        end
      elseif info == 29 then
        local success, dat = room:askForUseActiveSkill(player, "tianshu_active", prompt, true, {tianshu28 = "h"}, false)
        if success and dat then
          room:sortPlayersByAction(dat.targets)
          self.cost_data = {tos = dat.targets}
          return true
        end
      elseif info == 30 then
        return room:askForSkillInvoke(player, self.name, nil, prompt)
      end
    end,
    on_use = function(self, event, target, player, data)
      local room = player.room
      local info = room:getBanner("tianshu_skills")[self.name][2]
      local source = room:getBanner("tianshu_skills")[self.name][3]
      if source == player.id and player:usedSkillTimes(self.name, Player.HistoryGame) > 2 then
        player:setSkillUseHistory(self.name, 0, Player.HistoryGame)
        room:handleAddLoseSkills(player, "-"..self.name, nil, true, false)
        local banner = room:getBanner("tianshu_skills")
        banner[self.name] = nil
        room:setBanner("tianshu_skills", banner)
      else
        local mark = player:getTableMark("@[tianshu]")
        for i = 1, #mark do
          if mark[i].skillName == self.name then
            mark[i].skillTimes = 3 - player:usedSkillTimes(self.name, Player.HistoryGame)
            mark[i].visible = true
            break
          end
        end
        room:setPlayerMark(player, "@[tianshu]", mark)
      end
      switch(info, {
        [1] = function ()
          player:drawCards(1, self.name)
        end,
        [2] = function ()
          local to = room:getPlayerById(self.cost_data.tos[1])
          if to == player then
            local cards = table.filter(player:getCardIds("hej"), function (id)
              return not player:prohibitDiscard(id)
            end)
            local card = room:askForCard(player, 1, 1, true, self.name, false, tostring(Exppattern{ id = cards }),
              "#tianshu2-discard::"..player.id, player:getCardIds("j"))
            room:throwCard(card, self.name, player, player)
          else
            local card = room:askForCardChosen(player, to, "hej", self.name, "#tianshu2-discard::"..to.id)
            room:throwCard(card, self.name, to, player)
          end
        end,
        [3] = function ()
          room:askForGuanxing(player, room:getNCards(3))
        end,
        [4] = function ()
          room:throwCard(self.cost_data.cards, self.name, player, player)
          if player.dead then return end
          player:drawCards(#self.cost_data.cards, self.name)
        end,
        [5] = function ()
          room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
        end,
        [6] = function ()
          room:useCard(self.cost_data)
        end,
        [7] = function ()
          local to = room:getPlayerById(self.cost_data.tos[1])
          local flag = to == player and "ej" or "hej"
          local card = room:askForCardChosen(player, to, flag, self.name, "#tianshu7-prey::"..to.id)
          room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
        end,
        [8] = function ()
          room:recover{
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name
          }
        end,
        [9] = function ()
          player:drawCards(3, self.name)
          if not player.dead then
            room:askForDiscard(player, 1, 1, true, self.name, false)
          end
        end,
        [10] = function ()
          player:drawCards(math.min(player.maxHp - player:getHandcardNum(), 5), self.name)
        end,
        [11] = function ()
          local to = room:getPlayerById(self.cost_data.tos[1])
          room:addPlayerMark(to, "@@tianshu11", 1)
          room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity, 1)
        end,
        [12] = function ()
          local to = room:getPlayerById(self.cost_data.tos[1])
          to:drawCards(2, self.name)
          if not to.dead then
            to:turnOver()
          end
        end,
        [13] = function ()
          table.insertIfNeed(data.nullifiedTargets, player.id)
        end,
        [14] = function ()
          local to = room:getPlayerById(self.cost_data.tos[1])
          local judge = {
            who = to,
            reason = self.name,
            pattern = ".|.|spade",
          }
          room:judge(judge)
          if judge.card.suit == Card.Spade and not to.dead then
            room:damage{
              from = player,
              to = to,
              damage = 2,
              damageType = fk.ThunderDamage,
              skillName = self.name,
            }
          end
        end,
        [15] = function ()
          local card = Fk:getCardById(self.cost_data.cards[1])
          room:retrial(card, player, data, self.name, true)
        end,
        [16] = function ()
          room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
        end,
        [17] = function ()
          room:changeMaxHp(player, 1)
        end,
        [18] = function ()
          local to = room:getPlayerById(self.cost_data.tos[1])
          local pindian = player:pindian({to}, self.name)
          if pindian.results[to.id].winner == player then
            if not player.dead and not to.dead and not to:isNude() then
              local cards = room:askForCardsChosen(player, to, math.min(#to:getCardIds("he"), 2), 2, "he", self.name,
                "#tianshu18-prey::"..to.id)
              room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
            end
          end
        end,
        [19] = function ()
          for _, id in ipairs(self.cost_data.tos) do
            local p = room:getPlayerById(id)
            if not p.dead then
              p:drawCards(1, self.name)
            end
          end
        end,
        [20] = function ()
          local to = room:getPlayerById(self.cost_data.tos[1])
          room:addPlayerMark(to, MarkEnum.AddMaxCards, 2)
          room:addPlayerMark(to, "tianshu20", 2)
        end,
        [21] = function ()
          local cards = room:getCardsFromPileByRule(".|.|.|.|.|^basic", 2)
          if #cards > 0 then
            room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, false, player.id)
          end
        end,
        [22] = function ()
          local cards = room:getCardsFromPileByRule(".|.|.|.|.|trick", 2)
          if #cards > 0 then
            room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, false, player.id)
          end
        end,
        [23] = function ()
          player:drawCards(4, self.name)
          if not player.dead then
            player:turnOver()
          end
        end,
        [24] = function ()
          local to = room:getPlayerById(self.cost_data.tos[1])
          room:addTableMark(player, "tianshu24", to.id)
        end,
        [25] = function ()
          room:throwCard(self.cost_data.cards, self.name, player, player)
          local to = room:getPlayerById(self.cost_data.tos[1])
          if not player.dead and player:isWounded() then
            room:recover{
              who = player,
              num = 1,
              recoverBy = player,
              skillName = self.name
            }
          end
          if not to.dead and to:isWounded() then
            room:recover{
              who = to,
              num = 1,
              recoverBy = player,
              skillName = self.name
            }
          end
        end,
        [26] = function ()
          data.damage = data.damage + 1
        end,
        [27] = function ()
          room:loseHp(player, 1, self.name)
          if not player.dead then
            player:drawCards(3, self.name)
          end
        end,
        [28] = function ()
          local targets = table.map(self.cost_data.tos, Util.Id2PlayerMapper)
          U.swapCards(room, player, targets[1], targets[2], targets[1]:getCardIds("e"), targets[2]:getCardIds("e"), self.name,
            Card.PlayerEquip)
        end,
        [29] = function ()
          local targets = table.map(self.cost_data.tos, Util.Id2PlayerMapper)
          U.swapHandCards(room, player, targets[1], targets[2], self.name)
        end,
        [30] = function ()
          if data.from and not data.from.dead then
            data.from:drawCards(3, self.name)
          end
          return true
        end,
      })
    end,

    --几个持续一段时间的标记效果，在青书中清理。

    on_acquire = function (self, player, is_start)
      local room = player.room
      local info = room:getBanner("tianshu_skills")[self.name]
      local mark = player:getTableMark("@[tianshu]")
      table.insert(mark, {
        skillName = self.name,
        skillTimes = info[3] == player.id and 3 or 1,
        skillInfo = Fk:translate(":tianshu_triggers"..info[1]).."，"..Fk:translate(":tianshu_effects"..info[2]).."。",
        owner = { player.id, info[3] },
        visible = false
      })
      room:setPlayerMark(player, "@[tianshu]", mark)
    end,

    on_lose = function (self, player, is_death)
      local room = player.room
      local mark = player:getTableMark("@[tianshu]")
      for i = #mark, 1, -1 do
        if mark[i].skillName == self.name then
          table.remove(mark, i)
        end
      end
      room:setPlayerMark(player, "@[tianshu]", #mark > 0 and mark or 0)
      player:setSkillUseHistory(self.name, 0, Player.HistoryGame)
    end,
  }
  Fk:addSkill(tianshu)
  Fk:loadTranslationTable{
    ["tianshu"..loop] = "天书",
    [":tianshu"..loop] = "未翻开的天书。",
    ["tianshu_triggers"..loop] = "时机",
    ["tianshu_effects"..loop] = "效果",
  }
end
local tianshu_active = fk.CreateActiveSkill{
  name = "tianshu_active",
  card_num = 0,
  target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards, _, extra_data)
    if #selected < 2 then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        local area = extra_data.tianshu28
        return #Fk:currentRoom():getPlayerById(selected[1]):getCardIds(area) > 0 or
          #Fk:currentRoom():getPlayerById(to_select):getCardIds(area) > 0
      end
    end
  end,
}
Fk:addQmlMark{
  name = "tianshu",
  how_to_show = function(name, value)
    if type(value) == "table" then
      return tostring(#value)
    end
    return " "
  end,
  qml_path = "packages/ol/qml/Tianshu"
}
Fk:addSkill(tianshu_active)
nanhualaoxian:addSkill(qingshu)
nanhualaoxian:addSkill(ol__shoushu)
nanhualaoxian:addSkill(hedao)
Fk:loadTranslationTable{
  ["ol__nanhualaoxian"] = "南华老仙",
  ["#ol__nanhualaoxian"] = "",
  --["designer:ol__nanhualaoxian"] = "",

  ["qingshu"] = "青书",
  [":qingshu"] = "锁定技，游戏开始时，你的准备阶段和结束阶段，你书写一册<a href='tianshu_href'>“天书”</a>。",
  ["ol__shoushu"] = "授术",
  [":ol__shoushu"] = "出牌阶段限一次，你可以将一册未翻开的<a href='tianshu_href'>“天书”</a>交给一名其他角色。",
  ["hedao"] = "合道",
  [":hedao"] = "锁定技，游戏开始时，你可以至多拥有两册<a href='tianshu_href'>“天书”</a>。你的首次濒死结算后，你可以至多拥有三册"..
  "<a href='tianshu_href'>“天书”</a>。",
  ["tianshu_href"] = "从随机三个时机和三个效果中各选择一个组合为一个“天书”技能。<br>"..
  "“天书”技能初始可使用三次，若交给其他角色则可使用次数改为一次，当次数用完后销毁。<br>"..
  "当一名角色将获得“天书”时，若数量将超过其可拥有“天书”的上限，则选择一个已有“天书”替换。",
  ["#qingshu-choice_trigger"] = "请为天书选择一个时机",
  ["#qingshu-choice_effect"] = "请为此时机选择一个效果：<br>%arg，",
  ["#ol__shoushu-discard"] = "你的“天书”超出上限，请删除一个",
  ["#ol__shoushu"] = "授术：你可以将一册未翻开的“天书”交给一名其他角色",
  ["#ol__shoushu-give"] = "授术：选择交给 %dest 的“天书”",

  ["@[tianshu]"] = "天书",
  ["#tianshu2-discard"] = "弃置 %dest 区域内一张牌",
  ["#tianshu7-prey"] = "获得 %dest 区域内一张牌",
  ["#tianshu18-prey"] = "获得 %dest 两张牌",
  ["@@tianshu11"] = "非锁定技失效",
  ["tianshu_active"] = "天书",

  [":tianshu_triggers1"] = "你使用牌后",
  [":tianshu_triggers2"] = "其他角色对你使用牌后",
  [":tianshu_triggers3"] = "出牌阶段开始时",
  [":tianshu_triggers4"] = "你受到伤害后",
  [":tianshu_triggers5"] = "准备阶段",
  [":tianshu_triggers6"] = "结束阶段",
  [":tianshu_triggers7"] = "你造成伤害后",
  [":tianshu_triggers8"] = "你成为【杀】的目标时",
  [":tianshu_triggers9"] = "一名角色进入濒死时",
  [":tianshu_triggers10"] = "你失去装备牌后",
  [":tianshu_triggers11"] = "你使用或打出【闪】时",
  [":tianshu_triggers12"] = "当一张判定牌生效前",
  [":tianshu_triggers13"] = "你失去手牌后",
  [":tianshu_triggers14"] = "你使用的牌被抵消后",
  [":tianshu_triggers15"] = "一名其他角色死亡后",
  [":tianshu_triggers16"] = "当一张判定牌生效后",
  [":tianshu_triggers17"] = "【南蛮入侵】或【万箭齐发】结算后",
  [":tianshu_triggers18"] = "你使用【杀】造成伤害后",
  [":tianshu_triggers19"] = "你于回合外失去红色牌后",
  [":tianshu_triggers20"] = "弃牌阶段开始时",
  [":tianshu_triggers21"] = "一名角色受到【杀】的伤害后",
  [":tianshu_triggers22"] = "摸牌阶段开始时",
  [":tianshu_triggers23"] = "你成为普通锦囊牌的目标后",
  [":tianshu_triggers24"] = "一名角色进入连环状态后",
  [":tianshu_triggers25"] = "一名角色受到属性伤害后",
  [":tianshu_triggers26"] = "一名角色失去最后的手牌后",
  [":tianshu_triggers27"] = "你的体力值变化后",
  [":tianshu_triggers28"] = "每轮开始时",
  [":tianshu_triggers29"] = "一名角色造成伤害时",
  [":tianshu_triggers30"] = "一名角色受到伤害时",

  [":tianshu_effects1"] = "你可以摸一张牌",
  [":tianshu_effects2"] = "你可以弃置一名角色区域内的一张牌",
  [":tianshu_effects3"] = "你可以观看牌堆顶的3张牌，以任意顺序置于牌堆顶或牌堆底",
  [":tianshu_effects4"] = "你可以弃置任意张牌，摸等量张牌",
  [":tianshu_effects5"] = "你可以获得造成伤害的牌",
  [":tianshu_effects6"] = "你可以视为使用一张无距离次数限制的【杀】",
  [":tianshu_effects7"] = "你可以获得一名角色区域内的一张牌",
  [":tianshu_effects8"] = "你可以回复1点体力",
  [":tianshu_effects9"] = "你可以摸3张牌，弃置1张牌",
  [":tianshu_effects10"] = "你可以摸牌至体力上限（至多摸5张）",
  [":tianshu_effects11"] = "你可以令一名角色非锁定技失效直到其下回合开始",
  [":tianshu_effects12"] = "你可以令一名角色摸2张牌并翻面",
  [":tianshu_effects13"] = "你可以令此牌对你无效",
  [":tianshu_effects14"] = "你可以令一名其他角色判定，若结果为♠，你对其造成2点雷电伤害",
  [":tianshu_effects15"] = "你可以用一张手牌替换判定牌",
  [":tianshu_effects16"] = "你可以获得此判定牌",
  [":tianshu_effects17"] = "若你不是体力上限最高的角色，你可以增加1点体力上限",
  [":tianshu_effects18"] = "你可以与一名已受伤角色拼点，若你赢，你获得其两张牌",
  [":tianshu_effects19"] = "你可以令至多两名角色各摸一张牌",
  [":tianshu_effects20"] = "你可以令一名角色的手牌上限+2直到其回合结束",
  [":tianshu_effects21"] = "你可以获得两张非基本牌",
  [":tianshu_effects22"] = "你可以获得两张锦囊牌",
  [":tianshu_effects23"] = "你可以摸4张牌并翻面",
  [":tianshu_effects24"] = "你可以令你对一名角色使用牌无距离次数限制直到你的回合结束",
  [":tianshu_effects25"] = "你可以弃置两张牌，令你和一名其他角色各回复1点体力",
  [":tianshu_effects26"] = "你可以令此伤害值+1",
  [":tianshu_effects27"] = "你可以失去1点体力，摸3张牌",
  [":tianshu_effects28"] = "你可以交换两名角色装备区的牌",
  [":tianshu_effects29"] = "你可以交换两名角色手牌区的牌",
  [":tianshu_effects30"] = "你可以防止此伤害，令伤害来源摸3张牌",
}

local qinlang = General(extension, "ol__qinlang", "wei", 3)
qinlang:addSkill("tmp_illustrate")
qinlang.hidden = true

local wuanguo = General(extension, "ol__wuanguo", "qun", 4)
wuanguo:addSkill("tmp_illustrate")
wuanguo.hidden = true

Fk:loadTranslationTable{
  ["ol__qinlang"] = "秦朗",
  ["ol__wuanguo"] = "武安国",
}

return extension
