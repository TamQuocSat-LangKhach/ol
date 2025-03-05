local yangkuang = fk.CreateSkill{
  name = "yangkuang",
}

Fk:loadTranslationTable{
  ["yangkuang"] = "阳狂",
  [":yangkuang"] = "当你回复体力至上限后，你可以视为使用一张【酒】并与当前回合角色各摸一张牌。",

  ["#yangkuang-invoke"] = "阳狂：你可以视为使用【酒】并摸一张牌",
  ["#yangkuang2-invoke"] = "阳狂：你可以视为使用【酒】并与 %dest 各摸一张牌",

  ["$yangkuang1"] = "比干忠谏剖心死，箕子披发阳狂生。",
  ["$yangkuang2"] = "梅伯数谏遭炮烙，来革顺志而用国。",
}

yangkuang:addEffect(fk.HpRecover, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yangkuang.name) and not player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#yangkuang-invoke"
    if room.current and not room.current.dead then
      prompt = "#yangkuang2-invoke::"..room.current.id
    end
    if room:askToSkillInvoke(player, {
      skill_name = yangkuang.name,
      prompt = prompt,
    }) then
      if prompt:startsWith("#yangkuang2") then
        event:setCostData(self, {tos = {target}})
      else
        event:setCostData(self, nil)
      end
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:useVirtualCard("analeptic", nil, player, player, yangkuang.name)
    if not player.dead then
      player:drawCards(1, yangkuang.name)
    end
    if room.current and not room.current.dead then
      room.current:drawCards(1, yangkuang.name)
    end
  end,
})

return yangkuang
