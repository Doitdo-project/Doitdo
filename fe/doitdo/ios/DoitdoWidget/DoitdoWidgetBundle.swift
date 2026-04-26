//
//  DoitdoWidgetBundle.swift
//  DoitdoWidget
//
//  Widget extension 진입점. 우리는 홈 위젯 1개(DoitdoWidget) 만 사용하므로 자동 생성된
//  Control / LiveActivity 위젯은 Bundle 에서 제외했다.
//  사용 안 하는 두 .swift 파일(`DoitdoWidgetControl.swift`, `DoitdoWidgetLiveActivity.swift`)
//  은 Xcode 의 Project Navigator 에서 우클릭 → Delete → "Move to Trash" 로 정리 권장.
//

import WidgetKit
import SwiftUI

@main
struct DoitdoWidgetBundle: WidgetBundle {
    var body: some Widget {
        DoitdoWidget()
    }
}
