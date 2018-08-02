//
//  DragView.swift
//  DragView
//
//  Created by fashion on 2018/8/2.
//  Copyright © 2018年 shangZhu. All rights reserved.
//

import UIKit

enum DragDirection {
    case any
    case horizontal
    case vertical
}

@IBDesignable
class DragView: UIView {
    
    /// 是否能拖曳，默认为YES
    var dragEnable : Bool = true
    
    /**
     活动范围，默认为父视图的frame范围内（因为拖出父视图后无法点击，也没意义）
     如果设置了，则会在给定的范围内活动
     如果没设置，则会在父视图范围内活动
     注意：设置的frame不要大于父视图范围
     注意：设置的frame为0，0，0，0表示活动的范围为默认的父视图frame，如果想要不能活动，请设置dragEnable这个属性为NO
     */
    var freeRect : CGRect = CGRect.zero

    /// 拖曳的方向，默认为any，任意方向
    var dragDirection : DragDirection = DragDirection.any
     
    
    var isKeepBounds_ : Bool = false
    /**
     是不是总保持在父视图边界，默认为NO,没有黏贴边界效果
     isKeepBounds = YES，它将自动黏贴边界，而且是最近的边界
     isKeepBounds = NO， 它将不会黏贴在边界，它是free(自由)状态，跟随手指到任意位置，但是也不可以拖出给定的范围frame
     */
    @IBInspectable
    var isKeepBounds : Bool = false {
        didSet{
            isKeepBounds_ = isKeepBounds
        }
    }
    
    /**
     contentView内部懒加载的一个UIImageView
     开发者也可以自定义控件添加到本view中
     注意：最好不要同时使用内部的imageView和button
     */
    lazy var imageView: UIImageView = {
        let imageV = UIImageView.init()
        imageV.isUserInteractionEnabled = true
        imageV.clipsToBounds = true
        contentViewForDrag.addSubview(imageV)
        return imageV
    }()
    /**
     contentView内部懒加载的一个UIButton
     开发者也可以自定义控件添加到本view中
     注意：最好不要同时使用内部的imageView和button
     */
    @objc lazy var button: UIButton = {
        let btn = UIButton.init()
        btn.clipsToBounds = true
        contentViewForDrag.addSubview(btn)
        return btn
    }()
    @objc lazy var contentViewForDrag: UIView = {
        let contentV = UIView.init()
        contentV.clipsToBounds = true
        self.addSubview(contentV)
        return contentV
    }()
    
    /// 点击的回调block
    var clickDragViewBlock : ((DragView) -> ())?
    /// 开始拖动的回调block
    var beginDragBlock : ((DragView) -> ())?
    /// 拖动中的回调block
    var duringDragBlock : ((DragView) -> ())?
    /// 结束拖动的回调block
    var endDragBlock : ((DragView) -> ())?
    
    
    private var leftMove : String = "leftMove"
    private var rightMove : String = "rightMove"
    
    /// 动画时长
    private var animationTime : TimeInterval = 0.5
    private var startPoint : CGPoint = CGPoint.zero
    private var panGestureRecognizer : UIPanGestureRecognizer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
//        if freeRect.origin.x != 0 || freeRect.origin.y != 0 || freeRect.size.height != 0 || freeRect.size.width != 0 {
//            //设置了freeRect--活动范围
//        } else { //没有设置freeRect--活动范围，则设置默认的活动范围为父视图的frame
//            if let superview = self.superview {
//                freeRect = CGRect.init(origin: CGPoint.zero, size: superview.bounds.size)
//            }
//        }
        contentViewForDrag.frame = CGRect.init(origin: CGPoint.zero, size: self.bounds.size)
        button.frame = CGRect.init(origin: CGPoint.zero, size: self.bounds.size)
        imageView.frame = CGRect.init(origin: CGPoint.zero, size: self.bounds.size)
        
    }
    
    func setup() {
        // 默认为父视图的frame范围内
        if let superview = self.superview {
            freeRect = CGRect.init(origin: CGPoint.zero, size: superview.bounds.size)
        }
        self.clipsToBounds = true
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(clickDragView))
        self.addGestureRecognizer(singleTap)
        
        panGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(dragAction(pan:)))
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        self.addGestureRecognizer(panGestureRecognizer)
    }
    // 点击事件
    @objc func clickDragView() {
        if let block = clickDragViewBlock {
            block(self)
        }
    }
    
    /// 拖动事件
    @objc func dragAction(pan : UIPanGestureRecognizer){
        if dragEnable == false {
            return
        }
        
        switch pan.state {
        case .began:
            if let beginDragBlock = beginDragBlock {
                beginDragBlock(self)
            }
            // 注意完成移动后，将translation重置为0十分重要。否则translation每次都会叠加
            pan.setTranslation(CGPoint.zero, in: self)
            // 保存触摸起始点位置
            startPoint = pan.translation(in: self)
        case .changed:
             // 计算位移 = 当前位置 - 起始位置
            if let duringDragBlock = duringDragBlock {
                duringDragBlock(self)
            }
            let point : CGPoint = pan.translation(in: self)
            var dx : CGFloat = 0.0
            var dy : CGFloat = 0.0
            switch dragDirection {
            case .any:
                dx = point.x - startPoint.x
                dy = point.y - startPoint.y
            case .horizontal:
                dx = point.x - startPoint.x
                dy = 0
            case .vertical:
                dx = 0
                dy = point.y - startPoint.y
            }
            // 计算移动后的view中心点
            let newCenter : CGPoint = CGPoint.init(x: center.x + dx, y: center.y + dy)
            // 移动view
            center = newCenter
            // 注意完成上述移动后，将translation重置为0十分重要。否则translation每次都会叠加
            pan.setTranslation(CGPoint.zero, in: self)
            
        case .ended:
            keepBounds()
            if let endDragBlock = endDragBlock {
                endDragBlock(self)
            }
        default :
            break
        }
        
    }
    
    /// 黏贴边界效果
    private func keepBounds() {
        //中心点判断
        let centerX : CGFloat = freeRect.origin.x + (freeRect.size.width - frame.size.width)*0.5
        var rect : CGRect = self.frame
        if isKeepBounds_ == false {//没有黏贴边界的效果
            if frame.origin.x < freeRect.origin.x {

                UIView.beginAnimations(leftMove, context: nil)
                UIView.setAnimationCurve(.easeInOut)
                UIView.setAnimationDuration(animationTime)
                rect.origin.x = freeRect.origin.x
                self.frame = rect
                UIView.commitAnimations()
            }else if freeRect.origin.x + freeRect.size.width < frame.origin.x + frame.size.width{
                
                UIView.beginAnimations(rightMove, context: nil)
                UIView.setAnimationCurve(.easeInOut)
                UIView.setAnimationDuration(animationTime)
                rect.origin.x = freeRect.origin.x + freeRect.size.width - frame.size.width
                self.frame = rect
                UIView.commitAnimations()
            }
        } else if isKeepBounds_ == true{//自动粘边
            if frame.origin.x < centerX {
                
                UIView.beginAnimations(leftMove, context: nil)
                UIView.setAnimationCurve(.easeInOut)
                UIView.setAnimationDuration(animationTime)
                rect.origin.x = freeRect.origin.x
                self.frame = rect
                UIView.commitAnimations()
            }else{
                
                UIView.beginAnimations(rightMove, context: nil)
                UIView.setAnimationCurve(.easeInOut)
                UIView.setAnimationDuration(animationTime)
                rect.origin.x = freeRect.origin.x + freeRect.size.width - frame.size.width
                self.frame = rect
                UIView.commitAnimations()
            }
        }
        
        if frame.origin.y < freeRect.origin.y {
            UIView.beginAnimations("topMove", context: nil)
            UIView.setAnimationCurve(.easeInOut)
            UIView.setAnimationDuration(animationTime)
            rect.origin.y = freeRect.origin.y
            self.frame = rect
            UIView.commitAnimations()
        }else if freeRect.origin.y + freeRect.size.height <  frame.origin.y + frame.size.height {
            UIView.beginAnimations("bottomMove", context: nil)
            UIView.setAnimationCurve(.easeInOut)
            UIView.setAnimationDuration(animationTime)
            rect.origin.y = freeRect.origin.y + freeRect.size.height - frame.size.height
            self.frame = rect
            UIView.commitAnimations()
        }
        
    }
    
    

}

