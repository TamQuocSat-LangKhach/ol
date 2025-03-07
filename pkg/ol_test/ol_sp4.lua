local extension = Package("ol_sp4")
extension.extensionName = "ol"
local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_sp4"] = "OL专属4",
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
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  handly_pile = true,
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

  on_acquire = function (self, player, is_start)
    local room = player.room
    room:setPlayerMark(player, "kouchao1", "slash")
    room:setPlayerMark(player, "kouchao2", "fire_attack")
    room:setPlayerMark(player, "kouchao3", "dismantlement")
    room:setPlayerMark(player, "@$kouchao", {"slash", "fire_attack", "dismantlement"})
  end,
  on_lose = function (self, player, is_death)
    local room = player.room
    room:setPlayerMark(player, "kouchao1", 0)
    room:setPlayerMark(player, "kouchao2", 0)
    room:setPlayerMark(player, "kouchao3", 0)
    room:setPlayerMark(player, "@$kouchao", 0)
  end,
}
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
  handly_pile = true,
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
    local use = room:askForUseRealCard(player, cards, "leiluan", "#leiluan-use", {
      expand_pile = cards,
      bypass_times = true,
      extraUse = true,
    }, true, true)
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
      return target == player and data == leiluan and player.room:getBanner("RoundCount")
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
        use.nullifiedTargets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
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
      table.insertTableIfNeed(use.disresponsiveList, table.map(room:getOtherPlayers(player, false), Util.IdMapper))
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
    local card = room:askForCard(player, 1, 1, true, self.name, false, nil, "#shisuan-recast")
    room:recastCard(card, player, self.name)
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
  handly_pile = true,
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
  [":shisuan"] = "锁定技，当你受到伤害后，你重铸一张牌，伤害来源选择一项：1.失去1点体力；2.交给你其装备区内一张牌；3.翻面。",
  ["zonglue"] = "纵掠",
  [":zonglue"] = "出牌阶段限一次，你可以将一张牌当【杀】使用。当你使用【杀】对目标角色造成伤害后，若实体牌不为【杀】或没有实体牌，"..
  "你可以获得其每个区域各一张牌。",
  ["#shisuan-recast"] = "蓍算：请重铸一张牌",
  ["shisuan_give"] = "交给 %src 装备区一张牌",
  ["#shisuan-give"] = "蓍算：请交给 %src 装备区一张牌",
  ["#zonglue"] = "纵掠：你可以将一张牌当【杀】使用",
  ["#zonglue_trigger"] = "纵掠",
  ["#zonglue-invoke"] = "纵掠：是否获得 %dest 每个区域各一张牌？",
}

local nanhualaoxian = General(extension, "ol__nanhualaoxian", "qun", 3)
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
        return 2 - Self:usedSkillTimes(self.name, Player.HistoryGame)
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
        local targets = table.filter(room:getOtherPlayers(player, false), function (p)
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
        local targets = table.filter(room:getOtherPlayers(player, false), function (p)
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
        local targets = room:getOtherPlayers(player, false)
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
        local targets = table.filter(room:getOtherPlayers(player, false), function (p)
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
        local targets = table.filter(room:getOtherPlayers(player, false), function (p)
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
      if source ~= player.id or player:usedSkillTimes(self.name, Player.HistoryGame) > 1 then
        room:handleAddLoseSkills(player, "-"..self.name, nil, true, false)
        local banner = room:getBanner("tianshu_skills")
        banner[self.name] = nil
        room:setBanner("tianshu_skills", banner)
      else
        local mark = player:getTableMark("@[tianshu]")
        for i = 1, #mark do
          if mark[i].skillName == self.name then
            mark[i].skillTimes = 2 - player:usedSkillTimes(self.name, Player.HistoryGame)
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
          player:drawCards(3, self.name)
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

    dynamic_desc = function(self, player)
      local mark = Fk:currentRoom():getBanner("tianshu_skills")
      if mark == nil then return self.name end
      local info = mark[self.name]
      if info == nil then return self.name end
      if player:usedSkillTimes(self.name, Player.HistoryGame) > 0 or Self:isBuddy(player) or Self:isBuddy(info[3]) then
        --FIXME:直接用翻译很不好
        return "tianshu_inner:" .. (info[3] == player.id and 2 or 1) - player:usedSkillTimes(self.name, Player.HistoryGame) .. ":" ..
        Fk:translate(":tianshu_triggers"..info[1]) .. ":" .. Fk:translate(":tianshu_effects"..info[2])
      else
        return "tianshu_unknown:" .. (info[3] == player.id and 2 or 1)
      end
      return self.name
    end,

    on_acquire = function (self, player, is_start)
      local room = player.room
      local info = room:getBanner("tianshu_skills")[self.name]

      --FIXME:理论上这个mark可不要了，但是要分离的逻辑太复杂了，懒得搞(=ﾟωﾟ)ﾉ

      local mark = player:getTableMark("@[tianshu]")
      table.insert(mark, {
        skillName = self.name,
        skillTimes = info[3] == player.id and 2 or 1,
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
  qml_path = ""
}
Fk:addSkill(tianshu_active)
nanhualaoxian:addSkill(qingshu)
nanhualaoxian:addSkill(ol__shoushu)
nanhualaoxian:addSkill(hedao)
Fk:loadTranslationTable{
  ["ol__nanhualaoxian"] = "南华老仙",
  ["#ol__nanhualaoxian"] = "逍遥仙游",
  --["designer:ol__nanhualaoxian"] = "",

  ["qingshu"] = "青书",
  [":qingshu"] = "锁定技，游戏开始时，你的准备阶段和结束阶段，你书写一册<a href='tianshu_href'>“天书”</a>。",
  ["ol__shoushu"] = "授术",
  [":ol__shoushu"] = "出牌阶段限一次，你可以将一册未翻开的<a href='tianshu_href'>“天书”</a>交给一名其他角色。",
  ["tianshu_href"] = "从随机三个时机和三个效果中各选择一个组合为一个“天书”技能。<br>"..
    "“天书”技能初始可使用两次，若交给其他角色则可使用次数改为一次，当次数用完后销毁。<br>"..
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
  [":tianshu_effects23"] = "你可以摸3张牌并翻面",
  [":tianshu_effects24"] = "你可以令你对一名角色使用牌无距离次数限制直到你的回合结束",
  [":tianshu_effects25"] = "你可以弃置两张牌，令你和一名其他角色各回复1点体力",
  [":tianshu_effects26"] = "你可以令此伤害值+1",
  [":tianshu_effects27"] = "你可以失去1点体力，摸3张牌",
  [":tianshu_effects28"] = "你可以交换两名角色装备区的牌",
  [":tianshu_effects29"] = "你可以交换两名角色手牌区的牌",
  [":tianshu_effects30"] = "你可以防止此伤害，令伤害来源摸3张牌",

  [":tianshu_inner"] = "（还剩{1}次）{2}，{3}。",
  [":tianshu_unknown"] = "（还剩{1}次）未翻开的天书。",

  ["$qingshu1"] = "赤紫青黄，唯记万变其一。",
  ["$qingshu2"] = "天地万法，皆在此书之中。",
  ["$qingshu3"] = "以小篆记大道，则道可道。",
  ["$ol__shoushu1"] = "此书载天地至理，望汝珍视如命。",
  ["$ol__shoushu2"] = "天书非凡物，字字皆玄机。",
  ["$ol__shoushu3"] = "我得道成仙，当出世化生人中。",
  ["~ol__nanhualaoxian"] = "尔生异心，必获恶报！",
}

local wuanguo = General(extension, "ol__wuanguo", "qun", 4)
local liyongw = fk.CreateActiveSkill{
  name = "liyongw",
  switch_skill_name = "liyongw",
  anim_type = "switch",
  card_num = 1,
  min_target_num = 1,
  prompt = function(self)
    return "#liyongw-"..Self:getSwitchSkillState(self.name, false, true)
  end,
  expand_pile = function (self)
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return Self:getHandlyIds(false)
    elseif Self:getSwitchSkillState(self.name, false) == fk.SwitchYin then
      return table.filter(Fk:currentRoom().discard_pile, function (id)
        return table.contains(Self:getTableMark("@liyongw-turn"), Fk:getCardById(id):getSuitString(true))
      end)
    end
  end,
  can_use = Util.TrueFunc,
  card_filter = function (self, to_select, selected)
    if #selected == 0 then
      if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
        local suit = Fk:getCardById(to_select):getSuitString(true)
        if suit == "log_nosuit" then return end
        local card = Fk:cloneCard("duel")
        card.skillName = self.name
        card:addSubcard(to_select)
        return Self:canUse(card) and not table.contains(Self:getTableMark("@liyongw-turn"), suit)
      elseif Self:getSwitchSkillState(self.name, false) == fk.SwitchYin then
        return table.contains(Fk:currentRoom().discard_pile, to_select)
      end
    end
  end,
  target_filter = function(self, to_select, selected, selected_cards, _, _, player)
    if player:getSwitchSkillState(self.name, false) == fk.SwitchYang and #selected_cards == 1 then
      local card = Fk:cloneCard("duel")
      card.skillName = self.name
      card:addSubcards(selected_cards)
      return card.skill:targetFilter(to_select, selected, {}, card, nil, player)
    elseif player:getSwitchSkillState(self.name, false) == fk.SwitchYin then
      return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):canUseTo(Fk:cloneCard("duel"), player)
    end
  end,
  feasible = function (self, selected, selected_cards)
    if #selected_cards == 1 then
      if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
        local card = Fk:cloneCard("duel")
        card.skillName = self.name
        card:addSubcards(selected_cards)
        return card.skill:feasible(selected, {}, Self, card)
      elseif Self:getSwitchSkillState(self.name, false) == fk.SwitchYin then
        return #selected == 1
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      room:sortPlayersByAction(effect.tos)
      local targets = table.map(effect.tos, Util.Id2PlayerMapper)
      room:useVirtualCard("duel", effect.cards, player, targets, self.name)
    else
      room:moveCardTo(effect.cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
      local target = room:getPlayerById(effect.tos[1])
      if not player.dead then
        room:useVirtualCard("duel", nil, target, player, self.name)
      end
    end
  end,
}

local liyongw_trigger = fk.CreateTriggerSkill{
  name = "#liyongw_trigger",

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill("liyongw", true) and player.phase == Player.Play and data.card.suit ~= Card.NoSuit
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getTableMark("@liyongw-turn")
    table.insertIfNeed(mark, data.card:getSuitString(true))
    player.room:setPlayerMark(player, "@liyongw-turn", mark)
  end,

  on_acquire = function (self, player, is_start)
    if not is_start and player.phase ~= Player.NotActive then
      local room = player.room
      local mark = {}
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        if use.from == player.id and use.card.suit ~= Card.NoSuit then
          table.insertIfNeed(mark, use.card:getSuitString(true))
        end
      end, Player.HistoryTurn)
      if #mark > 0 then
        room:setPlayerMark(player, "@liyongw-turn", mark)
      end
    end
  end,
}
liyongw:addRelatedSkill(liyongw_trigger)
wuanguo:addSkill(liyongw)
Fk:loadTranslationTable{
  ["ol__wuanguo"] = "武安国",

  ["liyongw"] = "历勇",
  [":liyongw"] = "转换技，出牌阶段，阳：你可以将一张本回合你未使用过的花色的牌当【决斗】使用；阴：你可以从弃牌堆获得一张你本回合使用过的花色的牌，"..
  "令一名角色视为对你使用一张【决斗】。",
  ["#liyongw-yang"] = "历勇：将一张本回合未使用花色的牌当【决斗】使用",
  ["#liyongw-yin"] = "历勇：获得弃牌堆中一张本回合已使用花色的牌，选择一名角色视为对你使用【决斗】",
  ["@liyongw-turn"] = "历勇",
}

local guozhao = General(extension, "ol__guozhao", "wei", 3, 3, General.Female)
local jiaoyu = fk.CreateTriggerSkill{
  name = "jiaoyu",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.RoundStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if event == fk.RoundStart then
      return player:hasSkill(self) and
        table.find({3, 4, 5, 6, 7}, function (sub_type)
          return player:hasEmptyEquipSlot(sub_type)
        end)
    elseif event == fk.EventPhaseEnd then
      return target == player and player.phase == Player.Finish and player:getMark("jiaoyu_extra_phase-round") > 0
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.RoundStart then
      room:setPlayerMark(player, "jiaoyu_extra_phase-round", 1)
      local n = #table.filter({3, 4, 5, 6, 7}, function (sub_type)
        return player:hasEmptyEquipSlot(sub_type)
      end)
      local cards = {}
      for _ = 1, n, 1 do
        local judge = {
          who = player,
          reason = self.name,
          pattern = ".",
        }
        room:judge(judge)
        if judge.card then
          table.insert(cards, judge.card.id)
        end
      end
      if not player.dead then
        local color = room:askForChoice(player, {"red", "black"}, self.name, "#jiaoyu-choice")
        room:setPlayerMark(player, "@jiaoyu-round", color)
        local get = table.filter(cards, function (id)
          return Fk:getCardById(id):getColorString() == color and room:getCardArea(id) == Card.DiscardPile
        end)
        if #get > 0 then
          room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
        end
      end
    elseif event == fk.EventPhaseEnd then
      room:setPlayerMark(player, "jiaoyu_extra_phase-round", 0)
      room:setPlayerMark(player, "jiaoyu_prohibit-turn", 1)
      player:gainAnExtraPhase(Player.Play)
    end
  end,

  refresh_events = {fk.EventPhaseStart, fk.Damaged},
  can_refresh = function (self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return target == player and player.phase == Player.Play and player:getMark("jiaoyu_prohibit-turn") > 0
    elseif event == fk.Damaged then
      return target == player and player:getMark("jiaoyu_damaged-phase") == 0 and
        table.find(player.room:getOtherPlayers(player), function (p)
          return p:getMark("jiaoyu_prohibit-phase") > 0
        end)
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:setPlayerMark(player, "jiaoyu_prohibit-turn", 0)
      room:setPlayerMark(player, "jiaoyu_prohibit-phase", 1)
    elseif event == fk.Damaged then
      room:setPlayerMark(player, "jiaoyu_damaged-phase", 1)
    end
  end,
}
local jiaoyu_prohibit = fk.CreateProhibitSkill{
  name = "#jiaoyu_prohibit",
  prohibit_use = function(self, player, card)
    local src = table.find(Fk:currentRoom().alive_players, function (p)
      return p:getMark("jiaoyu_prohibit-phase") > 0
    end)
    if src and src ~= player and player:getMark("jiaoyu_damaged-phase") == 0 then
      return table.find(src:getCardIds("e"), function (id)
        return card:compareColorWith(Fk:getCardById(id))
      end)
    end
  end,
}
local neixun = fk.CreateTriggerSkill{
  name = "neixun",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:getMark("@jiaoyu-round") ~= 0 and target ~= player and not target.dead and
      data.card.type ~= Card.TypeEquip then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil or turn_event.data[1] ~= target then return end
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        return use.from == target.id and use.card.type ~= Card.TypeEquip
      end, Player.HistoryTurn)
      if #events == 1 and events[1] == player.room.logic:getCurrentEvent() then
        if data.card:getColorString() == player:getMark("@jiaoyu-round") then
          return not player:isNude()
        else
          return not target:isNude()
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card:getColorString() == player:getMark("@jiaoyu-round") then
      local card = room:askForCard(player, 1, 1, true, self.name, false, nil, "#neixun-give::"..target.id)
      room:moveCardTo(card, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id)
      if not player.dead then
        player:drawCards(1, self.name, "top", "@@neixun-inhand")
      end
    else
      local card = room:askForCardChosen(player, target, "he", self.name, "#neixun-prey::"..target.id)
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id, "@@neixun-inhand")
      if not target.dead then
        target:drawCards(1, self.name)
      end
    end
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function (self, event, target, player, data)
    return target == player and not player:isKongcheng()
  end,
  on_refresh = function (self, event, target, player, data)
    for _, id in ipairs(player:getCardIds("h")) do
      player.room:setCardMark(Fk:getCardById(id), "@@neixun-inhand", 0)
    end
  end,
}
local neixun_maxcards = fk.CreateMaxCardsSkill{
  name = "#neixun_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@neixun-inhand") > 0
  end,
}
jiaoyu:addRelatedSkill(jiaoyu_prohibit)
neixun:addRelatedSkill(neixun_maxcards)
guozhao:addSkill(jiaoyu)
guozhao:addSkill(neixun)
Fk:loadTranslationTable{
  ["ol__guozhao"] = "郭照",
  --["#ol__guozhao"] = "",
  --["illustrator:ol__guozhao"] = "",
}
Fk:loadTranslationTable{
  ["jiaoyu"] = "椒遇",
  [":jiaoyu"] = "锁定技，每轮开始时，你判定X次（X为你空置装备栏数），然后声明一种颜色并获得弃牌堆里此颜色的判定牌。"..
  "你的下个回合的结束阶段结束时，你获得一个额外出牌阶段，此阶段内其他角色不能使用与你装备区内牌颜色相同的牌直到其受到伤害后。",
  ["@jiaoyu-round"] = "椒遇",
  ["#jiaoyu-choice"] = "椒遇：选择获得一种颜色的判定牌",
}
Fk:loadTranslationTable{
  ["neixun"] = "内训",
  [":neixun"] = "锁定技，其他角色于其回合内使用第一张不为装备牌的牌后，若此牌与你上次发动〖椒遇〗时声明的颜色相同/不同，"..
  "你将一张牌交给其/获得其一张牌，你/其摸一张牌。直到你的下个回合结束之前，你以此法得到的牌不计入手牌上限。",
  ["#neixun-give"] = "内训：你需交给 %dest 一张牌",
  ["#neixun-prey"] = "内训：获得 %dest 一张牌",
  ["@@neixun-inhand"] = "内训",
}

local liuzhang = General(extension, "ol__liuzhang", "qun", 3)
local fengwei = fk.CreateTriggerSkill{
  name = "fengwei",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.RoundStart},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"1", "2", "3", "4"}, self.name, "#fengwei-choice")
    player:drawCards(tonumber(choice), self.name, "top", "@@fengwei-inhand-round")
  end,
}
local fengwei_delay = fk.CreateTriggerSkill{
  name = "#fengwei_delay",

  refresh_events = {fk.DamageInflicted},
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card and table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@fengwei-inhand-round") > 0
    end)
  end,
  on_refresh = function (self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local zonghu = fk.CreateViewAsSkill{
  name = "zonghu",
  pattern = "slash,jink",
  prompt = function (self)
    return "#zonghu:::"..math.min(Fk:currentRoom():getBanner("RoundCount"), 3)
  end,
  interaction = function(self)
    local all_names = {"slash", "jink"}
    local names = U.getViewAsCardNames(Self, self.name, all_names)
    if #names > 0 then
      return U.CardNameBox {choices = names, all_choices = all_names}
    end
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function (self, player, use)
    local room = player.room
    local n = math.min(room:getBanner("RoundCount"), 3)
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local to, cards = room:askForChooseCardsAndPlayers(player, n, n, targets, 1, 1, nil,
      "#zonghu-give:::"..n, self.name, false, false)
    room:moveCardTo(cards, Card.PlayerHand, to[1], fk.ReasonGive, self.name, nil, false, player.id)
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      #player:getCardIds("he") >= math.min(Fk:currentRoom():getBanner("RoundCount"), 3)
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      #player:getCardIds("he") >= math.min(Fk:currentRoom():getBanner("RoundCount"), 3) and
      #Fk:currentRoom().alive_players > 1 and
      #U.getViewAsCardNames(player, self.name, {"slash", "jink"}) > 0
  end,
}
fengwei:addRelatedSkill(fengwei_delay)
liuzhang:addSkill(fengwei)
liuzhang:addSkill(zonghu)
Fk:loadTranslationTable{
  ["ol__liuzhang"] = "刘璋",
  --["#ol__liuzhang"] = "",
}
Fk:loadTranslationTable{
  ["fengwei"] = "丰蔚",
  [":fengwei"] = "锁定技，每轮开始时，你摸至多四张牌；当你手牌中有本轮以此法获得的牌时，你受到牌造成的伤害+1。",
  ["#fengwei-choice"] = "丰蔚：摸至多四张牌，本轮手牌中有这些牌时受到伤害+1",
  ["@@fengwei-inhand-round"] = "丰蔚",
}
Fk:loadTranslationTable{
  ["zonghu"] = "宗护",
  [":zonghu"] = "每回合限一次，当你需要使用【杀】或【闪】时，你可以将X张牌交给一名其他角色，然后视为你使用之（X为游戏轮数，至多为3）。",
  ["#zonghu"] = "宗护：交给一名角色%arg张牌，视为使用【杀】或【闪】（先选择要使用的牌和目标，再交出牌）",
  ["#zonghu-give"] = "宗护：交给一名角色%arg张牌",
}


local yuanhuan = General(extension, "ol__yuanhuan", "qun", 3)
local deru = fk.CreateActiveSkill{
  name = "deru",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#deru",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local all_names = U.getAllCardNames("b", true)
    local choices = U.askForChooseCardNames(room, player, all_names, 0, #all_names, self.name,
      "#deru-choice::"..target.id, all_names, false, false)
    local names = {}
    for _, id in ipairs(target:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic then
        table.insertIfNeed(names, card.trueName)
      end
    end
    local n = 0
    for _, name in ipairs(all_names) do
      if (table.contains(choices, name) and table.contains(names, name)) or
        (not table.contains(choices, name) and not table.contains(names, name)) then
        n = n + 1
      end
    end
    if n > 0 and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
      if player.dead then return end
    end
    if n < #all_names and not target.dead then
      local cards = table.filter(target:getCardIds("h"), function (id)
        return Fk:getCardById(id).type == Card.TypeBasic
      end)
      if #cards > 0 then
        room:moveCardTo(table.random(cards), Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      end
      if player.dead then return end
    end
    if n == #all_names and player:getHandcardNum() < player.hp then
      player:drawCards(player.hp - player:getHandcardNum(), self.name)
    end
  end,
}
local linjie = fk.CreateTriggerSkill{
  name = "linjie",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead and not data.from:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.from.id})
    local card = room:askForDiscard(data.from, 1, 1, false, self.name, false)
    if #card > 0 and Fk:getCardById(card[1]).trueName == "slash" and not player.dead then
      player:drawCards(1, self.name)
    end
  end,
}
yuanhuan:addSkill(deru)
yuanhuan:addSkill(linjie)
Fk:loadTranslationTable{
  ["ol__yuanhuan"] = "袁涣",
  --["#ol__yuanhuan"] = "",

  ["deru"] = "德辱",
  [":deru"] = "出牌阶段限一次，你可以猜测一名其他角色手牌中的基本牌牌名，若你：有猜对，你回复1点体力；有猜错，随机获得其一张基本牌；全猜对，"..
  "你将手牌摸至体力值。",
  ["linjie"] = "临节",
  [":linjie"] = "锁定技，当你受到伤害后，伤害来源须弃置一张手牌，若为【杀】，你摸一张牌。",
  ["#deru"] = "德辱：选择一名角色，猜测其手牌中的基本牌牌名",
  ["#deru-choice"] = "德辱：选择你认为 %dest 手牌中有的基本牌",
}

local yangfeng = General(extension, "ol__yangfeng", "qun", 4)
local jiawei = fk.CreateTriggerSkill{
  name = "jiawei",
  anim_type = "offensive",
  events = {fk.TurnEnd},
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(self) and #player:getHandlyIds() > 0 then
      local targets = {}
      player.room.logic:getEventsOfScope(GameEvent.CardEffect, 1, function (e)
        local effect = e.data[1]
        if effect.card.trueName == "slash" and effect.isCancellOut then
          local to = player.room:getPlayerById(effect.to)
          if to ~= player and not to.dead then
            table.insertIfNeed(targets, effect.to)
          end
        end
      end, Player.HistoryTurn)
      if #targets > 0 then
        self.cost_data = {tos = targets}
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local success, dat = player.room:askForUseActiveSkill(player, "jiawei_viewas", "#jiawei-use", true,
      {
        exclusive_targets = self.cost_data.tos,
      })
    if success and dat then
      self.cost_data = {tos = dat.targets, cards = dat.cards}
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local use = room:useVirtualCard("duel", self.cost_data.cards, player, table.map(self.cost_data.tos, Util.Id2PlayerMapper), self.name)
    if use and use.damageDealt and not player.dead and player:getMark("jiawei-round") == 0 then
      local tos = {}
      if player:getHandcardNum() < math.min(player:getMaxCards(), 5) then
        table.insert(tos, player.id)
      end
      if not target.dead and target:getHandcardNum() < math.min(target:getMaxCards(), 5) then
        table.insertIfNeed(tos, target.id)
      end
      if #tos > 0 then
        local to = room:askForChoosePlayers(player, tos, 1, 1, "#jiawei-choose", self.name, true)
        if #to > 0 then
          room:setPlayerMark(player, "jiawei-round", 1)
          to = room:getPlayerById(to[1])
          to:drawCards(math.min(to:getMaxCards(), 5) - to:getHandcardNum(), self.name)
        end
      end
    end
  end,
}
local jiawei_viewas = fk.CreateViewAsSkill{
  name = "jiawei_viewas",
  handly_pile = true,
  card_filter = function(self, to_select, selected)
    return table.contains(Self:getHandlyIds(), to_select)
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("duel")
    card:addSubcards(cards)
    card.skillName = "jiawei"
    return card
  end,
}
Fk:addSkill(jiawei_viewas)
yangfeng:addSkill(jiawei)
Fk:loadTranslationTable{
  ["ol__yangfeng"] = "杨奉",
  --["#ol__yangfeng"] = "",

  ["jiawei"] = "假威",
  [":jiawei"] = "【杀】被抵消的回合结束时，你可以将任意张手牌当【决斗】对本回合抵消过【杀】的一名角色使用。每轮限一次，若此【决斗】造成伤害，"..
  "你可以令你或当前回合角色将手牌摸至手牌上限（至多摸至5）。",
  ["jiawei_viewas"] = "假威",
  ["#jiawei-use"] = "假威：你可以将任意张手牌当【决斗】对其中一名角色使用",
  ["#jiawei-choose"] = "假威：你可以令一名角色将手牌摸至手牌上限",
}

local hanshiwuhu = General(extension, "hanshiwuhu", "wei", 5)

Fk:loadTranslationTable{
  ["hanshiwuhu"] = "韩氏五虎",
  --["#hanshiwuhu"] = "",
  ["~hanshiwuhu"] = "",
}

local juejue = fk.CreateTriggerSkill{
  name = "juejueh",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.CardUsing then
      return player == target and table.contains({"slash", "jink", "peach", "analeptic"}, data.card.trueName) and
        not table.contains(player:getTableMark("juejueh_used"), data.card.trueName)
    else
      return data.extra_data and data.extra_data.juejueh and table.contains(data.extra_data.juejueh, player.id) and
        U.hasFullRealCard(player.room, data.card)
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.CardUsing then
      player.room:addTableMark(player, "juejueh_used", data.card.trueName)
      data.additionalRecover = (data.additionalRecover or 0) + 1
      data.additionalDamage = (data.additionalDamage or 0) + 1
      if not data.extraUse then
        player:addCardUseHistory(data.card.trueName, -1)
        data.extraUse = true
      end
      data.extra_data = data.extra_data or {}
      data.extra_data.juejueh = data.extra_data.juejueh or {}
      table.insert(data.extra_data.juejueh, player.id)
    else
      player.room:obtainCard(player, data.card, true, fk.ReasonJustMove, player.id, self.name)
    end
  end,

  on_lose = function (self, player)
    player.room:setPlayerMark(player, "juejueh_used", 0)
  end,
}

hanshiwuhu:addSkill(juejue)

Fk:loadTranslationTable{
  ["juejueh"] = "玨玨",
  [":juejueh"] = "锁定技，当你使用【杀】、【闪】、【桃】或【酒】时（每种牌名限一次），你令此牌的伤害值基数及回复值基数+1且不计次数，"..
    "此牌结算结束后，你获得之。",
}

local pimi = fk.CreateTriggerSkill{
  name = "pimi",
  anim_type = "offensive",
  events = {fk.TargetSpecified, fk.TargetConfirmed, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.CardUseFinished then
      if data.extra_data and data.extra_data.pimi and table.contains(data.extra_data.pimi, player.id) then
        local room = player.room
        local from = room:getPlayerById(data.from)
        if from.dead then return false end
        local isbig, issmall = true, true
        local x, y = from:getHandcardNum()
        for _, p in ipairs(room.alive_players) do
          y = p:getHandcardNum()
          if y > x then
            isbig = false
          elseif y < x then
            issmall = false
          end
        end
        return isbig or issmall
      end
    else
      if player ~= target then return false end
      local room = player.room
      if not U.isOnlyTarget(data.to, data, event) then return false end
      if event == fk.TargetSpecified then
        return player.id ~= data.to and not player:isNude()
      elseif player.id ~= data.from then
        local from = room:getPlayerById(data.from)
        return not (from.dead or from:isNude())
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetSpecified then
      local cards = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".",
      "#pimi-invoke::" .. data.from .. ":" .. data.card:toLogString(), true)
      if #cards > 0 then
        self.cost_data = { tos = { data.to }, cards = cards }
        return true
      end
    elseif event == fk.TargetConfirmed then
      if player.room:askForSkillInvoke(player, self.name, nil,
      "#pimi-invoke::" .. data.from .. ":" .. data.card:toLogString()) then
        self.cost_data = { tos = { data.from } }
        return true
      end
    else
      self.cost_data = {}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      room:drawCards(player, 1, self.name)
      if player.dead then return false end
      room:invalidateSkill(player, self.name, "-turn")
    else
      if event == fk.TargetSpecified then
        room:throwCard(self.cost_data.cards, self.name, player, player)
      else
        local to = room:getPlayerById(data.from)
        room:throwCard(room:askForCardChosen(player, to, "he", self.name), self.name, to, player)
      end
      data.additionalRecover = (data.additionalRecover or 0) + 1
      data.additionalDamage = (data.additionalDamage or 0) + 1
      data.extra_data = data.extra_data or {}
      data.extra_data.pimi = data.extra_data.pimi or {}
      table.insert(data.extra_data.pimi, player.id)
    end
  end,
}

hanshiwuhu:addSkill(pimi)

Fk:loadTranslationTable{
  ["pimi"] = "披靡",
  [":pimi"] = "当你使用的牌指定其他角色为唯一目标后，或当你成为其他角色使用的牌的唯一目标后，你可以弃置使用者的一张牌，"..
    "令此牌的伤害值基数及回复值基数+1，此牌结算结束后，若使用者为手牌数最大或最小的角色，你摸一张牌，此技能于当前回合内无效。",

  ["#pimi-invoke"] = "是否发动 披靡，弃置 %dest 的一张牌，令%arg的伤害、回复+1",
}

return extension
