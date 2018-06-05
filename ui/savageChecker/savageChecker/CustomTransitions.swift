//
//  CustomTransitions.swift
//  savageChecker
//
//  Created by Sam Hooper on 6/4/18.
//  Copyright © 2018 Sam Hooper. All rights reserved.
//

import UIKit


class CustomHorizontalTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    let duration: TimeInterval = 0.5
    var dismiss = false
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        
        if dismiss {
            let toView = transitionContext.view(forKey: .to)!
            
            container.addSubview(toView)
            toView.frame.origin = CGPoint(x: toView.frame.width, y: 0)
            
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
                toView.frame.origin = CGPoint(x: 0, y: 0)
            }, completion: { _ in
                transitionContext.completeTransition(true)
            })
        } else {
            let fromView = transitionContext.view(forKey: .from)!
            
            container.addSubview(fromView)
            fromView.frame.origin = .zero
            
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn, animations: {
                fromView.frame.origin = CGPoint(x: fromView.frame.width, y: 0)
            }, completion: { _ in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(true)
            })
        }
    }
}
    

class RightToLeftTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let duration: TimeInterval = 0.5
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)!
        
        container.addSubview(toView)
        toView.frame.origin = CGPoint(x: toView.frame.width, y: 0)
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
            toView.frame.origin = CGPoint(x: 0, y: 0)
        }, completion: { _ in
            transitionContext.completeTransition(true)
        })
    }
}

class LeftToRightTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let duration: TimeInterval = 0.5
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        let fromView = transitionContext.view(forKey: .from)!
        
        container.addSubview(fromView)
        fromView.frame.origin = .zero
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn, animations: {
            fromView.frame.origin = CGPoint(x: fromView.frame.width, y: 0)
        }, completion: { _ in
            fromView.removeFromSuperview()
            transitionContext.completeTransition(true)
        })
    }
}


extension BaseFormViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        print("presenting")
        return presentTransition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissTransition
    }
}

extension BaseTableViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        print("Transition will be present")
        return presentTransition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        print("Transition will be dismiss")
        return dismissTransition
    }
}
