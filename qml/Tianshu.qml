import QtQuick
import QtQuick.Layouts
import Fk.RoomElement

ColumnLayout {
  id: root
  anchors.fill: parent
  property var extra_data: ({ name: "", data: {
    skillName: [],
    skillTimes: [],
    skillInfo: [],
    owner: 0,
  } })
  signal finish()

  BigGlowText {
    Layout.fillWidth: true
    Layout.preferredHeight: childrenRect.height + 4

    text: luatr(extra_data.name)
  }

  ListView {
    id: body
    Layout.fillWidth: true
    Layout.fillHeight: true

    clip: true
    spacing: 20

    model: extra_data.data

    delegate: TextEdit {
      id: skillDesc

      width: body.width
      font.pixelSize: 18
      color: "#E4D5A0"
      text: (Self.id === modelData.owner || modelData.visible || leval(`(function() return ClientInstance:getPlayerById(Self.id):hasSkill("hedao") end)()`) ) ? 
        "<b>" + luatr(modelData.skillName) + "</b>: （还剩" + modelData.skillTimes + "次）"+ modelData.skillInfo :
        "<b>未知</b>: （还剩" + modelData.skillTimes + "次）"

      readOnly: true
      selectByKeyboard: true
      selectByMouse: false
      wrapMode: TextEdit.WordWrap
      textFormat: TextEdit.RichText
    }
  }

  onExtra_dataChanged: {
    if (typeof(extra_data.data) == "string") {
      extra_data.data = [ extra_data.data ];
    }
  }
}

