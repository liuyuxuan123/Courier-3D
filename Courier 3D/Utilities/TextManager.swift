/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Utility class for showing messages above the AR view.
 */

import Foundation
import ARKit

enum TextMessageType {
    case trackingStateEscalation
    case planeEstimation
    case contentPlacement
    case focusSquare
}

// Using an extension to get information for ARCamera
extension ARCamera.TrackingState {
    
    // Get the recommend operation string for the current state
    var recommendedOperationString: String? {
        switch self {
        case .limited(.excessiveMotion):
            return "Try slowing down your movement, or reset the session."
        case .limited(.insufficientFeatures):
            return "Try pointing at a flat surface, or reset the session."
        default:
            return nil
        }
    }
    
    // Get the prompt string for the current state
    var presentationString: String {
        switch self {
        case .notAvailable:
            return "TRACKING UNAVAILABLE"
        case .normal:
            return "TRACKING NORMAL"
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                return "TRACKING LIMITED\nToo much camera movement"
            case .insufficientFeatures:
                return "TRACKING LIMITED\nNot enough surface detail"
            case .initializing:
                return "Initializing AR Session"
            case .relocalizing:
                return "Relocalizing AR Object"
            }
        }
    }
    
}

// This TextManager Class is wroten for the ViewController and it cannot be reused for another class
class TextManager {
    
    // MARK: - Properties
    // TextManager have to stored as a Weak Object
    private weak var viewController: ViewController!
    
    // Timer for hiding messages
    private var messageHideTimer: Timer?
    
    // Timers for showing scheduled messages
    // Manage the time to let the massage box disappear
    // 4 timer corresponding to four states
    private var focusSquareMessageTimer: Timer?
    private var planeEstimationMessageTimer: Timer?
    private var contentPlacementMessageTimer: Timer?
    private var trackingStateFeedbackEscalationTimer: Timer?      // Timer for tracking state escalation
    
    let blurEffectViewTag = 100
    var schedulingMessagesBlocked = false
    var alertController: UIAlertController?
    
    // MARK: - Initialization
    
    init(viewController: ViewController) {
        self.viewController = viewController
    }
    
    // MARK: - Message Handling
    
    func showMessage(_ text: String, autoHide: Bool = true) {
        // Update UI have to be set in MainQueue
        DispatchQueue.main.async {
            // cancel any previous hide timer
            self.messageHideTimer?.invalidate()
            
            // set text
            // Task Manager will manage UILabel inside the viewcontroller
            // Add some protocol
            self.viewController.messageLabel.text = text
            
            // make sure status is showing
            self.showHideMessage(hide: false, animated: true)
            
            // This message will be hide automatically
            // So we have to set a timer to schedele it
            if autoHide {
                // Compute an appropriate amount of time to display the on screen message. According to https://en.wikipedia.org/wiki/Words_per_minute, adults read about 200 words per minute and the average English word is 5 characters long. So 1000 characters per minute / 60 = 15 characters per second.
                // We limit the duration to a range of 1-10 seconds.
                
                // let charCount = text.characters.count
                // characters property is deprecated using Array to convert a String to an Array of Character, than count the number of Characters
                let charCount = Array(text).count
                let displayDuration: TimeInterval = min(10, Double(charCount) / 15.0 + 1.0)
                // Using underbar to denote that we will ignore the input argument Timer
                // Using weak self to avoid memory cycle
                self.messageHideTimer = Timer.scheduledTimer(withTimeInterval: displayDuration,
                                                             repeats: false,
                                                             block: { [weak self] (_) in
                                                                self?.showHideMessage(hide: true, animated: true)
                })
            }
        }
    }
    
    func scheduleMessage(_ text: String, inSeconds seconds: TimeInterval, messageType: TextMessageType) {
        // Do not schedule a new message if a feedback escalation alert is still on screen.
        guard !schedulingMessagesBlocked else {
            return
        }
        // Schedule with timer depend on the message type
        // this part of code work better with RxSwift
        var timer: Timer?
        switch messageType {
        case .contentPlacement:
            timer = contentPlacementMessageTimer
        case .focusSquare:
            timer = focusSquareMessageTimer
        case .planeEstimation:
            timer = planeEstimationMessageTimer
        case .trackingStateEscalation:
            timer = trackingStateFeedbackEscalationTimer
        }
        
        // Fire former timer
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
        // After "seconds" second show the message on screen
        timer = Timer.scheduledTimer(withTimeInterval: seconds,
                                     repeats: false,
                                     block: { [weak self] ( _ ) in
                                        self?.showMessage(text)
                                        timer?.invalidate()
                                        timer = nil
        })
        switch messageType {
        case .contentPlacement:
            contentPlacementMessageTimer = timer
        case .focusSquare:
            focusSquareMessageTimer = timer
        case .planeEstimation:
            planeEstimationMessageTimer = timer
        case .trackingStateEscalation:
            trackingStateFeedbackEscalationTimer = timer
        }
    }
    
    func cancelScheduledMessage(forType messageType: TextMessageType) {
        var timer: Timer?
        switch messageType {
        case .contentPlacement:
            timer = contentPlacementMessageTimer
        case .focusSquare:
            timer = focusSquareMessageTimer
        case .planeEstimation:
            timer = planeEstimationMessageTimer
        case .trackingStateEscalation:
            timer = trackingStateFeedbackEscalationTimer
        }
        
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
    }
    
    // Cancel all scheduled messages
    func cancelAllScheduledMessages() {
        cancelScheduledMessage(forType: .contentPlacement)
        cancelScheduledMessage(forType: .planeEstimation)
        cancelScheduledMessage(forType: .trackingStateEscalation)
        cancelScheduledMessage(forType: .focusSquare)
    }
    
    // MARK: - ARKit
    
    func showTrackingQualityInfo(for trackingState: ARCamera.TrackingState, autoHide: Bool) {
        // trackingState.presentationString is the display string to show the current state of ARCamera
        showMessage(trackingState.presentationString, autoHide: autoHide)
    }
    
    
    // if current state is not good and after a couple of seconds the image condition have not been changed than provide some extra infomation
    func escalateFeedback(for trackingState: ARCamera.TrackingState, inSeconds seconds: TimeInterval) {
        if self.trackingStateFeedbackEscalationTimer != nil {
            self.trackingStateFeedbackEscalationTimer!.invalidate()
            self.trackingStateFeedbackEscalationTimer = nil
        }
        
        self.trackingStateFeedbackEscalationTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { _ in
            
            if let recommendation = trackingState.recommendedOperationString {
                self.showMessage(trackingState.presentationString + "\n" + recommendation, autoHide: false)
            } else {
                self.showMessage(trackingState.presentationString, autoHide: false)
            }
            
            self.trackingStateFeedbackEscalationTimer?.invalidate()
            self.trackingStateFeedbackEscalationTimer = nil
        })
    }
    
    // MARK: - Alert View
    
    func showAlert(title: String, message: String, actions: [UIAlertAction]? = nil) {
        
        // Present Alert via self.viewController 
        alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let actions = actions {
            for action in actions {
                alertController!.addAction(action)
            }
        } else {
            alertController!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        }
        DispatchQueue.main.async {
            self.viewController.present(self.alertController!, animated: true, completion: nil)
        }
    }
    
    func dismissPresentedAlert() {
        DispatchQueue.main.async {
            self.alertController?.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Background Blur
    
    func blurBackground() {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = viewController.view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.tag = blurEffectViewTag
        viewController.view.addSubview(blurEffectView)
    }
    
    func unblurBackground() {
        for view in viewController.view.subviews {
            if let blurView = view as? UIVisualEffectView, blurView.tag == blurEffectViewTag {
                blurView.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Panel Visibility
    
    private func showHideMessage(hide: Bool, animated: Bool) {
        
        if !animated {
            // if not animated
            // Directly set the isHidden to hide
            viewController.messageLabel.isHidden = hide
            return
        }
        
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState],
                       animations: {
                        self.viewController.messageLabel.isHidden = hide
                        self.updateMessagePanelVisibility()
        }, completion: nil)
    }
    
    private func updateMessagePanelVisibility() {
        // Show and hide the panel depending whether there is something to show.
        // If the label is hidden than directly hide the messagePanel
        viewController.messagePanel.isHidden = viewController.messageLabel.isHidden
    }
    
}

