//
//  OTKitIconLabel2.swift
//  opentable-iphone-otkit-components
//
//  Created by Christopher Brandow on 5/17/22.
//

import UIKit

/*
 ┌────────────────────────────────────────────────────────────────────────┐
 │ ██████  This `UILabel` subclass displays a single image w/i 24x24 pt   │
 │ ██████  and a single label. it center aligns when                      │
 │ ██████  text height is < than image height                             │
 │         and top aligns otherwise, like this                            │
 └────────────────────────────────────────────────────────────────────────┘

 ┌────────────────────────────────────────────────────────────────────────┐
 │ ██████                                                                 │
 │ ██████  it center aligns when text height is < than image height       │
 │ ██████                                                                 │
 └────────────────────────────────────────────────────────────────────────┘
 */
/// This UILabel subclass is an OTKit component, corresponding to "Inset Text Block Container"
/// It displays a single image w/i 24x24 pt and a single line of (attributed)text.
/// It center aligns image and label when text is a single line, and top aligns them when text is multi-line
/// Margin values is currently hard-coded to 8
/// It is IBDesignable, so it will render correctly in storyboards.
@IBDesignable // TBD if this works well with storyboards on non-M1
public class OTKitIconLabel2: UILabel {

    private enum LayoutStyle: Int {
        case roundedEntry = 0
        case smallWithoutInset = 1

        typealias RawValue = Int
    }

    @IBInspectable var layoutStyle: Int = 0 {
        didSet {
            self.setNeedsDisplay()
        }
    }

    private var layoutEnum: LayoutStyle { LayoutStyle(rawValue: self.layoutStyle) ?? .roundedEntry }

    @IBInspectable public var image: UIImage? {
        didSet { self.setNeedsDisplay() }
    }

    @IBInspectable public var debugImageBackground: Bool = false {
        didSet { self.setNeedsDisplay() }
    }


    override public var text: String? {
        didSet {
            super.text = text
            self.setNeedsDisplay()
        }
    }

    public var inset: CGFloat {
        switch self.layoutEnum {
        case .roundedEntry: return 8.0 // OTKit.Layout.smallSpacing
        case .smallWithoutInset: return 0.0
        }
    }

    private var imageTextSpacing: CGFloat {
        switch self.layoutEnum {
        case .roundedEntry: return 8.0 // OTKit.Layout.smallSpacing
        case .smallWithoutInset: return 4.0
        }
    }

    private var cornerRadius: CGFloat {
        switch self.layoutEnum {
        case .roundedEntry: return 8.0 // OTKit.Layout.smallSpacing
        case .smallWithoutInset: return 0.0
        }
    }

    private var iconEdge: CGFloat = 24.0 //OTKit.Layout.defaultIconEdge
    private var leftTextInset: CGFloat { self.imageTextSpacing + self.inset + self.iconEdge }

    private var padding: UIEdgeInsets {
        return self.hasText
        ? UIEdgeInsets(top: self.inset, left: self.leftTextInset, bottom: self.inset, right: self.inset)
        : UIEdgeInsets.zero
    }

    private var hasText: Bool {
        if self.text?.isEmpty == false {
            return true
        } else if let attLength = attributedText?.length,
                  attLength > 0
        {
            return true
        } else {
            return false
        }
    }

    var colorr: UIColor?
    override public var tintColor: UIColor! {
        didSet {
            self.colorr = self.tintColor
        }
    }

    public override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: self.padding))
        // the only issue is that we might need to adjust the padding so that it is always 8 above and below image for single line entries, rather than adjust it as i do below in draw(rect:)
    }

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
    }

    public override func draw(_ rect: CGRect) {

        guard let image = self.image
        else { return }

        self.drawRoundedBackgroundIfNeeded(for: rect)

        assert(image.size.width <= 24.0 && image.size.height <= 24.0, "This class is only to be used with images 24x24 or smaller")

        /// icon images smaller than 24x24 should be centered inside of 24x24 rect
        let xOffset = self.inset + (self.iconEdge - image.size.width)/2.0
        let rawYOffset = self.inset + (self.iconEdge - image.size.height)/2.0

        /// update yOffset if it is a single line
        let yOffset = rect.height > self.leftTextInset
            ? rawYOffset
            : (rect.height - image.size.height)/2.0
        let rawImageRect = CGRect(x: xOffset, y: yOffset, width: image.size.width, height: image.size.height)


        let imageRect = CGRect.rectWith(aspectRatio: image.size, insideRect: rawImageRect)
        self.drawDebugBackgroundForImageViewIfNeeded(in: imageRect)
        if let co = self.colorr {
            image.withTintColor(co).withRenderingMode(.alwaysTemplate).draw(in: imageRect)
        } else {
            image.draw(in: imageRect)

        }

        super.draw(rect) // super is called after everything else, so that text is drawn on top of background
    }

    /// two potential pitfalls here:
    /// 1. Won't play well with shadows around the rounded path
    /// 2. Technically, it would cover up anything behind it, but that should never happen, really
    private func drawRoundedBackgroundIfNeeded(for rect: CGRect) {
        if self.cornerRadius > 0,
           let backgroundcolor = self.backgroundColor {
            var superV = self.superview

            while superV != nil,
                    superV?.backgroundColor == nil {
                superV = superV?.superview
            }
            let backBack = superV?.backgroundColor ?? self.backgroundColor ?? UIColor.systemRed
            backBack.setFill()
            let backPath = UIBezierPath(rect: rect)
            backPath.fill()

            let roundedPath = UIBezierPath(roundedRect: rect, cornerRadius: self.cornerRadius)
            backgroundcolor.setFill()
            roundedPath.fill()
        }
    }

    private func drawDebugBackgroundForImageViewIfNeeded(in imageRect: CGRect) {
        if self.debugImageBackground {
            UIColor.orange.setFill()
            let imageBackgroundPath = UIBezierPath(rect: imageRect)
            imageBackgroundPath.fill()
        }
    }
    /// This determines the rectangle in which the text will be drawn
    public override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var textRect = super.textRect(forBounds: bounds.inset(by: self.padding), limitedToNumberOfLines: numberOfLines)
        guard textRect.height > 0, // empty label will produce size == .zero
              textRect.width > 0
        else { return textRect }
        textRect.size.height = max(textRect.height, self.iconEdge) // at least as high as the image
        return textRect.inset(by: self.padding.inverted())
    }
}

fileprivate extension UIEdgeInsets {
    func inverted() -> UIEdgeInsets {
        return UIEdgeInsets(top: -self.top, left: -self.left, bottom: -self.bottom, right: -self.right)
    }
}

fileprivate extension CGSize {
    func sizeThatFitsSize(_ aSize: CGSize) -> CGSize {
        let width = min(self.width*aSize.height/self.height, aSize.width)
        return CGSize(width: width, height: self.height*width/self.width)
    }
}

fileprivate extension CGRect {
    static func rectWith(aspectRatio: CGSize, insideRect rect: CGRect) -> CGRect{
        let sizeThatFits = aspectRatio.sizeThatFitsSize(rect.size)
        let imageRectX = rect.origin.x*sizeThatFits.width/rect.width
        let imageRectY = rect.origin.y*sizeThatFits.height/rect.height
        return CGRect(origin: CGPoint(x: imageRectX, y: imageRectY), size: sizeThatFits)
    }
}


