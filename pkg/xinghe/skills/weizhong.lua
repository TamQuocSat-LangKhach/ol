local weizhong = fk.CreateSkill{
  name = "ol__weizhong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__weizhong"] = "威重",
  [":ol__weizhong"] = "锁定技，每当你的体力上限变化时，若你手牌数：不为全场最少，你摸一张牌；为全场最少，你摸两张牌。",

  ["$ol__weizhong"] = "本将军，誓与寿春，共存亡。",
}

weizhong:addEffect(fk.MaxHpChanged, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.every(room.alive_players, function (p)
      return p:getHandcardNum() >= player:getHandcardNum()
    end) then
      player:drawCards(2, weizhong.name)
    else
      player:drawCards(1, weizhong.name)
    end
  end,
})

return weizhong
