import Foundation

enum KkangbuGradeBook {
    static let kkangbu = KkangbuGrade(id: "KKANGBU", emoji: "🤝", title: "주식 깐부", priority: 10)
    static let golden = KkangbuGrade(id: "GOLDEN", emoji: "🔥", title: "황금 깐부", priority: 40)
    static let destiny = KkangbuGrade(id: "DESTINY", emoji: "💎", title: "운명의 주식 파트너", priority: 50)
    static let godsMove = KkangbuGrade(id: "GODS_MOVE", emoji: "🚀", title: "신의 한 수 파트너", priority: 60)
    static let worst = KkangbuGrade(id: "WORST", emoji: "💀", title: "최악의 주식 파트너", priority: 30)
    static let graveyard = KkangbuGrade(id: "GRAVEYARD", emoji: "🪦", title: "공동묘지 파트너", priority: 35)

    static func grade(for bonds: [KkangbuBond], thresholds: EventThresholds) -> KkangbuGrade {
        guard !bonds.isEmpty else { return kkangbu }
        let avg = bonds.map(\.sharedReturn).reduce(0, +) / Double(bonds.count)
        let best = bonds.map(\.sharedReturn).max() ?? avg
        if bonds.count >= thresholds.destinySharedCount { return destiny }
        if best >= thresholds.godsMoveReturn { return godsMove }
        if avg <= thresholds.graveyardReturn { return graveyard }
        if avg <= thresholds.worstPartnerReturn { return worst }
        if avg >= thresholds.goldenReturn { return golden }
        return kkangbu
    }

    static func grade(sharedReturn: Double, thresholds: EventThresholds) -> KkangbuGrade {
        if sharedReturn >= thresholds.godsMoveReturn { return godsMove }
        if sharedReturn <= thresholds.graveyardReturn { return graveyard }
        if sharedReturn <= thresholds.worstPartnerReturn { return worst }
        if sharedReturn >= thresholds.goldenReturn { return golden }
        return kkangbu
    }
}

enum KkangbuMath {
    static func activeHolders(stockId: UUID, groupId: UUID, state: AppState) -> [Holding] {
        let memberIds = Set(state.members(of: groupId).map(\.userId))
        return state.holdings.filter {
            $0.stockId == stockId && $0.status == .holding && memberIds.contains($0.userId)
        }
    }

    static func bonds(in groupId: UUID, state: AppState, prices: [UUID: Double]) -> [KkangbuBond] {
        let memberIds = state.members(of: groupId).map(\.userId)
        let active = state.holdings.filter { holding in
            holding.status == .holding && memberIds.contains(holding.userId)
        }
        let byStock = Dictionary(grouping: active, by: \.stockId)
        var result: [KkangbuBond] = []
        for (stockId, holdings) in byStock {
            let uniqueUsers = Dictionary(grouping: holdings, by: \.userId).compactMap { $0.value.first }
            guard uniqueUsers.count >= 2 else { continue }
            for i in 0..<uniqueUsers.count {
                for j in (i + 1)..<uniqueUsers.count {
                    let a = uniqueUsers[i]
                    let b = uniqueUsers[j]
                    let price = prices[stockId] ?? a.averagePrice
                    let shared = (a.returnRate(currentPrice: price) + b.returnRate(currentPrice: price)) / 2
                    let started = max(a.createdAt, b.createdAt)
                    let pair = [a.userId.uuidString, b.userId.uuidString].sorted().joined(separator: "-")
                    result.append(
                        KkangbuBond(
                            id: "\(groupId.uuidString)-\(stockId.uuidString)-\(pair)",
                            groupId: groupId,
                            stockId: stockId,
                            userA: a.userId,
                            userB: b.userId,
                            startedAt: started,
                            sharedReturn: shared,
                            grade: KkangbuGradeBook.grade(sharedReturn: shared, thresholds: state.thresholds),
                            holdingA: a.id,
                            holdingB: b.id
                        )
                    )
                }
            }
        }
        return result.sorted { $0.startedAt < $1.startedAt }
    }

    static func pairSummaries(in groupId: UUID, state: AppState, prices: [UUID: Double]) -> [PairSummary] {
        let bonds = bonds(in: groupId, state: state, prices: prices)
        let grouped = Dictionary(grouping: bonds) { bond in
            [bond.userA.uuidString, bond.userB.uuidString].sorted().joined(separator: "|")
        }
        return grouped.map { key, items in
            let avg = items.map(\.sharedReturn).reduce(0, +) / Double(items.count)
            let grade = KkangbuGradeBook.grade(for: items, thresholds: state.thresholds)
            let first = items.map(\.startedAt).min() ?? Date()
            let a = items[0].userA
            let b = items[0].userB
            return PairSummary(
                id: "\(groupId.uuidString)-\(key)",
                groupId: groupId,
                userA: a,
                userB: b,
                bonds: items,
                grade: grade,
                averageReturn: avg,
                startedAt: first
            )
        }
        .sorted { $0.averageReturn > $1.averageReturn }
    }

    static func pairKey(_ a: UUID, _ b: UUID) -> String {
        [a.uuidString, b.uuidString].sorted().joined(separator: "|")
    }
}
