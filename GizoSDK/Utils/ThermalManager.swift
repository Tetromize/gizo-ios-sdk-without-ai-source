//
//  ThermalManager.swift
//  GizoSDK
//
//  Created by Meysam Farmani on 2/13/24.
//

import Foundation

protocol ThermalMonitorDelegate: AnyObject {
    func thermalStateDidChange(to state: ProcessInfo.ThermalState)
}

class ThermalMonitor {
    weak var delegate: ThermalMonitorDelegate?
    public var gizoAnalysisDelegate: GizoAnalysisDelegate?
    
    init() {
        addObserver()
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(thermalStateDidChange), name: ProcessInfo.thermalStateDidChangeNotification, object: nil)
    }
    
    @objc private func thermalStateDidChange() {
        let thermalState = ProcessInfo.processInfo.thermalState
        delegate?.thermalStateDidChange(to: thermalState)
        self.gizoAnalysisDelegate?.onThermalStatusChange(state: thermalState)
    }
    
    public func currentThermal(){
        thermalStateDidChange()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
