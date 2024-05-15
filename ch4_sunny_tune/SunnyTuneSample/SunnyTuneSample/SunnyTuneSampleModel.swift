//
//  SunnyTuneSampleModel.swift
//  SunnyTuneSample
//
//  Created by hisaki sato on 2024/01/31.
//

import Foundation
import RealityKit
import CoreLocation
import SwiftUI

class SunnyTuneSampleModel : ObservableObject {
    private let defaultLocation = CLLocation(latitude: 35.64219962645807, longitude: 139.71341242138175)
    private let defaultTimezone = TimeZone(identifier: "Asia/Tokyo")!
    private let dayLightColor = CGColor(red: 0.568, green: 0.568, blue: 0.282, alpha: 1)
    private let twilightLightColor = CGColor(red: 0.874, green: 0.117, blue: 0.058, alpha: 1)
    private let nightLightColor = CGColor(red: 0.117, green: 0.117, blue: 0.500, alpha: 1)

    private var celestialBody: Entity? = nil
    private var sun: Entity? = nil
    private var moon: Entity? = nil
    private var dome: Entity? = nil
    private var ground: Entity? = nil
    private var grass: Entity? = nil
    private var tree: LSystemEntity? = nil
    private var timezone: TimeZone
    private var location: CLLocation

    init(){
        self.timezone = defaultTimezone
        self.location = defaultLocation
    }
    
    ///  シーンのエンティティから必要な情報を取得してセットアップする
    /// - Parameter scene: 読み込んだシーンのエンティティ
    @MainActor
    func setup(scene: Entity) async throws {
        // シーンからEntityを検索して取得しておく.
        self.celestialBody = scene.findEntity(named: "CelestialBody")
        self.dome = scene.findEntity(named: "Dome_geometry")
        self.ground = scene.findEntity(named: "Ground_geometry")
        self.grass = scene.findEntity(named: "Grass_geometry")
        self.sun = scene.findEntity(named: "Sun")
        self.moon = scene.findEntity(named: "Moon")
        
        // L-Systemの木を生成してダミーの木と差し替える
        let dummyTree = scene.findEntity(named: "Tree_geometry")
        let dummyTreeMaterial = dummyTree?.components[ModelComponent.self]?.materials.first as? ShaderGraphMaterial
        self.tree = LSystemEntity()
        self.tree?.setParent(dummyTree?.parent)
        try await self.tree?.setup(lsystem: .init(initialSymbol: "FF[+F[+pX][-PXL]FX][-F[+PX][-pXL]FX]FF[+PXL][-pX]FXL", rule: ["F":"FF", "X":"F[+X][-X]FXL"]), material: dummyTreeMaterial!)
        dummyTree!.removeFromParent()

        try updateTime(now: Date(), location: defaultLocation, timezone: defaultTimezone)
        try updateCloud(cloud: 0)
        try updateWind(angle: Angle(degrees: 0))
    }
    
    /// 木を成長させる
    func growTree() async throws {
        try await self.tree?.grow()
    }
    
    /// 指定の時間の今日の日時を取得
    /// - Parameter hour: 取得したい時間
    /// - Returns: 今日の日時
    func getTodayDate(hour:Double) -> Date {
        var calender = Calendar.current
        calender.timeZone = defaultTimezone
        var dateComponents = calender.dateComponents([.year, .month, .day, .hour], from: Date())
        dateComponents.hour = Int(floor(hour))
        dateComponents.minute = Int(60 * hour.truncatingRemainder(dividingBy: 1))
        return calender.date(from: dateComponents)!
    }
    
    
    /// 雲の量の更新
    /// - Parameter cloud: 0〜1の雲の量
    func updateCloud(cloud:Float) throws {
        try self.dome?.updateMaterial({ material in
            try material.setParameter(name: "Cloud", value: MaterialParameters.Value.float(cloud))
        })
    }
    
    
    /// 風の更新
    /// - Parameter direction: 風の方向
    func updateWind(angle:Angle) throws {
        var direction: SIMD3<Float> = .zero
        direction.x = Float(sin(angle.radians))
        direction.z = Float(cos(angle.radians))
        try self.grass?.updateMaterial({ material in
            try material.setParameter(name: "Wind", value: MaterialParameters.Value.simd3Float(direction))
        })
        try self.tree?.model?.updateMaterial({ material in
            try material.setParameter(name: "Wind", value: MaterialParameters.Value.simd3Float(direction))
        })
    }
    
    /// 時間の更新を行い、時間に合わせた見た目に変更する
    /// - Parameters:
    ///   - now: 現在の時間
    func updateTime(now:Date) throws {
        try updateTime(now: now, location: self.location, timezone: self.timezone)
    }
    
    /// 時間の更新を行い、時間に合わせた見た目に変更する
    /// - Parameters:
    ///   - now: 現在の時間
    ///   - location: 緯度経度
    ///   - timezone: タイムゾーン
    private func updateTime(now:Date, location: CLLocation, timezone: TimeZone) throws {

        // 日の出、日の入りの時間を決め打ち
        // 実際はWeatherKitなどから取得します
        let sunrise = getTodayDate(hour: 7)
        let sunset = getTodayDate(hour: 18)

        // 天体の回転
        let sunPosition = Sorlar.getSunPosition(date: now, location: location, timezone: timezone)
        var rotation = simd_quatf(angle: Float(sunPosition.azimuth.radians), axis: [0,1,0])
        rotation *= simd_quatf(angle: Float(sunPosition.altitude.radians), axis: [1,0,0])
        
        celestialBody!.transform.rotation = rotation
        
        // シェーダーに渡す用の-1~1までのTimeパラメータを取得
        let time = Float(getTime(now:now, sunrise:sunrise, sunset:sunset))
        
        // 昼は太陽。夜は月の位置をライトの位置として使用する
        // また時間帯によってライトのカラーを変更
        var lightPosition = SIMD3<Float>.zero
        var lightColor = twilightLightColor
        if time >= 0 {
            lightColor = CGColor.mix(twilightLightColor, dayLightColor, CGFloat(time))!
            self.sun?.isEnabled = true
            self.moon?.isEnabled = false
            lightPosition = self.sun!.position
        } else if time < 0 {
            lightColor = CGColor.mix(twilightLightColor, nightLightColor, CGFloat(-time))!
            self.sun?.isEnabled = false
            self.moon?.isEnabled = true
            lightPosition = self.moon!.position
        }
        
        // ライト位置から中心への方向をライト方向とする
        let lightPosition4 = simd_mul(celestialBody!.transform.matrix, .init(lightPosition, 1.0))
        lightPosition = .init(lightPosition4.x, lightPosition4.y, lightPosition4.z)
        let lightDirection = -normalize(lightPosition)
        
        // シェーダーにパラメータを渡す
        try self.ground?.updateMaterial({ material in
            try material.setParameter(name: "LightDirection", value: MaterialParameters.Value.simd3Float(lightDirection))
            try material.setParameter(name: "LightColor", value: MaterialParameters.Value.color(lightColor))
        })
        try self.grass?.updateMaterial({ material in
            try material.setParameter(name: "LightDirection", value: MaterialParameters.Value.simd3Float(lightDirection))
            try material.setParameter(name: "LightColor", value: MaterialParameters.Value.color(lightColor))
        })
        try self.tree?.model?.updateMaterial({ material in
            try material.setParameter(name: "LightDirection", value: MaterialParameters.Value.simd3Float(lightDirection))
            try material.setParameter(name: "LightColor", value: MaterialParameters.Value.color(lightColor))
        })
        try self.dome?.updateMaterial({ material in
            try material.setParameter(name: "Time", value: MaterialParameters.Value.float(time))
        })
    }

    
    /// 日の出、日の入りの時間から-1~1のシェーダー用のTimeパラメータを取得
    /// - Parameters:
    ///   - now: 取得する時間
    ///   - sunrise: 日の出時間
    ///   - sunset: 日の入り時間
    /// - Returns: -1 ~ 1 のTimeパラメータ
    private func getTime(now: Date, sunrise: Date?, sunset: Date?) -> Double
    {
        // 日の入り時間がない時は白夜になっている
        guard let sunset = sunset  else {
            return 1
        }
        // 日の出時間がない時は極夜になっている
        guard let sunrise = sunrise else {
            return -1
        }
        
        // 日の出、日の入りの前後30分から徐々に昼と夜に切り替えていく.
        let hour: TimeInterval = 3600
        let halfHour: TimeInterval = hour / 2
        let sunsetStart = (sunset - halfHour)
        let sunsetEnd = (sunset + halfHour)
        let sunriseStart = (sunrise - halfHour)
        let sunriseEnd = (sunrise + halfHour)
        
        // 日の出前は夜にする
        if now < sunriseStart {
            return -1.0
        }
        // 日の出開始から終了までの１時間を-1〜0で変化させる
        else if now < sunriseEnd {
            return -1.0 + (now.timeIntervalSince(sunriseStart) / hour)
        }
        // 日中の時間を0~1~0と変化させるために sin カーブで 変化させている
        else if now < sunsetStart {
            let dayHour = (sunsetEnd).timeIntervalSince(sunriseStart)
            return sin(((sunsetStart).timeIntervalSince(now) / dayHour) * .pi)
        }
        // 日の入り開始から終了までの１時間を0〜-1で変化させる
        else if now < sunsetEnd {
            return -(now.timeIntervalSince(sunset - halfHour)) / hour
        }
        // 日の入り後なので夜にする
        else {
            return -1.0
        }
    }
}
