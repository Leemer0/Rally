import AVFoundation
import SwiftUI
import UIKit

struct WelcomeHeroMedia: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if reduceMotion {
                WelcomePosterImage()
            } else if let url = welcomeResourceURL(name: "welcome-loop", extension: "mp4") {
                OneShotVideoView(url: url, isPlaying: scenePhase == .active)
            } else {
                WelcomePosterImage()
            }
        }
        .aspectRatio(2, contentMode: .fit)
        .background(Color.black)
        .accessibilityHidden(true)
    }
}

private struct WelcomePosterImage: View {
    var body: some View {
        Group {
            if let url = welcomeResourceURL(name: "welcome-poster", extension: "jpg"),
               let image = UIImage(contentsOfFile: url.path)
            {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.black
            }
        }
    }
}

private func welcomeResourceURL(name: String, extension fileExtension: String) -> URL? {
    Bundle.main.url(forResource: name, withExtension: fileExtension, subdirectory: "Media")
        ?? Bundle.main.url(forResource: name, withExtension: fileExtension)
}

private struct OneShotVideoView: UIViewRepresentable {
    let url: URL
    let isPlaying: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIView(context: Context) -> PlayerLayerView {
        let view = PlayerLayerView()
        view.player = context.coordinator.player
        if isPlaying { context.coordinator.playIfNeeded() }
        return view
    }

    func updateUIView(_ view: PlayerLayerView, context: Context) {
        view.player = context.coordinator.player
        if isPlaying {
            context.coordinator.playIfNeeded()
        } else {
            context.coordinator.player.pause()
        }
    }

    static func dismantleUIView(_ uiView: PlayerLayerView, coordinator: Coordinator) {
        coordinator.player.pause()
        uiView.player = nil
    }

    final class Coordinator {
        let player: AVPlayer
        private var didFinish = false
        private var endObserver: NSObjectProtocol?

        init(url: URL) {
            let item = AVPlayerItem(url: url)
            player = AVPlayer(playerItem: item)
            player.isMuted = true
            player.actionAtItemEnd = .pause
            player.automaticallyWaitsToMinimizeStalling = false
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.didFinish = true
                self?.player.pause()
            }
        }

        deinit {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
        }

        func playIfNeeded() {
            guard !didFinish else {
                player.pause()
                return
            }
            player.play()
        }
    }
}

private final class PlayerLayerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        playerLayer.videoGravity = .resizeAspect
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
