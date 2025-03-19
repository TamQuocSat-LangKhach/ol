local yuanlv = fk.CreateSkill{
  name = "yuanlv",
}

Fk:loadTranslationTable{
  ["yuanlv"] = "渊虑",
  [":yuanlv"] = "此东吴命运线未开启。",

  ["$yuanlv1"] = "临江而眺，静观江水东流。",
  ["$yuanlv2"] = "屹立山巅，笑看大江潮来。",
}

yuanlv:addEffect("visibility", {
})

return yuanlv
