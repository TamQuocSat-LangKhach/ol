local xiashu = fk.CreateSkill{
  name = "xiashu",
}

Fk:loadTranslationTable{
  ["xiashu"] = "下书",
  [":xiashu"] = "出牌阶段开始时，你可以将所有手牌交给一名其他角色，然后该角色亮出任意数量的手牌（至少一张），令你选择一项："..
  "1.获得其亮出的手牌；2.获得其未亮出的手牌。",

  ["#xiashu-choose"] = "下书：将所有手牌交给一名角色，其展示任意张手牌，你获得展示或未展示的牌",
  ["#xiashu-card"] = "下书：展示任意张手牌，%src 选择获得你展示的牌或未展示的牌",
  ["xiashu_show"] = "获得展示的牌",
  ["xiashu_noshow"] = "获得未展示的牌[%arg张]",
  ["#xiashu-choice"] = "下书：选择获得 %dest 的牌",

  ["$xiashu1"] = "吾有密信，特来献于将军。",
  ["$xiashu2"] = "将军若不信，可亲自验看！",
}

local U = require "packages/utility/utility"

xiashu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiashu.name) and player.phase == Player.Play and
      not player:isKongcheng() and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = xiashu.name,
      prompt = "#xiashu-choose",
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
    room:moveCardTo(player:getCardIds("h"), Player.Hand, to, fk.ReasonGive, xiashu.name, nil, false, player)
    if player.dead or to.dead or to:isKongcheng() then return end
    local cards = room:askToCards(to, {
      min_num = 1,
      max_num = 999,
      include_equip = false,
      skill_name = xiashu.name,
      prompt = "#xiashu-card:"..player.id,
      cancelable = false,
    })
    to:showCards(cards)
    local choices = {"xiashu_show"}
    local x = to:getHandcardNum() - #cards
    if x > 0 then
      table.insert(choices, "xiashu_noshow:::" .. tostring(x))
    end
    local choice = U.askforViewCardsAndChoice(player, cards, choices, xiashu.name, "#xiashu-choice::"..to.id)
    if choice ~= "xiashu_show" then
      cards = table.filter(to:getCardIds("h"), function (id)
        return not table.contains(cards, id)
      end)
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, xiashu.name, nil, choice == "xiashu_show", player)
    end
  end,
})

return xiashu
