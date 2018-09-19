import UIKit
import DateToolsSwift

open class DayViewController: UIViewController, EventDataSource, DayViewDelegate {
    
    public lazy var dayView: DayView = DayView(startDate: startDate!, endDate: endDate!, isDefaultScheduleScreen:isDefaultScheduleScreen!)
    public var startDate:Date?
    public var endDate:Date?
    public var isDefaultScheduleScreen:Bool?
    
    open override func loadView() {
        view = dayView
    }
    
    @objc public init(startDate:Date , endDate: Date, isDefaultScheduleScreen:Bool)
    {
        super.init(nibName: nil, bundle: nil)
        self.startDate = startDate
        self.endDate = endDate
        self.isDefaultScheduleScreen = isDefaultScheduleScreen
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []
        view.tintColor = UIColor.red
        dayView.dataSource = self
        dayView.delegate = self
        
        //dayView.reloadData()
        let sizeClass = traitCollection.horizontalSizeClass
        configureDayViewLayoutForHorizontalSizeClass(sizeClass)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dayView.scrollToFirstEventIfNeeded()
    }
    
    open override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        configureDayViewLayoutForHorizontalSizeClass(newCollection.horizontalSizeClass)
    }
    
    func configureDayViewLayoutForHorizontalSizeClass(_ sizeClass: UIUserInterfaceSizeClass) {
        dayView.transitionToHorizontalSizeClass(sizeClass)
    }
    
    open func reloadData() {
        dayView.reloadData()
    }
    
    open func updateStyle(_ newStyle: CalendarStyle) {
        dayView.updateStyle(newStyle)
    }
    
    open func eventsForDate(_ date: Date) -> [EventDescriptor] {
        return [Event]()
    }
    
    // MARK: DayViewDelegate
    
    open func dayViewDidSelectEventView(_ eventView: EventView) {
    }
    
    open func dayViewDidLongPressEventView(_ eventView: EventView) {
    }
    
    open func dayViewDidLongPressTimelineAtHour(_ hour: Int) {
    }
    
    open func dayView(dayView: DayView, willMoveTo date: Date) {
    }
    
    open func dayView(dayView: DayView, didMoveTo date: Date) {
    }
    
    open func selectAllEvents(forDate: Date){
    }
    
    open func deSelectAllEvents(forDate: Date){
    }
    
    open func quickActionButtonPressed(forDate: Date){
    }
}
