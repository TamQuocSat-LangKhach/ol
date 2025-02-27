
local xuanhuo = fk.CreateSkill{
  name = "ol_ex__xuanhuo",
}

Fk:loadTranslationTable{
  ["ol_ex__xuanhuo"] = "眩惑",
  [":ol_ex__xuanhuo"] = "摸牌阶段结束时，你可以交给一名其他角色两张牌，令其选择一项：1.对你指定的另一名角色使用一张【杀】；2.你观看其手牌并"..
  "获得其两张牌。",

  ["#ol_ex__xuanhuo-invoke"] = "眩惑：交给第一名角色两张手牌，令其选择对第二名角色使用【杀】或你获得其两张牌",
  ["#ol_ex__xuanhuo-use"] = "眩惑：你需对 %dest 使用一张【杀】，否则 %src 观看你手牌并获得你两张牌",
  ["#ol_ex__xuanhuo-prey"] = "眩惑：获得 %dest 两张牌",

  ["$ol_ex__xuanhuo1"] = "眩惑之术，非为迷惑，乃为明辨贤愚。",
  ["$ol_ex__xuanhuo2"] = "以眩惑试人心，以真情待贤才，方能得天下。",
}

xuanhuo:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xuanhuo.name) and player.phase == Player.Draw and
      #player:getCardIds("he") > 1 and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ol_ex__xuanhuo_active",
      prompt = "#ol_ex__xuanhuo-invoke",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, cards = dat.cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, to, fk.ReasonGive, xuanhuo.name, nil, false, player)
    if to.dead then return end
    local victim = event:getCostData(self).tos[2]
    local use = room:askToUseCard(to, {
      pattern = "slash",
      prompt = "#ol_ex__xuanhuo-use:"..player.id..":"..victim.id,
      extra_data = {
        must_targets = {victim.id},
        bypass_times = true,
        bypass_distances = true,
      },
    })
    if use then
      use.extraUse = true
      room:useCard(use)
    else
      if player.dead or to.dead or to:isNude() then return end
      local cards = room:askToChooseCards(player, {
        target = to,
        min = math.min(#to:getCardIds("he"), 2),
        max = 2,
        flag = {
          card_data = {{to.general, to:getCardIds("he")}}
        },
        prompt = "#ol_ex__xuanhuo-prey::"..to.id,
        skill_name = xuanhuo.name,
      })
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, xuanhuo.name, nil, false, player)
    end
  end,
})

return xuanhuo
