local jinzhi = fk.CreateSkill{
  name = "jinzhi",
}

Fk:loadTranslationTable{
  ["jinzhi"] = "锦织",
  [":jinzhi"] = "当你需使用或打出基本牌时，你可以弃置X张颜色相同的牌（为你本轮发动本技能的次数），然后摸一张牌，视为使用或打出此基本牌。",

  ["#jinzhi"] = "锦织：弃置%arg张颜色相同的牌并摸一张牌，视为使用或打出一张基本牌",

  ["$jinzhi1"] = "织锦为旗，以扬威仪。",
  ["$jinzhi2"] = "坐而织锦，立则为仪。",
}

local U = require "packages/utility/utility"

jinzhi:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = function (self, player)
    return "#jinzhi:::"..(player:usedSkillTimes(jinzhi.name, Player.HistoryRound) + 1)
  end,
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(jinzhi.name, all_names)
    return U.CardNameBox { choices = names, all_choices = all_names, }
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected < player:usedSkillTimes(jinzhi.name, Player.HistoryRound) + 1 and
      table.every(selected, function (id)
        return Fk:getCardById(id):compareColorWith(Fk:getCardById(to_select))
      end) and
      not player:prohibitDiscard(to_select)
  end,
  view_as = function(self, player, cards)
    if #cards < player:usedSkillTimes(jinzhi.name, Player.HistoryRound) + 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = jinzhi.name
    self.cost_data = cards
    return card
  end,
  before_use = function(self, player)
    player.room:throwCard(self.cost_data, jinzhi.name, player, player)
    if not player.dead then
      player:drawCards(1, jinzhi.name)
    end
  end,
  enabled_at_play = function(self, player)
    return #player:getCardIds("he") >= player:usedSkillTimes(jinzhi.name, Player.HistoryRound) + 1
  end,
  enabled_at_response = function(self, player, response)
    return #player:getCardIds("he") >= player:usedSkillTimes(jinzhi.name, Player.HistoryRound) + 1
  end,
})

return jinzhi
