import MetalKit
import SwiftUI

/// The offer pass's single signature motion: a thin, open glass orbit whose
/// live segment recedes with the offer window. Countdown text remains native
/// SwiftUI so it stays sharp, scalable, and legible to VoiceOver.
struct OfferGlassOrbit: View {
    let progress: Double
    let duration: TimeInterval
    let reduceMotion: Bool

    var body: some View {
        Group {
            if MetalOfferOrbitSurface.isSupported {
                MetalOfferOrbitSurface(
                    progress: progress,
                    duration: duration,
                    reduceMotion: reduceMotion
                )
            } else {
                StaticOfferOrbit(progress: progress)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct MetalOfferOrbitSurface: UIViewRepresentable {
    let progress: Double
    let duration: TimeInterval
    let reduceMotion: Bool

    static let isSupported = MTLCreateSystemDefaultDevice() != nil

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.isOpaque = false
        view.layer.isOpaque = false
        view.backgroundColor = .clear
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = true
        view.autoResizeDrawable = true
        view.preferredFramesPerSecond = 30
        view.isUserInteractionEnabled = false
        view.accessibilityElementsHidden = true

        if let renderer = OfferGlassOrbitRenderer(view: view) {
            context.coordinator.renderer = renderer
            view.delegate = renderer
            renderer.update(
                view: view,
                progress: progress,
                duration: duration,
                reduceMotion: reduceMotion
            )
        }

        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.renderer?.update(
            view: view,
            progress: progress,
            duration: duration,
            reduceMotion: reduceMotion
        )
    }

    static func dismantleUIView(_ view: MTKView, coordinator: Coordinator) {
        view.isPaused = true
        view.delegate = nil
        coordinator.renderer = nil
    }

    final class Coordinator {
        fileprivate var renderer: OfferGlassOrbitRenderer?
    }
}

private final class OfferGlassOrbitRenderer: NSObject, MTKViewDelegate {
    private struct Uniforms {
        var viewportSize: SIMD2<Float>
        var time: Float
        var progress: Float
        var motion: Float
    }

    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let startTime = CACurrentMediaTime()

    private var baseProgress: Float = 1
    private var progressSetAt = CACurrentMediaTime()
    private var totalDuration: Float = Float(TimedOfferWindow.duration)
    private var reduceMotion = false

    init?(view: MTKView) {
        guard
            let device = view.device,
            let commandQueue = device.makeCommandQueue(),
            let library = device.makeDefaultLibrary(),
            let vertexFunction = library.makeFunction(name: "offerOrbitVertex"),
            let fragmentFunction = library.makeFunction(name: "offerOrbitFragment")
        else { return nil }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "Outly Offer Glass Orbit Pipeline"
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        guard let pipelineState = try? device.makeRenderPipelineState(descriptor: descriptor) else {
            return nil
        }

        self.commandQueue = commandQueue
        self.pipelineState = pipelineState
        super.init()
    }

    func update(
        view: MTKView,
        progress: Double,
        duration: TimeInterval,
        reduceMotion: Bool
    ) {
        baseProgress = Float(min(1, max(0, progress)))
        progressSetAt = CACurrentMediaTime()
        totalDuration = Float(max(0.001, duration))
        self.reduceMotion = reduceMotion

        view.preferredFramesPerSecond = ProcessInfo.processInfo.isLowPowerModeEnabled ? 15 : 30
        view.enableSetNeedsDisplay = reduceMotion
        view.isPaused = reduceMotion

        if reduceMotion {
            view.setNeedsDisplay()
            view.draw()
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        if reduceMotion {
            view.setNeedsDisplay()
        }
    }

    func draw(in view: MTKView) {
        guard
            view.drawableSize.width > 0,
            view.drawableSize.height > 0,
            let descriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        let now = CACurrentMediaTime()
        let elapsedSinceProgressUpdate = reduceMotion ? 0 : Float(now - progressSetAt)
        let interpolatedProgress = max(0, baseProgress - elapsedSinceProgressUpdate / totalDuration)
        var uniforms = Uniforms(
            viewportSize: SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            time: reduceMotion ? 0 : Float(now - startTime),
            progress: interpolatedProgress,
            motion: reduceMotion ? 0 : 1
        )

        commandBuffer.label = "Outly Offer Glass Orbit Frame"
        encoder.label = "Outly Offer Glass Orbit Encoder"
        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

private struct StaticOfferOrbit: View {
    @Environment(OutlyTheme.self) private var theme
    let progress: Double

    private var liveEnd: CGFloat {
        0.9167 * CGFloat(min(1, max(0, progress)))
    }

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.9167)
                .stroke(theme.chromeMid.opacity(0.08), style: StrokeStyle(lineWidth: 1, lineCap: .round))

            Circle()
                .trim(from: 0, to: liveEnd)
                .stroke(theme.chromeMid.opacity(0.10), style: StrokeStyle(lineWidth: 10, lineCap: .round))

            Circle()
                .inset(by: 0.75)
                .trim(from: 0, to: liveEnd)
                .stroke(theme.chromeLight.opacity(0.88), style: StrokeStyle(lineWidth: 1.15, lineCap: .round))

            Circle()
                .inset(by: 10.75)
                .trim(from: 0, to: liveEnd)
                .stroke(theme.chromeLight.opacity(0.68), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        }
        .padding(12)
        .rotationEffect(.degrees(-9))
    }
}
