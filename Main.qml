import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
    id: root
    property var pluginApi: null

    // Exposed to DesktopWidget via pluginApi.mainInstance
    property var eventData: null
    property bool loading: false
    property string errorMsg: ""

    // Server selection from settings
    property int serverIndex: pluginApi?.pluginSettings?.serverIndex ?? 1

    onServerIndexChanged: {
        if (pluginApi?.pluginSettings) {
            pluginApi.pluginSettings.serverIndex = serverIndex;
            pluginApi.saveSettings();
        }
        root.fetch();
    }

    readonly property string pluginDir: pluginApi?.pluginDir ?? ""

    // Server names for display
    readonly property var serverNames: ["JP", "EN", "TW", "CN"]

    // Refresh every 5 minutes
    Timer {
        id: refreshTimer
        interval: 5 * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.fetch()
    }

    function fetch() {
        if (fetchProcess.running) return
        root.eventData = null  // clear stale data so loading indicator shows
        root.loading = true
        root.errorMsg = ""
        fetchProcess.command = ["python3", root.pluginDir + "/fetch.py", String(root.serverIndex)]
        fetchProcess.running = true
    }

    Process {
        id: fetchProcess
        command: []
        stdout: StdioCollector {}
        running: false

        onExited: (exitCode) => {
            root.loading = false
            if (exitCode === 0) {
                try {
                    var raw = fetchProcess.stdout.text.trim()
                    root.eventData = JSON.parse(raw)
                } catch (e) {
                    root.errorMsg = "Parse error: " + e
                }
            } else {
                root.errorMsg = "Fetch failed (exit " + exitCode + ")"
            }
        }
    }
}
