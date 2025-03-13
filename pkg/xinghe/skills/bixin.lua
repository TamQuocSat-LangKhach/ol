local bixin = fk.CreateSkill{
  name = "bixin",
}

Fk:loadTranslationTable{
  ["bixin"] = "笔心",
  [":bixin"] = "每名角色的准备阶段和结束阶段，你可以声明一种牌的类型并摸3张牌（每种类型限1次），将所有此类型手牌当你本轮未使用过的基本牌使用。",

  ["#bixin"] = "笔心：你可以声明一种牌的类型并摸%arg张牌，将所有此类型手牌当一种基本牌使用",
  ["bixin_basic"] = "基本牌%arg",
  ["bixin_trick"] = "锦囊牌%arg",
  ["bixin_equip"] = "装备牌%arg",
  ["bixin_times0"] = "[0/3]",
  ["bixin_times1"] = "[1/3]",
  ["bixin_times2"] = "[2/3]",

  [":bixin_inner"] = "{1}{2}{3}你可以声明一种牌的类型并摸{4}张牌（每种类型限{5}次），将所有此类型手牌当你本轮未使用过的基本牌使用。",
  ["bixin_piece1"] = "每名角色的",
  ["bixin_piece2"] = "准备阶段和",
  ["bixin_piece3"] = "结束阶段，",

  ["$bixin1"] = "携笔落云藻，文书剖纤毫。",
  ["$bixin2"] = "执纸抒胸臆，挥笔涕汍澜。",
}

local U = require "packages/utility/utility"

bixin:addEffect("viewas", {
  dynamic_desc = function(self, player)
    local x = player:usedSkillTimes("ximo", Player.HistoryGame)
    local text = "bixin_inner:"
    for i = 1, 3, 1 do
      text = text .. (i <= x and "" or "bixin_piece"..i) .. ":"
    end
    if x >= 3 then
      text = text .. "1:3"
    else
      text = text .. "3:1"
    end
    return text
  end,
  pattern = ".|.|.|.|.|basic",
  prompt = function (self, player, selected_cards, selected)
    local n = player:usedSkillTimes("ximo", Player.HistoryGame) >= 3 and 1 or 3
    return "#bixin:::"..n
  end,
  expand_pile = function(self, player)
    return player:getTableMark("bixin_cards")
  end,
  interaction = function(self, player)
    local types, choices, all_choices = {"basic", "trick", "equip"}, {}, {}
    local x = 0
    local choice = ""
    for _, card_type in ipairs(types) do
      x = (player:usedSkillTimes("ximo", Player.HistoryGame) >= 3 and 3 or 1) - player:getMark("bixin_" .. card_type)
      choice = "bixin_"..card_type..":::bixin_times"..x
      table.insert(all_choices, choice)
      if x > 0 then
        table.insert(choices, choice)
      end
    end
    if #choices == 0 then return end
    return UI.ComboBox{ choices = choices, all_choices = all_choices }
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 or self.interaction.data == nil then return false end
    local mark = player:getTableMark("bixin_cards")
    if table.contains(mark, to_select) then
      local name = Fk:getCardById(to_select).name
      mark = player:getTableMark("bixin-round")
      if not table.contains(mark, name) then
        local card = Fk:cloneCard(name)
        card.skillName = bixin.name
        if player:prohibitUse(card) then return false end
        local pat = Fk.currentResponsePattern
        if pat == nil then
          return player:canUse(card)
        else
          return Exppattern:Parse(pat):match(card)
        end
      end
    end
  end,
  view_as = function(self, player, cards)
    if #cards == 1 and self.interaction.data ~= nil then
      local card = Fk:cloneCard(Fk:getCardById(cards[1]).name)
      card.skillName = bixin.name
      return card
    end
  end,
  before_use = function(self, player, use)
    local room = player.room
    local card_type = string.sub(self.interaction.data, 7, 11)
    room:addPlayerMark(player, "bixin_" .. card_type)
    player:drawCards(1, bixin.name)
    if player.dead then return "" end
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getTypeString() == card_type
    end)
    if #cards == 0 then return "" end
    use.card:addSubcards(cards)
    if player:prohibitUse(use.card) then return "" end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes("ximo", Player.HistoryGame) == 3 and
      (player:getMark("bixin_basic") < 3 or player:getMark("bixin_trick") < 3 or player:getMark("bixin_equip") < 3)
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes("ximo", Player.HistoryGame) == 3 and
      (player:getMark("bixin_basic") < 3 or player:getMark("bixin_trick") < 3 or player:getMark("bixin_equip") < 3)
  end,
})
bixin:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(bixin.name) and
      (player:getMark("bixin_basic") == 0 or player:getMark("bixin_trick") == 0 or player:getMark("bixin_equip") == 0) then
      if player:usedSkillTimes("ximo", Player.HistoryGame) == 2 then
        return target == player and player.phase == Player.Finish
      elseif player:usedSkillTimes("ximo", Player.HistoryGame) == 1 then
        return target == player and (player.phase == Player.Start or player.phase == Player.Finish)
      elseif player:usedSkillTimes("ximo", Player.HistoryGame) == 0 then
        return target.phase == Player.Start or target.phase == Player.Finish
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("bixin_cards") == 0 then
      room:setPlayerMark(player, "bixin_cards", U.getUniversalCards(room, "b"))
    end
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = bixin.name,
      prompt = "#bixin:::3",
    })
    if success and dat then
      event:setCostData(self, {extra_data = dat})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = table.simpleClone(event:getCostData(self).extra_data)
    local card_type = dat.interaction:match("bixin_(.-):::")
    room:addPlayerMark(player, "bixin_" .. card_type)
    player:drawCards(3, bixin.name)
    if player.dead then return false end
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getTypeString() == card_type
    end)
    if #cards == 0 then return false end
    local card = Fk:cloneCard(Fk:getCardById(dat.cards[1]).name)
    card.skillName = bixin.name
    card:addSubcards(cards)
    if player:prohibitUse(card) then return false end
    room:useCard{
      from = player,
      tos = dat.targets,
      card = card,
    }
  end,
})

bixin:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(bixin.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, "bixin-round", data.card.name)
  end,
})
bixin:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    if room.logic:getCurrentEvent() then
      local names = {}
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        if use.from == player then
          table.insertIfNeed(names, use.card.name)
        end
      end, Player.HistoryRound)
      room:setPlayerMark(player, "bixin-round", names)
    end
  end
end)

return bixin
