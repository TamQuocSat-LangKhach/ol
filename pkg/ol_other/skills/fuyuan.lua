local fuyuan = fk.CreateSkill{
  name = "fuyuanx",
}

Fk:loadTranslationTable{
  ["fuyuanx"] = "辅袁",
  [":fuyuanx"] = "当你于回合外使用或打出牌时，若当前回合角色的手牌数：小于你，你可以令其摸一张牌；不小于你，你可以摸一张牌。",

  ["#fuyuanx-invoke"] = "辅袁：你可以令 %dest 摸一张牌",

  ["$fuyuanx1"] = "袁门一体，休戚与共。",
  ["$fuyuanx2"] = "袁氏荣光，俯仰唯卿。",
}

local fuyuan_spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuyuan.name) and player.room.current ~= player and
      not player.room.current.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room.current:getHandcardNum() < player:getHandcardNum() and room.current or player
    if room:askToSkillInvoke(player, {
      skill_name = fuyuan.name,
      prompt = "#fuyuanx-invoke::"..to.id,
    }) then
      event:setCostData(self, {tos = {to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(1, fuyuan.name)
  end,
}

fuyuan:addEffect(fk.CardUsing, fuyuan_spec)
fuyuan:addEffect(fk.CardResponding, fuyuan_spec)

return fuyuan
