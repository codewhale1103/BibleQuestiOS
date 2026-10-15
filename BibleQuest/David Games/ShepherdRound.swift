import Foundation

enum ShepherdCoverKind: String {
    case oliveBush, limestone, shelter

    var asset: String {
        switch self {
        case .oliveBush: return "ShepherdOliveBush"
        case .limestone: return "ShepherdLimestone"
        case .shelter: return "ShepherdShelter"
        }
    }

    var name: String {
        switch self {
        case .oliveBush: return "olive bush"
        case .limestone: return "limestone rocks"
        case .shelter: return "shepherd’s shelter"
        }
    }

    var width: CGFloat {
        switch self {
        case .oliveBush: return 126
        case .limestone: return 112
        case .shelter: return 134
        }
    }
}

struct ShepherdLambSpot: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let cover: ShepherdCoverKind?

    static let flock: [ShepherdLambSpot] = [
        .init(id: 0, x: 0.24, y: 0.10, cover: nil),
        .init(id: 1, x: 0.72, y: 0.16, cover: .shelter),
        .init(id: 2, x: 0.20, y: 0.41, cover: .oliveBush),
        .init(id: 3, x: 0.53, y: 0.47, cover: nil),
        .init(id: 4, x: 0.81, y: 0.57, cover: .limestone),
        .init(id: 5, x: 0.28, y: 0.79, cover: .limestone),
        .init(id: 6, x: 0.72, y: 0.88, cover: .oliveBush)
    ]
}

/// The round owns discovery rules; animations and screen layout cannot collect a hidden lamb.
struct ShepherdRound {
    private(set) var revealed: Set<Int> = []
    private(set) var rescued: Set<Int> = []

    var isComplete: Bool { rescued.count == ShepherdLambSpot.flock.count }

    var nextClue: ShepherdLambSpot? {
        // Prefer a sheep already in sight before revealing another hiding place.
        ShepherdLambSpot.flock.first { !rescued.contains($0.id) && isVisible($0) }
            ?? ShepherdLambSpot.flock.first { !rescued.contains($0.id) }
    }

    func isVisible(_ lamb: ShepherdLambSpot) -> Bool {
        lamb.cover == nil || revealed.contains(lamb.id)
    }

    @discardableResult
    mutating func reveal(_ id: Int) -> Bool {
        guard let lamb = ShepherdLambSpot.flock.first(where: { $0.id == id }),
              lamb.cover != nil, !revealed.contains(id), !rescued.contains(id) else { return false }
        revealed.insert(id)
        return true
    }

    @discardableResult
    mutating func rescue(_ id: Int) -> Bool {
        guard let lamb = ShepherdLambSpot.flock.first(where: { $0.id == id }),
              isVisible(lamb), !rescued.contains(id) else { return false }
        rescued.insert(id)
        return true
    }
}
