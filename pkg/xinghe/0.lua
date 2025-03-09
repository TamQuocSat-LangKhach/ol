local guiming = fk.CreateSkill{
  name = "guiming",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["guiming"] = "归命",
  [":guiming"] = "主公技，锁定技，其他吴势力角色于你的回合内视为已受伤的角色。",

  ["$guiming1"] = "这是要我命归黄泉吗？",
  ["$guiming2"] = "这就是末世皇帝的不归路！",
}

guiming:addEffect("targetmod", {
})

return guiming
