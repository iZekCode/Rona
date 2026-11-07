//
//  PerformanceGateView.swift
//  Rona
//
//  Created by Filbert Naldo Wijaya on 07/11/26.
//

import SceneKit
import SwiftUI

// A developer page: shows the canvas painting by itself and the numbers that decide if a device is fast enough.
struct PerformanceGateView: View {
    let router: AppRouter

    @State private var stage = PerformanceGateStage()
    @State private var copied = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            GateSceneView(stage: stage).ignoresSafeArea()
            panel
        }
        .onAppear { stage.start() }
        .onDisappear { stage.stop() }
    }

    private var panel: some View {
        let r = stage.reading
        return VStack(alignment: .leading, spacing: 10) {
            Text(PerformanceGateStage.deviceModel).font(.headline.monospaced())
            Text(verdictText(r)).font(.title3.bold().monospaced()).foregroundStyle(color(r.verdict))
            Group {
                Text(String(format: "Paint GPU   avg %.2f  p95 %.2f ms", r.paintAverage, r.paintTail))
                Text(String(format: "Frame       avg %.1f  p95 %.1f  worst %.1f ms", r.frameAverage, r.frameTail, r.frameWorst))
                Text(String(format: "FPS %.0f   main thread %.2f ms   headroom %.1fx", r.fps, r.cpuAverage, r.headroom))
            }
            .font(.callout.monospaced())

            Picker("Resolusi", selection: Binding(get: { stage.resolution }, set: stage.setResolution)) {
                ForEach(PerformanceGateStage.resolutions, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.segmented)
            Picker("Kuas", selection: Binding(get: { stage.brushes }, set: stage.setBrushes)) {
                ForEach(PerformanceGateStage.brushCounts, id: \.self) { Text("\($0) kuas").tag($0) }
            }
            .pickerStyle(.segmented)
            Picker("Batas fps", selection: Binding(get: { stage.frameRate }, set: stage.setFrameRate)) {
                ForEach(PerformanceGateStage.frameRates, id: \.self) { Text("\($0) fps").tag($0) }
            }
            .pickerStyle(.segmented)
            Toggle("Tekstur NCA", isOn: Binding(get: { stage.texture }, set: stage.setTexture))
                .font(.callout)

            HStack {
                Button(copied ? "Tersalin" : "Salin hasil") {
                    UIPasteboard.general.string = stage.summary
                    copied = true
                }
                Button("Beranda", action: router.home)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .frame(width: 430)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(16)
    }

    private func verdictText(_ r: PerformanceGateStage.Reading) -> String {
        switch r.verdict {
        case .good: "LOLOS"
        case .tight: "MEPET"
        case .over: "GAGAL"
        }
    }

    private func color(_ verdict: FrameBudget.Verdict) -> Color {
        switch verdict {
        case .good: .green
        case .tight: .orange
        case .over: .red
        }
    }
}

// The 3D view that shows the stage's canvas scene.
private struct GateSceneView: UIViewRepresentable {
    let stage: PerformanceGateStage

    func makeUIView(context: Context) -> GateSCNView {
        let view = GateSCNView(frame: .zero, options: nil)
        view.antialiasingMode = .multisampling4X
        view.rendersContinuously = true
        view.preferredFramesPerSecond = stage.frameRate
        view.isPlaying = true
        view.onLayout = { [stage] size in stage.fit(size: size) }
        return view
    }

    func updateUIView(_ view: GateSCNView, context: Context) {
        _ = stage.sceneVersion
        view.preferredFramesPerSecond = stage.frameRate
        view.scene = stage.easel.scene
        view.pointOfView = stage.easel.cameraNode
        stage.fit(size: view.bounds.size)
    }
}

private final class GateSCNView: SCNView {
    var onLayout: ((CGSize) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?(bounds.size)
    }
}

#Preview(traits: .landscapeLeft) {
    PerformanceGateView(router: AppRouter())
}
