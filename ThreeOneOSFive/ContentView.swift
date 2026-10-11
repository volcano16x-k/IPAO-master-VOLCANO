import SwiftUI
import UIKit
import AVFoundation
import Network

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appState: AppState
    @State private var showSettings = false
    @State private var showCleaner = false
    @StateObject private var patchStore = PatchProjectStore()
    @State private var patchOperationBusy = false
    @State private var patchMessage = "READY — SELECT A PATCH"
    @State private var aimDragEnabled = false
    @State private var aimNeckEnabled = false
    @State private var hspeitoffEnabled = false

    @AppStorage("regditFile") private var regditFile = "VOLCANO File (6).3105"
    @AppStorage("fpsFile") private var fpsFile = "VOLCANO File (7).3105"
    @AppStorage("plusFile") private var plusFile = "VOLCANO File (8).3105"

    @AppStorage("lockRegditButton") private var lockRegditButton = false
    @AppStorage("lockFpsButton") private var lockFpsButton = false
    @AppStorage("lockPlusButton") private var lockPlusButton = false

    // Hide buttons from the main screen (controlled from Settings + the web panel)
    @AppStorage("hideRegditButton") private var hideRegditButton = false
    @AppStorage("hideFpsButton") private var hideFpsButton = false
    @AppStorage("hidePlusButton") private var hidePlusButton = false

    @AppStorage("currentPassword") private var currentPassword = "123"

    @State private var serverURL: String? = nil
    @State private var isServerRunning = false
    @State private var showServerDetails = false

    var body: some View {
        ZStack {
            AnimatedHyperBackdrop()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    brandHeader
                    devicePanel
                    webServerPanel
                    patchOptions
                    gameLaunchPanel
                    footerStatus
                    developerCredits
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showCleaner) {
            CleanerView()
        }
        .sheet(item: $patchStore.passwordRequest, onDismiss: patchStore.cancelUnlock) { _ in
            PatchUnlockPrompt(store: patchStore)
        }
        .onAppear {
            setupAudioSessionForBackground()
            syncPatchStates()
            startServerAutomatically()
        }
        .onChange(of: scenePhase) { phase in
            // keep audio + server alive on every phase change
            BackgroundKeeper.shared.start()
            if !IntegratedWebServer.shared.isRunning {
                isServerRunning = false
                startServerAutomatically()
            }
            guard phase == .active, !patchOperationBusy else { return }
            syncPatchStates()
            patchMessage = "READY — SELECT A PATCH"
        }
    }

    private func setupAudioSessionForBackground() {
        BackgroundKeeper.shared.start()
    }

    private func startServerAutomatically() {
        guard !IntegratedWebServer.shared.isRunning else { return }
        
        IntegratedWebServer.shared.itemsProvider = {
            return [
                WebPatchItem(id: "Regdit", title: "🎯 REGDIT", isEnabled: self.aimDragEnabled, isLocked: self.lockRegditButton, filename: self.regditFile, isHidden: self.hideRegditButton),
                WebPatchItem(id: "144fps", title: "🚀 144 FPS", isEnabled: self.aimNeckEnabled, isLocked: self.lockFpsButton, filename: self.fpsFile, isHidden: self.hideFpsButton),
                WebPatchItem(id: "plus", title: "⚡ EXTRA PATCH (+)", isEnabled: self.hspeitoffEnabled, isLocked: self.lockPlusButton, filename: self.plusFile, isHidden: self.hidePlusButton)
            ]
        }
        
        IntegratedWebServer.shared.statusProvider = { (self.patchOperationBusy, self.patchMessage) }
        
        IntegratedWebServer.shared.appPasswordProvider = { self.currentPassword }
        
        IntegratedWebServer.shared.onTogglePatch = { patchID in
            DispatchQueue.main.async {
                let isLocked: Bool
                if patchID == "Regdit" { isLocked = self.lockRegditButton }
                else if patchID == "144fps" { isLocked = self.lockFpsButton }
                else { isLocked = self.lockPlusButton }
                
                let isHiddenNow: Bool
                if patchID == "Regdit" { isHiddenNow = self.hideRegditButton }
                else if patchID == "144fps" { isHiddenNow = self.hideFpsButton }
                else { isHiddenNow = self.hidePlusButton }
                
                guard !isLocked, !isHiddenNow else { return }
                
                if patchID == "Regdit" {
                    self.togglePatch(packageFilename: self.regditFile, state: self.$aimDragEnabled)
                } else if patchID == "144fps" {
                    self.togglePatch(packageFilename: self.fpsFile, state: self.$aimNeckEnabled)
                } else if patchID == "plus" {
                    self.togglePatch(packageFilename: self.plusFile, state: self.$hspeitoffEnabled)
                }
            }
        }
        
        IntegratedWebServer.shared.onToggleLock = { patchID, isLocked in
            DispatchQueue.main.async {
                if patchID == "Regdit" {
                    self.lockRegditButton = isLocked
                } else if patchID == "144fps" {
                    self.lockFpsButton = isLocked
                } else if patchID == "plus" {
                    self.lockPlusButton = isLocked
                }
            }
        }
        
        IntegratedWebServer.shared.onToggleHide = { patchID, hidden in
            DispatchQueue.main.async {
                if patchID == "Regdit" {
                    self.hideRegditButton = hidden
                } else if patchID == "144fps" {
                    self.hideFpsButton = hidden
                } else if patchID == "plus" {
                    self.hidePlusButton = hidden
                }
            }
        }
        
        IntegratedWebServer.shared.onUpdateFileName = { patchID, newFilename in
            DispatchQueue.main.async {
                if patchID == "Regdit" {
                    self.regditFile = newFilename
                } else if patchID == "144fps" {
                    self.fpsFile = newFilename
                } else if patchID == "plus" {
                    self.plusFile = newFilename
                }
            }
        }
        
        IntegratedWebServer.shared.onUpdatePassword = { newPass in
            DispatchQueue.main.async {
                self.currentPassword = newPass
            }
        }
        
        if let url = IntegratedWebServer.shared.startServer() {
            serverURL = url
            isServerRunning = true
        }
    }

    private var brandHeader: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("VOLCANO")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.white)
                Text("PATCH CONTROL CENTER")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.7)
                    .foregroundStyle(AppTheme.accent)
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 48, height: 48)
                    .background(Color.black.opacity(0.38), in: Circle())
                    .overlay(Circle().stroke(AppTheme.accent.opacity(0.42), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var devicePanel: some View {
        VStack(spacing: 0) {
            panelTitle("DEVICE STATUS", icon: "shield.lefthalf.filled")
            statusRow(icon: "apple.logo", title: "iOS", value: AppInfo.osVersion, color: AppTheme.secondaryAccent)
            statusRow(icon: "iphone", title: "Device", value: AppInfo.displayMachineName, color: AppTheme.secondaryAccent)
            statusRow(icon: "checkmark.seal.fill", title: "Support", value: appState.isSupported ? "SUPPORTED" : "UNSUPPORTED", color: appState.isSupported ? .green : .red)
        }
        .padding(16)
        .background(Color.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(AppTheme.accent.opacity(0.38), lineWidth: 1))
    }

    private var webServerPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "network")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                
                Circle()
                    .fill(isServerRunning ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text("SERVER")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(AppTheme.accent)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showServerDetails.toggle()
                    }
                } label: {
                    Text(showServerDetails ? "HIDE DETAILS" : "SHOW DETAILS")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.4), in: Capsule())
                        .overlay(Capsule().stroke(AppTheme.accent.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            if showServerDetails, let url = serverURL {
                VStack(spacing: 8) {
                    Text("AUTO. Click to Copy:")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                    
                    Button {
                        UIPasteboard.general.string = url
                        patchMessage = "SERVER URL COPIED"
                    } label: {
                        Text(url)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                            .foregroundStyle(AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(AppTheme.accent.opacity(0.38), lineWidth: 1))
    }

    private var patchOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                panelTitle("PATCH OPTIONS", icon: "bolt.fill")
                Spacer()
                Text("SELECT TO ENABLE")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                if !hideRegditButton {
                    patchCard(name: "Regdit", target: "FREE FIRE • NORMAL", package: regditFile, color: AppTheme.accent, state: $aimDragEnabled, locked: lockRegditButton)
                }
                if !hideFpsButton {
                    patchCard(name: "144fps", target: "FREE FIRE • NORMAL", package: fpsFile, color: AppTheme.secondaryAccent, state: $aimNeckEnabled, locked: lockFpsButton)
                }
                if !hidePlusButton {
                    patchCard(name: "+", target: "FREE FIRE • NORMAL", package: plusFile, color: AppTheme.secondaryAccent, state: $hspeitoffEnabled, locked: lockPlusButton)
                }
            }

            HStack(spacing: 8) {
                Circle().fill(patchMessage.localizedCaseInsensitiveContains("successful") ? .green : AppTheme.accent).frame(width: 7, height: 7)
                Text(patchOperationBusy ? "PROCESSING PATCH…" : patchMessage)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(2)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.34), in: Capsule())
        }
    }

    private func patchCard(name: String, target: String, package: String, color: Color, state: Binding<Bool>, locked: Bool) -> some View {
        PatchOptionCard(name: name, target: target, color: color, isEnabled: state, isBusy: patchOperationBusy || locked) {
            togglePatch(packageFilename: package, state: state)
        }
    }

    private var gameLaunchPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            panelTitle("LAUNCH GAME", icon: "arrow.up.forward.app.fill")
            HStack(spacing: 12) {
                launchButton(title: "FF NORMAL", subtitle: "Free Fire Normal", color: AppTheme.accent, scheme: "freefireth")
            }
            Button {
                showCleaner = true
            } label: {
                Label("Clean Cache & Temp", systemImage: "trash.slash.fill")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color.black.opacity(0.40), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.accent.opacity(0.52), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private func launchButton(title: String, subtitle: String, color: Color, scheme: String) -> some View {
        Button { openGame(scheme: scheme) } label: {
            VStack(alignment: .leading, spacing: 7) {
                Image(systemName: "arrow.up.right.square.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
            .padding(.horizontal, 14)
            .background(Color.black.opacity(0.40), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(color.opacity(0.38), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var footerStatus: some View {
        HStack(spacing: 10) {
            Circle().fill(.green).frame(width: 9, height: 9).shadow(color: .green, radius: 6)
            Text("SYSTEM READY")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.72))
            Spacer()
            Text("VOLCANO • READY")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.accent.opacity(0.8))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color.black.opacity(0.45), in: Capsule())
        .overlay(Capsule().stroke(AppTheme.accent.opacity(0.2), lineWidth: 1))
    }

    private var developerCredits: some View {
        VStack(spacing: 10) {
            Text("Developed by VOLCANO")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                channelButton(title: "VOLCANO TikTok", url: "https://www.tiktok.com/@volcano16x")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private func channelButton(title: String, url: String) -> some View {
        Button {
            guard let destination = URL(string: url) else { return }
            UIApplication.shared.open(destination)
        } label: {
            Label(title, systemImage: "paperplane.fill")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(AppTheme.accent.opacity(0.18), in: Capsule())
                .overlay(Capsule().stroke(AppTheme.accent.opacity(0.42), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func panelTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 12, weight: .black, design: .rounded))
            .tracking(1.4)
            .foregroundStyle(AppTheme.accent)
    }

    private func statusRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 17, weight: .bold)).foregroundStyle(color).frame(width: 24)
            Text(title).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.58))
            Spacer()
            Text(value).font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(.white)
        }
        .padding(.top, 14)
    }

    private func syncPatchStates() {
        aimDragEnabled = isPatchActive(regditFile)
        aimNeckEnabled = isPatchActive(fpsFile)
        hspeitoffEnabled = isPatchActive(plusFile)
    }

    private func isPatchActive(_ packageFilename: String) -> Bool {
        patchStore.items.first(where: { $0.packageURL.lastPathComponent.caseInsensitiveCompare(packageFilename) == .orderedSame })
            .flatMap { DevicePatchService.latestReceipt(projectID: $0.id) } != nil
    }

    private enum PatchActionResult {
        case applied
        case restored
        case unavailable(String)
    }

    private func setPatchState(for packageFilename: String, enabled: Bool) {
        if packageFilename.caseInsensitiveCompare(regditFile) == .orderedSame {
            aimDragEnabled = enabled
        } else if packageFilename.caseInsensitiveCompare(fpsFile) == .orderedSame {
            aimNeckEnabled = enabled
        } else if packageFilename.caseInsensitiveCompare(plusFile) == .orderedSame {
            hspeitoffEnabled = enabled
        }
    }

    private func togglePatch(packageFilename: String, state: Binding<Bool>) {
        guard !patchOperationBusy else { return }
        guard let item = patchStore.items.first(where: { $0.packageURL.lastPathComponent.caseInsensitiveCompare(packageFilename) == .orderedSame }) else {
            patchMessage = "ERROR — PACKAGE NOT FOUND"
            return
        }

        let wasEnabled = state.wrappedValue
        patchOperationBusy = true
        patchMessage = "PROCESSING — \(packageFilename)"
        let project = item.project
        let projectID = item.id

        DispatchQueue.global(qos: .userInitiated).async {
            let result: PatchActionResult
            do {
                if wasEnabled {
                    guard let receipt = DevicePatchService.latestReceipt(projectID: projectID) else {
                        result = .unavailable("NO ACTIVE RECEIPT")
                        DispatchQueue.main.async {
                            self.setPatchState(for: packageFilename, enabled: false)
                            self.patchMessage = "OFF"
                            self.patchOperationBusy = false
                        }
                        return
                    }
                    try DevicePatchService.restore(receipt: receipt)
                    result = .restored
                } else {
                    guard let project else {
                        result = .unavailable("PASSWORD REQUIRED")
                        DispatchQueue.main.async {
                            self.patchStore.requestUnlock(for: item)
                            self.patchMessage = "PASSWORD REQUIRED"
                            self.patchOperationBusy = false
                        }
                        return
                    }
                    _ = try DevicePatchService.apply(project: project)
                    result = .applied
                }
            } catch {
                result = .unavailable("FAILED")
            }

            DispatchQueue.main.async {
                switch result {
                case .applied:
                    self.setPatchState(for: packageFilename, enabled: true)
                    self.patchMessage = "Inject Successful — \(packageFilename)"
                case .restored:
                    self.setPatchState(for: packageFilename, enabled: false)
                    self.patchMessage = "Restore Successful — \(packageFilename)"
                case .unavailable(let message):
                    self.patchMessage = message
                }
                self.patchOperationBusy = false
            }
        }
    }

    private func openGame(scheme: String) {
        guard let url = URL(string: "\(scheme)://") else { return }
        UIApplication.shared.open(url, options: [:]) { _ in }
    }
}

struct WebPatchItem {
    let id: String
    let title: String
    let isEnabled: Bool
    let isLocked: Bool
    let filename: String
    var isHidden: Bool = false
}

private class IntegratedWebServer {
    static let shared = IntegratedWebServer()
    private var listener: NWListener?
    var onTogglePatch: ((String) -> Void)?
    var onToggleLock: ((String, Bool) -> Void)?
    var onToggleHide: ((String, Bool) -> Void)?
    var onUpdateFileName: ((String, String) -> Void)?
    var onUpdatePassword: ((String) -> Void)?
    
    var itemsProvider: (() -> [WebPatchItem])?
    var statusProvider: (() -> (busy: Bool, message: String))?
    var appPasswordProvider: (() -> String)?
    var isWebUnlocked = false
    private(set) var isRunning = false
    private var retryCount = 0
    
    func startServer() -> String? {
        let port: UInt16 = 8080
        let ip = getLocalIPAddress() ?? "localhost"
        let serverURL = "http://\(ip):\(port)"
        
        stopServer()
        
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            let l = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
            l.newConnectionHandler = { connection in
                self.handleConnection(connection)
            }
            l.stateUpdateHandler = { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .ready:
                    self.isRunning = true
                    self.retryCount = 0
                case .failed, .cancelled:
                    self.isRunning = false
                    if case .failed = state, self.retryCount < 10 {
                        self.retryCount += 1
                        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                            _ = self.startServer()
                        }
                    }
                default:
                    break
                }
            }
            listener = l
            isRunning = true
            l.start(queue: .global())
            return serverURL
        } catch {
            isRunning = false
            return nil
        }
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global())
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, _ in
            if let data = data, let requestString = String(data: data, encoding: .utf8) {
                
                if requestString.contains("GET /toggle?patch=") {
                    if let range = requestString.range(of: "GET /toggle?patch=") {
                        let sub = String(requestString[range.upperBound...])
                        let patchID = sub.components(separatedBy: " ")[0].removingPercentEncoding ?? ""
                        self.onTogglePatch?(patchID)
                    }
                } else if requestString.contains("GET /hide?patch=") {
                    if self.isWebUnlocked, let range = requestString.range(of: "GET /hide?patch=") {
                        let sub = String(requestString[range.upperBound...])
                        let patchID = sub.components(separatedBy: " ")[0].removingPercentEncoding ?? ""
                        let currentItems = self.itemsProvider?() ?? []
                        if let item = currentItems.first(where: { $0.id == patchID }) {
                            self.onToggleHide?(patchID, !item.isHidden)
                        }
                    }
                } else if requestString.contains("GET /lock?patch=") {
                    if self.isWebUnlocked, let range = requestString.range(of: "GET /lock?patch=") {
                        let sub = String(requestString[range.upperBound...])
                        let patchID = sub.components(separatedBy: " ")[0].removingPercentEncoding ?? ""
                        let currentItems = self.itemsProvider?() ?? []
                        if let item = currentItems.first(where: { $0.id == patchID }) {
                            self.onToggleLock?(patchID, !item.isLocked)
                        }
                    }
                } else if requestString.contains("GET /lockweb") {
                    self.isWebUnlocked = false
                } else if requestString.contains("POST /unlockweb") {
                    if let bodyRange = requestString.range(of: "\r\n\r\n") {
                        let body = String(requestString[bodyRange.upperBound...])
                        let params = body.components(separatedBy: "&")
                        for param in params {
                            let pair = param.components(separatedBy: "=")
                            if pair.count == 2 && pair[0] == "password" {
                                let enteredPass = pair[1].removingPercentEncoding ?? ""
                                if enteredPass == (self.appPasswordProvider?() ?? "123") {
                                    self.isWebUnlocked = true
                                }
                            }
                        }
                    }
                } else if requestString.contains("POST /updatePassword") {
                    if let bodyRange = requestString.range(of: "\r\n\r\n") {
                        let body = String(requestString[bodyRange.upperBound...])
                        let params = body.components(separatedBy: "&")
                        for param in params {
                            let pair = param.components(separatedBy: "=")
                            if pair.count == 2 && pair[0] == "newpassword" {
                                let newPass = pair[1].removingPercentEncoding ?? ""
                                if !newPass.isEmpty {
                                    self.onUpdatePassword?(newPass)
                                }
                            }
                        }
                    }
                } else if requestString.contains("POST /updateFile") {
                    if let bodyRange = requestString.range(of: "\r\n\r\n") {
                        let body = String(requestString[bodyRange.upperBound...])
                        let params = body.components(separatedBy: "&")
                        var patchID = ""
                        var newName = ""
                        for param in params {
                            let pair = param.components(separatedBy: "=")
                            if pair.count == 2 {
                                if pair[0] == "patch" { patchID = pair[1].removingPercentEncoding ?? "" }
                                if pair[0] == "filename" { newName = pair[1].removingPercentEncoding?.replacingOccurrences(of: "+", with: " ") ?? "" }
                            }
                        }
                        if !patchID.isEmpty && !newName.isEmpty {
                            self.onUpdateFileName?(patchID, newName)
                        }
                    }
                }
                
                let firstLine = requestString.components(separatedBy: "\r\n").first ?? ""
                let isAction = firstLine.hasPrefix("POST ")
                    || firstLine.hasPrefix("GET /toggle")
                    || firstLine.hasPrefix("GET /lock")
                    || firstLine.hasPrefix("GET /hide")
                if isAction {
                    let redirect = "HTTP/1.1 303 See Other\r\nLocation: /\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
                    connection.send(content: redirect.data(using: .utf8), completion: .contentProcessed({ _ in
                        connection.cancel()
                    }))
                    return
                }
                
                var activeCardsHTML = ""
                let items = self.itemsProvider?() ?? []
                let st = self.statusProvider?() ?? (busy: false, message: "")
                let safeMessage = st.message
                    .replacingOccurrences(of: "&", with: "&amp;")
                    .replacingOccurrences(of: "<", with: "&lt;")
                    .replacingOccurrences(of: ">", with: "&gt;")
                
                for item in items where !item.isHidden || self.isWebUnlocked {
                    let isChecked = item.isEnabled ? "checked" : ""
                    let isLockedChecked = item.isLocked ? "checked" : ""
                    let disabledAttr = (item.isLocked || st.busy) ? "disabled style='opacity: 0.5; cursor: not-allowed;'" : ""
                    
                    var adminSection = ""
                    if self.isWebUnlocked {
                        adminSection = """
                        <div class="input-box" style="margin-top: 8px;">
                            <label>TARGET FILE</label>
                            <form action="/updateFile" method="POST" style="display: flex; gap: 5px;">
                                <input type="hidden" name="patch" value="\(item.id)">
                                <input type="text" name="filename" value="\(item.filename)">
                                <button type="submit" class="action-button" style="margin-top:0; width: 35%; padding: 7px;">UPDATE</button>
                            </form>
                        </div>
                        <div style="margin-top: 8px; display: flex; align-items: center; justify-content: space-between;">
                            <span style="font-size: 9px; font-family: 'Roboto Mono', monospace; color: rgba(255,255,255,0.7);">🙈 HIDE BUTTON:</span>
                            <label class="switch">
                                <input type="checkbox" \(item.isHidden ? "checked" : "") onchange="act('/hide?patch=\(item.id)')">
                                <span class="slider" style="background-color: #8b5cf6;"></span>
                            </label>
                        </div>
                        <div style="margin-top: 8px; display: flex; align-items: center; justify-content: space-between;">
                            <span style="font-size: 9px; font-family: 'Roboto Mono', monospace; color: rgba(255,255,255,0.7);">🔒 LOCK BUTTON:</span>
                            <label class="switch">
                                <input type="checkbox" \(isLockedChecked) onchange="act('/lock?patch=\(item.id)')">
                                <span class="slider" style="background-color: #f59e0b;"></span>
                            </label>
                        </div>
                        """
                    }
                    
                    activeCardsHTML += """
                    <div class="menu-option">
                        <div class="option-title-container">
                            <span class="option-title">\(item.title) \(item.isLocked ? "🔒" : "")</span>
                            <label class="switch">
                                <input type="checkbox" \(isChecked) \(disabledAttr) onchange="act('/toggle?patch=\(item.id)')">
                                <span class="slider"></span>
                            </label>
                        </div>
                        <div class="option-description">Status: \(item.isEnabled ? "ACTIVE" : "OFF") \(item.isLocked ? "| LOCKED" : "") \(item.isHidden ? "| HIDDEN" : "")</div>
                        \(adminSection)
                    </div>
                    """
                }
                
                var topSettingsHeader = ""
                if self.isWebUnlocked {
                    topSettingsHeader = """
                    <div class="menu-option" style="background: rgba(59, 130, 246, 0.08); border-color: rgba(59, 130, 246, 0.3);">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                            <span style="font-size: 11px; font-weight: 600; color: #3b82f6;">SETTINGS UNLOCKED</span>
                            <a href="/lockweb" style="background: #ff3333; color: #fff; text-decoration: none; padding: 4px 10px; border-radius: 6px; font-size: 9px; font-family: 'Roboto Mono', monospace;">LOCK</a>
                        </div>
                        <form action="/updatePassword" method="POST" style="display: flex; gap: 6px;">
                            <input type="text" name="newpassword" placeholder="New Password" style="width: 70%; padding: 7px; background: rgba(0,0,0,0.55); border: 1px solid rgba(255,40,40,0.18); color: white; border-radius: 7px; font-size: 9px; font-family: 'Roboto Mono', monospace;">
                            <button type="submit" class="action-button" style="margin-top:0; width: 30%; padding: 7px;">CHANGE</button>
                        </form>
                    </div>
                    """
                } else {
                    topSettingsHeader = """
                    <form action="/unlockweb" method="POST" class="menu-option" style="display: flex; gap: 6px; align-items: center;">
                        <input type="password" name="password" placeholder="Settings Password" style="width: 70%; padding: 7px; background: rgba(0,0,0,0.55); border: 1px solid rgba(255,40,40,0.18); color: white; border-radius: 7px; font-size: 9px; font-family: 'Roboto Mono', monospace;">
                        <button type="submit" class="action-button" style="margin-top:0; width: 30%; padding: 7px;">UNLOCK</button>
                    </form>
                    """
                }
                
                let htmlResponse = """
                <!DOCTYPE html>
                <html lang="en">
                <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>volcanoSENSI</title>
                <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&family=Roboto+Mono&display=swap" rel="stylesheet">
                <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { width: 100%; height: 100%; background: #000; }
                body { display: flex; justify-content: center; align-items: center; min-height: 100vh; overflow: hidden; background: radial-gradient(circle at center, rgba(255,40,40,0.07), #000 70%); color: white; font-family: Poppins, Arial, sans-serif; user-select: none; }
                .menu-container { width: 400px; height: 520px; position: absolute; display: flex; overflow: hidden; background: rgba(0,0,0,0.92); border: 1px solid rgba(255,40,40,0.4); border-radius: 16px; box-shadow: 0 0 18px rgba(255,40,40,0.35), 0 20px 60px rgba(0,0,0,0.85); backdrop-filter: blur(12px); }
                .main-content { flex: 1; height: 100%; padding: 14px; position: relative; z-index: 2; overflow-y: auto; }
                .main-content::-webkit-scrollbar { width: 3px; }
                .main-content::-webkit-scrollbar-thumb { background: rgba(255,40,40,0.4); border-radius: 10px; }
                .menu-header { position: relative; overflow: hidden; padding: 10px; border-radius: 10px; border: 1px solid rgba(255,40,40,0.3); background: rgba(0,0,0,0.4); margin-bottom: 12px; }
                .header-content { position: relative; display: flex; align-items: center; justify-content: space-between; }
                .logo-container { display: flex; align-items: center; }
                .main-title { color: #ff3030; font-size: 15px; font-weight: 600; text-shadow: 0 0 7px #ff3030; }
                .sub-title { display: block; margin-top: 2px; color: rgba(255,255,255,0.5); font-family: Roboto Mono, monospace; font-size: 8px; }
                .status { color: #ff3030; font-family: Roboto Mono, monospace; font-size: 8px; }
                .menu-content { display: flex; flex-direction: column; gap: 9px; }
                .menu-option { position: relative; padding: 12px; border-radius: 9px; background: rgba(255,40,40,0.035); border: 1px solid rgba(255,40,40,0.1); }
                .option-title-container { display: flex; align-items: center; justify-content: space-between; }
                .option-title { color: white; font-size: 12px; font-weight: 500; }
                .option-description { margin-top: 5px; color: rgba(255,255,255,0.52); font-family: Roboto Mono, monospace; font-size: 8px; line-height: 1.5; }
                .action-button { width: 100%; padding: 9px; margin-top: 8px; border-radius: 8px; color: #ff3030; background: rgba(255,40,40,0.08); border: 1px solid rgba(255,40,40,0.3); font-family: Poppins, sans-serif; font-size: 10px; font-weight: 600; cursor: pointer; }
                .input-box label { display: block; margin-bottom: 3px; color: rgba(255,255,255,0.7); font-family: Roboto Mono, monospace; font-size: 8px; }
                .input-box input { width: 100%; padding: 7px 9px; outline: none; border-radius: 7px; background: rgba(0,0,0,0.55); border: 1px solid rgba(255,40,40,0.18); color: white; font-family: Roboto Mono, monospace; font-size: 9px; }
                .switch { position: relative; display: inline-block; width: 40px; height: 22px; }
                .switch input { opacity: 0; width: 0; height: 0; }
                .slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #27272a; transition: .3s; border-radius: 22px; border: 1px solid #3f3f46; }
                .slider:before { position: absolute; content: ""; height: 16px; width: 16px; left: 2px; bottom: 2px; background-color: white; transition: .3s; border-radius: 50%; }
                input:checked + .slider { background-color: #ff3333; border-color: #ff3333; }
                input:checked + .slider:before { transform: translateX(18px); }
                </style>
                </head>
                <body>
                <div class="menu-container" id="menu">
                    <div class="main-content">
                        <header class="menu-header">
                            <div class="header-content">
                                <div class="logo-container">
                                    <div>
                                        <div class="main-title">VOLCANO CONTROL PANEL</div>
                                        <span class="sub-title">WEB DAV CONTROL CENTER</span>
                                    </div>
                                </div>
                                <span class="status" id="conn">● ONLINE</span>
                            </div>
                        </header>
                        <div class="menu-content" id="live">
                            <div class="menu-option" style="padding: 9px 12px;">
                                <div class="option-description" style="margin-top: 0; color: \(st.busy ? "#f59e0b" : "rgba(255,255,255,0.8)");">\(st.busy ? "⏳ PROCESSING…" : (safeMessage.isEmpty ? "READY" : safeMessage))</div>
                            </div>
                            \(topSettingsHeader)
                            \(activeCardsHTML)
                        </div>
                    </div>
                </div>
                <script>
                function typing() {
                    var a = document.activeElement;
                    return a && a.tagName === 'INPUT' && a.type !== 'checkbox';
                }
                function refresh() {
                    if (typing()) { return; }
                    fetch('/', { cache: 'no-store' })
                        .then(function (r) { return r.text(); })
                        .then(function (t) {
                            var d = new DOMParser().parseFromString(t, 'text/html');
                            var n = d.getElementById('live');
                            var l = document.getElementById('live');
                            if (n && l) { l.innerHTML = n.innerHTML; }
                            document.getElementById('conn').textContent = '● ONLINE';
                        })
                        .catch(function () {
                            document.getElementById('conn').textContent = '● OFFLINE';
                        });
                }
                function act(u) {
                    fetch(u, { cache: 'no-store' }).then(function () { setTimeout(refresh, 250); });
                }
                setInterval(refresh, 1500);
                </script>
                </body>
                </html>
                """
                
                let httpResponse = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nCache-Control: no-store\r\nContent-Length: \(htmlResponse.utf8.count)\r\nConnection: close\r\n\r\n\(htmlResponse)"
                
                connection.send(content: httpResponse.data(using: .utf8), completion: .contentProcessed({ _ in
                    connection.cancel()
                }))
            }
        }
    }
    
    func stopServer() {
        listener?.stateUpdateHandler = nil
        listener?.cancel()
        listener = nil
        isRunning = false
    }
    
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: (interface?.ifa_name)!)
                    if name == "en0" || name == "bridge0" || name == "pdp_ip0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
                ptr = ptr?.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}

private struct PatchOptionCard: View {
    let name: String
    let target: String
    let color: Color
    @Binding var isEnabled: Bool
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    Image(systemName: "bolt.fill").font(.system(size: 16, weight: .black)).foregroundStyle(color)
                    Spacer()
                    Text(isEnabled ? "ON" : "OFF")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(isEnabled ? .green : .white.opacity(0.58))
                }
                Text(name)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                Text(target)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(color)
                HStack(spacing: 7) {
                    Circle().fill(isEnabled ? Color.green : Color.white.opacity(0.25)).frame(width: 8, height: 8)
                    Text(isEnabled ? "PATCH ACTIVE" : "ACTIVATE PATCH")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 142, alignment: .leading)
            .padding(14)
            .background(Color.black.opacity(0.52), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(isEnabled ? color.opacity(0.85) : color.opacity(0.28), lineWidth: isEnabled ? 1.5 : 1))
            .shadow(color: isEnabled ? color.opacity(0.20) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .opacity(isBusy ? 0.55 : 1)
    }
}

private struct PatchUnlockPrompt: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: PatchProjectStore
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Package password", text: $password)
                        .textContentType(.password)
                }
            }
            .navigationTitle("Unlock package")
        }
    }
}

struct AnimatedHyperBackdrop: View {
    @State private var animate = false
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppTheme.pageBackground
                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .offset(x: animate ? 120 : -120, y: -proxy.size.height * 0.23)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) { animate = true }
            }
        }
    }
}


// MARK: - Background keep-alive (online audio stream + silent fallback)

final class BackgroundKeeper {
    static let shared = BackgroundKeeper()

    // 👇 Put a DIRECT audio link here (must be https and end in .mp3 / .aac / a radio stream).
    static let streamURLString = "https://PUT-YOUR-AUDIO-LINK-HERE.mp3"
    // Low volume so it is barely audible. 0.0 = mute (less reliable).
    static let streamVolume: Float = 0.05

    // Built-in soft low hum (no internet needed). Volume is very low.
    static let toneVolume: Float = 0.05

    private var tonePlayer: AVAudioPlayer?
    private var silentPlayer: AVAudioPlayer?
    private var streamPlayer: AVPlayer?
    private var observersAdded = false
    private var retryWork: DispatchWorkItem?

    func start() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }

        // 1) Local silent loop = safety net (works even if the stream fails / no internet)
        if silentPlayer == nil { silentPlayer = makeSilentPlayer() }
        silentPlayer?.numberOfLoops = -1
        if silentPlayer?.isPlaying != true { silentPlayer?.play() }

        // 2) Built-in low hum, looped (bundled keepalive.wav if present, else generated)
        if tonePlayer == nil { tonePlayer = makeTonePlayer() }
        tonePlayer?.numberOfLoops = -1
        tonePlayer?.volume = Self.toneVolume
        if tonePlayer?.isPlaying != true { tonePlayer?.play() }

        // 3) Optional online stream, looped
        startStream()

        if !observersAdded {
            observersAdded = true
            let nc = NotificationCenter.default
            nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
                let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
                if raw == AVAudioSession.InterruptionType.ended.rawValue { self?.start() }
            }
            nc.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
                self?.silentPlayer = nil
                self?.tonePlayer = nil
                self?.streamPlayer = nil
                self?.start()
            }
            nc.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { [weak self] _ in
                // loop (for finite files) / reconnect (for dropped streams)
                self?.streamPlayer?.seek(to: .zero)
                self?.streamPlayer?.play()
            }
            nc.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: nil, queue: .main) { [weak self] _ in
                self?.scheduleStreamRetry()
            }
            nc.addObserver(forName: .AVPlayerItemPlaybackStalled, object: nil, queue: .main) { [weak self] _ in
                self?.streamPlayer?.play()
            }
        }
    }

    private func startStream() {
        guard let url = URL(string: Self.streamURLString),
              url.scheme == "https",
              !Self.streamURLString.contains("PUT-YOUR-AUDIO-LINK-HERE") else { return }

        if streamPlayer == nil {
            let item = AVPlayerItem(url: url)
            let p = AVPlayer(playerItem: item)
            p.volume = Self.streamVolume
            p.automaticallyWaitsToMinimizeStalling = true
            streamPlayer = p
        }
        if streamPlayer?.timeControlStatus != .playing { streamPlayer?.play() }
    }

    private func scheduleStreamRetry() {
        retryWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.streamPlayer = nil
            self?.startStream()
        }
        retryWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
    }

    private func makeTonePlayer() -> AVAudioPlayer? {
        if let url = Bundle.main.url(forResource: "keepalive", withExtension: "wav"),
           let p = try? AVAudioPlayer(contentsOf: url) {
            return p
        }
        return try? AVAudioPlayer(data: Self.toneWAV())
    }

    private static func toneWAV() -> Data {
        var d = Data()
        let rate: UInt32 = 22050
        let seconds: UInt32 = 4
        let count = Int(rate * seconds)
        let size = UInt32(count * 2)
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
        d.append("RIFF".data(using: .ascii)!); u32(36 + size)
        d.append("WAVEfmt ".data(using: .ascii)!); u32(16)
        u16(1); u16(1); u32(rate); u32(rate * 2); u16(2); u16(16)
        d.append("data".data(using: .ascii)!); u32(size)
        for i in 0..<count {
            // 110 Hz sine, whole number of cycles -> seamless loop
            let v = Int16(0.3 * 32767.0 * sin(2.0 * Double.pi * 110.0 * Double(i) / Double(rate)))
            u16(UInt16(bitPattern: v))
        }
        return d
    }

    private func makeSilentPlayer() -> AVAudioPlayer? {
        for ext in ["wav", "mp3", "m4a"] {
            if let url = Bundle.main.url(forResource: "silent", withExtension: ext),
               let p = try? AVAudioPlayer(contentsOf: url) {
                return p
            }
        }
        return try? AVAudioPlayer(data: Self.silentWAV())
    }

    private static func silentWAV() -> Data {
        var d = Data()
        let rate: UInt32 = 8000
        let size: UInt32 = rate * 2
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
        d.append("RIFF".data(using: .ascii)!); u32(36 + size)
        d.append("WAVEfmt ".data(using: .ascii)!); u32(16)
        u16(1); u16(1); u32(rate); u32(rate * 2); u16(2); u16(16)
        d.append("data".data(using: .ascii)!); u32(size)
        d.append(Data(count: Int(size)))
        return d
    }
}
