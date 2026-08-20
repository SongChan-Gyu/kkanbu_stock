import Foundation

protocol StockPriceServing {
    func searchStocks(_ query: String, in stocks: [Stock]) -> [Stock]
    func currentPrice(for stock: Stock, offset: Double) -> Double
    func historicalPrices(for stock: Stock, days: Int, now: Date) -> [PricePoint]
    func basePrice(for stock: Stock) -> Double
}

struct MockStockPriceService: StockPriceServing {
    func searchStocks(_ query: String, in stocks: [Stock]) -> [Stock] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return stocks }
        return stocks.filter {
            $0.ticker.lowercased().contains(q)
            || $0.name.lowercased().contains(q)
            || ($0.krCode?.contains(q) ?? false)
        }
    }

    func currentPrice(for stock: Stock, offset: Double) -> Double {
        let history = historicalPrices(for: stock, days: 1, now: Date())
        let last = history.last?.price ?? basePrice(for: stock)
        return max(stock.market == .krx ? 100 : 0.5, last * (1 + offset))
    }

    func historicalPrices(for stock: Stock, days: Int, now: Date) -> [PricePoint] {
        let base = basePrice(for: stock)
        var price = base * 0.86
        var points: [PricePoint] = []
        let seed = seedValue(stock.ticker)
        for i in stride(from: days, through: 0, by: -1) {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: now) ?? now
            let wave = sin(Double(i + seed) / 6.5) * 0.018
            let drift = Double((seed % 7) - 3) * 0.0015
            price = max(base * 0.55, price * (1 + wave + drift))
            points.append(PricePoint(date: date, price: rounded(price, market: stock.market)))
        }
        if let last = points.indices.last {
            points[last].price = rounded(base, market: stock.market)
        }
        return points
    }

    func basePrice(for stock: Stock) -> Double {
        StockCatalog.basePrices[stock.ticker] ?? (stock.market == .krx ? 50000 : 100)
    }

    private func seedValue(_ ticker: String) -> Int {
        ticker.unicodeScalars.reduce(0) { $0 + Int($1.value) }
    }

    private func rounded(_ price: Double, market: Market) -> Double {
        if market == .krx {
            return (price / 50).rounded() * 50
        }
        return (price * 100).rounded() / 100
    }
}

enum StockCatalog {
    static let all: [Stock] = {
        let rows: [(String, String, Market, String?)] = [
            ("NVDA", "NVIDIA", .nasdaq, nil),
            ("AAPL", "Apple", .nasdaq, nil),
            ("TSLA", "Tesla", .nasdaq, nil),
            ("AMD", "AMD", .nasdaq, nil),
            ("MSFT", "Microsoft", .nasdaq, nil),
            ("AMZN", "Amazon", .nasdaq, nil),
            ("GOOGL", "Alphabet", .nasdaq, nil),
            ("META", "Meta", .nasdaq, nil),
            ("AVGO", "Broadcom", .nasdaq, nil),
            ("NFLX", "Netflix", .nasdaq, nil),
            ("INTC", "Intel", .nasdaq, nil),
            ("COIN", "Coinbase", .nasdaq, nil),
            ("PLTR", "Palantir", .nasdaq, nil),
            ("SMCI", "Super Micro", .nasdaq, nil),
            ("ARM", "Arm Holdings", .nasdaq, nil),
            ("005930", "삼성전자", .krx, "005930"),
            ("000660", "SK하이닉스", .krx, "000660"),
            ("035420", "NAVER", .krx, "035420"),
            ("035720", "카카오", .krx, "035720"),
            ("005380", "현대차", .krx, "005380"),
            ("000270", "기아", .krx, "000270"),
            ("068270", "셀트리온", .krx, "068270"),
            ("207940", "삼성바이오로직스", .krx, "207940"),
            ("051910", "LG화학", .krx, "051910"),
            ("006400", "삼성SDI", .krx, "006400"),
            ("373220", "LG에너지솔루션", .krx, "373220"),
            ("012330", "현대모비스", .krx, "012330"),
            ("105560", "KB금융", .krx, "105560"),
            ("055550", "신한지주", .krx, "055550"),
            ("003670", "포스코퓨처엠", .krx, "003670")
        ]
        return rows.map { ticker, name, market, code in
            Stock(
                id: uuid(from: ticker),
                ticker: market == .krx ? (code ?? ticker) : ticker,
                name: name,
                market: market,
                krCode: code
            )
        }
    }()

    static let basePrices: [String: Double] = [
        "NVDA": 182.40,
        "AAPL": 231.42,
        "TSLA": 248.10,
        "AMD": 156.80,
        "MSFT": 428.50,
        "AMZN": 197.30,
        "GOOGL": 176.20,
        "META": 512.40,
        "AVGO": 172.10,
        "NFLX": 686.00,
        "INTC": 22.40,
        "COIN": 198.70,
        "PLTR": 36.80,
        "SMCI": 62.40,
        "ARM": 141.20,
        "005930": 72300,
        "000660": 178000,
        "035420": 186500,
        "035720": 41200,
        "005380": 211000,
        "000270": 102300,
        "068270": 178400,
        "207940": 986000,
        "051910": 312000,
        "006400": 348500,
        "373220": 372000,
        "012330": 248000,
        "105560": 84500,
        "055550": 51200,
        "003670": 218000
    ]

    static func uuid(from ticker: String) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        let data = Array("kkanbu.\(ticker)".utf8)
        for (index, byte) in data.enumerated() {
            bytes[index % 16] ^= byte
        }
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    static func stock(ticker: String) -> Stock? {
        all.first { $0.ticker.caseInsensitiveCompare(ticker) == .orderedSame || $0.krCode == ticker || $0.name == ticker }
    }
}
