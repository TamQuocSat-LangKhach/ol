local shuimeng = fk.CreateSkill{
  name = "shuimeng",
}

Fk:loadTranslationTable{
  ["shuimeng"] = "说盟",
  [":shuimeng"] = "出牌阶段结束时，你可以与一名角色拼点，若你赢，视为你使用【无中生有】；若你没赢，视为其对你使用【过河拆桥】。",

  ["#shuimeng-choose"] = "说盟：你可以拼点，若赢，视为你使用【无中生有】；若没赢，视为其对你使用【过河拆桥】",

  ["$shuimeng1"] = "你我唇齿相依，共御外敌，何如？  ",
  ["$shuimeng2"] = "今兵薄势寡，可遣某为使往说之。",
}

shuimeng:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shuimeng.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return player:canPindian(p)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = shuimeng.name,
      prompt = "#shuimeng-choose",
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
    local pindian = player:pindian({to}, shuimeng.name)
    if player.dead then return end
    if pindian.results[to].winner == player then
      room:useVirtualCard("ex_nihilo", nil, player, player, shuimeng.name)
    else
      if to.dead then return end
      room:useVirtualCard("dismantlement", nil, to, player, shuimeng.name)
    end
  end,
})

return shuimeng
