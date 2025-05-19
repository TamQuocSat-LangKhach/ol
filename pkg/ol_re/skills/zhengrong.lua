local zhengrong = fk.CreateSkill {
  name = "ol__zhengrong",
}

Fk:loadTranslationTable{
  ["ol__zhengrong"] = "征荣",
  [":ol__zhengrong"] = "当你使用【杀】或伤害锦囊牌时，你可以选择一名手牌数不小于你的目标角色，将其一张牌置于你的武将牌上，称为“荣”。",

  ["$guanqiujian__glory"] = "荣",
  ["#ol__zhengrong-choose"] = "征荣：你可以将一名目标角色的一张牌置为“荣”",

  ["$ol__zhengrong1"] = "此役兵戈所向，贼众望风披靡。",
  ["$ol__zhengrong2"] = "世袭兵道，唯愿一扫蛮夷。",
}

zhengrong:addEffect(fk.CardUsing, {
  anim_type = "control",
  derived_piles = "$guanqiujian__glory",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhengrong.name) and data.card.is_damage_card and
      table.find(data.tos, function (p)
        return p:getHandcardNum() >= player:getHandcardNum()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.tos, function (p)
      return p:getHandcardNum() >= player:getHandcardNum()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = zhengrong.name,
      prompt = "#ol__zhengrong-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = zhengrong.name,
    })
    player:addToPile("$guanqiujian__glory", card, false, zhengrong.name)
  end,
})

return zhengrong
