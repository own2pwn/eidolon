import UIKit
import ReactiveCocoa
import Moya
import Swift_RAC_Macros

class RegistrationPasswordViewController: UIViewController, RegistrationSubController {
    @IBOutlet var passwordTextField: TextField!
    @IBOutlet var confirmButton: ActionButton!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var forgotPasswordButton: UIButton!
    let finishedSignal = RACSubject()

    lazy var viewModel: RegistrationPasswordViewModel = {
        let email = self.navigationController?.fulfillmentNav().bidDetails.newUser.email ?? ""
        return RegistrationPasswordViewModel(passwordSignal: self.passwordTextField.rac_textSignal(),
            manualInvocationSignal: self.passwordTextField.returnKeySignal(),
            finishedSubject: self.finishedSignal,
            email: email)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        forgotPasswordButton.hidden = false

        if let bidDetails = self.navigationController?.fulfillmentNav().bidDetails {

            let passwordTextSignal = passwordTextField.rac_textSignal()
            RAC(bidDetails, "newUser.password") <~ passwordTextSignal
            confirmButton.rac_command = viewModel.command
            viewModel.command.errors.subscribeNext { [weak self] _ -> Void in
                self?.showAuthenticationError()
                return
            }

            RAC(forgotPasswordButton, "hidden") <~ viewModel.emailExistsSignal.not().startWith(true)

            forgotPasswordButton.rac_command = RACCommand { [weak self] _ -> RACSignal! in
                let email = self?.navigationController!.fulfillmentNav().bidDetails.newUser.email! ?? ""

                return self?.viewModel.userForgotPasswordSignal(email).then {
                    self?.alertUserPasswordSent() ?? RACSignal.empty()
                } ?? RACSignal.empty()
            }

            RAC(subtitleLabel, "text") <~ viewModel.emailExistsSignal.map { (object) -> AnyObject! in
                let emailExists = object as Bool

                if emailExists {
                    return "Enter your Artsy password"
                } else {
                    return "Create a password"
                }
            }

            passwordTextField.becomeFirstResponder()
        }
    }

    func alertUserPasswordSent() -> RACSignal {
        return RACSignal.createSignal { (subscriber) -> RACDisposable! in

            let alertController = UIAlertController(title: "Forgot Password", message: "We have sent you your password.", preferredStyle: .Alert)

            let okAction = UIAlertAction(title: "OK", style: .Default) { (_) in }

            alertController.addAction(okAction)

            self.presentViewController(alertController, animated: true) {
                subscriber.sendCompleted()
            }

            return nil
        }
    }
    
    func showAuthenticationError() {
        confirmButton.flashError("Incorrect")
        passwordTextField.flashForError()
        confirmButton.setEnabled(false, animated: false)
        navigationController!.fulfillmentNav().bidDetails.newUser.password = ""
        passwordTextField.text = ""
    }
}
