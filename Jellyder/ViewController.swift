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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBeamComponent()
    }
    
    // MARK: - UI Setup
    
    /**
     * Sets up the main user interface
     */
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Beam Simulation"
    }
    
    /**
     * Creates and configures the beam component
     */
    private func setupBeamComponent() {
        beamComponent = BeamComponent()
        beamComponent.delegate = self
        beamComponent.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(beamComponent)
        
        NSLayoutConstraint.activate([
            beamComponent.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            beamComponent.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            beamComponent.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            beamComponent.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
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
}
