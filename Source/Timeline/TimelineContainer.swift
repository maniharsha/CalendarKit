import UIKit

public class TimelineContainer: UIScrollView, ReusableView {
  
  public let timeline: TimelineView
  
  public init(_ timeline: TimelineView) {
    self.timeline = timeline
    super.init(frame: .zero)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override public func layoutSubviews() {
    timeline.frame = CGRect(x: 0, y: 0, width: width, height: timeline.fullHeight)
  }
  
  public func prepareForReuse() {
    timeline.prepareForReuse()
  }
  
  public func scrollToFirstEvent() {
    if let yToScroll = timeline.firstEventYPosition {
      setTimelineOffset(CGPoint(x: contentOffset.x, y: yToScroll - 15), animated: true)
    }
  }
  
  public func scrollTo(hour24: Float) {
    let percentToScroll = CGFloat(hour24 / 28)
    let yToScroll = contentSize.height * percentToScroll
    let padding: CGFloat = 8
    setTimelineOffset(CGPoint(x: contentOffset.x, y: yToScroll - padding), animated: true)
  }

  private func setTimelineOffset(_ offset: CGPoint, animated: Bool) {
    let yToScroll = offset.y
    let bottomOfScrollView = contentSize.height - bounds.size.height
    let newContentY = (yToScroll < bottomOfScrollView) ? yToScroll : bottomOfScrollView
    setContentOffset(CGPoint(x: offset.x, y: newContentY), animated: animated)
  }
}
