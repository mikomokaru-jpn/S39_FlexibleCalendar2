import Cocoa

class UACalView: NSView {
    var thisCalInfo = CalendarInfo()
    var dayViewArray = [UADayView]()
    var calDateArray = [CalDate]()
    var calSize: Int = 0
    private var youbiViewArray = [UAHeadView]()
    private var holidays: Dictionary = [String: String]()
    //日付ユーティリティ
    private let dateUtil = UADateUtil.dateManager
    //外形定義
    static var calViewSize: NSSize { return NSSize(width: 140, height: 140) }
    private let dayViewSize = NSSize(width: 20, height: 20) //日付ビューのサイズ
    private let fontSize: CGFloat = 12
    private let smallFontSize: CGFloat = 8
    private let headerRect = NSRect.init(x: 0, y: 0, width: 140, height: 20) //見出しビューのサイズ

    private let WEEK4 = 28
    private let WEEK5 = 35
    private let WEEK6 = 42
    //コントロール参照
    private let headerViewObj = UAHeadView.init(frame: NSRect.init())
    //サイズ変更監視
    private var observers = [NSKeyValueObservation]()
    //カレンダ情報
    struct CalDate {
        var year: Int = 0
        var month: Int = 0
        var day: Int = 0
        var selected: Bool = false
        
        mutating func setDate (_ y: Int, _ m: Int, _ d: Int) {
            self.year = y
            self.month = m
            self.day = d
        }
        var ymd: Int{
            return year * 10000 + month * 100 + day
        }
    }
    //Y軸反転
    override var isFlipped: Bool{
        return true
    }
    //イニシャライザ
    init(frame frameRect: NSRect, calendarInfo: CalendarInfo) {
        thisCalInfo = calendarInfo
        //スーパークラスのイニシャライズ
        super.init(frame: frameRect)
        //初期処理
        self.frame.size = UACalView.calViewSize
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.gray.cgColor
        self.layer?.borderWidth = 1
        self.layer?.borderColor = NSColor.black.cgColor
        //見出しの作成
        headerViewObj.frame = self.headerRect
        self.addSubview(headerViewObj)
        //空の日付ビュー/カレンダー情報を作成
        var index = 0
        for i in 0 ..< 6{
            for j in 0 ..< 7{
                calDateArray.append(CalDate())
                dayViewArray.append(UADayView.init()) //日付ビュー
                dayViewArray[index].index = index
                addSubview(dayViewArray[index])
                dayViewArray[index].frame =
                    NSRect.init(x: dayViewSize.width * CGFloat(j),
                                y: dayViewSize.height * CGFloat(i) + headerRect.height,
                                width: dayViewSize.width,
                                height: dayViewSize.height)
                if j == 5{
                    dayViewArray[index].weekDay = .saturday
                }
                if j == 6{
                    dayViewArray[index].weekDay = .sunday
                }
                index += 1
            }
        }
        //休日ファイルの読み込み
        if let path = Bundle.main.path(forResource: "holiday", ofType: "json"){
            do {
                let url:URL = URL.init(fileURLWithPath: path)
                let data = try Data.init(contentsOf: url)
                let jsonData = try JSONSerialization.jsonObject(with: data)
                if  let dictionary = jsonData as? Dictionary<String, String>{
                    holidays = dictionary
                }else{
                    print("休日ファイルを読み込めません")
                    return
                }
            }catch{
                print("休日ファイルを読み込めません \(error.localizedDescription)")
            }
        }
        //日付のセット
        self.setDate()
        //親ビュー（自身）のサイズが変わったとき（コンテントビューのサイズと連動する）
        observers.append(self.observe(\.layer?.bounds, options: [.old, .new]){_,change in
            if let bounds = change.newValue as? CGRect{
                self.viewTransform(rect: bounds)
            }
        })
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented");
    }

    //日付のセット
    func setDate(){
        //見出し
        headerViewObj.text = String(format: "%ld月", thisCalInfo.month)
        headerViewObj.fontSize = fontSize
        headerViewObj.updateText()
        //初期化
        for i in 0 ..< dayViewArray.count{
            dayViewArray[i].day = 0
            dayViewArray[i].updateText()
        }
        //当月日付のセット
        let start = (thisCalInfo.firstWeekday + 5) % 7
        var day = 0
        for i in 0 ..< thisCalInfo.daysOfMonth{
            day += 1
            self.setDateItem(index: start + i,
                             calInfo: thisCalInfo,
                             day: day,
                             size: fontSize)
        }
        //初期化
        for dt in dayViewArray{
            dt.isHoliday = false
            dt.isToday = false
        }
        //休日のセット
        for i in 0 ..< calDateArray.count{
            for (key, _) in holidays{
                if let ymd = Int(key),
                   calDateArray[i].ymd == ymd{
                        dayViewArray[i].isHoliday = true
                        break
                }
            }
        }
        //現在日のセット
        let current = dateUtil.intDate(date: Date())
        for i in 0 ..< calDateArray.count{
            if calDateArray[i].ymd == current{
                dayViewArray[i].isToday = true
            }
        }
    }
    private func setDateItem(index: Int, calInfo:CalendarInfo, day: Int, size: CGFloat){
        dayViewArray[index].index = index
        dayViewArray[index].day = day
        dayViewArray[index].fontSize = size
        dayViewArray[index].updateText()
        calDateArray[index].setDate(calInfo.year, calInfo.month, day)
    }
    
    func viewTransform(rect: CGRect){
        let rateWidth: CGFloat = bounds.width / UACalView.calViewSize.width
        let rateHeight: CGFloat = bounds.height / UACalView.calViewSize.height
        //見出し
        self.transForm(rect: &self.headerViewObj.frame, original: self.headerRect,
                       xRate:rateWidth, yRate: rateHeight)
        self.self.headerViewObj.updateText(rate: sqrt(rateWidth * rateHeight))
        //日付
        var index = 0
        for i in 0 ..< 6{
            for j in 0 ..< 7{
                let point =  CGPoint(x: CGFloat(j) * self.dayViewSize.width,
                                     y: CGFloat(i) * self.dayViewSize.height + headerRect.height)
                self.transForm(rect: &self.dayViewArray[index].frame,
                               original: CGRect.init(origin: point, size: self.dayViewSize),
                               xRate:rateWidth, yRate: rateHeight)
                self.dayViewArray[index].updateText(rate: sqrt(rateWidth * rateHeight))
                index += 1
            }
        }
    }
    private func transForm(rect: inout CGRect, original: CGRect, xRate: CGFloat, yRate: CGFloat){
        rect.size.width = original.size.width * xRate
        rect.size.height = original.size.height * yRate
        rect.origin.x = original.origin.x * xRate
        rect.origin.y = original.origin.y * yRate
    }

    
    
    /*
    var thisCalendarInfo = CalendarInfo()
    private let dateUtil = UADateUtil.dateManager
    static var calViewSize: NSSize { return NSSize(width: 140, height: 140) }
    private let dayViewSize = NSSize(width: 20, height: 20)
    private let fontSize: CGFloat = 12
    private let smallFontSize: CGFloat = 8
    private let headerRect = NSRect.init(x: 0, y: 0, width: 140, height: 20)
    private var dayViewArray = [UADayView]()
    private let headerViewObj = UAHeadView.init(frame: NSRect.init())
    private let WEEK5 = 35
    private let WEEK6 = 42
    private var observers = [NSKeyValueObservation]()
    //Y軸反転
    override var isFlipped: Bool{
        return true
    }

    //イニシャライザ
    init(frame frameRect: NSRect, calendarInfo: CalendarInfo){
        //カレンダー情報
        thisCalendarInfo = calendarInfo
        //スーパークラスのイニシャライズ
        super.init(frame: frameRect)
        //初期処理
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
        self.layer?.borderWidth = 1
        self.layer?.borderColor = NSColor.black.cgColor
        //見出しの作成
        headerViewObj.frame = self.headerRect
        self.addSubview(headerViewObj)
        //空の日付ビューを作成
        for i in 0 ..< 6{
            for j in 0 ..< 7{
                let frame = NSRect.init(x: dayViewSize.width * CGFloat(j),
                                        y: dayViewSize.height * CGFloat(i) + headerRect.height,
                                        width: dayViewSize.width,
                                        height: dayViewSize.height)
                
                let dayView = UADayView.init(frame: frame)
                if j == 5{
                    dayView.weekDay = .saturday
                }
                if j == 6{
                    dayView.weekDay = .sunday
                }
                dayViewArray.append(dayView)
                self.addSubview(dayView)
            }
        }
        //日付のセット
        self.setDate()
        //親ビュー（自身）のサイズが変わったとき（コンテントビューのサイズと連動する）
        observers.append(self.observe(\.layer?.bounds, options: [.old, .new]){_,change in
            if let bounds = change.newValue as? CGRect{
                self.viewTransform(rect: bounds)
            }
        })
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented");
    }
    //日付のセット
    func setDate(){
        //見出し
        headerViewObj.text = String(format: "%ld月", thisCalendarInfo.month)
        headerViewObj.fontSize = fontSize
        headerViewObj.updateText()
        for i in 0 ..< dayViewArray.count{
            dayViewArray[i].day = 0
            dayViewArray[i].updateText()
        }
        let start = (thisCalendarInfo.firstWeekday + 5) % 7
        //当月日付のセット
        var day = 0
        for i in 0 ..< thisCalendarInfo.daysOfMonth{
            day += 1
            self.setDateItem(dayView: dayViewArray[start + i],
                             year: thisCalendarInfo.year,
                             month: thisCalendarInfo.month,
                             day: day, size: fontSize)
        }
    }
    func setDateItem(dayView: UADayView, year: Int, month: Int, day: Int, size: CGFloat){
        dayView.day = day
        dayView.fontSize = size
        dayView.updateText()
    }
    //拡大・縮小
    func kickTransform(){
        self.viewTransform(rect: self.bounds)
    }
    
    
    func viewTransform(rect: CGRect){
        let rateWidth: CGFloat = bounds.width / UACalView.calViewSize.width
        let rateHeight: CGFloat = bounds.height / UACalView.calViewSize.height
        //見出し
        self.transForm(rect: &self.headerViewObj.frame, original: self.headerRect,
                       xRate:rateWidth, yRate: rateHeight)
        self.self.headerViewObj.updateText(rate: sqrt(rateWidth * rateHeight))
        //日付
        var index = 0
        for i in 0 ..< 6{
              for j in 0 ..< 7{
                let point =  CGPoint(x: CGFloat(j) * self.dayViewSize.width,
                                     y: CGFloat(i) * self.dayViewSize.height + headerRect.height)
                self.transForm(rect: &self.dayViewArray[index].frame,
                               original: CGRect.init(origin: point, size: self.dayViewSize),
                               xRate:rateWidth, yRate: rateHeight)
                self.dayViewArray[index].updateText(rate: sqrt(rateWidth * rateHeight))
                index += 1
            }
        }
    }
    private func transForm(rect: inout CGRect, original: CGRect, xRate: CGFloat, yRate: CGFloat){
        rect.size.width = original.size.width * xRate
        rect.size.height = original.size.height * yRate
        rect.origin.x = original.origin.x * xRate
        rect.origin.y = original.origin.y * yRate
 
    }
 */
}
