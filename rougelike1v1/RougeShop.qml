// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Fk.Pages
import Fk.RoomElement

GraphicsBox {
  id: root

  property var result: []
  property int money: 0

  title.text: luatr("#rouge_shop")
  width: Math.max(140, body.width + 20)
  height: buttons.height + body.height + title.height + 20

  Component {
    id: talentOrSkill
    Flickable {
      property var modelValue: [0, 0, "slash"]
      x: 4
      contentHeight: detail.height
      clip: true
      Text {
        id: detail
        width: parent.width
        text: `<h3>${luatr(modelValue[2])}</h3>${luatr(":" + modelValue[2])}`
        color: "white"
        wrapMode: Text.WordWrap
        font.pixelSize: 16
        textFormat: TextEdit.RichText
      }
    }
  }

  Component {
    id: cardDelegate
    Item {
      property var modelValue: [0, 0, "slash", 7, 0]
      CardItem {
        anchors.centerIn: parent
        name: parent.modelValue[2]
        number: parent.modelValue[3]
        suit: (["spade", "club", "heart", "diamond"])[parent.modelValue[4]-1]
      }
    }
  }

  ListView {
    id: body
    x: 10
    y: title.height + 5
    width: Math.min(960, 220 * model.length)
    height: 300
    orientation: ListView.Horizontal
    clip: true
    spacing: 20

    model: []

    delegate: Item {
      width: 200
      height: 290

      MetroToggleButton {
        id: choicetitle
        width: parent.width
        text: luatr("rouge_money") + "x" + modelData[1]
        triggered: root.result.includes(index)
        textFont.pixelSize: 24
        anchors.top: choiceDetail.bottom
        anchors.topMargin: 8
        enabled: {
          if (triggered) return true;
          let rest_money = root.money;
          root.result.forEach(idx => rest_money -= body.model[idx][1]);
          return modelData[1] <= rest_money;
        }

        onClicked: {
          if (triggered) {
            root.result.push(index);
          } else {
            root.result.splice(root.result.indexOf(index), 1);
          }
          root.result = root.result;
        }
      }

      Loader {
        id: choiceDetail
        width: parent.width
        height: parent.height - choicetitle.height
        sourceComponent: {
          switch (modelData[0]) {
          case 'talent':
          case 'skill':
            return talentOrSkill;
          case 'card':
            return cardDelegate;
          default:
            return;  
          }
        }
        Binding {
          target: choiceDetail.item
          property: "modelValue"
          value: modelData
        }
      }
    }
  }

  Row {
    id: buttons
    anchors.margins: 8
    anchors.horizontalCenter: root.horizontalCenter
    anchors.top: body.bottom
    spacing: 32

    MetroButton {
      width: 100
      Layout.fillWidth: true
      text: luatr("rouge_shop_ok")
      id: buttonConfirm

      onClicked: {
        close();
        roomScene.state = "notactive";
        ClientInstance.replyToServer("",
          JSON.stringify(root.result.map(idx => body.model[idx])));
      }
    }
  }

  function loadData(data) {
    root.money = leval('Self:getMark("rouge_money")')
    body.model = data;
  }
}
