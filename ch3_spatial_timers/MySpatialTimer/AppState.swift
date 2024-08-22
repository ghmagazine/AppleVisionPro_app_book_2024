import Observation

@Observable
class AppState {

    var isAppendMode = true
    var immersiveSpaceOpened = false
    private(set) weak var immersiveViewModel: ImmersiveViewModel? = nil

    func immersiveSpaceOpened(with _immersiveViewModel: ImmersiveViewModel) {
        immersiveViewModel = _immersiveViewModel
        immersiveSpaceOpened = true
    }

    func didLeaveImmersiveSpace() {
        if let immersiveViewModel {
            immersiveViewModel.stopARKitSession()
        }
        immersiveViewModel = nil
        immersiveSpaceOpened = false
    }
}
