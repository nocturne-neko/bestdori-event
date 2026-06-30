import QtQuick
import QtQuick.Layouts
import qs.Widgets
import qs.Commons

ColumnLayout {
    id: root
    property var pluginApi: null

    // Local state variables for server selection
    property int valueServerIndex: pluginApi?.mainInstance?.serverIndex ?? (pluginApi?.pluginSettings?.serverIndex ?? 1)

    spacing: Style.marginM

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: "Game Server"
            description: "Choose which server's active event to track"
        }

        NComboBox {
            id: serverSelector
            Layout.fillWidth: true
            model: [
                { key: "0", name: "Japanese (JP)" },
                { key: "1", name: "English (EN)" },
                { key: "2", name: "Taiwanese (TW)" },
                { key: "3", name: "Chinese (CN)" }
            ]
            currentKey: String(root.valueServerIndex)
            onSelected: key => {
                root.valueServerIndex = parseInt(key)
                root.saveSettings()
            }
        }
    }

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("BestdoriEvent", "Cannot save settings: pluginApi is null");
            return;
        }

        pluginApi.pluginSettings.serverIndex = root.valueServerIndex;
        pluginApi.saveSettings();

        // Propagate to running instance immediately
        if (pluginApi.mainInstance) {
            pluginApi.mainInstance.serverIndex = root.valueServerIndex;
        }
    }
}
