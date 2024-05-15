import SwiftUI
import Foundation
import CoreLocation

class Sorlar {
    
    /// 太陽高度と方位角の取得
    /// - Parameters:
    ///   - date: 取得する時間
    ///   - location: 取得する緯度経度
    ///   - timezone: 取得するタイムゾーン
    /// - Returns:　azimuth: 太陽高度, altitude: 太陽方位角
    static func getSunPosition(date: Date, location:CLLocation, timezone:TimeZone) -> (azimuth:Angle, altitude:Angle) {
        
        // 指定のタイムゾーンのカレンダーを作成
        var calendar = Calendar.current
        calendar.timeZone = timezone
        
        // タイムゾーンに合わせた年と日を取得する
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date)!
        
        // 位置を調べる緯度
        let latitude = Angle(degrees: location.coordinate.latitude)

        // 太陽赤緯の計算
        let declination = Angle(degrees: 23.44 * sin((2 * .pi / 365) * (Double(dayOfYear) + 284)))

        // 時角の計算
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let hourAngle = Angle(degrees:15.0 * (Double(hour) + (Double(minute)/60.0) - 12.0))

        // 太陽高度角の計算
        let sinAltitude = sin(declination.radians) * sin(latitude.radians) + cos(declination.radians) * cos(latitude.radians) * cos(hourAngle.radians)
        let altitude = Angle(radians: asin(sinAltitude))

        // 太陽方位角の計算
        let sinAzimuth = -cos(declination.radians) * sin(hourAngle.radians)
        let cosAzimuth = (sinAltitude - sin(declination.radians) * sin(latitude.radians)) / (cos(declination.radians) * cos(latitude.radians))
        let azimuth = Angle(radians:atan2(sinAzimuth, cosAzimuth))

        return (azimuth: azimuth, altitude: altitude)
    }
}
