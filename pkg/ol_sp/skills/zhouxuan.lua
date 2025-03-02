local zhouxuan = fk.CreateSkill{
  name = "zhouxuanz",
}

Fk:loadTranslationTable{
  ["zhouxuanz"] = "周旋",
  [":zhouxuanz"] = "弃牌阶段开始时，你可将任意张手牌扣置于武将牌上（称为“旋”，至多五张）。"..
  "出牌阶段结束时，你移去所有“旋”。当你使用牌时，若你有“旋”，你摸一张牌，"..
  "若你不是唯一手牌数最大的角色，则改为摸X张牌（X为“旋”的数量），然后随机移去一张“旋”。",

  ["$zhanghe_xuan"] = "旋",
  ["#zhouxuanz-invoke"] = "周旋：你可以将至多%arg张手牌置为“旋”",

  ["$zhouxuanz1"] = "详勘细察，洞若观火。",
  ["$zhouxuanz2"] = "知敌底细，方能百战百胜。",
}

zhouxuan:addEffect(fk.EventPhaseStart, {
  derived_piles = "$zhanghe_xuan",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhouxuan.name) and player.phase == Player.Discard and
      not player:isKongcheng() and #player:getPile("$zhanghe_xuan") < 5
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = 5 - #player:getPile("$zhanghe_xuan")
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = x,
      include_equip = false,
      skill_name = zhouxuan.name,
      prompt = "#zhouxuanz-invoke:::"..x,
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("$zhanghe_xuan", event:getCostData(self).cards, false, zhouxuan.name)
  end,
})
zhouxuan:addEffect(fk.EventPhaseEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and #player:getPile("$zhanghe_xuan") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(player:getPile("$zhanghe_xuan"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile,
      zhouxuan.name, nil, true, player)
  end,
})
zhouxuan:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and #player:getPile("$zhanghe_xuan") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 1
    if table.find(room:getOtherPlayers(player, false), function (p)
      return p:getHandcardNum() >= player:getHandcardNum()
    end) then
      n = #player:getPile("$zhanghe_xuan")
    end
    player:drawCards(n, zhouxuan.name)
    if not player.dead and #player:getPile("$zhanghe_xuan") > 0 then
      room:moveCardTo(table.random(player:getPile("$zhanghe_xuan")), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile,
        zhouxuan.name, nil, true, player)
    end
  end,
})

return zhouxuan
