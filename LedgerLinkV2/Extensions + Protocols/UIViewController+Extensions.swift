//
//  UIViewController+Extensions.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-27.
//

import UIKit

// MARK: - UIViewController

extension UIViewController {
    /*! @fn showSpinner
     @brief Shows the please wait spinner.
     @param completion Called after the spinner has been hidden.
     */
    func showSpinner(message: String? = "Please Wait...\n\n\n\n", _ completion: (() -> Void)?) {
        DispatchQueue.main.async { [weak self] in
            let alertController = UIAlertController(title: nil, message: message,
                                                    preferredStyle: .alert)
            SaveAlertHandle.set(alertController)
            let spinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
            spinner.color = UIColor(ciColor: .black)
            spinner.center = CGPoint(x: alertController.view.frame.midX,
                                     y: alertController.view.frame.midY)
            spinner.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin,
                                        .flexibleLeftMargin, .flexibleRightMargin]
            spinner.startAnimating()
            alertController.view.addSubview(spinner)
            self?.present(alertController, animated: true, completion: completion)
        }
    }
    
    func showSpinner() {
        DispatchQueue.main.async { [weak self] in
            let alertController = UIAlertController(title: nil, message: "Please Wait...\n\n\n\n",
                                                    preferredStyle: .alert)
            SaveAlertHandle.set(alertController)
            let spinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
            spinner.color = UIColor(ciColor: .black)
            spinner.center = CGPoint(x: alertController.view.frame.midX,
                                     y: alertController.view.frame.midY)
            spinner.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin,
                                        .flexibleLeftMargin, .flexibleRightMargin]
            spinner.startAnimating()
            alertController.view.addSubview(spinner)
            self?.present(alertController, animated: true, completion: nil)
        }
    }
    
    /*! @fn hideSpinner
     @brief Hides the please wait spinner.
     @param completion Called after the spinner has been hidden.
     */
    func hideSpinner(_ completion: (() -> Void)?) {
        if let controller = SaveAlertHandle.get() {
            SaveAlertHandle.clear()
            DispatchQueue.main.async {
                controller.dismiss(animated: true, completion: completion)
            }
        } else {
            completion!()
        }
    }
    
    func hideSpinner() {
        if let controller = SaveAlertHandle.get() {
            SaveAlertHandle.clear()
            DispatchQueue.main.async {
                controller.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @objc func tapToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedToDismiss))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func tappedToDismiss() {
        view.endEditing(true)
    }
    
    /// Create an attributed strings using a symbol and a text
    func createAttributedString(imageString: String?, imageColor: UIColor?, text: String, textColor: UIColor? = UIColor.gray) -> NSMutableAttributedString {
        /// Add them to a mutable attributed string
        let mas = NSMutableAttributedString(string: "")
        
        /// Optional image attachment
        if let imageString = imageString, let imageColor = imageColor {
            let imageAttahment = NSTextAttachment()
            imageAttahment.image = UIImage(systemName: imageString)?.withTintColor(imageColor, renderingMode: .alwaysOriginal)
            let imageOffsetY: CGFloat = -5.0
            imageAttahment.bounds = CGRect(x: 0, y: imageOffsetY, width: imageAttahment.image!.size.width, height: imageAttahment.image!.size.height)
            let imageString = NSAttributedString(attachment: imageAttahment)
            mas.append(imageString)
        }
        
        let textString = NSAttributedString(string: text)
        mas.append(textString)

        
        /// Add attributes
        let rangeText = (mas.string as NSString).range(of: mas.string)
        mas.addAttributes([
            NSAttributedString.Key.foregroundColor: textColor,
            .font: UIFont.rounded(ofSize: 14, weight: .bold)
        ], range: rangeText)
        
        return mas
    }
    
    func createLabel(text: String, size: CGFloat = 18) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.rounded(ofSize: size, weight: .bold)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    func createTextField(placeHolderText: String, placeHolderImageString: String, height: CGFloat = 50, isPassword: Bool = false, delegate: UITextFieldDelegate? = nil) -> UITextField {
        let textField = UITextField()
        textField.font = UIFont.rounded(ofSize: 14, weight: .bold)
        textField.leftPadding()
        textField.delegate = delegate
        textField.textColor = .lightGray
        textField.isSecureTextEntry = isPassword
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.borderWidth = 0.5
        textField.layer.cornerRadius = 10
        textField.attributedPlaceholder = createAttributedString(imageString: placeHolderImageString, imageColor: .gray, text: placeHolderText)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: height).isActive = true
        return textField
    }
    
    func createTextView(placeHolderText: String, placeHolderImageString: String, height: CGFloat = 100, delegate: UITextViewDelegate? = nil) -> UITextView {
        let textView = UITextView()
        textView.delegate = delegate
        textView.textColor = .lightGray
        textView.backgroundColor = .clear
        textView.allowsEditingTextAttributes = true
        textView.autocorrectionType = .yes
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 0.5
        textView.layer.cornerRadius = 10
        textView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        textView.clipsToBounds = true
        textView.isScrollEnabled = true
        textView.font = UIFont.rounded(ofSize: 14, weight: .bold)
        textView.attributedText = createAttributedString(imageString: placeHolderImageString, imageColor: UIColor.gray, text: placeHolderText)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.heightAnchor.constraint(equalToConstant: height).isActive = true
        
        return textView
    }
    
    // Info box consists of a unit of text fields and text views
    func createInfoBoxView(title: String, subTitle: String, arrangedSubviews: [UIView]) -> UIView {
        let boxContainerView = UIView()
        boxContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        /// Event name and password
        let titleLabel = createLabel(text: title)
        boxContainerView.addSubview(titleLabel)
        
        let subtitleLabel = createLabel(text: subTitle, size: 12)
        subtitleLabel.textColor = .gray
        boxContainerView.addSubview(subtitleLabel)
        
        let lineView = UIView()
        lineView.layer.borderColor = UIColor.darkGray.cgColor
        lineView.layer.borderWidth = 0.5
        lineView.translatesAutoresizingMaskIntoConstraints = false
        boxContainerView.addSubview(lineView)
        
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        boxContainerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: boxContainerView.topAnchor, constant: 0),
            titleLabel.leadingAnchor.constraint(equalTo: boxContainerView.leadingAnchor, constant: 0),
            titleLabel.trailingAnchor.constraint(equalTo: boxContainerView.trailingAnchor, constant: 0),
            titleLabel.heightAnchor.constraint(equalToConstant: 25),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
            subtitleLabel.leadingAnchor.constraint(equalTo: boxContainerView.leadingAnchor, constant: 0),
            subtitleLabel.trailingAnchor.constraint(equalTo: boxContainerView.trailingAnchor, constant: 0),
            subtitleLabel.heightAnchor.constraint(equalToConstant: 20),
            
            lineView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            lineView.leadingAnchor.constraint(equalTo: boxContainerView.leadingAnchor, constant: 0),
            lineView.trailingAnchor.constraint(equalTo: boxContainerView.trailingAnchor, constant: 0),
            lineView.heightAnchor.constraint(equalToConstant: 0.5),
            
            stackView.topAnchor.constraint(equalTo: lineView.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: boxContainerView.leadingAnchor, constant: 0),
            stackView.trailingAnchor.constraint(equalTo: boxContainerView.trailingAnchor, constant: 0),
            stackView.bottomAnchor.constraint(equalTo: boxContainerView.bottomAnchor, constant: 0),
        ])
        
        return boxContainerView
    }

    
    func applyBarTintColorToTheNavigationBar(
        tintColor: UIColor = .black,
        titleTextColor: UIColor = .white
    ) {
        guard let navController = navigationController else { return }
        navController.isHiddenHairline = true
        
        // For comparison, apply the same barTintColor to the toolbar, which has been configured to be opaque.
        navController.toolbar.barTintColor = tintColor
        navController.toolbar.isTranslucent = true
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundImage = UIImage()
        appearance.backgroundColor = tintColor
        appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: titleTextColor, NSAttributedString.Key.font: UIFont.rounded(ofSize: 30, weight: .bold)]
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: titleTextColor]
        
        let navigationBarAppearance = navController.navigationBar
        navigationBarAppearance.prefersLargeTitles = true
        navigationBarAppearance.scrollEdgeAppearance = appearance
        navigationBarAppearance.standardAppearance = appearance
        navigationBarAppearance.tintColor = titleTextColor
        navigationBarAppearance.sizeToFit()
    }
    
    func applyTransparentBackgroundToTheNavigationBar(opacity: CGFloat, titleTextColor: UIColor, tintColor: UIColor) {
        var transparentBackground: UIImage
        
        /** The background of a navigation bar switches from being translucent to transparent when a background image is applied.
         The intensity of the background image's alpha channel is inversely related to the transparency of the bar.
         That is, a smaller alpha channel intensity results in a more transparent bar and vise-versa.
         Below, a background image is dynamically generated with the desired opacity.
         */
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 1),
                                               false,
                                               navigationController!.navigationBar.layer.contentsScale)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: opacity)
        UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
        transparentBackground = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        /** Use the appearance proxy to customize the appearance of UIKit elements.
         However changes made to an element's appearance proxy do not affect any existing instances of that element currently
         in the view hierarchy. Normally this is not an issue because you will likely be performing your appearance customizations in
         -application:didFinishLaunchingWithOptions:. However, this example allows you to toggle between appearances at runtime
         which necessitates applying appearance customizations directly to the navigation bar.
         */
        
        let appearance = UINavigationBarAppearance()
        appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: titleTextColor, NSAttributedString.Key.font: UIFont.rounded(ofSize: 30, weight: .bold)]
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: titleTextColor]
        
        let navigationBarAppearance = self.navigationController!.navigationBar
        navigationBarAppearance.setBackgroundImage(transparentBackground, for: .default)
        navigationBarAppearance.prefersLargeTitles = true
        navigationBarAppearance.standardAppearance = appearance
        navigationBarAppearance.sizeToFit()
        navigationBarAppearance.tintColor = tintColor
    }
    
    func applyGradientToTheNavigationBar(titleTextColor: UIColor = .white) {
        let gradientLayer = CAGradientLayer()
        var updatedFrame = self.navigationController!.navigationBar.bounds
        updatedFrame.size.height += view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        gradientLayer.frame = updatedFrame
//        gradientLayer.colors = [UIColor(red: 255/255, green: 159/255, blue: 159/255, alpha: 1).cgColor, UIColor(red: 139/255, green: 2/255, blue: 2/255, alpha: 1).cgColor]
        gradientLayer.colors = [UIColor.black.cgColor, UIColor.black.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.navigationController!.navigationBar.setBackgroundImage(image, for: UIBarMetrics.default)
        
        let appearance = navigationController!.navigationBar.standardAppearance.copy()
        appearance.backgroundImage = image
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: titleTextColor, NSAttributedString.Key.font: UIFont.rounded(ofSize: 30, weight: .bold)]
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    /// Configures the navigation bar to use an image as its background.
    func applyImageBackgroundToTheNavigationBar() {
        
        guard let bounds = navigationController?.navigationBar.bounds else { return }
        
        var backImageForDefaultBarMetrics =
        UIImage.gradientImage(bounds: bounds,
                              colors: [UIColor.systemBlue.cgColor, UIColor.systemFill.cgColor])
        var backImageForLandscapePhoneBarMetrics =
        UIImage.gradientImage(bounds: bounds,
                              colors: [UIColor.systemTeal.cgColor, UIColor.systemFill.cgColor])
        
        /** Both of the above images are smaller than the navigation bar's size.
         To enable the images to resize gracefully while keeping their content pinned to the bottom right corner of the bar, the images are
         converted into resizable images width edge insets extending from the bottom up to the second row of pixels from the top, and from the
         right over to the second column of pixels from the left. This results in the topmost and leftmost pixels being stretched when the images
         are resized. Not coincidentally, the pixels in these rows/columns are empty.
         */
        backImageForDefaultBarMetrics =
        backImageForDefaultBarMetrics.resizableImage(
            withCapInsets: UIEdgeInsets(top: 0,
                                        left: 0,
                                        bottom: backImageForDefaultBarMetrics.size.height - 1,
                                        right: backImageForDefaultBarMetrics.size.width - 1))
        backImageForLandscapePhoneBarMetrics =
        backImageForLandscapePhoneBarMetrics.resizableImage(
            withCapInsets: UIEdgeInsets(top: 0,
                                        left: 0,
                                        bottom: backImageForLandscapePhoneBarMetrics.size.height - 1,
                                        right: backImageForLandscapePhoneBarMetrics.size.width - 1))
        
        /** Use the appearance proxy to customize the appearance of UIKit elements. However changes made to an element's appearance
         proxy do not affect any existing instances of that element currently in the view hierarchy. Normally this is not an issue because you
         will likely be performing your appearance customizations in -application:didFinishLaunchingWithOptions:.
         However, this example allows you to toggle between appearances at runtime which necessitates applying appearance customizations
         directly to the navigation bar.
         */
        
        // Uncomment this line to use the appearance proxy to customize the appearance of UIKit elements.
        // let navigationBarAppearance =
        //      UINavigationBar.appearance(whenContainedInInstancesOf: [UINavigationController.self])
        /** The bar metrics associated with a background image determine when it is used.
         Use the background image associated with the Default bar metrics when a more suitable background image can't be found.
         
         The shorter variant of the navigation bar, that is used on iPhone when in landscape, uses the background image associated
         with the LandscapePhone bar metrics.
         */
        
        let navigationBarAppearance = self.navigationController!.navigationBar
        navigationBarAppearance.setBackgroundImage(backImageForDefaultBarMetrics, for: .default)
        navigationBarAppearance.setBackgroundImage(backImageForLandscapePhoneBarMetrics, for: .compact)
        navigationBarAppearance.setBackgroundImage(backImageForDefaultBarMetrics, for: .any, barMetrics: .default)
        navigationBarAppearance.largeContentImage = backImageForDefaultBarMetrics
        navigationBarAppearance.scalesLargeContentImage = true
    }
    
}

extension UIImage {
    static func gradientImage(bounds: CGRect, colors: [CGColor]) -> UIImage {
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors
        
        UIGraphicsBeginImageContext(gradient.bounds.size)
        gradient.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}


extension UINavigationController {
    var isHiddenHairline: Bool {
        get {
            guard let hairline = findHairlineImageViewUnder(navigationBar) else { return true }
            return hairline.isHidden
        }
        set {
            if let hairline = findHairlineImageViewUnder(navigationBar) {
                hairline.isHidden = newValue
            }
        }
    }
    
    private func findHairlineImageViewUnder(_ view: UIView) -> UIImageView? {
        if view is UIImageView && view.bounds.size.height <= 1.0 {
            return view as? UIImageView
        }
        
        for subview in view.subviews {
            if let imageView = self.findHairlineImageViewUnder(subview) {
                return imageView
            }
        }
        
        return nil
    }
}

// MARK: - SaveAlertHandle

private class SaveAlertHandle {
    static var alertHandle: UIAlertController?
    
    class func set(_ handle: UIAlertController) {
        alertHandle = handle
    }
    
    class func clear() {
        alertHandle = nil
    }
    
    class func get() -> UIAlertController? {
        return alertHandle
    }
}

// MARK: - UIView

extension UIView {
    var allSubviews: [UIView] {
        return self.subviews.flatMap { [$0] + $0.allSubviews }
    }
    
    func setFill() {
        guard let superview = superview else { return }
        self.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: superview.topAnchor),
            self.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            self.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
        ])
    }
    
    func roundCorners(topLeft: CGFloat = 0, topRight: CGFloat = 0, bottomLeft: CGFloat = 0, bottomRight: CGFloat = 0) {//(topLeft: CGFloat, topRight: CGFloat, bottomLeft: CGFloat, bottomRight: CGFloat) {
        let topLeftRadius = CGSize(width: topLeft, height: topLeft)
        let topRightRadius = CGSize(width: topRight, height: topRight)
        let bottomLeftRadius = CGSize(width: bottomLeft, height: bottomLeft)
        let bottomRightRadius = CGSize(width: bottomRight, height: bottomRight)
        let maskPath = UIBezierPath(shouldRoundRect: bounds, topLeftRadius: topLeftRadius, topRightRadius: topRightRadius, bottomLeftRadius: bottomLeftRadius, bottomRightRadius: bottomRightRadius)
        let shape = CAShapeLayer()
        shape.path = maskPath.cgPath
        layer.mask = shape
    }
}

// MARK: - UIBezierPath

extension UIBezierPath {
    convenience init(shouldRoundRect rect: CGRect, topLeftRadius: CGSize = .zero, topRightRadius: CGSize = .zero, bottomLeftRadius: CGSize = .zero, bottomRightRadius: CGSize = .zero){
        
        self.init()
        
        let path = CGMutablePath()
        
        let topLeft = rect.origin
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        
        if topLeftRadius != .zero{
            path.move(to: CGPoint(x: topLeft.x+topLeftRadius.width, y: topLeft.y))
        } else {
            path.move(to: CGPoint(x: topLeft.x, y: topLeft.y))
        }
        
        if topRightRadius != .zero{
            path.addLine(to: CGPoint(x: topRight.x-topRightRadius.width, y: topRight.y))
            path.addCurve(to:  CGPoint(x: topRight.x, y: topRight.y+topRightRadius.height), control1: CGPoint(x: topRight.x, y: topRight.y), control2:CGPoint(x: topRight.x, y: topRight.y+topRightRadius.height))
        } else {
            path.addLine(to: CGPoint(x: topRight.x, y: topRight.y))
        }
        
        if bottomRightRadius != .zero{
            path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y-bottomRightRadius.height))
            path.addCurve(to: CGPoint(x: bottomRight.x-bottomRightRadius.width, y: bottomRight.y), control1: CGPoint(x: bottomRight.x, y: bottomRight.y), control2: CGPoint(x: bottomRight.x-bottomRightRadius.width, y: bottomRight.y))
        } else {
            path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y))
        }
        
        if bottomLeftRadius != .zero{
            path.addLine(to: CGPoint(x: bottomLeft.x+bottomLeftRadius.width, y: bottomLeft.y))
            path.addCurve(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y-bottomLeftRadius.height), control1: CGPoint(x: bottomLeft.x, y: bottomLeft.y), control2: CGPoint(x: bottomLeft.x, y: bottomLeft.y-bottomLeftRadius.height))
        } else {
            path.addLine(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y))
        }
        
        if topLeftRadius != .zero{
            path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y+topLeftRadius.height))
            path.addCurve(to: CGPoint(x: topLeft.x+topLeftRadius.width, y: topLeft.y) , control1: CGPoint(x: topLeft.x, y: topLeft.y) , control2: CGPoint(x: topLeft.x+topLeftRadius.width, y: topLeft.y))
        } else {
            path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y))
        }
        
        path.closeSubpath()
        cgPath = path
    }
}
