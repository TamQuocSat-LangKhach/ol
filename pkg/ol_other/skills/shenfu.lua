local shenfu = fk.CreateSkill{
  name = "shenfu",
}

Fk:loadTranslationTable{
  ["shenfu"] = "神赋",
  [":shenfu"] = "结束阶段，如果你的手牌数量为：奇数，你可以对一名其他角色造成1点雷电伤害，然后若其死亡，你可以重复此流程；"..
  "偶数，你可以令一名角色摸一张牌或你弃置其一张手牌，然后若其手牌数等于体力值，你可以重复此流程（不能对本回合指定过的目标使用）。",

  ["#shenfu-damage"] = "神赋：你可以对一名其他角色造成1点雷电伤害",
  ["#shenfu-hand"] = "神赋：你可以令一名角色摸一张牌或你弃置其一张手牌",
  ["shenfu_draw"] = "其摸一张牌",
  ["shenfu_discard"] = "弃置其一张手牌",

  ["$shenfu1"] = "河洛之神，诗赋可抒。",
  ["$shenfu2"] = "云神鱼游，罗扇掩面。",
}

shenfu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shenfu.name) and player.phase == Player.Finish then
      if player:getHandcardNum() % 2 == 1 then
        return #player.room:getOtherPlayers(player, false) > 0
      else
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getHandcardNum() % 2 == 1 then
      while not player.dead do
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = room:getOtherPlayers(player, false),
          skill_name = shenfu.name,
          prompt = "#shenfu-damage",
          cancelable = true,
        })
        if #to > 0 then
          room:damage{
            from = player,
            to = to[1],
            damage = 1,
            damageType = fk.ThunderDamage,
            skillName = shenfu.name,
          }
          if not to[1].dead or #player.room:getOtherPlayers(player, false) == 0 then
            return
          end
        else
          return
        end
      end
    else
      while not player.dead do
        local success, dat = room:askToUseActiveSkill(player, {
          skill_name = "shenfu_active",
          prompt = "#shenfu-hand",
          cancelable = true,
          no_indicate = false,
        })
        if success and dat then
          local to = dat.targets[1]
          room:addTableMark(player, "shenfu-phase", to.id)
          if dat.interaction == "shenfu_draw" then
            to:drawCards(1, shenfu.name)
          else
            if to == player then
              room:askToDiscard(player, {
                min_num = 1,
                max_num = 1,
                include_equip = false,
                skill_name = shenfu.name,
                cancelable = false,
              })
            else
              local card = room:askToChooseCard(player, {
                target = to,
                flag = "h",
                skill_name = shenfu.name,
              })
              room:throwCard(card, shenfu.name, to, player)
            end
          end
          if #to:getCardIds("h") ~= to.hp or
            table.every(room.alive_players, function (p)
              return table.contains(player:getTableMark("shenfu-phase"), p.id)
            end) then
            return
          end
        else
          return
        end
      end
    end
  end,
})

return shenfu
