import UIKit
import SafariServices

class WallpaperViewController: UIViewController {
    var unsplash: Unsplash?
    
    weak var delegate: WallpaperViewControllerDelegate?
    
    var setupWasCompleted = false
    
    private var downloadLocation: URL?
    private var photographerProfile: URL?
    
    private lazy var tutorials = [("""
                            Welcome to Narwall!
                            Displayed photographs are from Unsplash.
                            """, view, { return CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0) }, UIPopoverArrowDirection(rawValue: 0), "Next."),
                                  ("""
                            Drag to position the wallpaper.
                            Swipe to the left to show another wallpaper.
                            """, view, { return CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0) }, UIPopoverArrowDirection(rawValue: 0), "Next."),
                                  ("Tap to save the wallpaper to Photos.", downloadButton, { return self.downloadButton.bounds }, UIPopoverArrowDirection.down, "Next."),
                                  ("Tap to view the photographer's Unsplash profile.", photographerButton, { return self.photographerButton.bounds }, UIPopoverArrowDirection.down, "Got it!")]
    private var nextTutorialIndex = 0
    
    @IBOutlet private weak var wallpaperView: UIImageView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var blurView: UIVisualEffectView!
    @IBOutlet private weak var downloadButton: UIButton!
    @IBOutlet private weak var photographerButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var errorLabel: UILabel!
    
    override func viewDidAppear(_ animated: Bool) {
        delegate!.manageTutorial(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        scrollView.contentInsetAdjustmentBehavior = .never
        setup()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setup() {
        if !errorLabel.isHidden {
            errorLabel.isHidden = true
        }
        if !activityIndicator.isAnimating {
            activityIndicator.startAnimating()
        }
        if wallpaperView.image != nil {
            wallpaperView.image = nil
        }
        if !photographerButton.isHidden {
            photographerButton.isHidden = true
            self.photographerButton.setTitle("", for: .normal)
        }
        
        unsplash!.getPhoto(nil) {    // TODO: download custom photo with width or height equal to the largest screen dimmension?
            do {
                let photo = try $0()
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height
                let longestScreenLength = screenWidth < screenHeight ? screenHeight : screenWidth
                
                let thumbnail = photo.thumbnail
                let rawImage = photo.rawImage
                let downloadLocation = photo.downloadLocation
                let photographer = photo.photographerName
                let profile = photo.photographerProfile
                
                self.downloadLocation = downloadLocation
                
                func setWallpaperFromURL(_ url: URL, then callback: @escaping (() throws -> Void) -> Void) {
                    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                        if let data = data {
                            let rawWallpaper = UIImage(data: data)
                            let rawWallpaperWidth = rawWallpaper!.size.width
                            let rawWallpaperHeight = rawWallpaper!.size.height
                            let scale = rawWallpaperWidth < rawWallpaperHeight ? CGFloat(rawWallpaperWidth) / longestScreenLength : CGFloat(rawWallpaperHeight) / longestScreenLength
                            
                            let newWallpaper = UIImage(data: data, scale: scale)
                            DispatchQueue.main.async {
                                self.wallpaperView.image = newWallpaper
                            }
                            callback({})
                        } else {
                            callback({throw WallpaperViewControllerError.offlineInternetConnection})
                        }
                    }
                    task.resume()
                }
                
                setWallpaperFromURL(thumbnail) {
                    do {
                        try $0()
                        setWallpaperFromURL(rawImage) {
                            do {
                                try $0()
                                DispatchQueue.main.async {
                                    let animator = UIViewPropertyAnimator(duration: 0.195, curve: .easeIn) {
                                        self.blurView.alpha = 0
                                    }
                                    animator.addCompletion() { _ in
                                        self.activityIndicator.stopAnimating()
                                    }
                                    animator.startAnimation()
                                    
                                    self.downloadButton.isEnabled = true
                                }
                                self.setupWasCompleted = true
                                self.delegate!.manageTutorial(self)
                            } catch {   // on WallpaperViewController.offlineInternetConnection
                                self.errorMessage("""
                                                    You appear to be offline.
                                                    Swipe to attempt to load a new wallpaper.
                                                    """)
                            }
                        }
                    } catch {   // on WallpaperViewController.offlineInternetConnection
                        self.errorMessage("""
                                            You appear to be offline.
                                            Swipe to attempt to load a new wallpaper.
                                            """)
                    }
                }
                
                self.photographerProfile = profile
                DispatchQueue.main.async {
                    self.photographerButton.setTitle(photographer, for: .normal)
                    self.photographerButton.isHidden = false
                }
            } catch Unsplash.UnsplashError.offlineInternetConnection {
                self.errorMessage("""
                                    You appear to be offline.
                                    Swipe to attempt to load a new wallpaper.
                                    """)
            } catch Unsplash.UnsplashError.rateLimitExceeded {
                self.errorMessage("Try again in the next hour.")
            } catch {
                self.errorMessage("An unknown error occured.")
            }
        }
    }
    
    // Callback for UIImageWriteToSavedPhotosAlbum().
    // If an image was successfully written to the Photos Album, this fulfills Unsplash's second technical API guideline.
    // See https://medium.com/unsplash/unsplash-api-guidelines-triggering-a-download-c39b24e99e02 for more info.
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        func animateDownloadButton(_ imageToSet: String) {
            let firstStep = UIViewPropertyAnimator(duration: 0.1, curve: .easeIn) {
                self.downloadButton.alpha = 0
            }
            let secondStep = UIViewPropertyAnimator(duration: 0.1, curve: .easeIn) {
                self.downloadButton.alpha = 1
            }
            let thirdStep = UIViewPropertyAnimator(duration: 0.1, curve: .easeIn) {
                self.downloadButton.alpha = 0
            }
            let fourthStep = UIViewPropertyAnimator(duration: 0.1, curve: .easeIn) {
                self.downloadButton.alpha = 1
            }
            
            firstStep.addCompletion() { _ in
                self.downloadButton.setImage(UIImage(named: imageToSet), for: .normal)
                secondStep.startAnimation()
            }
            secondStep.addCompletion() { _ in
                thirdStep.startAnimation(afterDelay: 0.5)
            }
            thirdStep.addCompletion() { _ in
                self.downloadButton.setImage(UIImage(named: "Download"), for: .normal)
                fourthStep.startAnimation()
            }
            fourthStep.addCompletion() { _ in
                self.downloadButton.isEnabled = true
            }
            
            firstStep.startAnimation()
        }
        
        if let error = error {
            animateDownloadButton("Error")
        } else {
            var downloadLocationRequest = URLRequest(url: downloadLocation!)
            downloadLocationRequest.setValue("Client-ID \(unsplash!.applicationId)", forHTTPHeaderField: "Authorization")
            downloadLocationRequest.setValue("v1", forHTTPHeaderField: "Accept-Version")
            
            let task = URLSession.shared.dataTask(with: downloadLocationRequest)
            task.resume()
            
            animateDownloadButton("Checked")
        }
    }
    
    @IBAction private func onDownloadButtonTouch() {
        downloadButton.isEnabled = false
        UIImageWriteToSavedPhotosAlbum(wallpaperView.image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @IBAction private func onPhotographerButtonTouch() {
        if let url = photographerProfile {
            let safariViewController = SFSafariViewController(url: url)
            present(safariViewController, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TutorialStoryboardSegue" {
            let viewController = segue.destination as! TutorialViewController
            let tuple = sender as! (instruction: String, anchorView: UIView, getAnchorRect: () -> CGRect, arrowDirection: UIPopoverArrowDirection, proceedButtonTitle: String)
            viewController.instruction = tuple.instruction
            viewController.getAnchorRect = tuple.getAnchorRect
            viewController.proceedButtonTitle = tuple.proceedButtonTitle
            viewController.delegate = self
            
            let popoverPresentationController = viewController.popoverPresentationController!
            popoverPresentationController.sourceView = tuple.anchorView
            popoverPresentationController.sourceRect = tuple.getAnchorRect()
            popoverPresentationController.permittedArrowDirections = tuple.arrowDirection
            popoverPresentationController.delegate = self
        }
    }
    
    private enum WallpaperViewControllerError: Error {
        case offlineInternetConnection
    }
    
    private func errorMessage(_ message: String) {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.errorLabel.text = message
            self.errorLabel.isHidden = false
        }
        
        delegate!.onError(self)
    }
}

extension WallpaperViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return false
    }
}

extension WallpaperViewController: TutorialViewControllerDelegate {
    func proceedWithTutorial() {
        if nextTutorialIndex == tutorials.count {
            nextTutorialIndex = 0
        } else {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "TutorialStoryboardSegue", sender: self.tutorials[self.nextTutorialIndex])
                self.nextTutorialIndex += 1
            }
        }
    }
}

protocol WallpaperViewControllerDelegate: class {
    func manageTutorial(_ completedWallpaperViewController: WallpaperViewController)
    func onError(_ throwingWallpaperViewController: WallpaperViewController)
}
