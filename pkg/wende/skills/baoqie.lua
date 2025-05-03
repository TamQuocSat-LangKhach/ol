local baoqie = fk.CreateSkill{
  name = "baoqie",
  tags = { Skill.Hidden, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["baoqie"] = "宝箧",
  [":baoqie"] = "隐匿技，锁定技，当你登场后，你从牌堆或弃牌堆获得一张宝物牌，然后你可以使用之。",

  ["#baoqie-use"] = "宝箧：是否使用%arg？",

  ["$baoqie1"] = "宝箧藏玺，时局变动。",
  ["$baoqie2"] = "曹亡宝箧，尽露锋芒。",
}

local U = require "packages/utility/utility"

baoqie:addEffect(U.GeneralAppeared, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(baoqie.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|.|.|.|.|treasure", 1, "allPiles")
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonJustMove, baoqie.name)
      local card = Fk:getCardById(cards[1])
      if table.contains(player:getCardIds("h"), cards[1]) and
        card.sub_type == Card.SubtypeTreasure and
        player:canUseTo(card, player) and
        room:askToSkillInvoke(player, {
          skill_name = baoqie.name,
          prompt = "#baoqie-use:::"..card:toLogString(),
        }) then
        room:useCard{
          from = player,
          tos = {player},
          card = card,
        }
      end
    end
  end,
})

return baoqie
