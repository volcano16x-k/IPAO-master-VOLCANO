import SwiftUI
import UIKit
import AVFoundation
import Network

struct ContentView: View {
    @StateObject private var licenseManager = LicenseManager()

    var body: some View {
        Group {
            if licenseManager.isActive {
                MainAppView(licenseManager: licenseManager)
            } else {
                LicenseActivationView(manager: licenseManager)
            }
        }
    }
}

struct MainAppView: View {
    @ObservedObject var licenseManager: LicenseManager
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appState: AppState
    @State private var showSettings = false
    @State private var showCleaner = false
    @StateObject private var patchStore = PatchProjectStore()
    @State private var patchOperationBusy = false
    @State private var patchMessage = "READY — SELECT A PATCH"
    
    @State private var aimAssestEnabled = false
    @State private var aimFpsEnabled = false
    @State private var aimDragEnabled = false
    @State private var aimBodyEnabled = false
    @State private var magicAntenaEnabled = false
    @State private var aimNeckAntenaEnabled = false
    @State private var panelEnabled = false
    @State private var aimHeadAntenaEnabled = false
    @State private var hsPescocoEnabled = false

    @AppStorage("regditFile") private var regditFile = "VOLCANO File (6).3105"
    @AppStorage("fpsFile") private var fpsFile = "VOLCANO File (7).3105"
    @AppStorage("plusFile") private var plusFile = "VOLCANO File (8).3105"
    @AppStorage("aimBodyFile") private var aimBodyFile = "VOLCANO File (9).3105"
    @AppStorage("magicAntenaFile") private var magicAntenaFile = "VOLCANO File (10).3105"
    @AppStorage("aimNeckAntenaFile") private var aimNeckAntenaFile = "VOLCANO File (11).3105"
    @AppStorage("panelFile") private var panelFile = "VOLCANO File (12).3105"
    @AppStorage("aimHeadAntenaFile") private var aimHeadAntenaFile = "VOLCANO File (13).3105"
    @AppStorage("hsPescocoFile") private var hsPescocoFile = "VOLCANO File (14).3105"

    @AppStorage("lockRegditButton") private var lockRegditButton = false
    @AppStorage("lockFpsButton") private var lockFpsButton = false
    @AppStorage("lockPlusButton") private var lockPlusButton = false
    @AppStorage("lockAimBodyButton") private var lockAimBodyButton = false
    @AppStorage("lockMagicAntenaButton") private var lockMagicAntenaButton = false
    @AppStorage("lockAimNeckAntenaButton") private var lockAimNeckAntenaButton = false
    @AppStorage("lockPanelButton") private var lockPanelButton = false
    @AppStorage("lockAimHeadAntenaButton") private var lockAimHeadAntenaButton = false
    @AppStorage("lockHsPescocoButton") private var lockHsPescocoButton = false

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
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showCleaner) { CleanerView() }
        .sheet(item: $patchStore.passwordRequest, onDismiss: patchStore.cancelUnlock) { _ in
            PatchUnlockPrompt(store: patchStore)
        }
        .onAppear {
            setupAudioSessionForBackground()
            syncPatchStates()
        }
    }

    private func setupAudioSessionForBackground() {
        BackgroundKeeper.shared.start()
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
                licenseManager.deactivate()
            } label: {
                Image(systemName: "lock.slash.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.red)
                    .frame(width: 48, height: 48)
                    .background(Color.black.opacity(0.38), in: Circle())
                    .overlay(Circle().stroke(Color.red.opacity(0.42), lineWidth: 1))
            }
            .buttonStyle(.plain)

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
                Text("SERVER")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(AppTheme.accent)
                Spacer()
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

    private var footerStatus: some View {
        HStack(spacing: 10) {
            Circle().fill(.green).frame(width: 9, height: 9)
            Text("SYSTEM READY").font(.system(size: 10, weight: .black, design: .rounded)).foregroundStyle(.white.opacity(0.72))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color.black.opacity(0.45), in: Capsule())
    }

    private var developerCredits: some View {
        VStack(spacing: 10) {
            Text("Developed by VOLCANO").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.72))
        }
    }

    private func panelTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon).font(.system(size: 12, weight: .black, design: .rounded)).foregroundStyle(AppTheme.accent)
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

    private enum PatchActionResult { case applied, restored, unavailable(String) }

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
        guard !patchOperationBusy else { return }
        guard let item = patchStore.items.first(where: { $0.packageURL.lastPathComponent.caseInsensitiveCompare(packageFilename) == .orderedSame }) else { return }

        let wasEnabled = state.wrappedValue
        patchOperationBusy = true
        let project = item.project
        let projectID = item.id

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if wasEnabled {
                    if let receipt = DevicePatchService.latestReceipt(projectID: projectID) {
                        try DevicePatchService.restore(receipt: receipt)
                    }
                } else {
                    if let project = project {
                        _ = try DevicePatchService.apply(project: project)
                    }
                }
            } catch {}

            DispatchQueue.main.async {
                self.syncPatchStates()
                self.patchOperationBusy = false
            }
        }
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
                    Text(isEnabled ? "ON" : "OFF").font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(isEnabled ? .green : .white.opacity(0.58))
                }
                Text(name).font(.system(size: 15, weight: .black, design: .rounded)).foregroundStyle(.white).lineLimit(2)
                Text(target).font(.system(size: 10, weight: .black, design: .rounded)).foregroundStyle(color)
            }
            .frame(maxWidth: .infinity, minHeight: 142, alignment: .leading)
            .padding(14)
            .background(Color.black.opacity(0.52), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(isEnabled ? color.opacity(0.85) : color.opacity(0.28), lineWidth: isEnabled ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .opacity(isBusy ? 0.55 : 1)
    }
}

private struct PatchUnlockPrompt: View {
    @ObservedObject var store: PatchProjectStore
    @State private var password = ""
    var body: some View {
        NavigationStack {
            Form { Section { SecureField("Package password", text: $password).textContentType(.password) } }
                .navigationTitle("Unlock package")
        }
    }
}

struct AnimatedHyperBackdrop: View {
    var body: some View {
        ZStack {
            AppTheme.pageBackground
        }
    }
}

final class BackgroundKeeper {
    static let shared = BackgroundKeeper()
    func start() {}
}
