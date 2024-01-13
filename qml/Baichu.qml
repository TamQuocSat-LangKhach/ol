import QtQuick
import QtQuick.Layouts
import Fk.RoomElement

ColumnLayout {
  id: root
  anchors.fill: parent
  property var extra_data: ({ name: "", data: {} })
  signal finish()

  BigGlowText {
    Layout.fillWidth: true
    Layout.preferredHeight: childrenRect.height + 4

    text: Backend.translate(extra_data.name)
  }

  // 懒得起名，功能是根据index从对象中取得牌名
  function getNameFromIdx(idx) {
    const tab = extra_data.data._tab;
    const suit = ["spade", "heart", "club", "diamond"][Math.floor(idx / 3)];
    const type = ["basic", "trick", "equip"][idx % 3];
    return (tab && tab[suit] && tab[suit][type]) ?? "";
  }

  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    GridLayout {
      id: table
      anchors.centerIn: parent
      columns: 3
      Repeater {
        model: 12
        Rectangle {
          height: 40
          width: 160
          color: getNameFromIdx(index) ? "snow" : "grey"
          opacity: 0.8
          radius: 8
          border.width: 2
          Text {
            anchors.centerIn: parent
            font.pixelSize: 24
            text: Backend.translate(getNameFromIdx(index))
          }
        }
      }
    }

    RowLayout {
      anchors.left: table.left
      anchors.bottom: table.top
      anchors.bottomMargin: 4
      Repeater {
        model: ["基本牌", "锦囊牌", "装备牌"]
        Item {
          width: 160
          height: childrenRect.height
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData
            font.pixelSize: 24
            color: "#E4D5A0"
          }
        }
      }
    }

    ColumnLayout {
      anchors.top: table.top
      anchors.right: table.left
      anchors.rightMargin: 4
      Repeater {
        model: ["♠", '<font color="red">♥</font>', "♣", '<font color="red">♦</font>']
        Item {
          width: childrenRect.width
          height: 40
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: modelData
            font.pixelSize: 24
            color: "#E4D5A0"
          }
        }
      }
    }
  }
}

