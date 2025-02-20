import SnapKit
import UIKit

final class LaunchScreenViewController: UIViewController {
    private let mainImageView = UIImageView()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.bgPrimary
        mainImageView.image = UIImage(named: "launch_image")

        view.addSubviews(mainImageView)

        mainImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        var currentPercentage = 0
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            currentPercentage += 1
            if currentPercentage >= 100 {
                timer.invalidate()
            }
        }
    }
}
