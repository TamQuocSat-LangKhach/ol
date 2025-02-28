
local guhuo = fk.CreateSkill{
  name = "ol_ex__guhuo",
}

local U = require "packages/utility/utility"

Fk:loadTranslationTable {
  ["ol_ex__guhuo"] = "蛊惑",
  [":ol_ex__guhuo"] = "每回合限一次，你可以扣置一张手牌，将此牌当任意一张基本牌或普通锦囊牌使用或打出。此牌使用前，其他角色同时选择是否质疑，"..
  "选择结束后，若有质疑则翻开此牌，若此牌为：假，此牌作废且所有质疑角色摸一张牌；真，所有质疑角色依次弃置一张牌或失去1点体力，然后获得技能〖缠怨〗。",

  ["#ol_ex__guhuo-discard"] = "蛊惑：弃置一张牌，否则失去1点体力",

  ["$ol_ex__guhuo1"] = "真真假假，虚实难测。",
  ["$ol_ex__guhuo2"] = "这牌，猜对了吗？",
}

guhuo:addEffect("viewas", {
  pattern = ".",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("bt")
    local names = player:getViewAsCardNames("ol_ex__guhuo", all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    self.cost_data = cards
    card.skillName = guhuo.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local cards = self.cost_data
    local card_id = cards[1]
    room:moveCardTo(cards, Card.Processing, nil, fk.ReasonPut, guhuo.name, nil, false, player)
    local targets = use.tos
    if targets and #targets > 0 then
      room:sendLog{
        type = "#guhuo_use",
        from = player.id,
        to = targets,
        arg = use.card.name,
        arg2 = guhuo.name,
      }

      room:doIndicate(player, targets)
    else
      room:sendLog{
        type = "#guhuo_no_target",
        from = player.id,
        arg = use.card.name,
        arg2 = guhuo.name,
      }
    end

    local canuse = true
    local players = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:hasSkill("ol_ex__chanyuan")
    end)
    if #players > 0 then
      local questioners = {}
      local result = U.askForJointChoice(players, {"noquestion", "question"}, guhuo.name,
        "#guhuo-ask::"..player.id..":"..use.card.name, true)
      for _, p in ipairs(players) do
        if result[p] == "question" then
          table.insert(questioners, p)
        end
      end
      if #questioners > 0 then
        player:showCards(card_id)
        if use.card.name == Fk:getCardById(card_id).name then
          room:setCardEmotion(card_id, "judgegood")
          for _, p in ipairs(questioners) do
            if not p.dead then
              if #room:askToDiscard(p, {
                min_num = 1,
                max_num = 1,
                include_equip = true,
                skill_name = guhuo.name,
                cancelable = true,
                prompt = "#ol_ex__guhuo-discard",
              }) == 0 then
                room:loseHp(p, 1, guhuo.name)
              end
            end
            room:handleAddLoseSkills(p, "ol_ex__chanyuan")
          end
        else
          room:setCardEmotion(card_id, "judgebad")
          for _, p in ipairs(questioners) do
            if not p.dead then
              p:drawCards(1, guhuo.name)
            end
          end
          canuse = false
        end
      end
    end

    if canuse then
      use.card:addSubcard(card_id)
    else
      room:moveCardTo(card_id, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, guhuo.name)
      return ""
    end
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(guhuo.name, Player.HistoryTurn) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not player:isKongcheng() and player:usedSkillTimes(guhuo.name, Player.HistoryTurn) == 0
  end,
})

return guhuo
