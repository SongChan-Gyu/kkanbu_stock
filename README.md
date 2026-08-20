# 주식 깐부

친구끼리 비공개 그룹을 만들고, 같은 종목을 보유하면 깐부가 되는 소셜 주식 게임입니다.

증권 앱이 아닙니다. 주가 숫자보다 **친구 사이에서 벌어진 사건**이 주인공입니다.

## 어디서 실행되나

| 환경 | iPhone 앱 (`KkanbuStock.xcodeproj`) | 웹 데모 (`web/index.html`) |
| --- | --- | --- |
| 아이폰만 | **불가** (설치 빌드가 없음) | **가능** — Safari 주소 |
| macOS + Xcode | 가능 | 가능 |
| Windows | **불가** (Xcode/시뮬레이터는 Mac 전용) | **가능** — 브라우저에서 연다 |
| Linux / Cursor 클라우드 | 불가 | 가능 |

아이폰만 있어도 **소스에서 네이티브 앱을 설치할 수는 없습니다.** 아이폰에는 컴파일러가 없고, App Store / TestFlight / Mac에서 서명한 빌드가 있어야 홈 화면에 깔립니다.

| 하고 싶은 것 | 아이폰만 | 필요한 것 |
| --- | --- | --- |
| Safari에서 핵심 루프 플레이 | 가능 | 아래 웹 데모 주소 |
| 홈 화면의 네이티브 앱으로 내부테스트 | 불가 | Mac + Xcode로 한 번 빌드 (이후 TestFlight 테스터는 아이폰만으로 가능) |
| 실친구와 각자 폰에서 멀티플레이 | 불가 | 서버 + 계정. MVP는 한 기기/브라우저 로컬 |

### 웹 데모 (아이폰 Safari / Windows 포함)

아이폰에서 바로 열려면 Safari에 이 주소를 붙여넣습니다.

https://cdn.jsdelivr.net/gh/SongChan-Gyu/kkanbu_stock@play/web/index.html

공유 시트 → **홈 화면에 추가** 하면 앱처럼 열립니다. (Safari 웹 데모입니다. 앱스토어 앱이 아닙니다.)

PC에서는 `web/index.html`을 Chrome / Edge에서 열어도 됩니다.

1. **데모 주식팟으로 시작**을 고른다.
2. 그룹 맨 위 **나한테 온 일**에서 영희의 NVIDIA 너도 사, 민수의 AMD 조르기를 처리한다.

웹 데모는 같은 사건 루프를 브라우저에서 돌립니다. OCR·로컬 푸시·실기기 카메라는 iOS 앱에만 있습니다.

### iOS 앱 (Mac 전용)

1. macOS에서 `KkanbuStock/KkanbuStock.xcodeproj`를 엽니다.
2. 시뮬레이터 또는 실기기 타깃을 iOS 17+로 맞춥니다.
3. Signing Team만 선택하고 Run 합니다.
4. 온보딩에서 **데모 주식팟으로 시작**을 고르면 철수·영희·민수·준호·수진이 이미 놀고 있는 그룹에 들어갑니다.
5. 초대 코드 기본값: `KKANBU`

Xcode 프로젝트를 다시 만들려면:

```bash
python3 scripts/generate_xcodeproj.py
```

## 핵심 루프

그룹 → 초대 → 주식 등록 → 같은 종목 발견 → 깐부 → 너도 사! / 이거 어때? → 같이 사자 → 매도/주가 변화 → 혼자 튐·선견지명·존버 → 칭호/랭킹 → 다시 접속

## 탭

- **그룹**: 피드, 멤버, 같이 사기, 초대 코드
- **내 주식**: 등록, 캡처 OCR, 차트 매수가, 매도, 너도 사!
- **활동**: 추천/제안/구라핑 의심 받은 일
- **프로필**: 신뢰도 장난 지표, 공개 범위, 시장 흔들기(데모)

## 설계

```
UI (SwiftUI)
  ↓
AppStore  (@Observable, MVVM 단일 소스)
  ↓
EventEngine + EventRule[]
  ↓
Feed / Badge / Ranking / InAppNotificationPort
```

- `StockPriceService`: UI와 시세 제공자를 분리. MVP는 `MockStockPriceService`.
- `StockScreenshotAnalyzer`: Vision OCR → `StockTextParser` → 종목 DB 매칭. 외부 OCR로 교체 가능.
- `VerificationService`: 캡처와 입력 비교. 사기 단정 없음.
- 이벤트 규칙은 `EventEngine.register`로 추가합니다.
- 푸시는 로컬 알림(`UNUserNotificationCenter`)입니다. APNs 원격 푸시는 없습니다. 웹 데모는 토스트만 씁니다.

## 데이터

보유는 사용자 단위, 깐부/피드/추천/랭킹은 그룹 단위입니다. 그룹은 초대 코드 없는 공개 검색이 없습니다.

보유수량·투자금액은 기본 비공개입니다. 캡처 원본은 친구에게 공유하지 않습니다.

입력한 보유 정보는 증권 계좌로 검증되지 않습니다.

## MVP에서 뺀 것

증권사 연동, 주문, 자문, 종목 추천 알고리즘, 재무제표, 공개 커뮤니티, 뉴스, 광고.

## 테스트

Xcode에서 `KkanbuStockTests`를 실행합니다.

- OCR 파서 (NVDA / 005930 / AAPL)
- 깐부 생성, 그룹 격리
- 혼자 튐, 존버, 선견지명, 너무 일찍 튐
- 너도 사! → 깐부 루프
- 조르기 쿨다운
