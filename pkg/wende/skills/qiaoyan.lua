local qiaoyan = fk.CreateSkill{
  name = "qiaoyan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qiaoyan"] = "巧言",
  [":qiaoyan"] = "锁定技，在你的回合外，当其他角色对你造成伤害时，若你：没有“珠”，你防止此伤害并摸一张牌，然后将一张牌置于你的武将牌上，"..
  "称为“珠”；有“珠”，其获得“珠”。",

  ["ol__lisu_zhu"] = "珠",
  ["#qiaoyan-ask"] = "巧言：将一张牌置为“珠”",

  ["$qiaoyan1"] = "此事不宜迟，在于速决。",
  ["$qiaoyan2"] = "公若到彼，贵不可言。",
}

qiaoyan:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  derived_piles = "ol__lisu_zhu",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiaoyan.name) and player.room.current ~= player and
      data.from and data.from ~= player and (#player:getPile("ol__lisu_zhu") == 0 or not data.from.dead)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player:getPile("ol__lisu_zhu") == 0 then
      data:preventDamage()
      player:drawCards(1, qiaoyan.name)
      if player:isNude() or player.dead then return end
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = qiaoyan.name,
        prompt = "#qiaoyan-ask",
        cancelable = false,
      })
      player:addToPile("ol__lisu_zhu", card, true, qiaoyan.name)
    else
      room:obtainCard(data.from, player:getPile("ol__lisu_zhu"), true, fk.ReasonJustMove, data.from, qiaoyan.name)
    end
  end,
})

return qiaoyan
