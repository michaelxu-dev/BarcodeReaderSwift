import AVFoundation
import UIKit

protocol ScannerViewControllerDelegate: AnyObject {
    func scanner(_ controller: ScannerViewController, didScan text: String, symbology: String)
    func scannerDidCancel(_ controller: ScannerViewController)
    func scanner(_ controller: ScannerViewController, didFailWith message: String)
}

/// Live camera preview that reports the first barcode it decodes, then stops.
final class ScannerViewController: UIViewController {
    weak var delegate: ScannerViewControllerDelegate?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.sagua.barcodereader.session")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var device: AVCaptureDevice?
    /// Set once a barcode is reported, so a single scan doesn't fire repeatedly.
    private var hasReported = false

    private let reticle = UIView()
    private let hintLabel = UILabel()
    private let torchButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        buildOverlay()
        requestAccessAndConfigure()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasReported = false
        startRunning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        previewLayer?.connection?.videoRotationAngle = currentRotationAngle
    }

    // MARK: - Session

    private func requestAccessAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    granted
                        ? self.configureSession()
                        : self.delegate?.scanner(self, didFailWith: "Camera access was denied.")
                }
            }
        default:
            delegate?.scanner(self, didFailWith: "Camera access is denied. Enable it in Settings to scan barcodes.")
        }
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            delegate?.scanner(self, didFailWith: "No usable camera is available on this device.")
            return
        }
        self.device = device

        let output = AVCaptureMetadataOutput()
        session.beginConfiguration()
        session.sessionPreset = .high
        session.addInput(input)
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            delegate?.scanner(self, didFailWith: "Barcode scanning is not available on this device.")
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        // Must be set after the output is attached to the session.
        output.metadataObjectTypes = BarcodeSymbology.supported.filter {
            output.availableMetadataObjectTypes.contains($0)
        }
        session.commitConfiguration()

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)
        previewLayer = preview

        torchButton.isHidden = !device.hasTorch
        startRunning()
    }

    private func startRunning() {
        guard previewLayer != nil else { return }
        sessionQueue.async { [session] in
            if !session.isRunning { session.startRunning() }
        }
    }

    private var currentRotationAngle: CGFloat {
        switch view.window?.windowScene?.interfaceOrientation {
        case .landscapeLeft: return 180
        case .landscapeRight: return 0
        case .portraitUpsideDown: return 270
        default: return 90
        }
    }

    // MARK: - Overlay

    private func buildOverlay() {
        reticle.layer.borderColor = UIColor.systemGreen.cgColor
        reticle.layer.borderWidth = 3
        reticle.layer.cornerRadius = 12
        reticle.backgroundColor = .clear
        reticle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reticle)

        hintLabel.text = "Hold the camera up to a barcode"
        hintLabel.textColor = .white
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 0
        hintLabel.font = .preferredFont(forTextStyle: .headline)
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)

        configure(torchButton, systemImage: "flashlight.off.fill", action: #selector(toggleTorch))
        configure(cancelButton, systemImage: "xmark", action: #selector(cancel))

        NSLayoutConstraint.activate([
            reticle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            reticle.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            reticle.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            reticle.heightAnchor.constraint(equalTo: reticle.widthAnchor, multiplier: 0.65),

            hintLabel.bottomAnchor.constraint(equalTo: reticle.topAnchor, constant: -24),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            cancelButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            cancelButton.widthAnchor.constraint(equalToConstant: 56),
            cancelButton.heightAnchor.constraint(equalToConstant: 56),

            torchButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            torchButton.bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor),
            torchButton.widthAnchor.constraint(equalToConstant: 56),
            torchButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func configure(_ button: UIButton, systemImage: String, action: Selector) {
        button.setImage(UIImage(systemName: systemImage), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        button.layer.cornerRadius = 28
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)
        view.addSubview(button)
    }

    @objc private func toggleTorch() {
        guard let device, device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = device.torchMode == .on ? .off : .on
        let image = device.torchMode == .on ? "flashlight.on.fill" : "flashlight.off.fill"
        torchButton.setImage(UIImage(systemName: image), for: .normal)
        device.unlockForConfiguration()
    }

    @objc private func cancel() {
        delegate?.scannerDidCancel(self)
    }
}

extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !hasReported,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let text = object.stringValue, !text.isEmpty else { return }

        hasReported = true
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        delegate?.scanner(self, didScan: text, symbology: BarcodeSymbology.displayName(for: object.type))
    }
}
