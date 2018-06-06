import UIKit
import DateToolsSwift

enum calendarType:String{
    case oneWeekCalendar
    case twoWeekCalendar
    case threeWeekCalendar
    case RegularCalendar
}

public protocol SelectAllEventsDelegate: class
{
    func selectAllEvents(forDate:Date)
    func deSelectAllEvents(forDate:Date)
}

public class DayHeaderView: UIView {

  public var daysInWeek = 7

  public var calendar = Calendar.autoupdatingCurrent
  public weak var selectAllEventsDelegate: SelectAllEventsDelegate?
    
  public var selectAllView: UIView = UIView()
  public var selectAllButton:UIButton = UIButton(type: .custom)
  public var deSelectAllButton:UIButton = UIButton(type: .custom)
  public var selectedDate = Date()
  var style = DayHeaderStyle()
    
  let startDate = Date()
  let endDate = Date().add(TimeChunk.dateComponents(days: 14))
    
  weak var state: DayViewState? {
    willSet(newValue) {
      state?.unsubscribe(client: self)
    }
    didSet {
      state?.subscribe(client: self)
      swipeLabelView.state = state
    }
  }

  var currentWeekdayIndex = -1

  var calendarTypeUpdated:calendarType = calendarType.RegularCalendar
  var daySymbolsViewHeight: CGFloat = 20
  var pagingScrollViewHeight: CGFloat = 40
  var swipeLabelViewHeight: CGFloat = 20

  lazy var daySymbolsView: DaySymbolsView = DaySymbolsView(daysInWeek: self.daysInWeek)
  let pagingScrollView = PagingScrollView<DaySelector>()
  lazy var swipeLabelView: SwipeLabelView = SwipeLabelView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    configure()
    configurePages()
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configure()
    configurePages()
  }

  func configure()
  {
    selectAllButton.setTitle("Select All", for: .normal)
    selectAllButton.setTitleColor(UIColor.blue, for: .normal)
    selectAllButton.addTarget(self, action: #selector(selectAllButtonPressed), for: .touchUpInside)
    
    deSelectAllButton.setTitle("Deselect All", for: .normal)
    deSelectAllButton.setTitleColor(UIColor.blue, for: .normal)
    deSelectAllButton.addTarget(self, action: #selector(deselectAllButtonPressed), for: .touchUpInside)
    
    selectAllView.addSubview(selectAllButton)
    selectAllView.addSubview(deSelectAllButton)
    selectAllView.groupAndFill(group: .horizontal, views: [selectAllButton, deSelectAllButton], padding: 10)
    [daySymbolsView, pagingScrollView, swipeLabelView, selectAllView].forEach {

      addSubview($0)
    }
    pagingScrollView.viewDelegate = self
    backgroundColor = style.backgroundColor
  }

  @objc func selectAllButtonPressed()
  {
    selectAllEventsDelegate?.selectAllEvents(forDate: selectedDate)
  }
    
  @objc func deselectAllButtonPressed()
  {
    selectAllEventsDelegate?.deSelectAllEvents(forDate: selectedDate)
  }
    
  func configurePages(_ selectedDate: Date = Date())
  {

    
    calendarTypeUpdated = calendarTypeForDates(startDate: startDate, endDate: endDate)
    
    switch calendarTypeUpdated
    {
        case .oneWeekCalendar:
            
            let daySelector = DaySelector(daysInWeek: daysInWeek)
            let date = selectedDate.add(TimeChunk.dateComponents(weeks: 0))
            daySelector.startDate = beginningOfWeek(date)
            pagingScrollView.reusableViews.append(daySelector)
            pagingScrollView.addSubview(daySelector)
            daySelector.delegate = self
            
            let centerDaySelector = pagingScrollView.reusableViews[0]
            centerDaySelector.selectedDate = selectedDate
            currentWeekdayIndex = centerDaySelector.selectedIndex
            
            break
        case .twoWeekCalendar:
            
            for i in 0...1
            {
                let daySelector = DaySelector(daysInWeek: daysInWeek)
                let date = selectedDate.add(TimeChunk.dateComponents(weeks: i))
                daySelector.startDate = beginningOfWeek(date)
                pagingScrollView.reusableViews.append(daySelector)
                pagingScrollView.addSubview(daySelector)
                daySelector.delegate = self
            }
            let centerDaySelector = pagingScrollView.reusableViews[0]
            centerDaySelector.selectedDate = selectedDate
            currentWeekdayIndex = centerDaySelector.selectedIndex
            
            break
        case .threeWeekCalendar:
        
            for i in 0...2
            {
                let daySelector = DaySelector(daysInWeek: daysInWeek)
                let date = selectedDate.add(TimeChunk.dateComponents(weeks: i))
                daySelector.startDate = beginningOfWeek(date)
                pagingScrollView.reusableViews.append(daySelector)
                pagingScrollView.addSubview(daySelector)
                daySelector.delegate = self
            }
            let centerDaySelector = pagingScrollView.reusableViews[0]
            centerDaySelector.selectedDate = selectedDate
            currentWeekdayIndex = centerDaySelector.selectedIndex
            
            break
        case .RegularCalendar:
            
            for i in -1...1
            {
                let daySelector = DaySelector(daysInWeek: daysInWeek)
                let date = selectedDate.add(TimeChunk.dateComponents(weeks: i))
                daySelector.startDate = beginningOfWeek(date)
                pagingScrollView.reusableViews.append(daySelector)
                pagingScrollView.addSubview(daySelector)
                daySelector.delegate = self
            }
            let centerDaySelector = pagingScrollView.reusableViews[1]
            centerDaySelector.selectedDate = selectedDate
            currentWeekdayIndex = centerDaySelector.selectedIndex
            
            break
    }

  }
  
  func beginningOfWeek(_ date: Date) -> Date
  {
    return calendar.date(from: DateComponents(calendar: calendar,
                                              weekday: calendar.firstWeekday,
                                              weekOfYear: date.weekOfYear,
                                              yearForWeekOfYear: date.yearForWeekOfYear))!
  }
  
  func calendarTypeForDates(startDate:Date, endDate:Date) -> calendarType
  {
      let startDateOfFirstWeek = beginningOfWeek(startDate)
      let startDateOfSecondWeek = startDateOfFirstWeek.add(TimeChunk.dateComponents(weeks: 1))
      let startDateOfThirdWeek = startDateOfSecondWeek.add(TimeChunk.dateComponents(weeks: 1))
      let startDateOfFourthWeek = startDateOfThirdWeek.add(TimeChunk.dateComponents(weeks: 1))

    if endDate.isEarlier(than: startDateOfSecondWeek)
    {
        return calendarType.oneWeekCalendar
    }
    else if endDate.isEarlier(than: startDateOfThirdWeek)
    {
        return calendarType.twoWeekCalendar
    }
    else if endDate.isEarlier(than: startDateOfFourthWeek)
    {
        return calendarType.threeWeekCalendar
    }
    else
    {
        return calendarType.RegularCalendar
    }
  }
    
  public func updateStyle(_ newStyle: DayHeaderStyle)
  {
    style = newStyle.copy() as! DayHeaderStyle
    daySymbolsView.updateStyle(style.daySymbols)
    swipeLabelView.updateStyle(style.swipeLabel)
    pagingScrollView.reusableViews.forEach { daySelector in
      daySelector.updateStyle(style.daySelector)
    }
    backgroundColor = style.backgroundColor
  }

  override public func layoutSubviews()
  {

    if calendarTypeUpdated == calendarType.RegularCalendar
    {
        pagingScrollView.contentOffset = CGPoint(x: bounds.width, y: 0)
    } else
    {
        pagingScrollView.contentOffset = CGPoint(x: 0 , y: 0)
    }

    pagingScrollView.contentSize = CGSize(width: bounds.size.width * CGFloat(pagingScrollView.reusableViews.count), height: 0)
    daySymbolsView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: daySymbolsViewHeight)
    pagingScrollView.alignAndFillWidth(align: .underCentered, relativeTo: daySymbolsView, padding: 0, height: pagingScrollViewHeight)
    swipeLabelView.alignAndFillWidth(align: .underCentered, relativeTo: pagingScrollView, padding: 0, height: swipeLabelViewHeight)
    selectAllView.groupAndFill(group: .horizontal, views: [selectAllButton, deSelectAllButton], padding: 10)
    selectAllView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 10, otherSize: 30)
  }

  public func transitionToHorizontalSizeClass(_ sizeClass: UIUserInterfaceSizeClass) {
    daySymbolsView.isHidden = sizeClass == .regular
    pagingScrollView.reusableViews.forEach{$0.transitionToHorizontalSizeClass(sizeClass)}
  }
}

extension DayHeaderView: DaySelectorDelegate
{
  func dateSelectorDidSelectDate(_ date: Date) {
    state?.move(to: date)
  }
}

extension DayHeaderView: DayViewStateUpdating
{
  public func move(from oldDate: Date, to newDate: Date)
  {
    selectedDate = newDate
    if(calendarTypeUpdated == .RegularCalendar)
    {
        let newDate = newDate.dateOnly()
        let centerView = pagingScrollView.reusableViews[1]
        let startDate = centerView.startDate.dateOnly()
        
        let daysFrom = newDate.days(from: startDate, calendar: calendar)
        let newStartDate = beginningOfWeek(newDate)
        
        let leftView = pagingScrollView.reusableViews[0]
        let rightView = pagingScrollView.reusableViews[2]
        
        if daysFrom < 0
        {
            currentWeekdayIndex = abs(daysInWeek + daysFrom % daysInWeek) % daysInWeek
            centerView.startDate = newStartDate
            centerView.selectedIndex = currentWeekdayIndex
            leftView.startDate = centerView.startDate.add(TimeChunk.dateComponents(weeks: -1))
            rightView.startDate = centerView.startDate.add(TimeChunk.dateComponents(weeks: 1))
        } else if daysFrom > daysInWeek - 1
        {
            currentWeekdayIndex = daysFrom % daysInWeek
            centerView.startDate = newStartDate
            centerView.selectedIndex = currentWeekdayIndex
            leftView.startDate = centerView.startDate.add(TimeChunk.dateComponents(weeks: -1))
            rightView.startDate = centerView.startDate.add(TimeChunk.dateComponents(weeks: 1))
        } else
        {
            currentWeekdayIndex = daysFrom
            centerView.selectedDate = newDate
            centerView.selectedIndex = currentWeekdayIndex
        }
    }
    else
    {
        moveToDate(currentPageScrollIndex: Int(pagingScrollView.currentIndex), newDate: newDate)

    }
}
    
    func moveToDate(currentPageScrollIndex:Int, newDate:Date)
    {
        let daysFromNextStartWeek = beginningOfWeek(newDate).days(from: beginningOfWeek(endDate), calendar: calendar)
        
        if(daysFromNextStartWeek >= 7)
        {
            return
        }
        
        let activeView = pagingScrollView.reusableViews[currentPageScrollIndex]
        let startDate = activeView.startDate.dateOnly()
        let daysFrom = newDate.days(from: startDate, calendar: calendar)
        
        if daysFrom < 0
        {
            pagingScrollView.scrollBackward()
            let updatedScrollIndex = currentPageScrollIndex - 1
            
            if(updatedScrollIndex > 0)
            {
                let activeView = pagingScrollView.reusableViews[updatedScrollIndex]
                let startDate = activeView.startDate.dateOnly()
                let daysFrom = newDate.days(from: startDate, calendar: calendar)
                
                if (daysFrom >= 0 && daysFrom <= daysInWeek - 1)
                {
                    currentWeekdayIndex = abs(daysInWeek + daysFrom % daysInWeek) % daysInWeek
                    activeView.selectedIndex = currentWeekdayIndex
                }
                else
                {
                    moveToDate(currentPageScrollIndex: updatedScrollIndex, newDate: newDate)
                }
            }else if(updatedScrollIndex == 0)
            {
                currentWeekdayIndex = abs(daysInWeek + daysFrom % daysInWeek) % daysInWeek
                activeView.selectedIndex = currentWeekdayIndex
            }

        } else if daysFrom > daysInWeek - 1
        {
            pagingScrollView.scrollForward()
            
            let updatedScrollIndex = currentPageScrollIndex + 1
            
            if(updatedScrollIndex < pagingScrollView.reusableViews.count)
            {
                let activeView = pagingScrollView.reusableViews[updatedScrollIndex]
                let startDate = activeView.startDate.dateOnly()
                let daysFrom = newDate.days(from: startDate, calendar: calendar)
                
                if (daysFrom >= 0 && daysFrom <= daysInWeek - 1)
                {
                    currentWeekdayIndex = daysFrom % daysInWeek
                    activeView.selectedIndex = currentWeekdayIndex
                }
                else
                {
                    moveToDate(currentPageScrollIndex: updatedScrollIndex, newDate: newDate)
                }
            }else if (updatedScrollIndex == pagingScrollView.reusableViews.count)
            {
                currentWeekdayIndex = daysFrom % daysInWeek
                activeView.selectedIndex = currentWeekdayIndex
            }

        } else
        {
            currentWeekdayIndex = daysFrom
            activeView.selectedDate = newDate
            activeView.selectedIndex = currentWeekdayIndex
        }
    }
}

extension DayHeaderView: PagingScrollViewDelegate
{
    func scrollviewCanRecenter(_ index: Int, scrollDirection:TSScrollDirection) -> Bool
    {
        if calendarTypeUpdated == calendarType.RegularCalendar
        {
            let activeView = pagingScrollView.reusableViews[index]
            
            let startDateOfNextWeek = activeView.startDate.add(TimeChunk.dateComponents(weeks: 1))
            
            if(startDate.isEarlier(than: activeView.startDate) && endDate.isLaterThanOrEqual(to: startDateOfNextWeek))
            {
                return true
            }else
            {
                return false
            }
        }
        else
        {
            return false
        }
    }
    
  func scrollviewDidScrollToViewAtIndex(_ index: Int)
  {
    let activeView = pagingScrollView.reusableViews[index]
    activeView.selectedIndex = currentWeekdayIndex

    switch calendarTypeUpdated
    {
        case .oneWeekCalendar:
            state?.client(client: self, didMoveTo: activeView.selectedDate!)

            break
        case .twoWeekCalendar:
            
            let firstWeekView = pagingScrollView.reusableViews[0]
            let secondWeekView = pagingScrollView.reusableViews[1]
            
            //firstWeekView.startDate = activeView.startDate.add(TimeChunk.dateComponents(weeks: 0))
            //secondWeekView.startDate = activeView.startDate.add(TimeChunk.dateComponents(weeks: 1))
            
            state?.client(client: self, didMoveTo: activeView.selectedDate!)
            
            break
        case .threeWeekCalendar:
            //let leftView = pagingScrollView.reusableViews[0]
            //let rightView = pagingScrollView.reusableViews[2]
            
            //leftView.startDate = activeView.startDate.add(TimeChunk.dateComponents(weeks: -1))
            //rightView.startDate = activeView.startDate.add(TimeChunk.dateComponents(weeks: 1))
            
            state?.client(client: self, didMoveTo: activeView.selectedDate!)
            
            break
        
        case .RegularCalendar:
            let leftView = pagingScrollView.reusableViews[0]
            let rightView = pagingScrollView.reusableViews[2]
            
            leftView.startDate = activeView.startDate.add(TimeChunk.dateComponents(weeks: -1))
            rightView.startDate = activeView.startDate.add(TimeChunk.dateComponents(weeks: 1))
            
            state?.client(client: self, didMoveTo: activeView.selectedDate!)
            
            break
    }

  }
}
