local this = fk.CreateSkill{
  name = "ol_ex__xuanfeng",
}

this:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(this.name) then
      for _, move in ipairs(data) do
        if move.from == player.id then
          local n = 0
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              n = n + 1
            elseif info.fromArea == Card.PlayerEquip then
              n = 2
            end
          end
          if n > 1 then
            return table.find(player.room:getOtherPlayers(player, false), function(p) return not p:isNude() end)
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude() end), Util.IdMapper)
    while player.room:askToSkillInvoke(player, { skill_name = this.name }) do
      local to = room:askToChoosePlayers(player, { targets = targets, min_num = 1, max_num = 1, prompt = "#xuanfeng-choose", skill_name = this.name, cancelable = true})
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askToChooseCard(player, { target = to, flag = "he", skill_name = this.name})
    room:throwCard({card}, this.name, to, player)
    local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude() end), Util.IdMapper)
    if #targets == 0 or player.dead then return end
    to = room:askToChoosePlayers(player, { targets = targets, min_num = 1, max_num = 1, prompt = "#xuanfeng-choose", skill_name = this.name, cancelable = true})
    if #to > 0 then
      to = to[1]
      card = room:askToChooseCard(player, { target = to, flag = "he", skill_name = this.name})
      room:throwCard({card}, this.name, to, player)
    end
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__xuanfeng"] = "旋风",
  [":ol_ex__xuanfeng"] = "当你失去装备区里的牌后，或一次性失去至少两张牌后，你可以依次弃置至多两名其他角色共计至多两张牌。",

  ["$ol_ex__xuanfeng1"] = "短兵相接，让敌人丢盔弃甲！",
  ["$ol_ex__xuanfeng2"] = "攻敌不备，看他们闻风而逃！",
}

return this
