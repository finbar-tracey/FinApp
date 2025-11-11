//
//  Sound.swift
//  FinApp
//
//  Created by Finbar Tracey on 11/11/2025.
//

import Foundation
import AudioToolbox

enum BeepKind {
    case tick   // 3, 2, 1
    case done   // 0
}

enum Sound {
    /// Play a short system beep. (Respects the mute switch.)
    static func beep(_ kind: BeepKind) {
        let id: SystemSoundID
        switch kind {
        case .tick:
            // "Tock" style tap (short, subtle)
            id = 1104
        case .done:
            // Slightly more noticeable "Alert"
            id = 1111
        }
        AudioServicesPlaySystemSound(id)
    }
}
