import UIKit

class TutorialViewController: UIViewController {
    var instruction: String?
    var getAnchorRect: (() -> CGRect)?
    var proceedButtonTitle: String?
    weak var delegate: TutorialViewControllerDelegate?
    
    @IBOutlet private weak var instructionLabel: UILabel!
    @IBOutlet private weak var proceedButton: UIButton!
    @IBOutlet private weak var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        instructionLabel.text = instruction
        proceedButton.setTitle(proceedButtonTitle, for: .normal)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let fittedSize = stackView?.sizeThatFits(UILayoutFittingCompressedSize) {
            preferredContentSize = CGSize(width: fittedSize.width + 44, height: fittedSize.height + 44)
        }
    }
    
    @IBAction private func onProceedButtonTouch() {
        presentingViewController?.dismiss(animated: true) {
            self.delegate!.proceedWithTutorial()
        }
    }
    
    // see https://stackoverflow.com/questions/26069874/what-is-the-right-way-to-handle-orientation-changes-in-ios-8
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil, completion: {_ in
            self.popoverPresentationController?.sourceRect = self.getAnchorRect!()
        })
    }
}

protocol TutorialViewControllerDelegate: class {
    func proceedWithTutorial()
}
