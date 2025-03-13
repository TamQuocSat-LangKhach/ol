local chuyuan = fk.CreateSkill{
  name = "chuyuan",
}

Fk:loadTranslationTable{
  ["chuyuan"] = "储元",
  [":chuyuan"] = "当一名角色受到伤害后，若你的“储”数小于体力上限，你可以令其摸一张牌，然后其将一张手牌置于你的武将牌上，称为“储”。",

  ["#chuyuan-invoke"] = "储元：你可以令 %dest 摸一张牌，然后其将一张手牌置为“储”",
  ["caopi_chu"] = "储",
  ["#chuyuan-card"] = "储元：将一张手牌作为“储”置于 %src 武将牌上",

  ["$chuyuan1"] = "储君之位，囊中之物。",
  ["$chuyuan2"] = "此役，我之胜。",
}

chuyuan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  derived_piles = "caopi_chu",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chuyuan.name) and #player:getPile("caopi_chu") < player.maxHp and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = chuyuan.name,
      prompt = "#chuyuan-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target:drawCards(1, chuyuan.name)
    if target:isKongcheng() or not player:hasSkill(chuyuan.name) then return end
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = chuyuan.name,
      prompt = "#chuyuan-card:"..player.id,
      cancelable = false,
    })
    player:addToPile("caopi_chu", card, true, chuyuan.name)
  end,
})

return chuyuan
