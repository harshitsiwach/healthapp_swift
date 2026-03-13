import Foundation

// MARK: - AI Telemetry

actor AITelemetry {
    
    struct RequestLog: Codable {
        let timestamp: Date
        let backendID: String
        let task: String
        let latencyMs: Double
        let tokensIn: Int
        let tokensOut: Int
        let success: Bool
        let failureReason: String?
    }
    
    struct SessionLog: Codable {
        let startTime: Date
        var modelLoadDurationMs: Double?
        var warmupDurationMs: Double?
        var peakStorageBytes: Int64?
        var documentIndexSize: Int?
    }
    
    private var requestLogs: [RequestLog] = []
    private var currentSession: SessionLog
    
    init() {
        currentSession = SessionLog(startTime: Date())
    }
    
    func log(
        backendID: String,
        task: AITask,
        latencyMs: Double,
        tokensIn: Int,
        tokensOut: Int,
        success: Bool,
        failureReason: String? = nil
    ) {
        let entry = RequestLog(
            timestamp: Date(),
            backendID: backendID,
            task: task.rawValue,
            latencyMs: latencyMs,
            tokensIn: tokensIn,
            tokensOut: tokensOut,
            success: success,
            failureReason: failureReason
        )
        requestLogs.append(entry)
        
        // Keep only last 500 entries in memory
        if requestLogs.count > 500 {
            requestLogs = Array(requestLogs.suffix(500))
        }
    }
    
    func logModelLoad(durationMs: Double) {
        currentSession.modelLoadDurationMs = durationMs
    }
    
    func logWarmup(durationMs: Double) {
        currentSession.warmupDurationMs = durationMs
    }
    
    // MARK: - Stats
    
    func averageLatency(for task: AITask? = nil) -> Double {
        let filtered = task == nil ? requestLogs : requestLogs.filter { $0.task == task!.rawValue }
        guard !filtered.isEmpty else { return 0 }
        return filtered.map(\.latencyMs).reduce(0, +) / Double(filtered.count)
    }
    
    func successRate() -> Double {
        guard !requestLogs.isEmpty else { return 1.0 }
        let successes = requestLogs.filter(\.success).count
        return Double(successes) / Double(requestLogs.count)
    }
    
    func totalRequests() -> Int {
        requestLogs.count
    }
    
    func clearLogs() {
        requestLogs.removeAll()
        currentSession = SessionLog(startTime: Date())
    }
}
