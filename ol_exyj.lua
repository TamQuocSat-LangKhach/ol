local extension = Package("ol_exyj")
extension.extensionName = "ol"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_exyj"] = "OL-界一将成名",
}

local lingtong = General(extension, "ol_ex__lingtong", "wu", 4)
local ol_ex__xuanfeng = fk.CreateTriggerSkill{
  name = "ol_ex__xuanfeng",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
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
            return table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper)
    while player.room:askForSkillInvoke(player, self.name) do
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#xuanfeng-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCardChosen(player, to, "he", self.name)
    room:throwCard({card}, self.name, to, player)
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper)
    if #targets == 0 or player.dead then return end
    to = room:askForChoosePlayers(player, targets, 1, 1, "#xuanfeng-choose", self.name, true)
    if #to > 0 then
      to = room:getPlayerById(to[1])
      card = room:askForCardChosen(player, to, "he", self.name)
      room:throwCard({card}, self.name, to, player)
    end
  end,
}
lingtong:addSkill(ol_ex__xuanfeng)
Fk:loadTranslationTable{
  ["ol_ex__lingtong"] = "界凌统",
  ["#ol_ex__lingtong"] = "豪情烈胆",
  ["designer:ol_ex__lingtong"] = "玄蝶既白",
  ["illustrator:ol_ex__lingtong"] = "君桓文化",
  
  ["ol_ex__xuanfeng"] = "旋风",
  [":ol_ex__xuanfeng"] = "当你失去装备区里的牌后，或一次性失去至少两张牌后，你可以依次弃置至多两名其他角色共计至多两张牌。",

  ["$ol_ex__xuanfeng1"] = "短兵相接，让敌人丢盔弃甲！",
  ["$ol_ex__xuanfeng2"] = "攻敌不备，看他们闻风而逃！",
  ["~ol_ex__lingtong"] = "先……停一下吧……",
}

-- yj2012
local ol_ex__caozhang = General(extension, "ol_ex__caozhang", "wei", 4)
local ol_ex__jiangchi_select = fk.CreateActiveSkill{
  name = "ol_ex__jiangchi_select",
  target_num = 0,
  max_card_num = 1,
  min_card_num = 0,
  interaction = function()
    return UI.ComboBox {choices = {"ol_ex__jiangchi1", "ol_ex__jiangchi2"}}
  end,
  card_filter = function(self, to_select, selected)
    return (self.interaction or {}).data == "ol_ex__jiangchi2" and #selected == 0
  end,
}
local ol_ex__jiangchi = fk.CreateTriggerSkill{
  name = "ol_ex__jiangchi",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local _, ret = player.room:askForUseActiveSkill(player, "ol_ex__jiangchi_select", "#ol_ex__jiangchi-invoke", true)
    if ret then
      self.cost_data = ret.cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #self.cost_data > 0 then
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke(self.name, 2)
      room:recastCard(self.cost_data, player, self.name)
      room:addPlayerMark(player, "ol_ex__jiangchi_plus-turn")
    else
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name, 1)
      player:drawCards(1, self.name)
      room:addPlayerMark(player, "ol_ex__jiangchi_minus-turn")
    end
  end,
}
local ol_ex__jiangchi_targetmod = fk.CreateTargetModSkill{
  name = "#ol_ex__jiangchi_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      local n = 0
      if player:getMark("ol_ex__jiangchi_plus-turn") > 0 then
        n = n + 1
      end
      if player:getMark("ol_ex__jiangchi_minus-turn") > 0 then
        n = n - 1
      end
      return n
    end
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return skill.trueName == "slash_skill" and player:getMark("ol_ex__jiangchi_plus-turn") > 0
  end,
}
local ol_ex__jiangchi_maxcards = fk.CreateMaxCardsSkill{
  name = "#ol_ex__jiangchi_maxcards",
  exclude_from = function(self, player, card)
    return card and card.trueName == "slash" and player:getMark("ol_ex__jiangchi_minus-turn") > 0
  end,
}
Fk:addSkill(ol_ex__jiangchi_select)
ol_ex__jiangchi:addRelatedSkill(ol_ex__jiangchi_targetmod)
ol_ex__jiangchi:addRelatedSkill(ol_ex__jiangchi_maxcards)
ol_ex__caozhang:addSkill(ol_ex__jiangchi)

Fk:loadTranslationTable{
  ["ol_ex__caozhang"] = "界曹彰",
  ["#ol_ex__caozhang"] = "黄须儿",
  ["designer:ol_ex__caozhang"] = "玄蝶既白",
  ["illustrator:ol_ex__caozhang"] = "枭瞳",
  ["ol_ex__jiangchi"] = "将驰",
  [":ol_ex__jiangchi"] = "摸牌阶段结束时，你可以选择一项：1.摸一张牌，本回合使用【杀】的次数上限-1，且【杀】不计入手牌上限；2.重铸一张牌，本回合使用【杀】无距离限制且次数上限+1。",
  ["#ol_ex__jiangchi-invoke"] = "1.摸一张牌，【杀】次数-1，不计入手牌上限；2.重铸一张牌，【杀】次数+1，无距离限制",
  ["ol_ex__jiangchi_select"] = "将驰",
  ["ol_ex__jiangchi1"] = "摸牌，少用【杀】",
  ["ol_ex__jiangchi2"] = "重铸，多用【杀】",
  ["$ol_ex__jiangchi1"] = "丈夫当将十万骑驰沙漠，立功建号耳。",
  ["$ol_ex__jiangchi2"] = "披坚执锐，临危不难，身先士卒。",
  ["~ol_ex__caozhang"] = "黄须儿，愧对父亲……",
}

return extension
