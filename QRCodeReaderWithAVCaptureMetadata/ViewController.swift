//
//  ViewController.swift
//  QRCodeReaderWithAVCaptureMetadata
//
//  Created by hiraya.shingo on 2019/01/18.
//  Copyright © 2019 shingo.hiraya. All rights reserved.
//

import UIKit
import AVFoundation
import SafariServices

class ViewController: UIViewController {
    @IBOutlet weak var guideView: UIView!

    let captureSession = AVCaptureSession()
    var videoLayer: AVCaptureVideoPreviewLayer?
    var metadataOutput: AVCaptureMetadataOutput?

    var layouted = false
    var captured = false

    override func viewDidLoad() {
        super.viewDidLoad()
        prepareCamera()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCapture()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !layouted else { return }
        layouted = true
        prepareRectOfInterest()
    }

    @IBAction func closeButtonDidTap(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !captured else { return }
        guard let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            metadata.type == .qr,
            let text = metadata.stringValue,
            let url = URL(string: text) else { return }
        captureSession.stopRunning()
        captured = true
        present(SFSafariViewController(url: url), animated: true)
        print("text:\(text)")
    }
}

private extension ViewController {
    func prepareCamera() {
        // 入力（背面カメラ）
        let videoDevice = AVCaptureDevice.default(for: .video)
        let videoInput = try! AVCaptureDeviceInput(device: videoDevice!)
        captureSession.addInput(videoInput)

        // 出力（メタデータ）
        let metadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(metadataOutput)
        self.metadataOutput = metadataOutput
        // QRコードを検出した際のデリゲート設定
        metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
        // QRコードの認識を指定
        metadataOutput.metadataObjectTypes = [.qr]

        // プレビュー表示
        videoLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoLayer?.frame = view.bounds
        videoLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(videoLayer!)

        // 正方形のガイド表示
        guideView.backgroundColor = .clear
        guideView.layer.borderWidth = 2
        guideView.layer.borderColor = UIColor.darkGray.cgColor
        view.bringSubview(toFront: guideView)
    }

    func prepareRectOfInterest() {
        // 参考: https://qiita.com/tomosooon/items/9cb7bf161a9f76f3199b#%E8%AA%AD%E3%81%BF%E5%8F%96%E3%82%8A%E7%AF%84%E5%9B%B2%E3%82%92%E6%8C%87%E5%AE%9A%E3%81%99%E3%82%8B
        // 検出対象のRectを作成(値は[0, 1]で正規化)
        let x = guideView.frame.minX / view.bounds.width
        let y = guideView.frame.minY / view.bounds.height
        let width = guideView.frame.width / view.bounds.width
        let height = guideView.frame.height / view.bounds.height
        // カメラの向きが横扱いなので、変換する
        let rectOfInterest = CGRect(x: y,
                                    y: 1 - x - width,
                                    width: height,
                                    height: width)
        metadataOutput?.rectOfInterest = rectOfInterest
    }

    func startCapture() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
}
