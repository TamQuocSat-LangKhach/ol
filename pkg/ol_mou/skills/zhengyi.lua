local zhengyi = fk.CreateSkill{
  name = "ol__zhengyi",
}

Fk:loadTranslationTable{
  ["ol__zhengyi"] = "争义",
  [":ol__zhengyi"] = "当有“贤”标记的角色受到非属性伤害时，其他有“贤”标记的角色同时选择是否失去体力，若有角色同意，则防止此伤害，"..
  "同意的角色中体力值最大的角色失去等同于此伤害值的体力。",

  ["#ol__zhengyi-choice"] = "争义：是否失去%arg点体力，防止 %dest 受到的伤害？（只有选“是”的体力值最大的角色会失去体力）",

  ["$ol__zhengyi1"] = "保纳舍藏者，融也，当坐之。",
  ["$ol__zhengyi2"] = "子曰当仁不让，当义，亦不能让。",
}

zhengyi:addEffect(fk.DamageInflicted, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhengyi.name) and
      target:getMark("@kongrong_virtuous") > 0 and data.damageType == fk.NormalDamage and
      table.find(player.room:getOtherPlayers(target, false), function (p)
        return p:getMark("@kongrong_virtuous") > 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(target, false), function (p)
      return p:getMark("@kongrong_virtuous") > 0
    end)
    local result = room:askToJointChoice(player, {
      players = targets,
      choices = {"yes", "no"},
      skill_name = zhengyi.name,
      prompt = "#ol__zhengyi-choice::"..target.id..":"..data.damage,
      send_log = true,
    })
    local n = 0
    for _, p in ipairs(targets) do
      if result[p] == "yes" and p.hp > n then
        n = p.hp
      end
    end
    if n == 0 then return end
    for _, p in ipairs(room:getAlivePlayers(false)) do
      if result[p] == "yes" and p.hp == n then
        event:setCostData(self, {extra_data = p})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    local p = event:getCostData(self).extra_data
    room:doIndicate(p, {target})
    room:loseHp(p, data.damage, zhengyi.name)
  end,
})

return zhengyi
