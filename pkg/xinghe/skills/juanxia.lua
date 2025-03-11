local juanxia = fk.CreateSkill{
  name = "juanxia",
}

Fk:loadTranslationTable{
  ["juanxia"] = "狷狭",
  [":juanxia"] = "结束阶段，你可以选择一名其他角色，依次视为对其使用至多两张仅指定唯一目标的普通锦囊牌。"..
  "若如此做，该角色的下回合结束时，其可以依次视为对你使用等量的【杀】。",

  ["#juanxia-choose"] = "狷狭：你可以选择一名角色，依次视为对其使用至多两张仅指定唯一目标的普通锦囊牌",
  ["#juanxia-invoke"] = "狷狭：你可以视为对 %dest 再使用一张锦囊",
  ["#juanxia-slash"] = "狷狭：是否视为对 %src 使用 %arg 张【杀】？",
  ["@juanxia"] = "狷狭",

  ["$juanxia1"] = "汝有何功？竟能居我之上！",
  ["$juanxia2"] = "恃才傲立，恩怨必偿。",
}

local U = require "packages/utility/utility"

juanxia:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juanxia.name) and player.phase == Player.Finish and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("juanxia_cards")
    if mark == 0 then
      mark = table.filter(U.getUniversalCards(room, "t"), function(id)
        local trick = Fk:getCardById(id)
        return not trick.multiple_targets and trick.skill:getMinTargetNum(player) > 0
      end)
      room:setPlayerMark(player, "juanxia_cards", mark)
    end
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "juanxia_active",
      prompt = "#juanxia-choose",
      cancelable = true,
      extra_data = {
        juanxia_names = mark,
      }
    })
    if success then
      event:setCostData(self, {extra_data = dat})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self).extra_data
    local to = dat.targets[1]
    local card = Fk:cloneCard(Fk:getCardById(dat.cards[1]).name)
    card.skillName = juanxia.name
    room:useCard{
      from = player,
      tos = dat.targets,
      card = card,
    }
    if player.dead or to.dead then return false end
    local x = 1
    local mark = table.clone(player:getMark("juanxia_cards"))
    table.removeOne(mark, dat.cards[1])
    local success = false
    success, dat = room:askToUseActiveSkill(player, {
      skill_name = "juanxia_active",
      prompt = "#juanxia-invoke::"..to.id,
      cancelable = true,
      extra_data = {
        juanxia_names = mark,
        juanxia_target = to.id,
      }
    })
    if success and dat then
      card = Fk:cloneCard(Fk:getCardById(dat.cards[1]).name)
      card.skillName = juanxia.name
      local targets = dat.targets
      table.insert(targets, 1, to)
      room:useCard{
        from = player,
        tos = targets,
        card = card,
      }
      if player.dead or to.dead then return false end
      x = x + 1
    end
    room:addPlayerMark(to, "@juanxia", x)
    mark = to:getTableMark("juanxia_record")
    mark[tostring(player.id)] = (mark[tostring(player.id)] or 0) + x
    room:setPlayerMark(to, "juanxia_record", mark)
  end,
})
juanxia:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and not target.dead and target:getMark("@juanxia") > 0 and
      target:getMark("juanxia_record") ~= 0 and
      target:getMark("juanxia_record")[tostring(player.id)] ~= nil
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = target:getMark("juanxia_record")[tostring(player.id)]
    for i = 1, n, 1 do
      local slash = Fk:cloneCard("slash")
      slash.skillName = juanxia.name
      if not target:canUseTo(slash, player, {bypass_distances = true, bypass_times = true}) or
      (i == 1 and not room:askToSkillInvoke(target, {
        skill_name = juanxia.name,
        prompt = "#juanxia-slash:"..player.id.."::"..n,
      })) then break end
      room:useVirtualCard("slash", nil, target, player, juanxia.name, true)
      if player.dead or target.dead then break end
    end
  end,

  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and (player:getMark("@juanxia") > 0 or player:getMark("juanxia_record") ~= 0)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@juanxia", 0)
    room:setPlayerMark(player, "juanxia_record", 0)
  end,
})

return juanxia
