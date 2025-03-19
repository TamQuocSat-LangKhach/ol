local qionglan = fk.CreateSkill{
  name = "qionglan",
}

Fk:loadTranslationTable{
  ["qionglan"] = "穹览",
  [":qionglan"] = "此东吴命运线未开启。",

  ["$qionglan1"] = "事无巨细，咸既问询。",
  ["$qionglan2"] = "纵览全局，以小见大。",
}

qionglan:addEffect("visibility", {
})

return qionglan
