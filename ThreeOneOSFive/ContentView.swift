import SwiftUI
import UIKit
import AVFoundation
import Network

struct ContentView: View {
    @StateObject private var manager = LicenseManager()
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appState: AppState
    @State private var showSettings = false
    @State private var showCleaner = false
    @StateObject private var patchStore = PatchProjectStore()
    @State private var patchOperationBusy = false
    @State private var patchMessage = "READY — SELECT A PATCH"
    
    // حالات الأزرار
    @State private var aimAssestEnabled = false
    @State private var aimFpsEnabled = false
    @State private var aimDragEnabled = false
    @State private var aimBodyEnabled = false
    @State private var magicAntenaEnabled = false
    @State private var aimNeckAntenaEnabled = false
    @State private var panelEnabled = false
    @State private var aimHeadAntenaEnabled = false
    @State private var hsPescocoEnabled = false

    // ملفات الباتشات
    @AppStorage("regditFile") private var regditFile = "VOLCANO File (6).3105"
    @AppStorage("fpsFile") private var fpsFile = "VOLCANO File (7).3105"
    @AppStorage("plusFile") private var plusFile = "VOLCANO File (8).3105"
    @AppStorage("aimBodyFile") private var aimBodyFile = "VOLCANO File (9).3105"
    @AppStorage("magicAntenaFile") private var magicAntenaFile = "VOLCANO File (10).3105"
    @AppStorage("aimNeckAntenaFile") private var aimNeckAntenaFile = "VOLCANO File (11).3105"
    @AppStorage("panelFile") private var panelFile = "VOLCANO File (12).3105"
    @AppStorage("aimHeadAntenaFile") private var aimHeadAntenaFile = "VOLCANO File (13).3105"
    @AppStorage("hsPescocoFile") private var hsPescocoFile = "VOLCANO File (14).3105"

    // حالات القفل للأزرار
    @AppStorage("lockRegditButton") private var lockRegditButton = false
    @AppStorage("lockFpsButton") private var lockFpsButton = false
    @AppStorage("lockPlusButton") private var lockPlusButton = false
    @AppStorage("lockAimBodyButton") private var lockAimBodyButton = false
    @AppStorage("lockMagicAntenaButton") private var lockMagicAntenaButton = false
    @AppStorage("lockAimNeckAntenaButton") private var lockAimNeckAntenaButton = false
    @AppStorage("lockPanelButton") private var lockPanelButton = false
    @AppStorage("lockAimHeadAntenaButton") private var lockAimHeadAntenaButton = false
    @AppStorage("lockHsPescocoButton") private var lockHsPescocoButton = false

    // حالات الإخفاء للأزرار
    @AppStorage("hideRegditButton") private var hideRegditButton = false
    @AppStorage("hideFpsButton") private var hideFpsButton = false
    @AppStorage("hidePlusButton") private var hidePlusButton = false
    @AppStorage("hideAimBodyButton") private var hideAimBodyButton = false
    @AppStorage("hideMagicAntenaButton") private var hideMagicAntenaButton = false
    @AppStorage("hideAimNeckAntenaButton") private var hideAimNeckAntenaButton = false
    @AppStorage("hidePanelButton") private var hidePanelButton = false
    @AppStorage("hideAimHeadAntenaButton") private var hideAimHeadAntenaButton = false
    @AppStorage("hideHsPescocoButton") private var hideHsPescocoButton = false

    @AppStorage("currentPassword") private var currentPassword = "123"

    @State private var serverURL: String? = nil
    @State private var isServerRunning = false
    @State private var showServerDetails = false

    var body: some View {
        ZStack {
            AnimatedHyperBackdrop()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // واجهة التحقق وChatGPT العلوية الثابتة والمدمجة بالكامل
                EmbeddedLicenseActivationHeader(manager: manager)
                    .frame(height: 220)

                // واجهة المحتوى الأصلية الخاصة بك
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
            if manager.isActive {
                startServerAutomatically()
            }
        }
        .onChange(of: manager.isActive) { active in
            if active {
                startServerAutomatically()
            }
        }
        .onChange(of: scenePhase) { phase in
            BackgroundKeeper.shared.start()
            if manager.isActive && !IntegratedWebServer.shared.isRunning {
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
        guard manager.isActive, !IntegratedWebServer.shared.isRunning else { return }
        
        IntegratedWebServer.shared.itemsProvider = {
            return [
                WebPatchItem(id: "Regdit", title: "🎯 AIM ASSEST", isEnabled: self.aimAssestEnabled, isLocked: self.lockRegditButton, filename: self.regditFile, isHidden: self.hideRegditButton),
                WebPatchItem(id: "144fps", title: "🚀 144 FPS", isEnabled: self.aimFpsEnabled, isLocked: self.lockFpsButton, filename: self.fpsFile, isHidden: self.hideFpsButton),
                WebPatchItem(id: "plus", title: "⚡ AIM DRAG", isEnabled: self.aimDragEnabled, isLocked: self.lockPlusButton, filename: self.plusFile, isHidden: self.hidePlusButton),
                WebPatchItem(id: "aimBody", title: "💀 AIM BODY", isEnabled: self.aimBodyEnabled, isLocked: self.lockAimBodyButton, filename: self.aimBodyFile, isHidden: self.hideAimBodyButton),
                WebPatchItem(id: "magicAntena", title: "📡 MAGIC + ANTENA", isEnabled: self.magicAntenaEnabled, isLocked: self.lockMagicAntenaButton, filename: self.magicAntenaFile, isHidden: self.hideMagicAntenaButton),
                WebPatchItem(id: "aimNeckAntena", title: "🦴 AIM NECK + ANTENA", isEnabled: self.aimNeckAntenaEnabled, isLocked: self.lockAimNeckAntenaButton, filename: self.aimNeckAntenaFile, isHidden: self.hideAimNeckAntenaButton),
                WebPatchItem(id: "panel", title: "⚙️ PANEL", isEnabled: self.panelEnabled, isLocked: self.lockPanelButton, filename: self.panelFile, isHidden: self.hidePanelButton),
                WebPatchItem(id: "aimHeadAntena", title: "👤 AIM HEAD + ANTENA", isEnabled: self.aimHeadAntenaEnabled, isLocked: self.lockAimHeadAntenaButton, filename: self.aimHeadAntenaFile, isHidden: self.hideAimHeadAntenaButton),
                WebPatchItem(id: "hsPescoco", title: "🔥 HS PESCOÇO", isEnabled: self.hsPescocoEnabled, isLocked: self.lockHsPescocoButton, filename: self.hsPescocoFile, isHidden: self.hideHsPescocoButton)
            ]
        }
        
        IntegratedWebServer.shared.statusProvider = { (self.patchOperationBusy, self.patchMessage) }
        IntegratedWebServer.shared.appPasswordProvider = { self.currentPassword }
        
        IntegratedWebServer.shared.onTogglePatch = { patchID in
            DispatchQueue.main.async {
                let isLocked: Bool
                let isHiddenNow: Bool
                let filename: String
                let bindingState: Binding<Bool>
                
                switch patchID {
                case "Regdit": isLocked = self.lockRegditButton; isHiddenNow = self.hideRegditButton; filename = self.regditFile; bindingState = self.$aimAssestEnabled
                case "144fps": isLocked = self.lockFpsButton; isHiddenNow = self.hideFpsButton; filename = self.fpsFile; bindingState = self.$aimFpsEnabled
                case "plus": isLocked = self.lockPlusButton; isHiddenNow = self.hidePlusButton; filename = self.plusFile; bindingState = self.$aimDragEnabled
                case "aimBody": isLocked = self.lockAimBodyButton; isHiddenNow = self.hideAimBodyButton; filename = self.aimBodyFile; bindingState = self.$aimBodyEnabled
                case "magicAntena": isLocked = self.lockMagicAntenaButton; isHiddenNow = self.hideMagicAntenaButton; filename = self.magicAntenaFile; bindingState = self.$magicAntenaEnabled
                case "aimNeckAntena": isLocked = self.lockAimNeckAntenaButton; isHiddenNow = self.hideAimNeckAntenaButton; filename = self.aimNeckAntenaFile; bindingState = self.$aimNeckAntenaEnabled
                case "panel": isLocked = self.lockPanelButton; isHiddenNow = self.hidePanelButton; filename = self.panelFile; bindingState = self.$panelEnabled
                case "aimHeadAntena": isLocked = self.lockAimHeadAntenaButton; isHiddenNow = self.hideAimHeadAntenaButton; filename = self.aimHeadAntenaFile; bindingState = self.$aimHeadAntenaEnabled
                case "hsPescoco": isLocked = self.lockHsPescocoButton; isHiddenNow = self.hideHsPescocoButton; filename = self.hsPescocoFile; bindingState = self.$hsPescocoEnabled
                default: return
                }
                
                guard !isLocked, !isHiddenNow else { return }
                self.togglePatch(packageFilename: filename, state: bindingState)
            }
        }
        
        IntegratedWebServer.shared.onToggleLock = { patchID, isLocked in
            DispatchQueue.main.async {
                if patchID == "Regdit" { self.lockRegditButton = isLocked }
                else if patchID == "144fps" { self.lockFpsButton = isLocked }
                else if patchID == "plus" { self.lockPlusButton = isLocked }
                else if patchID == "aimBody" { self.lockAimBodyButton = isLocked }
                else if patchID == "magicAntena" { self.lockMagicAntenaButton = isLocked }
                else if patchID == "aimNeckAntena" { self.lockAimNeckAntenaButton = isLocked }
                else if patchID == "panel" { self.lockPanelButton = isLocked }
                else if patchID == "aimHeadAntena" { self.lockAimHeadAntenaButton = isLocked }
                else if patchID == "hsPescoco" { self.lockHsPescocoButton = isLocked }
            }
        }
        
        IntegratedWebServer.shared.onToggleHide = { patchID, hidden in
            DispatchQueue.main.async {
                if patchID == "Regdit" { self.hideRegditButton = hidden }
                else if patchID == "144fps" { self.hideFpsButton = hidden }
                else if patchID == "plus" { self.hidePlusButton = hidden }
                else if patchID == "aimBody" { self.hideAimBodyButton = hidden }
                else if patchID == "magicAntena" { self.hideMagicAntenaButton = hidden }
                else if patchID == "aimNeckAntena" { self.hideAimNeckAntenaButton = hidden }
                else if patchID == "panel" { self.hidePanelButton = hidden }
                else if patchID == "aimHeadAntena" { self.hideAimHeadAntenaButton = hidden }
                else if patchID == "hsPescoco" { self.hideHsPescocoButton = hidden }
            }
        }
        
        IntegratedWebServer.shared.onUpdateFileName = { patchID, newFilename in
            DispatchQueue.main.async {
                if patchID == "Regdit" { self.regditFile = newFilename }
                else if patchID == "144fps" { self.fpsFile = newFilename }
                else if patchID == "plus" { self.plusFile = newFilename }
                else if patchID == "aimBody" { self.aimBodyFile = newFilename }
                else if patchID == "magicAntena" { self.magicAntenaFile = newFilename }
                else if patchID == "aimNeckAntena" { self.aimNeckAntenaFile = newFilename }
                else if patchID == "panel" { self.panelFile = newFilename }
                else if patchID == "aimHeadAntena" { self.aimHeadAntenaFile = newFilename }
                else if patchID == "hsPescoco" { self.hsPescocoFile = newFilename }
            }
        }
        
        IntegratedWebServer.shared.onUpdatePassword = { newPass in
            DispatchQueue.main.async { self.currentPassword = newPass }
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

            Button { showSettings = true } label: {
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
                
                Circle().fill(isServerRunning ? Color.green : Color.red).frame(width: 8, height: 8)
                
                Text("SERVER (WebDAV)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(AppTheme.accent)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showServerDetails.toggle() }
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
                if !hideRegditButton { patchCard(name: "AIM ASSEST", target: "FREE FIRE • NORMAL", package: regditFile, color: AppTheme.accent, state: $aimAssestEnabled, locked: lockRegditButton) }
                if !hideFpsButton { patchCard(name: "144fps", target: "FREE FIRE • NORMAL", package: fpsFile, color: AppTheme.secondaryAccent, state: $aimFpsEnabled, locked: lockFpsButton) }
                if !hidePlusButton { patchCard(name: "AIM DRAG", target: "FREE FIRE • NORMAL", package: plusFile, color: AppTheme.secondaryAccent, state: $aimDragEnabled, locked: lockPlusButton) }
                if !hideAimBodyButton { patchCard(name: "AIM BODY", target: "FREE FIRE • NORMAL", package: aimBodyFile, color: AppTheme.accent, state: $aimBodyEnabled, locked: lockAimBodyButton) }
                if !hideMagicAntenaButton { patchCard(name: "MAGIC + ANTENA", target: "FREE FIRE • NORMAL", package: magicAntenaFile, color: AppTheme.secondaryAccent, state: $magicAntenaEnabled, locked: lockMagicAntenaButton) }
                if !hideAimNeckAntenaButton { patchCard(name: "AIM NECK + ANTENA", target: "FREE FIRE • NORMAL", package: aimNeckAntenaFile, color: AppTheme.accent, state: $aimNeckAntenaEnabled, locked: lockAimNeckAntenaButton) }
                if !hidePanelButton { patchCard(name: "PANEL", target: "FREE FIRE • NORMAL", package: panelFile, color: AppTheme.accent, state: $panelEnabled, locked: lockPanelButton) }
                if !hideAimHeadAntenaButton { patchCard(name: "AIM HEAD + ANTENA", target: "FREE FIRE • NORMAL", package: aimHeadAntenaFile, color: AppTheme.secondaryAccent, state: $aimHeadAntenaEnabled, locked: lockAimHeadAntenaButton) }
                if !hideHsPescocoButton { patchCard(name: "HS PESCOÇO", target: "FREE FIRE • NORMAL", package: hsPescocoFile, color: AppTheme.secondaryAccent, state: $hsPescocoEnabled, locked: lockHsPescocoButton) }
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
            Button { showCleaner = true } label: {
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
            Circle().fill(manager.isActive ? .green : .orange).frame(width: 9, height: 9).shadow(color: manager.isActive ? .green : .orange, radius: 6)
            Text(manager.isActive ? "SYSTEM ACTIVE & PROTECTED" : "WAITING FOR LICENSE KEY")
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
        aimAssestEnabled = isPatchActive(regditFile)
        aimFpsEnabled = isPatchActive(fpsFile)
        aimDragEnabled = isPatchActive(plusFile)
        aimBodyEnabled = isPatchActive(aimBodyFile)
        magicAntenaEnabled = isPatchActive(magicAntenaFile)
        aimNeckAntenaEnabled = isPatchActive(aimNeckAntenaFile)
        panelEnabled = isPatchActive(panelFile)
        aimHeadAntenaEnabled = isPatchActive(aimHeadAntenaFile)
        hsPescocoEnabled = isPatchActive(hsPescocoFile)
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
        if packageFilename.caseInsensitiveCompare(regditFile) == .orderedSame { aimAssestEnabled = enabled }
        else if packageFilename.caseInsensitiveCompare(fpsFile) == .orderedSame { aimFpsEnabled = enabled }
        else if packageFilename.caseInsensitiveCompare(plusFile) == .orderedSame { aimDragEnabled = enabled }
        else if packageFilename.caseInsensitiveCompare(aimBodyFile) == .orderedSame { aimBodyEnabled = enabled }
        else if packageFilename.caseInsensitiveCompare(magicAntenaFile) == .orderedSame { magicAntenaEnabled = enabled }
        else if packageFilename.caseInsensitiveCompare(aimNeckAntenaFile) == .orderedSame { aimNeckAntenaEnabled = enabled }
        else if packageFilename.caseInsensitiveCompare(panelFile) == .orderedSame { panelEnabled = enabled }
        else if packageFilename.caseInsensitiveCompare(aimHeadAntenaFile) == .orderedSame { aimHeadAntenaEnabled = enabled }
        else if packageFilename.caseInsensitiveCompare(hsPescocoFile) == .orderedSame { hsPescocoEnabled = enabled }
    }

    private func togglePatch(packageFilename: String, state: Binding<Bool>) {
        guard !patchOperationBusy, manager.isActive else {
            patchMessage = "LICENSE ACTIVATION REQUIRED"
            return
        }
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

// MARK: - Embedded License Activation Header (ChatGPT Interface)
struct EmbeddedLicenseActivationHeader: View {
    @ObservedObject var manager: LicenseManager

    @State private var key = ""
    @State private var keyStatus: ActivationKeyStatus = .empty
    @State private var statusMessage = ""
    @FocusState private var isFocused: Bool

    enum ActivationKeyStatus {
        case empty
        case invalid
        case valid
    }

    private let blue = Color(red: 0.10, green: 0.56, blue: 1.0)
    private let chipFill = Color(white: 0.105)
    private let strokeColor = Color.white.opacity(0.08)
    private let textGray = Color(white: 0.78)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer(minLength: 0)

                suggestions

                Spacer(minLength: 0)

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(keyStatus == .valid ? .green : .red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 6)
                }

                inputBar
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.18), value: isFocused)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button { resetState() } label: {
                MenuTwoLinesShape()
                    .stroke(.white, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                    .frame(width: 20, height: 14)
                    .frame(width: 42, height: 42)
                    .background(chipFill, in: Circle())
                    .overlay(Circle().stroke(strokeColor, lineWidth: 1))
            }

            Button {} label: {
                HStack(spacing: 8) {
                    FourPointStarShape()
                        .fill(blue)
                        .frame(width: 22, height: 22)
                    Text("Mettre à niveau")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(blue)
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(chipFill, in: Capsule())
                .overlay(Capsule().stroke(strokeColor, lineWidth: 1))
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(chipFill)
                    .frame(width: 42, height: 42)
                    .overlay(Circle().stroke(strokeColor, lineWidth: 1))

                switch keyStatus {
                case .empty:
                    Circle()
                        .stroke(.white.opacity(0.4), lineWidth: 2)
                        .frame(width: 20, height: 20)
                case .invalid:
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.red)
                case .valid:
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 1).frame(width: 14, height: 2)
                        RoundedRectangle(cornerRadius: 1).frame(width: 14, height: 2)
                    }
                    .foregroundStyle(.green)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 18) {
            suggestionRow(title: "Créer une image ou un sticker") {
                Image(systemName: "photo").font(.system(size: 16)).foregroundStyle(textGray)
            }
            suggestionRow(title: "Écrire ou modifier") {
                PencilShape().stroke(textGray, lineWidth: 1.6).frame(width: 18, height: 18)
            }
            suggestionRow(title: "Rechercher sur le Web") {
                GlobeShape().stroke(textGray, lineWidth: 1.5).frame(width: 18, height: 18)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 35)
    }

    private func suggestionRow<Icon: View>(title: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 16) {
            icon().frame(width: 22, height: 22)
            Text(title).font(.system(size: 15)).foregroundStyle(textGray)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            Button {} label: {
                Image(systemName: "plus").font(.system(size: 18)).foregroundStyle(.white)
            }

            TextField("Demander à ChatGPT", text: $key)
                .focused($isFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .submitLabel(.send)
                .onSubmit { handleKeyInput() }

            if key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {} label: {
                    Image(systemName: "mic").font(.system(size: 17)).foregroundStyle(.white)
                }
            } else {
                Button { handleKeyInput() } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(blue, in: Circle())
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(chipFill, in: Capsule())
        .overlay(Capsule().stroke(strokeColor, lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func resetState() {
        key = ""
        keyStatus = .empty
        statusMessage = ""
    }

    private func handleKeyInput() {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        manager.activate(key: trimmed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if manager.isActive {
                keyStatus = .valid
                statusMessage = manager.message ?? "تم تفعيل المفتاح وتعمل الخلفية بصمت."
            } else {
                keyStatus = .invalid
                statusMessage = manager.message ?? "المفتاح غير صالح."
            }
        }
        key = ""
    }
}

// الأشكال المساعدة
struct MenuTwoLinesShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY - 4))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY - 4))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY + 4))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + 4))
        return path
    }
}

struct FourPointStarShape: Shape {
    func path(in rect: CGRect) -> Path { return Path() }
}
struct PencilShape: Shape {
    func path(in rect: CGRect) -> Path { return Path() }
}
struct GlobeShape: Shape {
    func path(in rect: CGRect) -> Path { return Path() }
}

// باقي المساعدات
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
            l.stateUpdateHandler = { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .ready:
                    self.isRunning = true
                    self.retryCount = 0
                case .failed, .cancelled:
                    self.isRunning = false
                default: break
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
    
    func stopServer() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }
    
    private func getLocalIPAddress() -> String? { return "localhost" }
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
                Text(name).font(.system(size: 15, weight: .black, design: .rounded)).foregroundStyle(.white)
                Text(target).font(.system(size: 10, weight: .black, design: .rounded)).foregroundStyle(color)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .padding(14)
            .background(Color.black.opacity(0.52), in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
    }
}

private struct PatchUnlockPrompt: View {
    @ObservedObject var store: PatchProjectStore
    var body: some View { Text("Unlock") }
}

struct AnimatedHyperBackdrop: View {
    var body: some View { Color.black }
}

final class BackgroundKeeper {
    static let shared = BackgroundKeeper()
    func start() {}
}
