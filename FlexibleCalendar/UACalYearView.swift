import Cocoa

class UACalYearView: NSView {
    private var firstDate :Date
    private let dateUtil = UADateUtil.dateManager
    private var observers = [NSKeyValueObservation]()
    //外形定義
    let calYearViewSize = NSSize(width: 140*4+50, height: 140*3+40+30)
    private let viewMargin = NSSize(width: 10, height: 10)
    private let headerRect = NSRect.init(x: 0, y: 0, width: 140*4+50, height: 30)
    private let preBtnRect = NSRect.init(x: 5, y: 2, width: 26, height: 26)
    private let nextBtnRect = NSRect.init(x: 140*4+50-5-26, y: 2, width: 26, height: 26)
    private let fontSize: CGFloat = 16
    //コントロールオブジェクト
    private var calViewArray = [UACalView]()
    private let headerViewObj = UAHeadView.init(frame: NSRect.init())
    private let preBtnObj = NSButton.init()
    private let nextBtnObj = NSButton.init()
    //Y軸反転
    override var isFlipped: Bool{
        return true
    }
    //イニシャライザ
    override init(frame frameRect: NSRect) {
        //当月の初日
        firstDate = dateUtil.firstDate(date: Date())
        //スーパークラスのイニシャライズ
        super.init(frame: frameRect)
        //年間カレンダー情報
        let calendarInfoList = dateUtil.calendarYearInfo(date:firstDate)
        self.frame.size = calYearViewSize
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
        self.layer?.borderWidth = 1
        self.layer?.borderColor = NSColor.black.cgColor
        //見出しの作成
        headerViewObj.frame = self.headerRect
        self.addSubview(headerViewObj)
        headerViewObj.text = String(format: "%ld年", calendarInfoList[0].year)
        headerViewObj.fontSize = fontSize
        headerViewObj.updateText()
        //移動ボタンの作成
        preBtnObj.frame = self.preBtnRect
        preBtnObj.bezelStyle = .texturedSquare
        preBtnObj.title = "<"
        preBtnObj.font = NSFont.systemFont(ofSize: fontSize)
        preBtnObj.tag = -1
        preBtnObj.target = self
        preBtnObj.action = #selector(self.btnClicked(_:))
        headerViewObj.addSubview(preBtnObj)
        nextBtnObj.frame = self.nextBtnRect
        nextBtnObj.bezelStyle = .texturedSquare
        nextBtnObj.title = ">"
        nextBtnObj.font = NSFont.systemFont(ofSize: fontSize)
        nextBtnObj.tag = 1
        nextBtnObj.target = self
        nextBtnObj.action = #selector(self.btnClicked(_:))
        headerViewObj.addSubview(nextBtnObj)
        //12ヶ月カレンダーを作成
        var index = 0
        for i in 0 ..< 3{
            for j in 0 ..< 4{
                let rect = NSRect(x: CGFloat(j) * UACalView.calViewSize.width + CGFloat(j+1) * viewMargin.width,
                                  y: CGFloat(i) * UACalView.calViewSize.height + CGFloat(i+1) * viewMargin.height + headerRect.height,
                                  width: UACalView.calViewSize.width, height: UACalView.calViewSize.width)
                let calendarView = UACalView(frame: rect,
                                             calendarInfo: calendarInfoList[index])
                index += 1
                self.calViewArray.append(calendarView)
                self.addSubview(calendarView)
            }
        }
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
    //年移動ボタン
    @objc private func btnClicked(_ sender: NSButton){
        //年の初日
        firstDate = dateUtil.date(date: firstDate, addYears: sender.tag)
        //年間カレンダー情報
        let calendarInfoList = dateUtil.calendarYearInfo(date:firstDate)
        //見出しの編集
        headerViewObj.text = String(format: "%ld年", calendarInfoList[0].year)
        headerViewObj.fontSize = fontSize
        headerViewObj.updateText()
        //12ヶ月カレンダーを作成
        for i in 0 ..< 12 {
            calViewArray[i].thisCalInfo = calendarInfoList[i]
            calViewArray[i].setDate()
            calViewArray[i].viewTransform(rect: calViewArray[i].bounds)
        }
    }
    //拡大・縮小
    func viewTransform(rect: CGRect){
        let rateWidth: CGFloat = bounds.width / self.calYearViewSize.width
        let rateHeight: CGFloat = bounds.height / self.calYearViewSize.height
        //見出し
        self.transForm(rect: &self.headerViewObj.frame, original: self.headerRect,
                       xRate:rateWidth, yRate: rateHeight)
        self.self.headerViewObj.updateText(rate: sqrt(rateWidth * rateHeight))
        self.transForm(rect: &self.preBtnObj.frame, original: self.preBtnRect,
                       xRate:rateWidth, yRate: rateHeight)
        self.transForm(rect: &self.nextBtnObj.frame, original: self.nextBtnRect,
                       xRate:rateWidth, yRate: rateHeight)
        //月カレンダー
        var index = 0
        for i in 0 ..< 3{
            for j in 0 ..< 4{
                let point =  CGPoint(x: CGFloat(j) * UACalView.calViewSize.width + CGFloat(j+1) * viewMargin.width,
                                     y: CGFloat(i) * UACalView.calViewSize.height + CGFloat(i+1) * viewMargin.height + headerRect.height)
                self.transForm(rect: &self.calViewArray[index].frame,
                               original: CGRect(origin: point, size: UACalView.calViewSize),
                               xRate:rateWidth, yRate: rateHeight)
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
}
