import UIKit

protocol SelectImageViewDelegate: AnyObject {
    func didTapAddPhoto(sender: SelectImageView)
}

final class SelectImageView: UIControl {
    // MARK: - Properties
    
    let buttonContainer = UIImageView()
    let addButton = GeneralButton()
    weak var delegate: SelectImageViewDelegate?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        drawSelf()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        addDashedBorder(to: buttonContainer)
    }

    // MARK: - Private methods

    private func drawSelf() {
        buttonContainer.do { make in
            make.backgroundColor = UIColor.bgTertiary
            make.layer.cornerRadius = 12
            make.isUserInteractionEnabled = false
            make.layer.borderColor = UIColor.clear.cgColor
            make.layer.borderWidth = 2
            make.layer.masksToBounds = true
            make.isUserInteractionEnabled = true
            addDashedBorder(to: make)
        }
        
        addButton.do { make in
            make.addPhoto()
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapAddPhoto))
            make.addGestureRecognizer(tapGesture)
        }

        buttonContainer.addSubviews(addButton)
        addSubviews(buttonContainer)

        buttonContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
            make.height.equalTo(48)
        }
    }
    
    private func addDashedBorder(to view: UIView) {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor.accentSecondary.cgColor
        shapeLayer.lineDashPattern = [12, 12]
        shapeLayer.fillColor = nil
        shapeLayer.lineWidth = 2
        shapeLayer.frame = view.bounds
        shapeLayer.path = UIBezierPath(roundedRect: view.bounds, cornerRadius: 12).cgPath

        view.layer.addSublayer(shapeLayer)
    }
    
    @objc private func didTapAddPhoto() {
        delegate?.didTapAddPhoto(sender: self)
    }
    
    func firstImageMode() {
        addButton.addFirstImage()
        
        addButton.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(48)
        }
    }
    
    func secondImageMode() {
        addButton.addSecondImage()
        
        addButton.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(48)
        }
    }
    
    func addImage(image: UIImage) {
        buttonContainer.image = image
        addButton.isHidden = true
        let containerTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapAddPhoto))
        buttonContainer.addGestureRecognizer(containerTapGesture)
    }
}
