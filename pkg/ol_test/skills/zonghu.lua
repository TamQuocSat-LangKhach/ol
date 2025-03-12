local zonghu = fk.CreateSkill{
  name = "zonghu",
}

Fk:loadTranslationTable{
  ["zonghu"] = "宗护",
  [":zonghu"] = "每回合限一次，当你需要使用【杀】或【闪】时，你可以将X张牌交给一名其他角色，然后视为你使用之（X为游戏轮数，至多为3）。",

  ["#zonghu"] = "宗护：交给一名角色%arg张牌，视为使用【杀】或【闪】（先选择要使用的牌和目标，再交出牌）",
  ["#zonghu-give"] = "宗护：交给一名角色%arg张牌",

  ["$zonghu1"] = "",
  ["$zonghu2"] = "",
}

local U = require "packages/utility/utility"

zonghu:addEffect("viewas", {
  pattern = "slash,jink",
  prompt = function (self, player)
    return "#zonghu:::"..math.min(Fk:currentRoom():getBanner("RoundCount"), 3)
  end,
  interaction = function(self, player)
    local all_names = {"slash", "jink"}
    local names = player:getViewAsCardNames(zonghu.name, all_names)
    if #names > 0 then
      return U.CardNameBox {choices = names, all_choices = all_names}
    end
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = zonghu.name
    return card
  end,
  before_use = function (self, player, use)
    local room = player.room
    local n = math.min(room:getBanner("RoundCount"), 3)
    local to, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = n,
      max_card_num = n,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = zonghu.name,
      prompt = "#zonghu-give:::"..n,
      cancelable = false,
    })
    room:moveCardTo(cards, Card.PlayerHand, to[1], fk.ReasonGive, zonghu.name, nil, false, player)
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(zonghu.name, Player.HistoryTurn) == 0 and
      #player:getCardIds("he") >= math.min(Fk:currentRoom():getBanner("RoundCount"), 3)
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(zonghu.name, Player.HistoryTurn) == 0 and
      #player:getCardIds("he") >= math.min(Fk:currentRoom():getBanner("RoundCount"), 3) and
      #Fk:currentRoom().alive_players > 1 and
      #player:getViewAsCardNames(zonghu.name, {"slash", "jink"}) > 0
  end,
})

return zonghu
