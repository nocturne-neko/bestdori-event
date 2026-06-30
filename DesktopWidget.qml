import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Widgets

DraggableDesktopWidget {
    id: root
    property var pluginApi: null

    implicitWidth: 320
    implicitHeight: mainColumn.height + Style.marginM * 2
    showBackground: true

    readonly property var event: root.pluginApi?.mainInstance?.eventData
    readonly property bool isLoading: root.pluginApi?.mainInstance?.loading ?? false
    readonly property string errorMsg: root.pluginApi?.mainInstance?.errorMsg ?? ""

    function formatTime(ms) {
        if (!ms) return "";
        var date = new Date(Number(ms));
        return date.toLocaleDateString(Qt.locale(), "MMM d") + " " +
               date.toLocaleTimeString(Qt.locale(), "HH:mm");
    }

    Column {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Style.marginL
        anchors.rightMargin: Style.marginL
        anchors.topMargin: Style.marginM
        spacing: 10

        // 1. Banner Image
        Rectangle {
            width: parent.width
            height: 100
            color: Color.mSurfaceVariant
            radius: Style.radiusM
            clip: true

            Image {
                id: bannerImage
                anchors.fill: parent
                source: root.event ? root.event.bannerUrl : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
                visible: status === Image.Ready
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }

            NBusyIndicator {
                anchors.centerIn: parent
                visible: root.isLoading && bannerImage.status !== Image.Ready
            }

            NText {
                anchors.centerIn: parent
                anchors.topMargin: 20
                text: {
                    if (root.isLoading && bannerImage.status !== Image.Ready)
                        return "Fetching latest event...";
                    if (root.errorMsg)
                        return root.errorMsg;
                    return "";
                }
                color: root.errorMsg ? Color.mError : Color.mOnSurfaceVariant
                visible: bannerImage.status !== Image.Ready
                font.pointSize: Style.fontSizeS
            }
        }

        // 2. Body (Title + Duration)
        Column {
            width: parent.width
            spacing: 3

            NText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.event ? root.event.eventName : ""
                font.weight: Font.DemiBold
                font.pointSize: Style.fontSizeS
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                color: Color.mOnSurface
            }

            NText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.event ? (formatTime(root.event.startAt) + " ~ " + formatTime(root.event.endAt)) : ""
                font.pointSize: Style.fontSizeS - 1
                color: Color.mOnSurfaceVariant
            }
        }

        // 3. Info Row
        RowLayout {
            width: parent.width
            spacing: 4

            // Left side: Type + Attribute Icon + Band
            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                RowLayout {
                    spacing: 6

                    Rectangle {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        color: "transparent"

                        Image {
                            anchors.fill: parent
                            source: root.event ? root.event.attributeIconUrl : ""
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            visible: source.toString() !== ""
                        }
                    }

                    NText {
                        text: root.event ? root.event.eventTypeDisplay : ""
                        font.weight: Font.DemiBold
                        font.pointSize: Style.fontSizeS
                        color: Color.mPrimary
                    }
                }

                RowLayout {
                    spacing: 6
                    visible: !!root.event

                    Rectangle {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        color: "transparent"

                        Image {
                            anchors.fill: parent
                            source: root.event ? root.event.bandIconUrl : ""
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            visible: source.toString() !== ""
                        }
                    }

                    NText {
                        text: root.event ? root.event.bandName : ""
                        font.weight: Font.DemiBold
                        font.pointSize: Style.fontSizeS - 1
                        color: Color.mOnSurfaceVariant
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Right side: Character Card Icons
            RowLayout {
                spacing: 4
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                Repeater {
                    model: root.event ? root.event.cards : 0

                    delegate: Rectangle {
                        width: 40
                        height: 40
                        color: "transparent"
                        border.width: 1
                        border.color: Color.mOutline
                        radius: 6
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: modelData.iconUrl
                            sourceSize.width: 38
                            sourceSize.height: 38
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }
                }
            }
        }
    }
}
