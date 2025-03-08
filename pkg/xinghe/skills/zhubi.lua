local zhubi = fk.CreateSkill{
  name = "ol__zhubi",
}

Fk:loadTranslationTable{
  ["ol__zhubi"] = "铸币",
  [":ol__zhubi"] = "出牌阶段限X次，你可以令一名角色重铸一张牌，以此法摸的牌称为“币”；有“币”的角色的结束阶段，其观看牌堆底的五张牌，"..
  "然后可以用任意“币”交换其中等量张牌（X为你的体力上限）。",

  ["#ol__zhubi"] = "铸币：令一名角色重铸一张牌，其结束阶段可以将之与牌堆底牌交换",
  ["#ol__zhubi-ask"] = "铸币：重铸一张牌，摸到的“币”可以在你的结束阶段与牌堆底牌交换",
  ["@@ol__zhubi-inhand"] = "币",
  ["#ol__zhubi-exchange"] = "铸币：你可以用“币”交换牌堆底的卡牌",

  ["$ol__zhubi1"] = "钱货之通者，在乎币。",
  ["$ol__zhubi2"] = "融金为料，可铸五铢。",
}

local U = require "packages/utility/utility"

zhubi:addEffect("active", {
  anim_type = "support",
  prompt = "#ol__zhubi",
  card_num = 0,
  target_num = 1,
  times = function(self, player)
    return player.phase == Player.Play and player.maxHp - player:usedSkillTimes(zhubi.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(zhubi.name, Player.HistoryPhase) < player.maxHp
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not to_select:isNude()
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    local cards = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = zhubi.name,
      prompt = "#ol__zhubi-ask",
      cancelable = false,
    })
    room:recastCard(cards, target, zhubi.name, "@@ol__zhubi-inhand")
  end,
})
zhubi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and not player.dead and
      table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@ol__zhubi-inhand") > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@ol__zhubi-inhand") > 0
    end)
    local result = room:askToArrangeCards(player, {
      skill_name = zhubi.name,
      card_map = {
        "Bottom", room:getNCards(5, "bottom"),
        "@@ol__zhubi-inhand", cards,
      },
      prompt = "#ol__zhubi-exchange",
    })
    room:swapCardsWithPile(player, result[1], result[2], zhubi.name, "Bottom")
  end,
})

return zhubi
