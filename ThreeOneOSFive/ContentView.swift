import SwiftUI
import UIKit
import AVFoundation
import AVKit
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

    @AppStorage("currentPassword") private var currentPassword = "123"
    @AppStorage("keepAliveActive") private var keepAliveActive = false

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
                    backgroundKeepAlivePanel
                    patchOptions
                    gameLaunchPanel
                    footerStatus
                    developerCredits
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            
            // مشغل الفيديو الخلفي المخفي لدعم استمرار النظام
            BackgroundVideoView()
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .allowsHitTesting(false)
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
            if keepAliveActive {
                BackgroundAudioPlayer.shared.startSilentAudio()
            }
            syncPatchStates()
            startServerAutomatically()
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active, !patchOperationBusy else { return }
            syncPatchStates()
            patchMessage = "READY — SELECT A PATCH"
        }
    }

    private func setupAudioSessionForBackground() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }
    }

    private var backgroundKeepAlivePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                
                Text("BACKGROUND KEEPALIVE")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(AppTheme.accent)
                
                Spacer()
                
                Toggle("", isOn: $keepAliveActive)
                    .labelsHidden()
                    .tint(AppTheme.accent)
                    .onChange(of: keepAliveActive) { newValue in
                        if newValue {
                            BackgroundAudioPlayer.shared.startSilentAudio()
                            patchMessage = "KEEP-ALIVE ACTIVE (AUDIO & VIDEO)"
                        } else {
                            BackgroundAudioPlayer.shared.stopSilentAudio()
                            patchMessage = "KEEP-ALIVE STOPPED"
                        }
                    }
            }
            
            Text("Play silent audio and video to prevent server suspension in background.")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(16)
        .background(Color.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(AppTheme.accent.opacity(0.38), lineWidth: 1))
    }

    private func startServerAutomatically() {
        guard !isServerRunning else { return }
        
        IntegratedWebServer.shared.itemsProvider = {
            return [
                WebPatchItem(id: "Regdit", title: "⚡ REGDIT", isEnabled: self.aimDragEnabled, isLocked: self.lockRegditButton, filename: self.regditFile),
                WebPatchItem(id: "144fps", title: "⚡ 144 FPS", isEnabled: self.aimNeckEnabled, isLocked: self.lockFpsButton, filename: self.fpsFile),
                WebPatchItem(id: "plus", title: "⚡ EXTRA PATCH (+)", isEnabled: self.hspeitoffEnabled, isLocked: self.lockPlusButton, filename: self.plusFile)
            ]
        }
        
        IntegratedWebServer.shared.appPasswordProvider = { self.currentPassword }
        
        IntegratedWebServer.shared.onTogglePatch = { patchID in
            DispatchQueue.main.async {
                let isLocked: Bool
                if patchID == "Regdit" { isLocked = self.lockRegditButton }
                else if patchID == "144fps" { isLocked = self.lockFpsButton }
                else { isLocked = self.lockPlusButton }
                
                guard !isLocked else { return }
                
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
                patchCard(name: "Regdit", target: "FREE FIRE • NORMAL", package: regditFile, color: AppTheme.accent, state: $aimDragEnabled)
                patchCard(name: "144fps", target: "FREE FIRE • NORMAL", package: fpsFile, color: AppTheme.secondaryAccent, state: $aimNeckEnabled)
                patchCard(name: "+", target: "FREE FIRE • NORMAL", package: plusFile, color: AppTheme.secondaryAccent, state: $hspeitoffEnabled)
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

    private func patchCard(name: String, target: String, package: String, color: Color, state: Binding<Bool>) -> some View {
        PatchOptionCard(name: name, target: target, color: color, isEnabled: state, isBusy: patchOperationBusy) {
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

// مشغل الصوت الصامت في الخلفية
class BackgroundAudioPlayer {
    static let shared = BackgroundAudioPlayer()
    private var player: AVAudioPlayer?

    func startSilentAudio() {
        guard let url = Bundle.main.url(forResource: "silent", withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = 0.0
            player?.play()
        } catch {
            print("Audio player error: \(error)")
        }
    }

    func stopSilentAudio() {
        player?.stop()
        player = nil
    }
}

// مشغل الفيديو الصامت في الخلفية (لزيادة استقرار التطبيق في الخلفية)
struct BackgroundVideoView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        
        if let path = Bundle.main.path(forResource: "silent", ofType: "mp4") {
            let player = AVPlayer(url: URL(fileURLWithPath: path))
            player.isMuted = true
            controller.player = player
            
            // تكرار الفيديو بلا توقف
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { [weak player] _ in
                player?.seek(to: .zero)
                player?.play()
            }
            
            player.play()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

struct WebPatchItem {
    let id: String
    let title: String
    let isEnabled: Bool
    let isLocked: Bool
    let filename: String
}

private class IntegratedWebServer {
    static let shared = IntegratedWebServer()
    private var listener: NWListener?
    var onTogglePatch: ((String) -> Void)?
    var onToggleLock: ((String, Bool) -> Void)?
    var onUpdateFileName: ((String, String) -> Void)?
    var onUpdatePassword: ((String) -> Void)?
    
    var itemsProvider: (() -> [WebPatchItem])?
    var appPasswordProvider: (() -> String)?
    var isWebUnlocked = false
    
    func startServer() -> String? {
        let port: UInt16 = 8080
        guard let ip = getLocalIPAddress() else { return nil }
        let serverURL = "http://\(ip):\(port)"
        
        do {
            let parameters = NWParameters.tcp
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
            listener?.newConnectionHandler = { connection in
                self.handleConnection(connection)
            }
            listener?.start(queue: .global())
            return serverURL
        } catch {
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
                } else if requestString.contains("GET /lock?patch=") {
                    if let range = requestString.range(of: "GET /lock?patch=") {
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
                
                var activeCardsHTML = ""
                let items = self.itemsProvider?() ?? []
                
                for item in items {
                    let isChecked = item.isEnabled ? "checked" : ""
                    let isLockedChecked = item.isLocked ? "checked" : ""
                    let disabledAttr = item.isLocked ? "disabled style='opacity: 0.5; cursor: not-allowed;'" : ""
                    
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
                            <span style="font-size: 9px; font-family: 'Roboto Mono', monospace; color: rgba(255,255,255,0.7);">🔒 LOCK BUTTON:</span>
                            <label class="switch">
                                <input type="checkbox" \(isLockedChecked) onchange="location.href='/lock?patch=\(item.id)'">
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
                                <input type="checkbox" \(isChecked) \(disabledAttr) onchange="location.href='/toggle?patch=\(item.id)'">
                                <span class="slider"></span>
                            </label>
                        </div>
                        <div class="option-description">Status: \(item.isEnabled ? "ACTIVE" : "OFF") \(item.isLocked ? "| LOCKED" : "")</div>
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
                                <span class="status">● ONLINE</span>
                            </div>
                        </header>
                        <div class="menu-content">
                            \(topSettingsHeader)
                            \(activeCardsHTML)
                        </div>
                    </div>
                </div>
                </body>
                </html>
                """
                
                let httpResponse = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(htmlResponse.utf8.count)\r\nConnection: close\r\n\r\n\(htmlResponse)"
                
                connection.send(content: httpResponse.data(using: .utf8), completion: .contentProcessed({ _ in
                    connection.cancel()
                }))
            }
        }
    }
    
    func stopServer() {
        listener?.cancel()
        listener = nil
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
    @State private var animate = largeAnimateState()
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
    private static func largeAnimateState() -> Bool { false }
}
