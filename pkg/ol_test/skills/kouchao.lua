local kouchao = fk.CreateSkill{
  name = "kouchao",
}

Fk:loadTranslationTable{
  ["kouchao"] = "寇钞",
  [":kouchao"] = "每轮每项限一次，你可以将一张牌当【杀】/【火攻】/【过河拆桥】使用，然后将此项改为最后不因使用而置入弃牌堆的基本牌或普通锦囊牌，" ..
  "然后若所有项均为基本牌，将所有项改为【顺手牵羊】。",

  ["#kouchao"] = "寇钞：将一张牌当一种“寇钞”牌使用，每轮每项限一次",
  ["@$kouchao"] = "寇钞",
  ["kouchao_index"] = "[%arg] "..Fk:translate("%arg2"),
}

local U = require "packages/utility/utility"

kouchao:addAcquireEffect(function (self, player)
  local room = player.room
  room:setPlayerMark(player, "kouchao1", "slash")
  room:setPlayerMark(player, "kouchao2", "fire_attack")
  room:setPlayerMark(player, "kouchao3", "dismantlement")
  room:setPlayerMark(player, "@$kouchao", {"slash", "fire_attack", "dismantlement"})
end)

kouchao:addLoseEffect(function (self, player)
  local room = player.room
  room:setPlayerMark(player, "kouchao1", 0)
  room:setPlayerMark(player, "kouchao2", 0)
  room:setPlayerMark(player, "kouchao3", 0)
  room:setPlayerMark(player, "@$kouchao", 0)
end)

kouchao:addEffect("viewas", {
  prompt = "#kouchao",
  pattern = ".",
  interaction = function(self, player)
    local all_names = player:getTableMark("@$kouchao")
    local names = {}
    for i = 1, 3, 1 do
      local card_name = all_names[i]
      all_names[i] = "kouchao_index:::"..i..":"..card_name
      if player:getMark("kouchao"..i.."-round") == 0 and
        #player:getViewAsCardNames(kouchao.name, {card_name}) > 0 then
        table.insert(names, all_names[i])
      end
    end
    if #names > 0 then
      return UI.ComboBox { choices = names, all_choices = all_names }
    end
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and self.interaction.data
  end,
  view_as = function(self, player, cards)
    if #cards == 0 or not self.interaction.data then return end
    local card = Fk:cloneCard(string.split(self.interaction.data, ":")[5])
    card:addSubcards(cards)
    card.skillName = kouchao.name
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
  enabled_at_response = function(self, player, response)
    if not response and not player:isNude() and Fk.currentResponsePattern then
      local mark = player:getTableMark("@$kouchao")
      for i = 1, 3, 1 do
        if player:getMark("kouchao"..i.."-round") == 0 and
          #player:getViewAsCardNames(kouchao.name, {mark[i]}) > 0 then
          return true
        end
      end
    end
  end,
})

return kouchao
