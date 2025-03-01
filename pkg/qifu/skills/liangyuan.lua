local liangyuan = fk.CreateSkill{
  name = "liangyuan",
}

Fk:loadTranslationTable{
  ["liangyuan"] = "良缘",
  [":liangyuan"] = "每轮各限一次，你可以将全场所有「灵杉」当【酒】、「玉树」当【桃】使用。",

  ["#liangyuan"] = "良缘：将全场所有「灵杉」当【酒】、「玉树」当【桃】使用",

  ["$liangyuan1"] = "千古奇遇，共剪西窗。",
  ["$liangyuan2"] = "金玉良缘，来日方长。",
}

local U = require "packages/utility/utility"

liangyuan:addEffect("viewas", {
  anim_type = "support",
  pattern = "peach,analeptic",
  prompt = "#liangyuan",
  interaction = function(self, player)
    local all_names, piles, names = {"peach", "analeptic"}, {"huamu_yushu", "huamu_lingshan"}, {}
    for i = 1, 2, 1 do
      local name = all_names[i]
      if not table.contains(player:getTableMark("liangyuan-round"), name) then
        local subcards = {}
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          table.insertTable(subcards, p:getPile(piles[i]))
        end
        if #subcards > 0 and #player:getViewAsCardNames(liangyuan.name, {name}, subcards) > 0 then
          table.insertIfNeed(names, name)
        end
      end
    end
    if #names == 0 then return end
    return U.CardNameBox { choices = names }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not self.interaction.data then return nil end
    local subcards = {}
    local pile_name = self.interaction.data == "peach" and "huamu_yushu" or "huamu_lingshan"
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      table.insertTable(subcards, p:getPile(pile_name))
    end
    if #subcards == 0 then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = liangyuan.name
    card:addSubcards(subcards)
    return card
  end,
  before_use = function(self, player, use)
    player.room:addTableMark(player, "liangyuan-round", self.interaction.data)
  end,
  enabled_at_play = function (self, player)
    local all_names, piles = {"peach", "analeptic"}, {"huamu_yushu", "huamu_lingshan"}
    for i = 1, 2, 1 do
      local name = all_names[i]
      if not table.contains(player:getTableMark("liangyuan-round"), name) then
        local subcards = {}
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          table.insertTable(subcards, p:getPile(piles[i]))
        end
        if #subcards > 0 and #player:getViewAsCardNames(liangyuan.name, {name}, subcards) > 0 then
          return true
        end
      end
    end
  end,
  enabled_at_response = function (self, player, response)
    if response then return end
    local all_names, piles = {"peach", "analeptic"}, {"huamu_yushu", "huamu_lingshan"}
    for i = 1, 2, 1 do
      local name = all_names[i]
      if not table.contains(player:getTableMark("liangyuan-round"), name) then
        local subcards = {}
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          table.insertTable(subcards, p:getPile(piles[i]))
        end
        if #subcards > 0 and #player:getViewAsCardNames(liangyuan.name, {name}, subcards) > 0 then
          return true
        end
      end
    end
  end,
})

return liangyuan
