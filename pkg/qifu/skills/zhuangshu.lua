local zhuangshu = fk.CreateSkill{
  name = "zhuangshu",
}

Fk:loadTranslationTable{
  ["zhuangshu"] = "妆梳",
  [":zhuangshu"] = "游戏开始时，你可以将一张“宝梳”置入你的装备区。"..
  "一名角色的回合开始时，你可以弃置一张牌，根据此牌的类别将对应的“宝梳”置入其装备区（基本牌-<a href=':jade_comb'>【琼梳】</a>、"..
  "锦囊牌-<a href=':rhino_comb'>【犀梳】</a>、装备牌-<a href=':golden_comb'>【金梳】</a>）。当“宝梳”进入非装备区时，销毁之。",

  ["#zhuangshu-ask"] = "妆梳：你可以选择一张“宝梳”置入你的装备区",
  ["#zhuangshu-invoke"] = "妆梳：你可以弃置一张牌，将对应种类的“宝梳”置入 %dest 的装备区：<br>基本牌-【琼梳】  锦囊牌-【犀梳】  装备牌-【金梳】",

  ["$zhuangshu1"] = "殿前妆梳，风姿绝世。",
  ["$zhuangshu2"] = "顾影徘徊，丰容靓饰。",
  ["$zhuangshu3"] = "鬓怯琼梳，朱颜消瘦。",
  ["$zhuangshu4"] = "犀梳斜插，醉倚阑干。",
  ["$zhuangshu5"] = "金梳富贵，蒙君宠幸。",
}

local U = require "packages/utility/utility"

local zhuangshu_combs = {{"jade_comb", Card.Spade, 12}, {"rhino_comb", Card.Club, 12}, {"golden_comb", Card.Heart, 12}}

zhuangshu:addEffect(fk.GameStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhuangshu.name) and player:hasEmptyEquipSlot(Card.SubtypeTreasure) and
      table.find(U.prepareDeriveCards(player.room, zhuangshu_combs, "zhuangshu_derivecards"), function (id)
        return player.room:getCardArea(id) == Card.Void
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local combs = table.filter(U.prepareDeriveCards(room, zhuangshu_combs, "zhuangshu_derivecards"), function (id)
      return room:getCardArea(id) == Card.Void
    end)
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = zhuangshu.name,
      pattern = tostring(Exppattern{ id = combs }),
      prompt = "#zhuangshu-ask",
      cancelable = true,
      expand_pile = combs,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, zhuangshu.name, "support")
    player:broadcastSkillInvoke(zhuangshu.name, math.random(2))
    local id = event:getCostData(self).cards[1]
    room:setCardMark(Fk:getCardById(id), MarkEnum.DestructOutEquip, 1)
    room:moveCardIntoEquip(player, id, zhuangshu.name, true, player)
  end,
})
zhuangshu:addEffect(fk.GameStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhuangshu.name) and not target.dead and
      not player:isNude() and target:hasEmptyEquipSlot(Card.SubtypeTreasure)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = zhuangshu.name,
      prompt = "#zhuangshu-invoke::"..target.id,
      cancelable = true,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {tos = {target}, cards = cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, zhuangshu.name, "support")
    player:broadcastSkillInvoke(zhuangshu.name, math.random(2))
    local card_type = Fk:getCardById(event:getCostData(self).cards[1]):getTypeString()
    room:throwCard(event:getCostData(self).cards, zhuangshu.name, player, player)
    if target.dead or (not target:hasEmptyEquipSlot(Card.SubtypeTreasure)) then return end
    local card_types = {"basic", "trick", "equip"}
    local comb_names = {"jade_comb", "rhino_comb", "golden_comb"}
    local comb_name = comb_names[table.indexOf(card_types, card_type)]
    local comb_id = table.find(U.prepareDeriveCards(room, zhuangshu_combs, "zhuangshu_derivecards"), function (id)
      return room:getCardArea(id) == Card.Void and Fk:getCardById(id).name == comb_name
    end)
    if comb_id == nil then
      for _, p in ipairs(room:getOtherPlayers(target, false)) do
        local new = table.find(p:getCardIds("e"), function (id)
          return Fk:getCardById(id).name == comb_name
        end)
        if new then
          comb_id = new
          break
        end
      end
    end
    if comb_id then
      room:setCardMark(Fk:getCardById(comb_id), MarkEnum.DestructOutEquip, 1)
      room:moveCardIntoEquip(target, comb_id, zhuangshu.name, true, player)
    end
  end,
})

return zhuangshu
