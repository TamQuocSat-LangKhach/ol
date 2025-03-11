local weijie = fk.CreateSkill{
  name = "weijie",
}

Fk:loadTranslationTable{
  ["weijie"] = "诿解",
  [":weijie"] = "每回合限一次，当你于其他角色的回合内需要使用/打出基本牌时，你可以弃置距离为1的一名角色的一张牌，"..
  "若此牌与你需要使用/打出的牌牌名相同，你视为使用/打出此牌名的牌。",

  ["#weijie"] = "诿解：选择视为使用/打出的基本牌，弃置距离1角色一张牌，若与你需要的牌相同则视为使用/打出之",
  ["#weijie-choose"] = "诿解：弃置距离1一名角色的一张牌，若为【%arg】则视为你使用或打出之",

  ["$weijie1"] = "败战之罪在你，休要多言！",
  ["$weijie2"] = "纵汝舌灿莲花，亦难逃死罪。",
}

local U = require "packages/utility/utility"

weijie:addEffect("viewas", {
  anim_type = "control",
  pattern = ".|.|.|.|.|basic",
  prompt = "#weijie",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(weijie.name, all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = weijie.name
    return card
  end,
  before_use = function(self, player)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isNude() and player:distanceTo(p) == 1
    end)
    if #targets == 0 then return "" end
    local name = Fk:cloneCard(self.interaction.data).trueName
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = weijie.name,
      prompt = "#weijie-choose:::"..name,
      cancelable = false,
    })[1]
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = weijie.name,
    })
    local yes = Fk:getCardById(card).trueName == name
    room:throwCard(card, weijie.name, to, player)
    if not yes then return "" end
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    return player:usedSkillTimes(weijie.name, Player.HistoryTurn) == 0 and
      Fk:currentRoom().current ~= player and
      table.find(Fk:currentRoom().alive_players, function (p)
        return not p:isNude() and player:distanceTo(p) == 1
      end)
  end,
})

return weijie
