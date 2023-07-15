// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import Fk.Pages
import Fk.RoomElement

GraphicsBox {
  id: root

  property var selected_ids: []
  property string prompt: ""
  property var cards: []

  title.text: Backend.translate(prompt)
  // TODO: Adjust the UI design in case there are more than 7 cards
  width: 70 + Math.min(7, Math.max(4, cards.length)) * 100
  height: 230

  Component {
    id: cardDelegate
    CardItem {
      Component.onCompleted: {
        setData(modelData);
      }
      autoBack: false
      selectable: true
      onSelectedChanged: {
        if (selected) {
          origY = origY - 20;
          root.selected_ids.push(cid);
        } else {
          origY = origY + 20;
          root.selected_ids.splice(root.selected_ids.indexOf(cid), 1);
        }
        origX = x;
        goBack(true);
        root.selected_idsChanged();
        root.updateCardSelectable();
      }
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.topMargin: 40
    anchors.leftMargin: 20
    anchors.rightMargin: 20
    anchors.bottomMargin: 20

    Row {
      height: 130
      spacing: 15

      Row {
        spacing: 7
        Repeater {
          id: to_select
          model: cards
          delegate: cardDelegate
        }
      }
    }

    Row {
      MetroButton {
        text: Backend.translate("guzheng_yes")
        enabled: root.selected_ids.length == 1
        onClicked: {
          close();
          const reply = JSON.stringify(
            {
              cards: root.selected_ids,
              choice: "guzheng_yes",
            }
          );
          ClientInstance.replyToServer("", reply);
        }
      }
      MetroButton {
        text: Backend.translate("guzheng_no")
        enabled: root.selected_ids.length == 1
        onClicked: {
          close();
          const reply = JSON.stringify(
            {
              cards: root.selected_ids,
              choice: "guzheng_no",
            }
          );
          ClientInstance.replyToServer("", reply);
        }
      }
    }
  }

  function updateCardSelectable() {
    for (let i = 0; i < cards.length; i++) {
      const item = to_select.itemAt(i);
      if (item.selected) continue;
      item.selectable = root.selected_ids.length == 0;
    }
  }

  function loadData(data) {
    const d = data;
    cards = d[0].map(cid => {
      return JSON.parse(Backend.callLuaFunction("GetCardData", [cid]));
    });
    prompt = d[1];
  }
}

