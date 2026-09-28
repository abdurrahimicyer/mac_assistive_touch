import Foundation
import IOKit.ps

@MainActor
public final class SystemMonitorService: ObservableObject {
    public static let shared = SystemMonitorService()

    @Published public var batteryPercentage: Int? = nil
    @Published public var isCharging: Bool = false
    @Published public var cpuUsage: Double = 0.0
    @Published public var ramUsageGB: Double = 0.0

    private var timer: Timer?
    private var previousCpuInfo: host_cpu_load_info?

    private init() {
        refreshAll()
        startMonitoring()
    }

    public func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAll()
            }
        }
    }

    public func refreshAll() {
        updateBattery()
        updateCpu()
        updateRam()
    }

    // MARK: - Pil Bilgisi
    private func updateBattery() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return
        }

        for ps in sources {
            if let desc = IOPSGetPowerSourceDescription(snapshot, ps)?.takeUnretainedValue() as? [String: Any] {
                if let current = desc[kIOPSCurrentCapacityKey as String] as? Int,
                   let max = desc[kIOPSMaxCapacityKey as String] as? Int, max > 0 {
                    self.batteryPercentage = Int((Double(current) / Double(max)) * 100)
                }
                if let state = desc[kIOPSPowerSourceStateKey as String] as? String {
                    self.isCharging = (state == (kIOPSACPowerValue as String))
                }
            }
        }
    }

    // MARK: - CPU Kullanımı
    private func updateCpu() {
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        var cpuInfo = host_cpu_load_info()

        let result = withUnsafeMutablePointer(to: &cpuInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            if let prev = previousCpuInfo {
                let user = Double(cpuInfo.cpu_ticks.0 - prev.cpu_ticks.0)
                let sys = Double(cpuInfo.cpu_ticks.1 - prev.cpu_ticks.1)
                let idle = Double(cpuInfo.cpu_ticks.2 - prev.cpu_ticks.2)
                let nice = Double(cpuInfo.cpu_ticks.3 - prev.cpu_ticks.3)
                let total = user + sys + idle + nice

                if total > 0 {
                    let active = user + sys + nice
                    self.cpuUsage = min(max((active / total) * 100.0, 0.0), 100.0)
                }
            }
            previousCpuInfo = cpuInfo
        }
    }

    // MARK: - RAM Kullanımı
    private func updateRam() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let pageSize = Double(vm_kernel_page_size)
            let usedBytes = Double(stats.active_count + stats.wire_count) * pageSize
            self.ramUsageGB = usedBytes / (1024 * 1024 * 1024)
        }
    }
}
