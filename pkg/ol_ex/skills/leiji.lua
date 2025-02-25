local this = fk.CreateSkill { name = "ol_ex__leji", }

local judge_data = {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(this.name) or target ~= player then return end
    return data.card.trueName == "jink" or data.card.trueName == "lightning"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = this.name,
    }
    room:judge(judge)
  end,
}

this:addEffect(fk.CardUsing, judge_data)
this:addEffect(fk.CardResponding, judge_data)
this:addEffect(fk.FinishJudge, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(this.name) or target ~= player then return end
    return data.card.color == Card.Black
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = 2
    if data.card.suit == Card.Club then
      x = 1
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = this.name,
        })
      end
      if player.dead then return false end
    end
    local targets = room:askToChoosePlayers(player, { targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper), min_num = 1, max_num = 1, prompt = "#ol_ex__leiji-choose:::" .. x, skill_name = this.name, cancelable = true})
    if #targets > 0 then
      local tar = targets[1]
      room:damage{
        from = player,
        to = tar,
        damage = x,
        damageType = fk.ThunderDamage,
        skillName = this.name,
      }
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__leiji"] = "雷击",
  [":ol_ex__leiji"] = "①当你使用或打出【闪】或【闪电】时，你可判定。②当你的判定结果确定后，若结果为：♠，你可对一名其他角色造成2点雷电伤害；♣，你回复1点体力，然后你可对一名其他角色造成1点雷电伤害。",
  
  ["#ol_ex__leiji-choose"] = "雷击：你可以选择一名其他角色，对其造成%arg点雷电伤害",

  ["$ol_ex__leiji1"] = "疾雷迅电，不可趋避！",
  ["$ol_ex__leiji2"] = "雷霆之诛，灭军毁城！",
}

return this