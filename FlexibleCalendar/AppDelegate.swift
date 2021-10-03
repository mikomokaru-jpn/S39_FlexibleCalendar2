
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let calYearView = UACalYearView.init(frame: NSRect.init(x: 10, y: 10, width: 0, height: 0))
        calYearView.autoresizingMask = [.width, .height]
        window.setContentSize(NSSize(width: calYearView.calYearViewSize.width + 20,
                                     height: calYearView.calYearViewSize.height + 20))
        window.contentView?.addSubview(calYearView)
    }
}

