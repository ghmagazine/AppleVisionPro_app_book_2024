import ARKit
import Observation
import QuartzCore
import RealityKit

@Observable
class ImmersiveViewModel {

    private let rootEntity = Entity()
    private let arkitSession = ARKitSession()
    private let worldTracking = WorldTrackingProvider()

    // 配置場所エンティティ
    private let placementLocation = Entity()

    private var anchoredObjects: [UUID: Entity] = [:]
    private var objectsBeingAnchored: [UUID: Entity] = [:]

    private var appState: AppState!
    private var timerManager: TimerManager!

    private(set) var providersStoppedWithError = false

    func setup(appState: AppState, timerManager: TimerManager) -> Entity {
        self.appState = appState
        self.timerManager = timerManager
        rootEntity.addChild(placementLocation)

        for timerModel in timerManager.timerModels {
            if getTargetEntity(name: timerModel.id.uuidString) == nil {
                addPlaceHolder(timerModel: timerModel, attachToWorldAnchor: false)
            }
        }

        return rootEntity
    }

    func getTargetEntity(name: String) -> Entity? {
        return rootEntity.children.first { $0.name == name}
    }

    func resetProvidersStoppedWithError() {
        providersStoppedWithError = false
    }

    func addMarker() {
        // タップ対象となる半透明の円盤を生成
        let entity = ModelEntity(
            mesh: .generateCylinder(height: 0.01, radius: 0.06),
            materials: [SimpleMaterial(color: .init(red: 0, green: 0, blue: 1, alpha: 0.5), isMetallic: false)]
        )

        // タップ操作が反応するようInputTargetComponentとCollisionを設定
        entity.components.set(InputTargetComponent())
        entity.generateCollisionShapes(recursive: true)

        // 円盤が90°こちらに向いた状態にするためクォータニオンで回転を指定
        let rotationQuaternionX = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0))
        entity.orientation *= rotationQuaternionX

        // 設置場所となるEntityに追加
        placementLocation.addChild(entity)
    }

    func addPlaceHolder() {
        let timerModel = timerManager.makeTimerModel()
        timerManager.addTimerModel(timerModel: timerModel)

        addPlaceHolder(timerModel: timerModel, attachToWorldAnchor: true)
    }

    func addPlaceHolder(timerModel: TimerModel, attachToWorldAnchor: Bool) {
        let entity = Entity()
        entity.name = timerModel.id.uuidString
        entity.transform = placementLocation.transform
        rootEntity.addChild(entity)

        if attachToWorldAnchor {
            // Works only on device
            Task {
                await attachObjectToWorldAnchor(entity)
            }
        }
    }

    func removePlaceHolder(timerModelID: UUID) {
        guard let timerModel = timerManager.getTargetTimerModel(id: timerModelID),
              let placeHolderEntity = getTargetEntity(name: timerModelID.uuidString) else { return }

        placeHolderEntity.removeFromParent()
        timerManager.removeTimerModel(timerModel: timerModel)
    }

    // MARK: - ARKit and Anchor handlings

    @MainActor
    func runARKitSession() async {
        do {
            // WorldTrackingProviderを指定しARKitのセッションを開始
            try await arkitSession.run([worldTracking])
        } catch {
            return
        }
    }

    func stopARKitSession() {
        arkitSession.stop()
    }

    func monitorSessionEvents() async {
        for await event in arkitSession.events {
            switch event {
            case .dataProviderStateChanged(_, let newState, let error):
                switch newState {
                case .initialized:
                    break
                case .running:
                    break
                case .paused:
                    break
                case .stopped:
                    if let error {
                        print("An error occurred: \(error)")
                        providersStoppedWithError = true
                    }
                @unknown default:
                    break
                }
            case .authorizationChanged(let type, let status):
                print("Authorization type \(type) changed to \(status)")
            default:
                print("An unknown event occured \(event)")
            }
        }
    }

    @MainActor
    func processDeviceAnchorUpdates() async {
        await run(function: self.queryAndProcessLatestDeviceAnchor, withFrequency: 90)
    }

    @MainActor
    private func queryAndProcessLatestDeviceAnchor() async {
        guard worldTracking.state == .running else { return }

        placementLocation.isEnabled = appState?.isAppendMode ?? false

        // 端末の位置と向きを取得
        let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())

        guard let deviceAnchor, deviceAnchor.isTracked else { return }

        // カメラ位置前方0.5メートルの位置を取得
        let matrix = deviceAnchor.originFromAnchorTransform
        let forward = simd_float3(0, 0, -1)
        let cameraForward = simd_act(matrix.rotation, forward)

        let front = SIMD3<Float>(x: cameraForward.x, y: cameraForward.y, z: cameraForward.z)
        let length: Float = 0.5
        let offset = length * simd_normalize(front)

        // 配置場所エンティティに位置と回転情報を反映
        placementLocation.position = matrix.position + offset
        placementLocation.orientation = matrix.rotation
    }

    @MainActor
    func processWorldAnchorUpdates() async {
        for await anchorUpdate in worldTracking.anchorUpdates {
            process(anchorUpdate)
        }
    }

    @MainActor
    private func process(_ anchorUpdate: AnchorUpdate<WorldAnchor>) {
        let anchor = anchorUpdate.anchor

        switch anchorUpdate.event {
        case .added:
            if let objectBeingAnchored = objectsBeingAnchored[anchor.id] {
                // 追加操作から新たに追加した場合
                objectsBeingAnchored.removeValue(forKey: anchor.id)
                anchoredObjects[anchor.id] = objectBeingAnchored

                if let timerManager = self.timerManager,
                   let uuid = UUID(uuidString: objectBeingAnchored.name),
                   let timerModel = timerManager.getTargetTimerModel(id: uuid) {

                    timerModel.worldAnchorID = anchor.id
                    timerManager.updateTimerModel(timerModel: timerModel)
                }
            } else if let timerModel = timerManager.getTargetTimerModel(worldAnchorID: anchor.id) {
                // 保存データから読み込んだ場合
                if let placeHolder = getTargetEntity(name: timerModel.id.uuidString) {
                    anchoredObjects[anchor.id] = placeHolder
                }
            } else {
                if anchoredObjects[anchor.id] == nil {
                    Task {
                        await removeAnchorWithID(anchor.id)
                    }
                }
            }
            fallthrough
        case .updated:
            if let object = anchoredObjects[anchor.id] {
                object.position = anchor.originFromAnchorTransform.translation
                object.orientation = anchor.originFromAnchorTransform.rotation
                object.isEnabled = anchor.isTracked
            }
        case .removed:
            if let object = anchoredObjects[anchor.id] {
                object.removeFromParent()
            }
            anchoredObjects.removeValue(forKey: anchor.id)
        }
    }

    private func removeAnchorWithID(_ uuid: UUID) async {
        do {
            try await worldTracking.removeAnchor(forID: uuid)
        } catch {
            //print("Failed to delete world anchor \(uuid) with error \(error).")
        }
    }

    private func attachObjectToWorldAnchor(_ object: Entity) async {
        let anchor = await WorldAnchor(originFromAnchorTransform: object.transformMatrix(relativeTo: nil))
        objectsBeingAnchored[anchor.id] = object
        do {
            try await worldTracking.addAnchor(anchor)
        } catch {
            print("Failed to add world anchor \(anchor.id) with error: \(error).")
            objectsBeingAnchored.removeValue(forKey: anchor.id)
            await object.removeFromParent()
        }
    }
}

extension ImmersiveViewModel {

    @MainActor
    func run(function: () async -> Void, withFrequency hz: UInt64) async {
        while true {
            if Task.isCancelled {
                return
            }

            // 処理呼び出し前に 1秒/周波数 スリープする
            let nanoSecondsToSleep: UInt64 = NSEC_PER_SEC / hz
            do {
                try await Task.sleep(nanoseconds: nanoSecondsToSleep)
            } catch {
                // タスクをキャンセルされた場合スリープは失敗する。ループを抜ける。
                return
            }

            // 処理を実行
            await function()
        }
    }
}
