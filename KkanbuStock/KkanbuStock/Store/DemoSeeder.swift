import Foundation

enum DemoSeeder {
    static func seed(into state: inout AppState, currentUser: User) {
        let cheolsu = User(nickname: "철수", avatarEmoji: "🦊")
        let younghee = User(nickname: "영희", avatarEmoji: "🐰")
        let minsu = User(nickname: "민수", avatarEmoji: "🐼")
        let junho = User(nickname: "준호", avatarEmoji: "🐯")
        let sujin = User(nickname: "수진", avatarEmoji: "🐥")
        state.users.append(contentsOf: [cheolsu, younghee, minsu, junho, sujin])

        let group = Group(
            name: "우리 주식팟",
            inviteCode: "KKANBU",
            ownerId: cheolsu.id,
            createdAt: Date().addingTimeInterval(-86400 * 21)
        )
        state.groups.append(group)
        state.selectedGroupId = group.id

        let people = [currentUser, cheolsu, younghee, minsu, junho, sujin]
        for (offset, person) in people.enumerated() {
            state.members.append(
                GroupMember(
                    groupId: group.id,
                    userId: person.id,
                    joinedAt: Date().addingTimeInterval(-86400 * Double(20 - offset))
                )
            )
        }

        func stock(_ ticker: String) -> Stock {
            StockCatalog.stock(ticker: ticker) ?? state.stocks[0]
        }

        let nvda = stock("NVDA")
        let tsla = stock("TSLA")
        let aapl = stock("AAPL")
        let samsung = stock("005930")
        let hynix = stock("000660")
        let amd = stock("AMD")

        let cheolsuNVDA = Holding(
            userId: cheolsu.id,
            stockId: nvda.id,
            averagePrice: 163.40,
            quantity: 4,
            purchaseDate: Date().addingTimeInterval(-86400 * 40),
            inputMethod: .screenshot,
            verificationState: .screenshotVerified,
            createdAt: Date().addingTimeInterval(-86400 * 40)
        )
        let youngheeNVDA = Holding(
            userId: younghee.id,
            stockId: nvda.id,
            averagePrice: 168.20,
            quantity: 2,
            purchaseDate: Date().addingTimeInterval(-86400 * 32),
            inputMethod: .chart,
            verificationState: .unverified,
            createdAt: Date().addingTimeInterval(-86400 * 32)
        )
        let cheolsuAAPL = Holding(
            userId: cheolsu.id,
            stockId: aapl.id,
            averagePrice: 198.00,
            purchaseDate: Date().addingTimeInterval(-86400 * 50),
            verificationState: .screenshotVerified
        )
        let youngheeAAPL = Holding(
            userId: younghee.id,
            stockId: aapl.id,
            averagePrice: 210.40,
            purchaseDate: Date().addingTimeInterval(-86400 * 18)
        )
        let minsuTSLA = Holding(
            userId: minsu.id,
            stockId: tsla.id,
            averagePrice: 180.00,
            purchaseDate: Date().addingTimeInterval(-86400 * 25),
            sellPrice: 212.00,
            sellDate: Date().addingTimeInterval(-86400 * 2),
            status: .sold,
            verificationState: .unverified
        )
        let junhoTSLA = Holding(
            userId: junho.id,
            stockId: tsla.id,
            averagePrice: 241.00,
            purchaseDate: Date().addingTimeInterval(-86400 * 10),
            verificationState: .suspected,
            suspicionCount: 1
        )
        let sujinSamsung = Holding(
            userId: sujin.id,
            stockId: samsung.id,
            averagePrice: 68500,
            purchaseDate: Date().addingTimeInterval(-86400 * 60),
            inputMethod: .screenshot,
            verificationState: .screenshotVerified
        )
        let minsuHynix = Holding(
            userId: minsu.id,
            stockId: hynix.id,
            averagePrice: 210000,
            purchaseDate: Date().addingTimeInterval(-86400 * 12),
            verificationState: .unverified
        )
        let youngheeAMD = Holding(
            userId: younghee.id,
            stockId: amd.id,
            averagePrice: 142.00,
            purchaseDate: Date().addingTimeInterval(-86400 * 22)
        )
        let meAAPL = Holding(
            userId: currentUser.id,
            stockId: aapl.id,
            averagePrice: 205.00,
            purchaseDate: Date().addingTimeInterval(-86400 * 14),
            inputMethod: .chart,
            verificationState: .unverified
        )

        state.holdings.append(contentsOf: [
            cheolsuNVDA, youngheeNVDA, cheolsuAAPL, youngheeAAPL,
            minsuTSLA, junhoTSLA, sujinSamsung, minsuHynix, youngheeAMD, meAAPL
        ])

        state.suspicions.append(
            GurapingSuspicion(
                groupId: group.id,
                holdingId: junhoTSLA.id,
                actorId: minsu.id,
                targetUserId: junho.id,
                createdAt: Date().addingTimeInterval(-3600 * 5)
            )
        )

        let rec = StockRecommendation(
            groupId: group.id,
            senderId: younghee.id,
            receiverId: currentUser.id,
            stockId: nvda.id,
            holdingId: youngheeNVDA.id,
            message: "나 이거 샀으니까 너도 사 ㅋㅋ",
            createdAt: Date().addingTimeInterval(-3600 * 3)
        )
        state.recommendations.append(rec)

        let proposal = StockProposal(
            groupId: group.id,
            proposerId: minsu.id,
            stockId: amd.id,
            message: "이번에 같이 들어갈 사람?",
            createdAt: Date().addingTimeInterval(-3600 * 8)
        )
        state.proposals.append(proposal)
        state.coBuys.append(contentsOf: [
            CoBuyRequest(proposalId: proposal.id, groupId: group.id, userId: minsu.id, stockId: amd.id, nagCount: 1, lastNagAt: Date().addingTimeInterval(-3600)),
            CoBuyRequest(proposalId: proposal.id, groupId: group.id, userId: younghee.id, stockId: amd.id)
        ])

        state.events = [
            FeedEvent(groupId: group.id, type: .memberJoined, actorId: currentUser.id, title: "👋 새 멤버", message: "\(currentUser.nickname)님이 우리 주식팟에 들어왔습니다.", createdAt: Date().addingTimeInterval(-120)),
            FeedEvent(groupId: group.id, type: .recommendStock, actorId: younghee.id, targetUserId: currentUser.id, stockId: nvda.id, title: "📣 너도 사!", message: "영희가 \(currentUser.nickname)에게 NVIDIA를 추천했습니다.\n“나 이거 샀으니까 너도 사 ㅋㅋ”", createdAt: Date().addingTimeInterval(-3600 * 3)),
            FeedEvent(groupId: group.id, type: .proposalCreated, actorId: minsu.id, stockId: amd.id, title: "🤔 이거 어때?", message: "민수가 AMD 같이 사자고 제안했습니다.\n“이번에 같이 들어갈 사람?”", createdAt: Date().addingTimeInterval(-3600 * 8)),
            FeedEvent(groupId: group.id, type: .persistentNagging, actorId: minsu.id, targetUserId: currentUser.id, stockId: amd.id, title: "😂 같이 사자고 조르기", message: "민수가 \(currentUser.nickname)에게 AMD를 두 번째로 같이 사자고 조르고 있습니다.", createdAt: Date().addingTimeInterval(-3600)),
            FeedEvent(groupId: group.id, type: .newKkangbu, actorId: currentUser.id, targetUserId: cheolsu.id, stockId: aapl.id, title: "🤝 새로운 주식 깐부", message: "\(currentUser.nickname) × 철수\nApple 깐부가 탄생했습니다.", createdAt: Date().addingTimeInterval(-86400 * 14)),
            FeedEvent(groupId: group.id, type: .newKkangbu, actorId: cheolsu.id, targetUserId: younghee.id, stockId: nvda.id, title: "🤝 새로운 주식 깐부", message: "철수 × 영희\nNVIDIA 깐부가 탄생했습니다.", createdAt: Date().addingTimeInterval(-86400 * 32)),
            FeedEvent(groupId: group.id, type: .goldenKkangbu, actorId: cheolsu.id, targetUserId: younghee.id, stockId: nvda.id, title: "🔥 황금 깐부", message: "철수와 영희가 NVIDIA 황금 깐부가 되었습니다.", createdAt: Date().addingTimeInterval(-86400 * 4)),
            FeedEvent(groupId: group.id, type: .soloEscape, actorId: minsu.id, stockId: tsla.id, title: "🏃 혼자 튐", message: "민수가 Tesla를 팔고 혼자 튀었습니다.\n준호는 아직 남아 있습니다.", createdAt: Date().addingTimeInterval(-86400 * 2)),
            FeedEvent(groupId: group.id, type: .verificationRequested, actorId: minsu.id, targetUserId: junho.id, stockId: tsla.id, holdingId: junhoTSLA.id, title: "🕵️ 구라핑 의혹", message: "친구들이 준호의 Tesla 매수가를 의심하고 있습니다.", createdAt: Date().addingTimeInterval(-3600 * 5)),
            FeedEvent(groupId: group.id, type: .screenshotVerified, actorId: cheolsu.id, stockId: nvda.id, title: "📸 매수가 인증 완료", message: "철수가 NVIDIA 매수가를 인증했습니다.", createdAt: Date().addingTimeInterval(-86400 * 39)),
            FeedEvent(groupId: group.id, type: .diamondHands, actorId: junho.id, targetUserId: minsu.id, stockId: tsla.id, title: "💎 끝까지 존버", message: "친구들이 Tesla에서 떠났는데 준호만 남아 있습니다.", createdAt: Date().addingTimeInterval(-86400 * 2 + 30))
        ]

        state.badges.append(contentsOf: [
            Badge(userId: cheolsu.id, groupId: group.id, type: "GOLDEN", title: "황금 깐부", emoji: "🔥"),
            Badge(userId: younghee.id, groupId: group.id, type: "GOLDEN", title: "황금 깐부", emoji: "🔥"),
            Badge(userId: junho.id, groupId: group.id, type: "DIAMOND", title: "끝까지 존버", emoji: "💎")
        ])
    }
}
