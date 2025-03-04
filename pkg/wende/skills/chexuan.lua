local chexuan = fk.CreateSkill{
  name = "chexuan",
}

Fk:loadTranslationTable{
  ["chexuan"] = "车悬",
  [":chexuan"] = "出牌阶段，若你的装备区里没有宝物牌，你可以弃置一张黑色牌，选择一张“舆”置入你的装备区（此牌离开装备区时销毁）。"..
  "当你不因使用装备牌失去装备区里的宝物牌后，你可以判定，若结果为黑色，将一张随机的“舆”置入你的装备区。",

  ["#chexuan"] = "车悬：弃置一张黑色牌，选择一张“舆”置入你的装备区",
  ["#chexuan-ask"] = "车悬：选择一种“舆”置入你的装备区",
  ["#chexuan-invoke"] = "车悬：你可以判定，若结果为黑色，将一张随机的“舆”置入你的装备区",

  ["$chexuan1"] = "兵车疾动，以悬敌首！",
  ["$chexuan2"] = "层层布设，以多胜强！",
}

local U = require "packages/utility/utility"

local chexuan_cart = {
  {"wheel_cart", Card.Spade, 5},
  {"caltrop_cart", Card.Club, 5},
  {"grain_cart", Card.Heart, 5},
}

chexuan:addEffect("active", {
  prompt = "#chexuan",
  card_num = 1,
  can_use = function(self, player)
    return #player:getEquipments(Card.SubtypeTreasure) == 0 and player:hasEmptyEquipSlot(Card.SubtypeTreasure)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black and not player:prohibitDiscard(to_select)
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, chexuan.name, player, player)
    if player.dead or not player:hasEmptyEquipSlot(Card.SubtypeTreasure) then return end
    local carts = table.filter(U.prepareDeriveCards(room, chexuan_cart, "chexuan_derivecards"), function (id)
      return room:getCardArea(id) == Card.Void
    end)
    if #carts == 0 then return end
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = chexuan.name,
      pattern = tostring(Exppattern{ id = carts }),
      prompt = "#chexuan-ask",
      cancelable = false,
      expand_pile = carts,
    })
    room:setCardMark(Fk:getCardById(card[1]), MarkEnum.DestructOutMyEquip, 1)
    room:moveCardIntoEquip(player, card, chexuan.name, true, player)
  end,
})
chexuan:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chexuan.name) and player:hasEmptyEquipSlot(Card.SubtypeTreasure) then
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId).sub_type == Card.SubtypeTreasure then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chexuan.name,
      prompt = "#chexuan-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = chexuan.name,
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge:matchPattern() and not player.dead and player:hasEmptyEquipSlot(Card.SubtypeTreasure) then
      local carts = table.filter(U.prepareDeriveCards(room, chexuan_cart, "chexuan_derivecards"), function (id)
        return room:getCardArea(id) == Card.Void
      end)
      if #carts > 0 then
        local card = table.random(carts)
        room:setCardMark(Fk:getCardById(card), MarkEnum.DestructOutMyEquip, 1)
        room:moveCardIntoEquip(player, card, chexuan.name, true, player)
      end
    end
  end,
})

return chexuan
