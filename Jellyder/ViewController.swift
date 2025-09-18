//
//  ViewController.swift
//  Jellyder
//
//  Created by BAHATTIN KOC on 15.09.2025.
//

import UIKit

/**
 * Main view controller that demonstrates the BeamComponent
 * This controller shows how to use the custom beam component and respond to its events
 */
final class ViewController: UIViewController, BeamComponentDelegate {

    // MARK: - UI Components
    private var beamComponent: BeamComponent!
    private let gradientLayer = CAGradientLayer()
    private var valueLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGradientBackground()
        setupBeamComponent()
        setupValueLabel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    // MARK: - UI Setup

    /**
     * Sets up the main user interface
     */
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Jellyder Simulation"
    }

    private func setupGradientBackground() {
        gradientLayer.colors = [
            UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1).cgColor,
            UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1).cgColor,
            UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1).cgColor,
            UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1).cgColor,
            UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1).cgColor,
            UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0.0)
        gradientLayer.endPoint   = CGPoint(x: 0.8, y: 1.0)

        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    /**
     * Creates and configures the beam component
     */
    private func setupBeamComponent() {
        beamComponent = BeamComponent()
        beamComponent.delegate = self
        beamComponent.translatesAutoresizingMaskIntoConstraints = false
        beamComponent.backgroundColor = .clear
        view.addSubview(beamComponent)

        NSLayoutConstraint.activate([
            beamComponent.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            beamComponent.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            beamComponent.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            beamComponent.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80)
        ])
    }

    /**
     * Creates and configures the value display label
     */
    private func setupValueLabel() {
        valueLabel = UILabel()
        valueLabel.text = "100"
        valueLabel.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        valueLabel.textColor = .white
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.backgroundColor = .clear

        view.addSubview(valueLabel)
        DispatchQueue.main.async {
            NSLayoutConstraint.activate([
                self.valueLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                self.valueLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 50),
                self.valueLabel.heightAnchor.constraint(equalToConstant: 100)
            ])
        }
    }

    // MARK: - BeamComponentDelegate

    /**
     * Called when the beam compression changes
     */
    func beamComponent(_ component: BeamComponent, didChangeCompression compression: CGFloat) {
        // You can handle compression changes here.
    }

    /**
     * Called when the beam wobble amplitude changes
     */
    func beamComponent(_ component: BeamComponent, didChangeWobbleAmplitude amplitude: CGFloat) {
        // You can handle wobble changes here.
    }

    /**
     * Called when the slider value changes
     */
    func beamComponent(_ component: BeamComponent, didChangeSliderValue value: Int) {
        valueLabel.text = "\(value)"

        // Add a subtle animation when value changes
        UIView.animate(withDuration: 0.1, animations: {
            self.valueLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.valueLabel.transform = .identity
            }
        }
    }
}
