import Foundation
import AudioToolbox

@objc(CAPSplashScreenPlugin)
public class CAPSplashScreenPlugin: CAPPlugin {
    var viewController = UIViewController()
    var spinner = UIActivityIndicatorView()
    var showSpinner: Bool = false
    var call: CAPPluginCall?
    var hideTask: Any?
    var isVisible: Bool = false

    let launchShowDuration = 3000
    let launchAutoHide = true

    let defaultFadeInDuration = 200
    let defaultFadeOutDuration = 200
    let defaultShowDuration = 3000
    let defaultAutoHide = true

    override public func load() {
        buildViews()
        showOnLaunch()
    }

    // Show the splash screen
    @objc public func show(_ call: CAPPluginCall) {
        self.call = call

        let showDuration = call.get("showDuration", Int.self, defaultShowDuration)!
        let fadeInDuration = call.get("fadeInDuration", Int.self, defaultFadeInDuration)!
        let fadeOutDuration = call.get("fadeOutDuration", Int.self, defaultFadeOutDuration)!
        let autoHide = call.get("autoHide", Bool.self, defaultAutoHide)!
        let backgroundColor = getConfigValue("backgroundColor") as? String ?? nil
        let spinnerStyle = getConfigValue("iosSpinnerStyle") as? String ?? nil
        let spinnerColor = getConfigValue("spinnerColor") as? String ?? nil
        showSpinner = getConfigValue("showSpinner") as? Bool ?? false

        showSplash(showDuration: showDuration,
                   fadeInDuration: fadeInDuration,
                   fadeOutDuration: fadeOutDuration,
                   autoHide: autoHide,
                   backgroundColor: backgroundColor,
                   spinnerStyle: spinnerStyle,
                   spinnerColor: spinnerColor,
                   completion: {
                    call.success()
        }, isLaunchSplash: false)
    }

    // Hide the splash screen
    @objc public func hide(_ call: CAPPluginCall) {
        self.call = call
        let fadeDuration = call.get("fadeOutDuration", Int.self, defaultFadeOutDuration)!
        hideSplash(fadeOutDuration: fadeDuration)
        call.success()
    }

    func buildViews() {
        viewController = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()!

        // Observe for changes on frame and bounds to handle rotation resizing
        let parentView = bridge?.viewController?.view
        parentView?.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
        parentView?.addObserver(self, forKeyPath: "bounds", options: .new, context: nil)

        updateSplashImageBounds()
        showSpinner = getConfigValue("showSpinner") as? Bool ?? false
        if showSpinner {
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.startAnimating()
        }
    }

    func tearDown() {
        isVisible = false
        bridge?.viewController?.view.isUserInteractionEnabled = true
        viewController.view.removeFromSuperview()

        if showSpinner {
            spinner.removeFromSuperview()
        }
    }

    // Update the bounds for the splash image. This will also be called when
    // the parent view observers fire
    func updateSplashImageBounds() {
        guard let delegate = UIApplication.shared.delegate else {
            bridge?.modulePrint(self, "Unable to find root window object for SplashScreen bounds. Please file an issue")
            return
        }

        guard let window = delegate.window as? UIWindow else {
            bridge?.modulePrint(self, "Unable to find root window object for SplashScreen bounds. Please file an issue")
            return
        }
        viewController.view.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: window.bounds.size)
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change _: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        updateSplashImageBounds()
    }

    func showOnLaunch() {
        let launchShowDurationConfig = getConfigValue("launchShowDuration") as? Int ?? launchShowDuration
        let launchAutoHideConfig = getConfigValue("launchAutoHide") as? Bool ?? launchAutoHide
        let launchBackgroundColorConfig = getConfigValue("backgroundColor") as? String ?? nil
        let launchSpinnerStyleConfig = getConfigValue("iosSpinnerStyle") as? String ?? nil
        let launchSpinnerColorConfig = getConfigValue("spinnerColor") as? String ?? nil

        if launchShowDurationConfig == 0 {
            return
        }

        let view = bridge?.viewController?.view
        view?.addSubview(viewController.view)

        if showSpinner {
            view?.addSubview(spinner)
            spinner.centerXAnchor.constraint(equalTo: view!.centerXAnchor).isActive = true
            spinner.centerYAnchor.constraint(equalTo: view!.centerYAnchor).isActive = true
        }

        showSplash(showDuration: launchShowDurationConfig,
                   fadeInDuration: 0,
                   fadeOutDuration: defaultFadeOutDuration,
                   autoHide: launchAutoHideConfig,
                   backgroundColor: launchBackgroundColorConfig,
                   spinnerStyle: launchSpinnerStyleConfig,
                   spinnerColor: launchSpinnerColorConfig,
                   completion: {},
                   isLaunchSplash: true)
    }

    // disable linting for the large number of parameters, since this is meant to be an internal method.
    // although a struct might be a better refactor in the future.
    // swiftlint:disable:next function_parameter_count
    func showSplash(showDuration: Int, fadeInDuration: Int, fadeOutDuration: Int, autoHide: Bool, backgroundColor: String?, spinnerStyle: String?, spinnerColor: String?, completion: @escaping () -> Void, isLaunchSplash: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self, let view = strongSelf.bridge?.viewController?.view else {
                return
            }
            if backgroundColor != nil {
                strongSelf.viewController.view.backgroundColor = UIColor.capacitor.color(fromHex: backgroundColor!)
            }

            if strongSelf.showSpinner {
                if spinnerStyle != nil {
                    switch spinnerStyle!.lowercased() {
                    case "small":
                        strongSelf.spinner.style = .white
                    default:
                        strongSelf.spinner.style = .whiteLarge
                    }
                }

                if spinnerColor != nil {
                    strongSelf.spinner.color = UIColor.capacitor.color(fromHex: spinnerColor!)
                }
            }

            if !isLaunchSplash {
                view.addSubview(strongSelf.viewController.view)

                if strongSelf.showSpinner {
                    view.addSubview(strongSelf.spinner)
                    strongSelf.spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
                    strongSelf.spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
                }
            }

            view.isUserInteractionEnabled = false

            UIView.transition(with: strongSelf.viewController.view, duration: TimeInterval(Double(fadeInDuration) / 1000), options: .curveLinear, animations: {
                strongSelf.viewController.view.alpha = 1

                if strongSelf.showSpinner {
                    strongSelf.spinner.alpha = 1
                }
            }) { (_: Bool) in
                strongSelf.isVisible = true

                if autoHide {
                    strongSelf.hideTask = DispatchQueue.main.asyncAfter(
                        deadline: DispatchTime.now() + (Double(showDuration) / 1000)
                    ) {
                        strongSelf.hideSplash(fadeOutDuration: fadeOutDuration, isLaunchSplash: isLaunchSplash)
                        completion()
                    }
                } else {
                    completion()
                }
            }
        }
    }

    func hideSplash(fadeOutDuration: Int) {
        hideSplash(fadeOutDuration: fadeOutDuration, isLaunchSplash: false)
    }

    func hideSplash(fadeOutDuration: Int, isLaunchSplash: Bool) {
        if isLaunchSplash, isVisible {
            CAPLog.print("SplashScreen.hideSplash: SplashScreen was automatically hidden after default timeout. " +
                "You should call `SplashScreen.hide()` as soon as your web app is loaded (or increase the timeout). " +
                "Read more at https://capacitorjs.com/docs/apis/splash-screen#hiding-the-splash-screen")
        }
        if !isVisible { return }
        DispatchQueue.main.async {
            UIView.transition(with: self.viewController.view, duration: TimeInterval(Double(fadeOutDuration) / 1000), options: .curveLinear, animations: {
                self.viewController.view.alpha = 0

                if self.showSpinner {
                    self.spinner.alpha = 0
                }
            }) { (_: Bool) in
                self.tearDown()
            }
        }
    }
}
