import SwiftUI

struct UltraSimpleRecorderView: View {
    @ObservedObject var whisperState: WhisperState
    @ObservedObject var recorder: Recorder
    @EnvironmentObject var windowManager: UltraSimpleWindowManager
    @EnvironmentObject private var enhancementService: AIEnhancementService

    // MARK: - Design Constants
    private let mainContentHeight: CGFloat = 32
    private let width: CGFloat = 120
    private let cornerRadius: CGFloat = 16

    var body: some View {
        if windowManager.isVisible {
            RecorderStatusDisplay(
                currentState: whisperState.recordingState,
                audioMeter: recorder.audioMeter
            )
            .frame(width: width, height: mainContentHeight)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}
