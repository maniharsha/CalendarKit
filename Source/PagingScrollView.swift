import UIKit

protocol PagingScrollViewDelegate: class {
  func scrollviewDidScrollToViewAtIndex(_ index: Int)
    func scrollviewCanRecenter(_ index: Int, scrollDirection:TSScrollDirection) -> Bool
}

protocol ReusableView: class {
  func prepareForReuse()
}

enum TSScrollDirection:String{
    case ScrollDirectionNone
    case ScrollDirectionRight
    case ScrollDirectionLeft
}

class PagingScrollView<T: UIView>: UIScrollView, UIScrollViewDelegate where T: ReusableView {

  var reusableViews = [T]()
  weak var viewDelegate: PagingScrollViewDelegate?
  var calendarType:calendarType = .RegularCalendar
  var previousPage: CGFloat = 1
    var lastContentOffset:CGFloat = 0.0
    
  var currentScrollViewPage: CGFloat {
    get {
      let width = bounds.width
      let centerOffsetX = contentOffset.x + width / 2

      let result = centerOffsetX / width - 0.5
      // Return central page if impossible to calculate (View has no size yet)
      return result.isNaN ? 1 : result
    }
  }

  var accumulator: CGFloat = 0
  var currentIndex: CGFloat {
    return round(currentScrollViewPage) + accumulator
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    configure()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configure()
  }

  func configure() {
    isPagingEnabled = true
    isDirectionalLockEnabled = true
    showsHorizontalScrollIndicator = false
    showsVerticalScrollIndicator = false
    delegate = self
    lastContentOffset = contentOffset.x
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    realignViews()
  }

  func recenterIfNecessary() {
    if reusableViews.isEmpty { return }
    let contentWidth = contentSize.width
    let centerOffsetX = (contentWidth - bounds.size.width) / 2

    let distanceFromCenter = contentOffset.x - centerOffsetX

    if fabs(distanceFromCenter) > (contentWidth / 3) {
      recenter()
    }
  }

  func recenter() {
    let contentWidth = contentSize.width
    let centerOffsetX = (contentWidth - bounds.size.width) / 2
    let distanceFromCenter = contentOffset.x - centerOffsetX

    if distanceFromCenter > 0 {
      reusableViews.shift(1)
      accumulator += 1
      reusableViews.last!.prepareForReuse()
    } else if distanceFromCenter < 0 {
      reusableViews.shift(-1)
      accumulator -= 1
      reusableViews.first!.prepareForReuse()
    }
    contentOffset = CGPoint(x: centerOffsetX, y: contentOffset.y)
  }

  func realignViews() {
    for (index, subview) in reusableViews.enumerated() {
      subview.frame.origin.x = bounds.width * CGFloat(index)
      subview.frame.size = bounds.size
    }
  }

  func scrollForward() {
    setContentOffset(CGPoint(x: contentOffset.x + bounds.width, y: 0), animated: true)
  }

  func scrollBackward() {
    setContentOffset(CGPoint(x: contentOffset.x - bounds.width, y: 0), animated: true)
  }

  func checkForPageChange()
  {
    var scrollDirection:TSScrollDirection = .ScrollDirectionNone
    
    if(lastContentOffset > contentOffset.x)
    {
        scrollDirection = .ScrollDirectionRight
    }else if(lastContentOffset < contentOffset.x)
    {
        scrollDirection = .ScrollDirectionLeft
    }
    
    if (viewDelegate?.scrollviewCanRecenter(Int(currentScrollViewPage), scrollDirection: scrollDirection))!
    {
        recenter()
    }
    
    lastContentOffset = contentOffset.x
    
    viewDelegate?.scrollviewDidScrollToViewAtIndex(Int(currentScrollViewPage))
    
//    if currentIndex != previousPage
//    {
//      viewDelegate?.scrollviewDidScrollToViewAtIndex(Int(currentScrollViewPage))
//      previousPage = currentIndex
//    }
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if decelerate {return}
    checkForPageChange()
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    checkForPageChange()
  }

  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    checkForPageChange()
  }
}
