import UIKit

class KeyboardManager {
    static let shared = KeyboardManager()

    private weak var viewController: UIViewController?
    private weak var targetView: UIView?
    private var textFieldsToMove: [UITextField] = []
    private var textViewsToMove: [UITextView] = []

    private var moveableView: UIView?
    private var originalYPosition: CGFloat = 0
    private var isFromOnboarding: Bool

    private init() {
        isFromOnboarding = false
    }

    func configureKeyboard(for viewController: UIViewController, targetView: UIView? = nil, textFields: [UITextField] = [], textViews: [UITextView] = [], moveFor textFieldsToMove: [UITextField] = [], moveFor textViewsToMove: [UITextView] = [], with returnType: UIReturnKeyType) {
        self.viewController = viewController
        self.targetView = targetView
        self.textFieldsToMove = textFieldsToMove
        self.textViewsToMove = textViewsToMove

        let tapGesture = UITapGestureRecognizer(target: viewController.view, action: #selector(UIView.endEditing(_:)))
        tapGesture.cancelsTouchesInView = false
        viewController.view.addGestureRecognizer(tapGesture)

        for textField in textFields {
            textField.returnKeyType = returnType
            textField.delegate = viewController as? UITextFieldDelegate
        }
        
        for textView in textViews {
            textView.delegate = viewController as? UITextViewDelegate
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let viewController = viewController else { return }

        let activeView = textFieldsToMove.first(where: { $0.isFirstResponder }) ?? textViewsToMove.first(where: { $0.isFirstResponder })

        if let activeView = activeView {
            guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }

            let targetFrame = activeView.convert(activeView.bounds, to: viewController.view)

            let screenHeight = UIScreen.main.bounds.height
            let keyboardHeight = keyboardFrame.height
            var coefficient: CGFloat

            if UIDevice.isIphoneBelowX {
                coefficient = (keyboardHeight / 2.9) / screenHeight
            } else {
                coefficient = (keyboardHeight / 2.3) / screenHeight
            }

            let distanceToKeyboard = (keyboardFrame.origin.y - targetFrame.maxY) - screenHeight * coefficient

            if distanceToKeyboard < 0 {
                viewController.view.frame.origin.y = distanceToKeyboard
            } else if distanceToKeyboard > 0 {
                viewController.view.frame.origin.y = 0
            }
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        guard let viewController = viewController else { return }

        viewController.view.frame.origin.y = 0
        
        for textView in textViewsToMove {
            if let appTextFieldView = textView.superview as? TextView {
                appTextFieldView.placeholderLabel.isHidden = !textView.text.isEmpty
            }
        }
    }
}

extension KeyboardManager {
    func configureKeyboardForProfile(for viewController: UIViewController, targetView: UIView?, moveFor moveableView: UIView, with returnType: UIReturnKeyType, isFromOnboarding: Bool) {
        self.viewController = viewController
        self.isFromOnboarding = isFromOnboarding
        self.targetView = targetView
        self.moveableView = moveableView
        originalYPosition = moveableView.frame.origin.y

        let tapGesture = UITapGestureRecognizer(target: viewController.view, action: #selector(UIView.endEditing(_:)))
        viewController.view.addGestureRecognizer(tapGesture)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowForProfile(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideForProfile(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        
        viewController = nil
        targetView = nil
        moveableView = nil
    }

    @objc func keyboardWillShowForProfile(_ notification: Notification) {
        guard let moveableView = moveableView,
              let viewController = viewController else { return }

        if let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let topOfKeyboard = keyboardFrame.origin.y
            let moveableViewHeight = moveableView.frame.height

            let targetYPosition: CGFloat

            if UIDevice.isIphoneBelowX {
                targetYPosition = topOfKeyboard - moveableView.frame.height - moveableViewHeight
            } else {
                targetYPosition = topOfKeyboard - moveableView.frame.height - (moveableViewHeight + 24)
            }

            if moveableView.superview != viewController.view {
                viewController.view.addSubview(moveableView)
            }

            moveableView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(targetYPosition)
                make.leading.trailing.equalToSuperview().inset(16)
                make.height.equalTo(56)
            }

            UIView.animate(withDuration: 0.3) {
                viewController.view.layoutIfNeeded()
                moveableView.isHidden = false
            }
        }
    }

    @objc func keyboardWillHideForProfile(_ notification: Notification) {
        guard let moveableView = moveableView else { return }

        if isFromOnboarding {
            moveableView.isHidden = false
        } else {
            moveableView.isHidden = true
        }

        moveableView.snp.remakeConstraints { make in
            make.bottom.equalToSuperview().offset(-31)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(56)
        }

        UIView.animate(withDuration: 0.3) {
            self.viewController?.view.layoutIfNeeded()
        }
    }
}
