import MetalKit
import SwiftUI

/// A small Metal-backed surface used only behind Outly's highest-intent actions.
/// The SwiftUI button remains responsible for layout, hit testing, and accessibility.
struct MetalSilverSurface: UIViewRepresentable {
    let isPressed: Bool
    let isEnabled: Bool
    let reduceMotion: Bool

    static let isSupported = MTLCreateSystemDefaultDevice() != nil

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.isOpaque = false
        view.backgroundColor = .clear
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = true
        view.autoResizeDrawable = true
        view.preferredFramesPerSecond = 30
        view.isUserInteractionEnabled = false
        view.accessibilityElementsHidden = true

        if let renderer = MetalSilverRenderer(view: view) {
            context.coordinator.renderer = renderer
            view.delegate = renderer
            renderer.update(
                view: view,
                isPressed: isPressed,
                isEnabled: isEnabled,
                reduceMotion: reduceMotion
            )
        }

        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.renderer?.update(
            view: view,
            isPressed: isPressed,
            isEnabled: isEnabled,
            reduceMotion: reduceMotion
        )
    }

    static func dismantleUIView(_ view: MTKView, coordinator: Coordinator) {
        view.isPaused = true
        view.delegate = nil
        coordinator.renderer = nil
    }

    final class Coordinator {
        fileprivate var renderer: MetalSilverRenderer?
    }
}

private final class MetalSilverRenderer: NSObject, MTKViewDelegate {
    private struct Uniforms {
        var viewportSize: SIMD2<Float>
        var time: Float
        var pressed: Float
        var enabled: Float
        var motion: Float
    }

    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let startTime = CACurrentMediaTime()

    private var isPressed = false
    private var isEnabled = true
    private var reduceMotion = false

    init?(view: MTKView) {
        guard
            let device = view.device,
            let commandQueue = device.makeCommandQueue(),
            let library = device.makeDefaultLibrary(),
            let vertexFunction = library.makeFunction(name: "silverButtonVertex"),
            let fragmentFunction = library.makeFunction(name: "silverButtonFragment")
        else { return nil }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "Outly Silver Button Pipeline"
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
        isPressed: Bool,
        isEnabled: Bool,
        reduceMotion: Bool
    ) {
        let stateChanged = self.isPressed != isPressed
            || self.isEnabled != isEnabled
            || self.reduceMotion != reduceMotion

        self.isPressed = isPressed
        self.isEnabled = isEnabled
        self.reduceMotion = reduceMotion

        // Thirty frames is enough for a slow reflection and materially cheaper than 60.
        view.preferredFramesPerSecond = ProcessInfo.processInfo.isLowPowerModeEnabled ? 15 : 30
        view.enableSetNeedsDisplay = reduceMotion
        view.isPaused = reduceMotion

        if reduceMotion, stateChanged {
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
            let descriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        let elapsed = reduceMotion ? 0 : CACurrentMediaTime() - startTime
        var uniforms = Uniforms(
            viewportSize: SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            time: Float(elapsed),
            pressed: isPressed ? 1 : 0,
            enabled: isEnabled ? 1 : 0,
            motion: reduceMotion ? 0 : 1
        )

        commandBuffer.label = "Outly Silver Button Frame"
        encoder.label = "Outly Silver Button Encoder"
        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
