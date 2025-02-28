local xiongni = fk.CreateSkill{
  name = "xiongni",
}

Fk:loadTranslationTable{
  ["xiongni"] = "凶逆",
  [":xiongni"] = "出牌阶段开始时，你可以弃置一张牌，所有其他角色需弃置一张与花色相同的牌，否则你对其造成1点伤害。",

  ["#xiongni-invoke"] = "凶逆：你可以弃一张牌，所有其他角色选择弃一张相同花色的牌或你对其造成1点伤害",
  ["#xiongni-discard"] = "凶逆：弃置一张%arg牌，否则 %src 对你造成1点伤害！",

  ["$xiongni1"] = "不愿做我殿上宾客？哼哼！那便做我刀下鬼！",
  ["$xiongni2"] = "尔等，要试试我宝剑锋利否？",
}

xiongni:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiongni.name) and player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = xiongni.name,
      cancelable = true,
      prompt = "#xiongni-invoke",
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = room:getOtherPlayers(player, false), cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suit = Fk:getCardById(event:getCostData(self).cards[1]):getSuitString()
    room:throwCard(event:getCostData(self).cards, xiongni.name, player, player)
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead then
        if suit == "log_nosuit" or p:isNude() or
          #room:askToDiscard(p, {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            skill_name = xiongni.name,
            cancelable = true,
            pattern = ".|.|"..suit,
            prompt = "#xiongni-discard:"..player.id.."::"..suit,
          }) == 0 then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = xiongni.name,
          }
        end
      end
    end
  end,
})

return xiongni
