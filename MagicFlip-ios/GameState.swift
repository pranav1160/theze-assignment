import Foundation
import Combine

enum GameDifficulty: String, CaseIterable {
    case veryEasy = "Very Easy"
    case easy = "Easy"
    case moderate = "Moderate"
    case hard = "Hard"
    case veryHard = "Very Hard"

    private var levelIndex: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    private var speedMultiplier: CGFloat {
        CGFloat(pow(1.5, Double(levelIndex)))
    }

    var baseObstacleSpeed: CGFloat {
        140 * speedMultiplier
    }

    var speedGrowth: CGFloat {
        1.2 * speedMultiplier
    }

    var baseSpawnInterval: TimeInterval {
        switch self {
        case .veryEasy: return 1.2
        case .easy: return 1.0
        case .moderate: return 0.85
        case .hard: return 0.7
        case .veryHard: return 0.58
        }
    }

    var minSpawnInterval: TimeInterval {
        switch self {
        case .veryEasy: return 0.9
        case .easy: return 0.78
        case .moderate: return 0.66
        case .hard: return 0.56
        case .veryHard: return 0.48
        }
    }

    var spawnDecay: TimeInterval {
        switch self {
        case .veryEasy: return 0.003
        case .easy: return 0.004
        case .moderate: return 0.005
        case .hard: return 0.006
        case .veryHard: return 0.007
        }
    }

    var heightRange: ClosedRange<CGFloat> {
        switch self {
        case .veryEasy: return 56...84
        case .easy: return 62...94
        case .moderate: return 70...106
        case .hard: return 80...122
        case .veryHard: return 90...136
        }
    }
}

enum GamePalette: String, CaseIterable {
    case neonCyan = "Neon Cyan"
    case neonPink = "Neon Pink"
    case neonGreen = "Neon Green"
    case neonPurple = "Neon Purple"
    case sunsetOrange = "Sunset Orange"
    case electricBlue = "Electric Blue"
}

final class GameState: ObservableObject {
    private static let highScoreKey = "magicflip.highscore"

    @Published private(set) var score: Int = 0
    @Published private(set) var isGameOver: Bool = false
    @Published private(set) var bestScore: Int = UserDefaults.standard.integer(forKey: highScoreKey)
    @Published private(set) var difficulty: GameDifficulty = .moderate
    @Published private(set) var palette: GamePalette = .neonCyan

    func setScore(_ value: Int) {
        score = value
        if value > bestScore {
            bestScore = value
            UserDefaults.standard.set(value, forKey: Self.highScoreKey)
        }
    }

    func setGameOver(_ value: Bool) {
        isGameOver = value
    }

    func resetForNewRun() {
        score = 0
        isGameOver = false
    }

    func setDifficulty(_ value: GameDifficulty) {
        difficulty = value
    }

    func setPalette(_ value: GamePalette) {
        palette = value
    }
}
