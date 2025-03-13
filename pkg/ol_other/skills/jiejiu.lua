local jiejiu = fk.CreateSkill{
  name = "jiejiu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiejiu"] = "戒酒",
  [":jiejiu"] = "锁定技，你的【酒】仅能当其他基本牌使用。游戏开始时，将其他女性角色武将牌上随机一个技能替换为〖离间〗。",

  ["#jiejiu"] = "戒酒：仅能将【酒】当其他基本牌使用",

  ["$jiejiu"] = "我被酒色所伤，竟然如此憔悴。自今日始，戒酒！",
}

local U = require "packages/utility/utility"

jiejiu:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = "#jiejiu",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(jiejiu.name, all_names, nil, {"analeptic"})
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "analeptic"
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = jiejiu.name
    return card
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})
jiejiu:addEffect(fk.GameStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiejiu.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:isFemale() then
        local skills = Fk.generals[p.general]:getSkillNameList(true)
        if #skills > 0 then
          room:handleAddLoseSkills(p, "lijian|-"..table.random(skills))
        end
      end
    end
  end,
})
jiejiu:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if not player:hasSkill(jiejiu.name) or not card or card.trueName ~= "analeptic" or #card.skillNames > 0 then return end
    local subcards = Card:getIdList(card)
    return #subcards > 0 and table.every(subcards, function(id)
      return table.contains(player:getHandlyIds(), id)
    end)
  end,
})

return jiejiu
