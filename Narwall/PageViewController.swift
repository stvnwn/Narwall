import UIKit

class PageViewController: UIPageViewController {
    let unsplash = Unsplash(applicationName: "Name of an application registered on Unsplash", applicationId: "Access key of an application registered on Unsplash")
    var currentViewController: WallpaperViewController? {
        get {
            return viewControllers?.first as? WallpaperViewController
        }
    }
    
    // the view controller the user previously navigated to
    var previousViewController: WallpaperViewController?
    
    var cachedViewController: WallpaperViewController?
    
    var throwingViewControllers = Set<WallpaperViewController>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if UserDefaults.standard.object(forKey: "tutorial_preference") == nil {
            UserDefaults.standard.set(true, forKey: "tutorial_preference")
        }
        UserDefaults.standard.addObserver(self, forKeyPath: "tutorial_preference", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
        dataSource = self
        delegate = self
        setViewControllers([getWallpaperViewController()], direction: .forward, animated: false, completion: {done in })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func getWallpaperViewController() -> WallpaperViewController {
        let wallpaperViewController = self.storyboard!.instantiateViewController(withIdentifier: "WallpaperViewController") as! WallpaperViewController
        wallpaperViewController.unsplash = unsplash
        wallpaperViewController.delegate = self
        return wallpaperViewController
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if currentViewController != nil && currentViewController!.setupWasCompleted && UserDefaults.standard.bool(forKey: "tutorial_preference") {
            UserDefaults.standard.set(false, forKey: "tutorial_preference")
            currentViewController!.proceedWithTutorial()
        }
    }
}

extension PageViewController: UIPageViewControllerDataSource {
    // these functions are called after a transition is completed, except for the first transition, when it is also called beforehand
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if cachedViewController === currentViewController || cachedViewController == nil {
            cachedViewController = getWallpaperViewController()
        }
        return cachedViewController
    }
}

extension PageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        if let pendingViewController = pendingViewControllers.first as? WallpaperViewController, throwingViewControllers.contains(pendingViewController) {
            throwingViewControllers.remove(pendingViewController)
            pendingViewController.setup()
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            // if the previous view controller threw an error and the user did not navigate to the previous view controller
            if previousViewController === currentViewController && throwingViewControllers.contains(previousViewController!) {
                throwingViewControllers.remove(previousViewController!)
            }
            previousViewController = previousViewControllers.first as! WallpaperViewController
        }
    }
}

extension PageViewController: WallpaperViewControllerDelegate {
    func manageTutorial(_ completedWallpaperViewController: WallpaperViewController) {
        if completedWallpaperViewController === currentViewController {
            observeValue(forKeyPath: nil, of: nil, change: nil, context: nil)
        }
    }
    
    func onError(_ throwingWallpaperViewController: WallpaperViewController) {
        throwingViewControllers.insert(throwingWallpaperViewController)
    }
}
