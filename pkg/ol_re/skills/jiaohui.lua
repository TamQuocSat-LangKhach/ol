local jiaohui = fk.CreateSkill{
  name = "jiaohui",
}

Fk:loadTranslationTable{
  ["jiaohui"] = "交辉",
  [":jiaohui"] = "此东吴命运线未开启。",

  ["$jiaohui1"] = "日月交辉，天下大白。",
  ["$jiaohui2"] = "雄鸡引颈，声鸣百里。",
}

jiaohui:addEffect("visibility", {
})

return jiaohui
