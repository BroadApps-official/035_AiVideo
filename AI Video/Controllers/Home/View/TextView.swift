import SnapKit
import UIKit

protocol TextViewDelegate: AnyObject {
    func didTapTextField(type: TextView.TextType)
}

final class TextView: UIControl {
    enum TextType {
        case promt
        case description

        var placeholder: String {
            switch self {
            case .promt: L.enterPromt
            case .description: ""
            }
        }

        var title: String? {
            switch self {
            case .promt: return nil
            case .description: return nil
            }
        }
    }

    private let type: TextType
    weak var delegate: TextViewDelegate?

    let textField = UITextField()
    let textView = UITextView()
    let placeholderLabel = UILabel()
    let surpriseButton = UIButton()
    let deleteButton = UIButton()

    init(type: TextType) {
        self.type = type
        super.init(frame: .zero)
        backgroundColor = .clear
        drawSelf()
        setupConstraints()
        configureButtonActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func drawSelf() {
        if type == .promt {
            backgroundColor = UIColor.bgTertiary
            layer.cornerRadius = 12

            surpriseButton.do { make in
                make.backgroundColor = UIColor.accentPrimaryAlpha
                make.setImage(UIImage(named: "surprise_icon"), for: .normal)
                make.setTitle(L.surpriseLabel, for: .normal)
                make.setTitleColor(UIColor.labelsPrimary, for: .normal)
                make.titleLabel?.font = UIFont.CustomFont.footnoteEmphasized
                make.layer.cornerRadius = 12
                make.isHidden = false
                make.addTarget(self, action: #selector(didTapSurpriseButton), for: .touchUpInside)
            }

            deleteButton.do { make in
                make.backgroundColor = UIColor.accentPrimaryAlpha
                make.setImage(UIImage(named: "delete_icon"), for: .normal)
                make.setTitle(L.delete, for: .normal)
                make.setTitleColor(UIColor.labelsPrimary, for: .normal)
                make.titleLabel?.font = UIFont.CustomFont.footnoteEmphasized
                make.layer.cornerRadius = 12
                make.isHidden = true
                make.addTarget(self, action: #selector(didTapDeleteButton), for: .touchUpInside)
            }

            textView.do { make in
                make.font = UIFont.CustomFont.bodyRegular
                make.textColor = UIColor.labelsPrimary
                make.textAlignment = .left
                make.backgroundColor = .clear
                make.delegate = self
                make.showsVerticalScrollIndicator = false
                make.showsHorizontalScrollIndicator = false
            }
            
            placeholderLabel.do { make in
                make.text = type.placeholder
                make.font = UIFont.CustomFont.bodyRegular
                make.textColor = UIColor.labelsQuaternary
                make.isHidden = !textView.text.isEmpty
                make.numberOfLines = 0
            }

            addSubviews(textView, placeholderLabel, surpriseButton, deleteButton)
        } else if type == .description {
            backgroundColor = UIColor.bgTertiary
            layer.cornerRadius = 12
            
            textView.do { make in
                make.font = UIFont.CustomFont.bodyRegular
                make.textColor = UIColor.labelsPrimary
                make.textAlignment = .left
                make.backgroundColor = .clear
                make.delegate = self
                make.showsVerticalScrollIndicator = false
                make.showsHorizontalScrollIndicator = false
                make.isEditable = false
                make.isUserInteractionEnabled = false
            }
            
            addSubviews(textView)
        }
    }

    private func setupConstraints() {
        if type == .promt {
            textView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(7)
                make.leading.trailing.equalToSuperview().inset(10)
            }
            
            placeholderLabel.snp.makeConstraints { make in
                make.top.equalTo(textView.snp.top).offset(7)
                make.leading.equalTo(textView.snp.leading).offset(5)
                make.trailing.equalTo(textView.snp.trailing).offset(-16)
            }
            
            surpriseButton.snp.makeConstraints { make in
                make.bottom.trailing.equalToSuperview().inset(16)
                make.height.equalTo(34)
                make.width.equalTo(125)
            }
            
            deleteButton.snp.makeConstraints { make in
                make.bottom.trailing.equalToSuperview().inset(16)
                make.height.equalTo(34)
                make.width.equalTo(85)
            }
        }  else if type == .description {
            textView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(7)
                make.leading.trailing.equalToSuperview().inset(10)
            }
        }
    }

    private func configureButtonActions() {
        textView.delegate = self
        textView.isEditable = true
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidChangeNotification(_:)), name: UITextView.textDidChangeNotification, object: textView)
        addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        addTarget(self, action: #selector(didTapButton), for: .touchUpOutside)

        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    private func updateButtonVisibility() {
        let hasText = !textView.text.isEmpty
        surpriseButton.isHidden = hasText
        deleteButton.isHidden = !hasText
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        delegate?.didTapTextField(type: type)
        updateButtonVisibility()
    }

    @objc private func didTapButton() {
        delegate?.didTapTextField(type: type)
    }

    @objc private func textViewDidChangeNotification(_ notification: Notification) {
        if let textView = notification.object as? UITextView {
            placeholderLabel.isHidden = !textView.text.isEmpty
            delegate?.didTapTextField(type: type)
            updateButtonVisibility()
        }
    }
    
    @objc private func didTapSurpriseButton() {
        textView.text = "A girl walking through the evening city in pink tones"
        placeholderLabel.isHidden = !textView.text.isEmpty
        delegate?.didTapTextField(type: type)
        updateButtonVisibility()
    }

    @objc private func didTapDeleteButton() {
        textView.text = ""
        placeholderLabel.isHidden = !textView.text.isEmpty
        delegate?.didTapTextField(type: type)
        updateButtonVisibility()
    }
}

// MARK: - UITextViewDelegate
extension TextView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        delegate?.didTapTextField(type: type)
    }
}
