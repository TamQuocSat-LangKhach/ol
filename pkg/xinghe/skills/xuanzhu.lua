local xuanzhu = fk.CreateSkill{
  name = "xuanzhu",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["xuanzhu"] = "玄注",
  [":xuanzhu"] = "转换技，每回合限一次，阳：你可以将一张牌移出游戏，视为使用任意基本牌；"..
  "阴：你可以将一张牌移出游戏，视为使用仅指定唯一角色为目标的普通锦囊牌。"..
  "若移出游戏的牌：不为装备牌，你弃置一张牌；为装备牌，你重铸以此法移出游戏的牌。",

  ["#xuanzhu-yang"] = "玄注：将一张牌移出游戏，视为使用任意基本牌",
  ["#xuanzhu-yin"] = "玄注：将一张牌移出游戏，视为使用单目标普通锦囊牌",

  ["$xuanzhu1"] = "提笔注太玄，佐国定江山。",
  ["$xuanzhu2"] = "总太玄之要，纵弼国之实。",
}

local U = require "packages/utility/utility"

xuanzhu:addEffect("viewas", {
  anim_type = "switch",
  derived_piles = "xuanzhu",
  pattern = ".",
  prompt = function (self, player)
    return "#xuanzhu:::"..player:getSwitchSkillState(xuanzhu.name, false, true)
  end,
  interaction = function(self, player)
    local all_names = {}
    if player:getSwitchSkillState(xuanzhu.name, false) == fk.SwitchYang then
      all_names = Fk:getAllCardNames("b")
    else
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card:isCommonTrick() and not (card.is_derived or card.multiple_targets or card.is_passive) then
          table.insertIfNeed(all_names, card.name)
        end
      end
    end
    local names = player:getViewAsCardNames(xuanzhu.name, all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    self.cost_data = cards
    card.skillName = xuanzhu.name
    return card
  end,
  before_use = function(self, player, use)
    local cards = self.cost_data
    if Fk:getCardById(cards[1]).type == Card.TypeEquip then
      use.extra_data = use.extra_data or {}
      use.extra_data.xuanzhu_equip = true
    end
    player:addToPile(xuanzhu.name, cards, true, xuanzhu.name)
  end,
  after_use = function(self, player, use)
    if player.dead then return end
    if use.extra_data and use.extra_data.xuanzhu_equip then
      local cards = player:getPile(xuanzhu.name)
      if #cards > 0 then
        player.room:recastCard(cards, player)
      end
    else
      player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = xuanzhu.name,
        cancelable = false,
      })
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(xuanzhu.name, Player.HistoryTurn) == 0
  end,
  enabled_at_response = function(self, player, response)
    if not response and player:usedSkillTimes(xuanzhu.name, Player.HistoryTurn) == 0 then
      local all_names = {}
      if player:getSwitchSkillState(xuanzhu.name, false) == fk.SwitchYang then
        all_names = Fk:getAllCardNames("b")
      else
        for _, id in ipairs(Fk:getAllCardIds()) do
          local card = Fk:getCardById(id)
          if card:isCommonTrick() and not (card.is_derived or card.multiple_targets or card.is_passive) then
            table.insertIfNeed(all_names, card.name)
          end
        end
      end
      return #player:getViewAsCardNames(xuanzhu.name, all_names) > 0
    end
  end,
})

return xuanzhu
