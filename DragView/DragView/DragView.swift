//
//  DragView.swift
//  DragView
//
//  Created by fashion on 2018/8/2.
//  Copyright © 2018年 shangZhu. All rights reserved.
//

import UIKit

public enum DragDirection: Int{
    case any = 0
    case horizontal
    case vertical
}
let kScreenH = UIScreen.main.bounds.height
let isIphoneX: Bool = kScreenH >= 812.0 ? true: false
let kStatusBarH: CGFloat = isIphoneX == true ? 44 : 20
let kSafeBottomH: CGFloat = isIphoneX == true ? 34 : 0
let kNavBarH: CGFloat = isIphoneX ? 88 : 64

@IBDesignable
class DragView: UIView {
    
    /// 是否能拖曳，默认为YES
    public var dragEnable: Bool = true
    
    /**
     活动范围，默认为父视图的frame范围内（因为拖出父视图后无法点击，也没意义）
     如果设置了，则会在给定的范围内活动
     如果没设置，则会在父视图范围内活动
     注意：设置的frame不要大于父视图范围
     注意：设置的frame为0，0，0，0表示活动的范围为默认的父视图frame，如果想要不能活动，请设置dragEnable这个属性为NO
     */
    public var freeRect: CGRect = CGRect.zero

    /// 拖曳的方向，默认为any，任意方向
    public var dragDirection: DragDirection = DragDirection.any
     

    /**
     是不是总保持在父视图边界，默认为NO,没有黏贴边界效果
     isKeepBounds = YES，它将自动黏贴边界，而且是最近的边界
     isKeepBounds = NO， 它将不会黏贴在边界，它是free(自由)状态，跟随手指到任意位置，但是也不可以拖出给定的范围frame
     */
    @IBInspectable
    public var isKeepBounds: Bool = false
    
    /// 是否可以拖出父类Rect
    @IBInspectable
    public var forbidenOutFree: Bool = true
    
    /// 父类是否是有导航栏,如果有禁止进入导航栏
    @IBInspectable
    public var hasNavagation: Bool = true
    
    /// 顶部禁止进入状态栏
    @IBInspectable
    public var forbidenEnterStatusBar: Bool = false
    
    /// 父类是否是UIViewController
    @IBInspectable
    public var fatherIsController: Bool = false
    
    /**
     contentView内部懒加载的一个UIImageView
     开发者也可以自定义控件添加到本view中
     注意：最好不要同时使用内部的imageView和button
     */
    public lazy var imageView: UIImageView = {
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
    public var clickDragViewBlock: ((DragView) -> ())?
    /// 开始拖动的回调block
    public var beginDragBlock: ((DragView) -> ())?
    /// 拖动中的回调block
    public var duringDragBlock: ((DragView) -> ())?
    /// 结束拖动的回调block
    public var endDragBlock: ((DragView) -> ())?
    
    
    private var leftMove: String = "leftMove"
    private var rightMove: String = "rightMove"
    
    /// 动画时长
    private var animationTime: TimeInterval = 0.5
    private var startPoint: CGPoint = CGPoint.zero
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    /// 禁止拖出父控件动画时长
    private var endaAimationTime: TimeInterval = 0.2
    
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
        if let superview = self.superview {
            freeRect = CGRect.init(origin: CGPoint.zero, size: superview.bounds.size)
        }
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
        clickDragViewBlock?(self)
    }
    
    /// 拖动事件
    @objc func dragAction(pan: UIPanGestureRecognizer){
        if dragEnable == false {
            return
        }
        
        switch pan.state {
        case .began:
            
            beginDragBlock?(self)
            
            // 注意完成移动后，将translation重置为0十分重要。否则translation每次都会叠加
            pan.setTranslation(CGPoint.zero, in: self)
            // 保存触摸起始点位置
            startPoint = pan.translation(in: self)
        case .changed:
            
            duringDragBlock?(self)
            // 计算位移 = 当前位置 - 起始位置
            
            // 禁止拖动到父类之外区域
            if forbidenOutFree == true && (frame.origin.x < 0 || frame.origin.x > freeRect.size.width - frame.size.width || frame.origin.y < 0 || frame.origin.y > freeRect.size.height - frame.size.height){
                var newframe: CGRect = self.frame
                if frame.origin.x < 0 {
                    newframe.origin.x = 0
                }else if frame.origin.x > freeRect.size.width - frame.size.width {
                    newframe.origin.x = freeRect.size.width - frame.size.width
                }
                if frame.origin.y < 0 {
                    newframe.origin.y = 0
                }else if frame.origin.y > freeRect.size.height - frame.size.height{
                    newframe.origin.y = freeRect.size.height - frame.size.height
                }
                
                UIView.animate(withDuration: endaAimationTime) {
                    self.frame = newframe
                }
                return
            }
            
            // 如果父类是控制器View 禁止进入状态栏
            if fatherIsController && forbidenEnterStatusBar && frame.origin.y < kStatusBarH {
                var newframe: CGRect = self.frame
                newframe.origin.y = kStatusBarH
                UIView.animate(withDuration: endaAimationTime) {
                    self.frame = newframe
                }
                return
            }
            // 如果父类是控制器View
            if fatherIsController && frame.origin.y > freeRect.size.height - frame.size.height - kSafeBottomH {
                var newframe: CGRect = self.frame
                newframe.origin.y = freeRect.size.height - frame.size.height - kSafeBottomH
                UIView.animate(withDuration: endaAimationTime) {
                    self.frame = newframe
                }
            }
            
            // 如果父类是控制器View 禁止进入导航栏
            if fatherIsController && hasNavagation && frame.origin.y < kNavBarH{
                var newframe: CGRect = self.frame
                newframe.origin.y = kNavBarH
                UIView.animate(withDuration: endaAimationTime) {
                    self.frame = newframe
                }
                return
            }
            
            
            let point: CGPoint = pan.translation(in: self)
            var dx: CGFloat = 0.0
            var dy: CGFloat = 0.0
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
            let newCenter: CGPoint = CGPoint.init(x: center.x + dx, y: center.y + dy)
            // 移动view
            center = newCenter
            // 注意完成上述移动后，将translation重置为0十分重要。否则translation每次都会叠加
            pan.setTranslation(CGPoint.zero, in: self)
            
        case .ended:
            keepBounds()
            endDragBlock?(self)
        default:
            break
        }
        
    }
    
    /// 黏贴边界效果
    private func keepBounds() {
        //中心点判断
        let centerX: CGFloat = freeRect.origin.x + (freeRect.size.width - frame.size.width)*0.5
        var rect: CGRect = self.frame
        if isKeepBounds == false {//没有黏贴边界的效果
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

        } else if isKeepBounds == true{//自动粘边
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

