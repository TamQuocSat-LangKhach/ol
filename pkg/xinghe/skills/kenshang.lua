local kenshang = fk.CreateSkill{
  name = "kenshang",
}

Fk:loadTranslationTable{
  ["kenshang"] = "垦伤",
  [":kenshang"] = "你可以将至少两张牌当【杀】使用，然后目标可以改为等量的角色。你以此法使用的【杀】结算后，若这些牌数大于此牌造成的伤害，"..
  "你摸一张牌。",

  ["#kenshang"] = "垦伤：将至少两张牌当【杀】使用，可以将目标改为等量角色",
  ["#kenshang-choose"] = "垦伤：你可以将目标改为指定%arg名角色",

  ["$kenshang1"] = "择兵选将，一击而大白。",
  ["$kenshang2"] = "纵横三辅，垦伤庸富。",
}

kenshang:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#kenshang",
  handly_pile = true,
  card_filter = Util.TrueFunc,
  view_as = function(self, player, cards)
    if #cards < 2 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = kenshang.name
    c:addSubcards(cards)
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not player:isProhibited(p, use.card)
    end)
    local n = math.min(#targets, #use.card.subcards)
    local tos = room:askToChoosePlayers(player, {
      min_num = n,
      max_num = n,
      targets = targets,
      skill_name = kenshang.name,
      prompt = "#kenshang-choose:::"..n,
      cancelable = true,
    })
    if #tos == n then
      use.tos = targets
    end
  end,
  after_use = function (self, player, use)
    if not player.dead then
      local n = 0
      if use.damageDealt then
        for _, p in ipairs(player.room.players) do
          if use.damageDealt[p] then
            n = n + use.damageDealt[p]
          end
        end
      end
      if #use.card.subcards > n then
        player:drawCards(1, kenshang.name)
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})

return kenshang
