local bingzheng = fk.CreateSkill{
  name = "bingzheng",
}

Fk:loadTranslationTable{
  ["bingzheng"] = "秉正",
  [":bingzheng"] = "出牌阶段结束时，你可以令手牌数不等于体力值的一名角色弃置一张手牌或摸一张牌。然后若其手牌数等于体力值，你摸一张牌，"..
  "且可以交给该角色一张牌。",

  ["#bingzheng-choose"] = "秉正：令一名角色执行一项，然后若其手牌数等于体力值，你摸一张牌且可以交给其一张牌",
  ["#bingzheng_discard"] = "弃置一张手牌",
  ["#bingzheng-give"] = "秉正：你可以交给 %dest 一张牌",

  ["$bingzheng1"] = "自古，就是邪不胜正！",
  ["$bingzheng2"] = "主公面前，岂容小人搬弄是非！",
}

bingzheng:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bingzheng.name) and player.phase == Player.Play and
      table.find(player.room.alive_players, function(p)
        return p:getHandcardNum() ~= p.hp
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "bingzheng_active",
      prompt = "#bingzheng-choose",
      cancelable = true,
    })
    if #success and dat then
      event:setCostData(self, {tos = dat.targets, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    if choice == "draw1" then
      to:drawCards(1, bingzheng.name)
    else
      room:askToDiscard(to, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = bingzheng.name,
        cancelable = false,
      })
    end
    if player.dead then return end
    if to:getHandcardNum() == to.hp then
      player:drawCards(1, bingzheng.name)
      if to ~= player and not to.dead and not player.dead then
        local card = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = bingzheng.name,
          prompt = "#bingzheng-give::"..to.id,
          cancelable = true,
        })
        if #card > 0 then
          room:obtainCard(to, card, false, fk.ReasonGive, player, bingzheng.name)
        end
      end
    end
  end,
})

return bingzheng
