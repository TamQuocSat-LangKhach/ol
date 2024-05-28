// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Fk.Pages
import Fk.RoomElement

GraphicsBox {
  id: root

  property var cards: []
  property int result

  title.text: luatr("#guangu-choice")
  width: 440
  height: 260

  Rectangle {
    id: cardArea
    anchors.fill: parent
    anchors.topMargin: 40
    anchors.leftMargin: 15
    anchors.rightMargin: 15
    anchors.bottomMargin: 50

    color: "#88EEEEEE"
    radius: 10

    Row {
      anchors.centerIn: parent
      spacing: 5

      Repeater {
        id: to_select
        model: cards

        CardItem {
          cid: modelData
          name: ""
          suit: ""
          number: 0
          autoBack: false
          known: false
          selectable: true
          onSelectedChanged: {
            root.result = cid;
            root.updateCardSelectable();
          }
        }
      }
    }
  }

  Row {
    id: buttons
    anchors.margins: 8
    anchors.top: cardArea.bottom
    anchors.horizontalCenter: root.horizontalCenter
    spacing: 32

    MetroButton {
      width: 100
      Layout.fillWidth: true
      text: luatr("OK")
      id: buttonConfirm
      enabled : false

      onClicked: {
        close();
        roomScene.state = "notactive";
        ClientInstance.replyToServer("", root.result.toString());
      }
    }
  }


  function updateCardSelectable() {
    buttonConfirm.enabled = true;
    let item;
    for (let i = 0; i < to_select.count; i++) {
      item = to_select.itemAt(i);
      item.chosenInBox = (i < result);
    }
  }

  function loadData(data) {
    cards = data;
  }
}

