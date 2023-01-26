//
//  SettingsStore.swift
//  NFCPassportReaderApp
//
//  Created by Andy Qua on 10/02/2021.
//  Copyright © 2021 Andy Qua. All rights reserved.
//

import SwiftUI
import Combine
import NFCPassportReader

class SettingsStore {

    private enum Keys {
        static let captureLog = "captureLog"
        static let logLevel = "logLevel"
        static let passportNumber = "passportNumber"
        static let dateOfBirth = "dateOfBirth"
        static let dateOfExpiry = "dateOfExpiry"

        static let allVals = [captureLog, logLevel, passportNumber, dateOfBirth, dateOfExpiry]
    }
    
    private let cancellable: Cancellable
    private let defaults: UserDefaults
    
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        

        defaults.register(defaults: [
            Keys.captureLog: true,
            Keys.logLevel: 1,
            Keys.passportNumber: "",
            Keys.dateOfBirth: "",
            Keys.dateOfExpiry: "",
        ])
        
        cancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .map { _ in () }
            .subscribe(objectWillChange)
    }
    
    func reset() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
    
    var shouldCaptureLogs: Bool {
        set { defaults.set(newValue, forKey: Keys.captureLog) }
        get { defaults.bool(forKey: Keys.captureLog) }
    }
    
    var logLevel: LogLevel {
        get {
            return LogLevel(rawValue:defaults.integer(forKey: Keys.logLevel)) ?? .info
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.logLevel)
        }
    }
    
    
    
    var passportNumber: String {
        set { defaults.set(newValue, forKey: Keys.passportNumber) }
        get { defaults.string(forKey: Keys.passportNumber) ?? "" }
    }
    var dateOfBirth: String {
        set { defaults.set(newValue, forKey: Keys.dateOfBirth) }
        get { defaults.string(forKey: Keys.dateOfBirth) ?? "" }
    }
    var dateOfExpiry: String {
        set { defaults.set(newValue, forKey: Keys.dateOfExpiry) }
        get { defaults.string(forKey: Keys.dateOfExpiry) ?? "" }
    }



    
    @Published var passport : NFCPassportModel?
}

