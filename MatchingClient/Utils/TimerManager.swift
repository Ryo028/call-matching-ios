import Foundation
import Combine

/// タイマー管理クラス
class TimerManager: ObservableObject {
    @Published var remainingTime: Int = 10
    @Published var timerProgress: Double = 1.0
    @Published var count: Double = 0.0
    @Published var countText: String = ""
    @Published var isTimeout = false
    @Published var isReservationTime = false
    
    private var timerCancellable: AnyCancellable?
    private var startTime = Date()
    private let totalTime: Double = 10.0
    private let interval: Double = 1.0
    private var lastCountUp: Double = 0.0
    private var reservationTimeThreshold: Double = 0.0
    private var isCountDown: Bool = true
    
    /// タイマーを開始
    /// - Parameter onComplete: タイマー完了時のコールバック
    func startTimer(onComplete: @escaping () -> Void) {
        // すでにタイマーが動作中の場合は何もしない
        guard timerCancellable == nil else {
            print("Timer is already running, skipping start")
            return
        }
        
        // 既存のタイマーをキャンセル
        stopTimer()
        
        // 初期値をリセット
        remainingTime = 10
        timerProgress = 1.0
        startTime = Date()
        
        
        // タイマーを開始
        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                let elapsed = Date().timeIntervalSince(self.startTime)
                let remaining = self.totalTime - elapsed
                
                // 更新
                self.remainingTime = max(0, Int(ceil(remaining)))
                self.timerProgress = max(0, remaining / self.totalTime)
                
                // 終了チェック
                if remaining <= 0 {
                    self.stopTimer()
                    onComplete()
                }
            }
    }
    
    /// CallView.swift互換のタイマー開始メソッド
    func start(
        minutes: Double = 0.0,
        seconds: Double = 0.0,
        reservationTime: Double = 0.0,
        isFormatSeconds: Bool = false,
        isCountDown: Bool = true
    ) {
        print("timer start isCountDown:\(isCountDown)")
        // TimerPublisherが存在しているときは念の為処理をキャンセル
        timerCancellable?.cancel()
        
        isTimeout = false
        isReservationTime = false
        self.isCountDown = isCountDown
        self.reservationTimeThreshold = reservationTime

        count = (minutes * 60.0) + seconds
        if isFormatSeconds {
            countText = "\(Int(count))"
        } else {
            countText = String(format: "%02d:%02d", Int(minutes), 0)
        }
        
        timerCancellable = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if isCountDown {
                    self.count -= self.interval
                    if self.count < self.interval {
                        self.stop()
                        print("timer isTimeout true")
                        // タイムアウトを通知
                        self.isTimeout = true
                        // isTimeoutをfalseに戻すのは、受信側で処理した後にする必要がある
                        // ここで即座にfalseに戻すと、onReceiveが反応しない可能性がある
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.isTimeout = false
                        }
                    } else {
                        let minutes = Int(self.count / 60)
                        let seconds = Int(self.count) % 60
                        if isFormatSeconds {
                            self.countText = "\(Int(self.count))"
                        } else {
                            self.countText = String(format: "%02d:%02d", minutes, seconds)
                        }
                    }
                    if self.count > 0 && self.count < reservationTime && self.isReservationTime == false {
                        // 一度通知したらもうしない
                        self.isReservationTime = true
                    }
                } else {
                    self.count += self.interval
                    self.lastCountUp = self.count
                    if isFormatSeconds {
                        self.countText = "\(Int(self.count))"
                    } else {
                        self.countText = self.countUpformatter(count: self.count)
                    }
                }
            }
    }
    
    private func countUpformatter(count: Double) -> String {
        let hour = Int(count / 3600)
        let minutes = Int(count / 60)
        let seconds = Int(count) % 60
        return String(format: "%d:%02d:%02d", hour, minutes, seconds)
    }
    
    func stop() {
        print("timer stop")
        timerCancellable?.cancel()
        timerCancellable = nil
        isTimeout = false
        isReservationTime = false
        countText = ""
        count = 0.0
    }
    
    var lastCountUpText: String {
        return countUpformatter(count: lastCountUp)
    }
    
    /// タイマーを停止
    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    deinit {
        stopTimer()
    }
}