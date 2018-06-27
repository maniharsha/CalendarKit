import UIKit
import Neon
import DateToolsSwift

public protocol TimelineViewDelegate: class {
    func timelineView(_ timelineView: TimelineView, didLongPressAt hour: Int)
}

public class TimelineView: UIView, ReusableView {
    
    public weak var delegate: TimelineViewDelegate?
    
    public weak var eventViewDelegate: EventViewDelegate?
    
    public var date = Date() {
        didSet {
            setNeedsLayout()
        }
    }
    
    var currentTime: Date {
        return Date()
    }
    
    var eventViews = [EventView]()
    public var layoutAttributes = [EventLayoutAttributes]() {
        didSet {
            recalculateEventLayout()
            prepareEventViews()
            setNeedsLayout()
        }
    }
    var pool = ReusePool<EventView>()
    
    var firstEventYPosition: CGFloat? {
        return layoutAttributes.sorted{$0.frame.origin.y < $1.frame.origin.y}
            .first?.frame.origin.y
    }
    
    lazy var nowLine: CurrentTimeIndicator = CurrentTimeIndicator()
    
    var style = TimelineStyle()
    
    var verticalDiff: CGFloat = 45
    var verticalInset: CGFloat = 10
    var leftInset: CGFloat = 53
    
    var horizontalEventInset: CGFloat = 3
    
    public var fullHeight: CGFloat {
        return verticalInset * 2 + verticalDiff * 28
    }
    
    var calendarWidth: CGFloat {
        return bounds.width - leftInset
    }
    
    var is24hClock = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    init() {
        super.init(frame: .zero)
        frame.size.height = fullHeight
        configure()
    }
    
    var times: [String] {
        return is24hClock ? _24hTimes : _12hTimes
    }
    
    fileprivate lazy var _12hTimes: [String] = Generator.timeStrings12H()
    fileprivate lazy var _24hTimes: [String] = Generator.timeStrings24H()
    
    fileprivate lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
    
    var isToday: Bool {
        return date.isToday
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    func configure() {
        contentScaleFactor = 1
        layer.contentsScale = 1
        contentMode = .redraw
        backgroundColor = .white
        //addSubview(nowLine)
        // Add long press gesture recognizer
        addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc func longPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if (gestureRecognizer.state == .began) {
            // Get timeslot of gesture location
            let pressedLocation = gestureRecognizer.location(in: self)
            let percentOfHeight = (pressedLocation.y - verticalInset) / (bounds.height - (verticalInset * 2))
            let pressedAtHour: Int = Int(28 * percentOfHeight)
            delegate?.timelineView(self, didLongPressAt: pressedAtHour)
        }
    }
    
    public func updateStyle(_ newStyle: TimelineStyle) {
        style = newStyle.copy() as! TimelineStyle
        nowLine.updateStyle(style.timeIndicator)
        
        switch style.dateStyle {
        case .twelveHour:
            is24hClock = false
            break
        case .twentyFourHour:
            is24hClock = true
            break
        default:
            is24hClock = Locale.autoupdatingCurrent.uses24hClock()
            break
        }
        
        backgroundColor = style.backgroundColor
        setNeedsDisplay()
    }
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        
        var hourToRemoveIndex = -1
        
        if isToday {
            let minute = currentTime.minute
            if minute > 39 {
                hourToRemoveIndex = currentTime.hour + 1
            } else if minute < 21 {
                hourToRemoveIndex = currentTime.hour
            }
        }
        
        let mutableParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        mutableParagraphStyle.lineBreakMode = .byWordWrapping
        mutableParagraphStyle.alignment = .right
        let paragraphStyle = mutableParagraphStyle.copy() as! NSParagraphStyle
        
        let attributes = [NSAttributedStringKey.paragraphStyle: paragraphStyle,
                          NSAttributedStringKey.foregroundColor: self.style.timeColor,
                          NSAttributedStringKey.font: style.font] as [NSAttributedStringKey : Any]
        
        for (i, time) in times.enumerated() {
            let iFloat = CGFloat(i)
            let context = UIGraphicsGetCurrentContext()
            context!.interpolationQuality = .none
            context?.saveGState()
            context?.setStrokeColor(self.style.lineColor.cgColor)
            context?.setLineWidth(onePixel)
            context?.translateBy(x: 0, y: 0.5)
            let x: CGFloat = 53
            let y = verticalInset + iFloat * verticalDiff
            context?.beginPath()
            context?.move(to: CGPoint(x: x, y: y))
            context?.addLine(to: CGPoint(x: (bounds).width, y: y))
            context?.strokePath()
            context?.restoreGState()
            
            //if i == hourToRemoveIndex { continue }
            
            let fontSize = style.font.pointSize
            let timeRect = CGRect(x: 2, y: iFloat * verticalDiff + verticalInset - 7,
                                  width: leftInset - 8, height: fontSize + 2)
            
            let timeString = NSString(string: time)
            
            timeString.draw(in: timeRect, withAttributes: attributes)
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        recalculateEventLayout()
        layoutEvents()
        layoutNowLine()
    }
    
    func layoutNowLine() {
        if !isToday {
            nowLine.alpha = 0
        } else {
            bringSubview(toFront: nowLine)
            nowLine.alpha = 1
            let size = CGSize(width: bounds.size.width, height: 20)
            let rect = CGRect(origin: CGPoint.zero, size: size)
            nowLine.date = currentTime
            nowLine.frame = rect
            nowLine.center.y = dateToY(currentTime)
        }
    }
    
    func layoutEvents() {
        if eventViews.isEmpty {return}
        
        for (idx, attributes) in layoutAttributes.enumerated() {
            let descriptor = attributes.descriptor
            let eventView = eventViews[idx]
            eventView.frame = attributes.frame
            eventView.updateWithDescriptor(event: descriptor)
        }
    }
    
    func recalculateEventLayout() {
        let sortedEvents = layoutAttributes.sorted { (attr1, attr2) -> Bool in
            let start1 = attr1.descriptor.startDate
            let start2 = attr2.descriptor.startDate
            return start1.isEarlier(than: start2)
        }
        
        var groupsOfEvents = [[EventLayoutAttributes]]()
        var overlappingEvents = [EventLayoutAttributes]()
        
        for event in sortedEvents {
            if overlappingEvents.isEmpty {
                overlappingEvents.append(event)
                continue
            }
            
            let longestEvent = overlappingEvents.sorted { (attr1, attr2) -> Bool in
                let period1 = attr1.descriptor.datePeriod.seconds
                let period2 = attr2.descriptor.datePeriod.seconds
                return period1 > period2
                }
                .first!
            
            let isLastEvent = overlappingEvents.last!
            if longestEvent.descriptor.datePeriod.overlaps(with: event.descriptor.datePeriod) ||
                isLastEvent.descriptor.datePeriod.overlaps(with: event.descriptor.datePeriod) {
                overlappingEvents.append(event)
                continue
            } else {
                groupsOfEvents.append(overlappingEvents)
                overlappingEvents.removeAll()
                overlappingEvents.append(event)
            }
        }
        
        groupsOfEvents.append(overlappingEvents)
        overlappingEvents.removeAll()
        
        for overlappingEvents in groupsOfEvents
        {
            let totalCount = CGFloat(overlappingEvents.count)
            var totalPersonalEventCount = 0
            for event in overlappingEvents
            {
                if (event.descriptor.userInfo as! String == "PERSONALAPPOINTMENT")
                {
                    totalPersonalEventCount = totalPersonalEventCount + 1
                }
            }
            
            let sortedOverlappingEvents = overlappingEvents.sorted(by: { (event1, event2) -> Bool in
                
                if (event1.descriptor.userInfo as! String != "PERSONALAPPOINTMENT")
                {
                    return true
                }
                else
                {
                    if(event2.descriptor.userInfo as! String == "PERSONALAPPOINTMENT" )
                    {
                        return event1.descriptor.endDate.minutes(from: event1.descriptor.startDate) > event2.descriptor.endDate.minutes(from: event2.descriptor.startDate)
                    }
                    else
                    {
                        return false
                    }
                }
            })
            
            var floatIndex = 0
            
            for (index, event) in sortedOverlappingEvents.enumerated()
            {
                let startY = dateToY(event.descriptor.datePeriod.beginning!)
                let endY = dateToY(event.descriptor.datePeriod.end!)
                if (event.descriptor.userInfo as! String == "PERSONALAPPOINTMENT") && (totalCount > 1)
                {
                    floatIndex = floatIndex + 1
                }
                
                var x = leftInset + CGFloat(floatIndex) / CGFloat(totalPersonalEventCount + 1) * calendarWidth
                
                var equalWidth = calendarWidth
                
                if (totalCount > 1)
                {
                    equalWidth = calendarWidth / CGFloat(totalPersonalEventCount + 1)
                }
                
                event.frame = CGRect(x: x, y: startY, width: equalWidth, height: endY - startY)
            }
        }
    }
    
    func prepareEventViews() {
        pool.enqueue(views: eventViews)
        eventViews.removeAll()
        for _ in 0...layoutAttributes.endIndex {
            let newView = pool.dequeue()
            newView.delegate = eventViewDelegate
            if newView.superview == nil {
                addSubview(newView)
            }
            eventViews.append(newView)
        }
    }
    
    func prepareForReuse() {
        pool.enqueue(views: eventViews)
        eventViews.removeAll()
        setNeedsDisplay()
    }
    
    // MARK: - Helpers
    
    fileprivate var onePixel: CGFloat {
        return 1 / UIScreen.main.scale
    }
    
    fileprivate func dateToY(_ date: Date) -> CGFloat {
        if date.dateOnly() > self.date.dateOnly() {
            // Event ending the next day
            return 28 * verticalDiff + verticalInset
        } else if date.dateOnly() < self.date.dateOnly() {
            // Event starting the previous day
            return verticalInset
        } else {
            var hourY:CGFloat = 0.0
            var minuteY:CGFloat = 0.0
            
            hourY = ((CGFloat(date.hour) * verticalDiff ) * 2) + verticalInset
            minuteY = (CGFloat(date.minute) * verticalDiff / 30)
            
            return hourY + minuteY
        }
    }
}
