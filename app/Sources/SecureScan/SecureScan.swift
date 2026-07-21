// SecureScan.app — natywny frontend SwiftUI dla silnika secure-scan.
// Silnik (secure-scan.sh + lib/) jest w Contents/Resources/engine i wywoływany z --json.
import SwiftUI
import AppKit

// MARK: - Model danych (zgodny z JSON silnika)

struct Report: Codable {
    let version: String
    let score: Int
    let grade: String
    let pass, warn, fail, info: Int
    let model, os: String
    let checks: [Check]
}

struct Check: Codable, Identifiable, Hashable {
    let category, name, status, detail: String
    let weight: Int
    var id: String { category + "/" + name }
}

// MARK: - Uruchamianie silnika

enum Engine {
    static var scriptPath: String {
        (Bundle.main.resourceURL ?? URL(fileURLWithPath: "."))
            .appendingPathComponent("engine/secure-scan.sh").path
    }

    /// Uruchamia silnik przez /bin/bash i zwraca (stdout, kod wyjścia).
    static func run(args: [String], env: [String: String] = [:]) -> (out: String, code: Int32) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/bash")
        p.arguments = [scriptPath] + args
        var e = ProcessInfo.processInfo.environment
        env.forEach { e[$0] = $1 }
        p.environment = e
        let outPipe = Pipe(); p.standardOutput = outPipe; p.standardError = Pipe()
        do { try p.run() } catch { return ("", -1) }
        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (String(data: data, encoding: .utf8) ?? "", p.terminationStatus)
    }
}

// MARK: - ViewModel

@MainActor
final class ScanModel: ObservableObject {
    @Published var report: Report?
    @Published var scanning = false
    @Published var busyLabel = ""
    @Published var lastError: String?
    @Published var lang: String = UserDefaults.standard.string(forKey: "lang") ?? "pl" {
        didSet { UserDefaults.standard.set(lang, forKey: "lang") }
    }

    func t(_ pl: String, _ en: String) -> String { lang == "en" ? en : pl }

    func scan() {
        guard !scanning else { return }
        scanning = true; lastError = nil; busyLabel = t("Skanowanie…", "Scanning…")
        let lang = self.lang
        Task.detached(priority: .userInitiated) {
            let r = Engine.run(args: ["--json", "--lang", lang])
            await MainActor.run {
                self.scanning = false; self.busyLabel = ""
                guard let data = r.out.data(using: .utf8),
                      let rep = try? JSONDecoder().decode(Report.self, from: data) else {
                    self.lastError = self.t("Nie udało się odczytać wyniku skanu.",
                                            "Failed to read scan result.")
                    return
                }
                withAnimation { self.report = rep }
            }
        }
    }

    func fix() {
        guard !scanning else { return }
        scanning = true; busyLabel = t("Utwardzanie (wymaga hasła)…", "Hardening (needs password)…")
        let script = Engine.scriptPath
        let tmp = NSTemporaryDirectory()
        Task.detached(priority: .userInitiated) {
            // Natywny monit administratora macOS; zapis raportu do tmp (bundle jest RO)
            let shell = "SECURE_SCAN_OUT='\(tmp)' '\(script)' --fix --yes --no-open --no-notify"
            let cmd = "do shell script \"\(shell)\" with administrator privileges"
            let osa = Process()
            osa.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            osa.arguments = ["-e", cmd]
            try? osa.run(); osa.waitUntilExit()
            await MainActor.run { self.scanning = false; self.busyLabel = ""; self.scan() }
        }
    }

    func openFullReport() {
        let tmp = NSTemporaryDirectory()
        _ = Engine.run(args: ["--no-open", "--no-notify", "--lang", lang],
                       env: ["SECURE_SCAN_OUT": tmp])
        let url = URL(fileURLWithPath: tmp).appendingPathComponent("security-dashboard.html")
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Kolory / pomocnicze

func scoreColor(_ s: Int) -> Color {
    switch s { case 90...: return .green; case 75..<90: return Color(red:0.52,green:0.8,blue:0.09)
               case 60..<75: return .orange; default: return .red }
}
func statusColor(_ s: String) -> Color {
    switch s { case "PASS": return .green; case "WARN": return .orange
               case "FAIL": return .red; default: return .blue }
}
func statusSymbol(_ s: String) -> String {
    switch s { case "PASS": return "checkmark.circle.fill"; case "WARN": return "exclamationmark.triangle.fill"
               case "FAIL": return "xmark.octagon.fill"; default: return "info.circle.fill" }
}

// MARK: - Widoki

struct GaugeView: View {
    let score: Int
    var body: some View {
        ZStack {
            Circle().stroke(Color.secondary.opacity(0.18), lineWidth: 11)
            Circle().trim(from: 0, to: CGFloat(score) / 100)
                .stroke(scoreColor(score), style: StrokeStyle(lineWidth: 11, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: score)
            VStack(spacing: 0) {
                Text("\(score)").font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor(score))
                Text("/100").font(.caption2).foregroundStyle(.secondary)
            }
        }.frame(width: 104, height: 104)
    }
}

struct StatPill: View {
    let n: Int; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 1) {
            Text("\(n)").font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }.frame(minWidth: 44)
    }
}

struct CheckRow: View {
    let check: Check
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: statusSymbol(check.status))
                .foregroundStyle(statusColor(check.status)).font(.callout).frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(check.name).font(.callout.weight(.medium))
                Text(check.detail).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }.padding(.vertical, 3)
    }
}

struct DashboardView: View {
    @EnvironmentObject var model: ScanModel

    var categories: [String] {
        guard let checks = model.report?.checks else { return [] }
        var seen = Set<String>(), order = [String]()
        for c in checks where !seen.contains(c.category) { seen.insert(c.category); order.append(c.category) }
        return order
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if let rep = model.report {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(categories, id: \.self) { cat in
                            let items = rep.checks.filter { $0.category == cat }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cat.uppercased()).font(.caption2.bold())
                                    .foregroundStyle(.secondary).padding(.top, 4)
                                ForEach(items) { CheckRow(check: $0) }
                            }
                        }
                    }.padding(12)
                }
            } else {
                VStack(spacing: 8) {
                    if model.scanning { ProgressView() }
                    Text(model.lastError ?? model.t("Uruchamiam skan…", "Starting scan…"))
                        .font(.callout).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, minHeight: 180)
            }
            Divider()
            footer
        }
        .frame(width: 380, height: 560)
        .onAppear { if model.report == nil { model.scan() } }
    }

    var header: some View {
        HStack(spacing: 14) {
            GaugeView(score: model.report?.score ?? 0)
            VStack(alignment: .leading, spacing: 6) {
                Text("secure-scan").font(.headline)
                if let r = model.report {
                    Text(r.grade).font(.subheadline.bold()).foregroundStyle(scoreColor(r.score))
                    HStack(spacing: 12) {
                        StatPill(n: r.pass, label: "OK", color: .green)
                        StatPill(n: r.warn, label: model.t("Uwaga","Warn"), color: .orange)
                        StatPill(n: r.fail, label: model.t("Błąd","Fail"), color: .red)
                        StatPill(n: r.info, label: "Info", color: .blue)
                    }
                    Text("\(r.model) · macOS \(r.os)").font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }.padding(12)
    }

    var footer: some View {
        HStack(spacing: 8) {
            Button { model.scan() } label: {
                Label(model.t("Skanuj","Scan"), systemImage: "arrow.clockwise")
            }.disabled(model.scanning)

            Button { model.fix() } label: {
                Label(model.t("Napraw","Fix"), systemImage: "wrench.and.screwdriver.fill")
            }.disabled(model.scanning).tint(.orange)

            Button { model.openFullReport() } label: {
                Label(model.t("Raport","Report"), systemImage: "doc.text")
            }.disabled(model.scanning)

            Spacer()
            Picker("", selection: $model.lang) {
                Text("PL").tag("pl"); Text("EN").tag("en")
            }.pickerStyle(.segmented).frame(width: 88).onChange(of: model.lang) { model.scan() }

            Button { NSApplication.shared.terminate(nil) } label: {
                Image(systemName: "power")
            }.help(model.t("Zakończ","Quit"))
        }
        .padding(8)
        .overlay(alignment: .top) {
            if model.scanning && !model.busyLabel.isEmpty {
                Text(model.busyLabel).font(.caption2).foregroundStyle(.secondary)
                    .padding(.top, -14)
            }
        }
    }
}

// MARK: - App

@main
struct SecureScanApp: App {
    @StateObject private var model = ScanModel()
    var body: some Scene {
        MenuBarExtra {
            DashboardView().environmentObject(model)
        } label: {
            Text(model.report.map { "🛡 \($0.score)" } ?? "🛡")
        }
        .menuBarExtraStyle(.window)
    }
}
