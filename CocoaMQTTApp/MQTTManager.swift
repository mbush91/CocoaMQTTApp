//
//  MQTTManager.swift
//  CocoaMQTTApp
//
//  Created by Mike Bush on 10/15/24.
//
import CocoaMQTT
import SwiftUI

class MQTTManager: NSObject, ObservableObject, CocoaMQTTDelegate {
    @Published var connectionStatus = "Connecting..."
    var mqtt: CocoaMQTT?
    
    override init() {
        super.init()
        setupMQTT()
    }
    
    func getClientCertFromP12File(certName: String, certPassword: String) -> CFArray? {
        let resourcePath = Bundle.main.path(forResource: certName, ofType: "p12")
        
        guard let filePath = resourcePath, let p12Data = NSData(contentsOfFile: filePath) else {
            NSLog("Failed to open the certificate file: \(certName).p12")
            return nil
        }
        
        let key = kSecImportExportPassphrase as String
        let options: NSDictionary = [key: certPassword]
        
        var items: CFArray?
        let securityError = SecPKCS12Import(p12Data, options, &items)
        
        guard securityError == errSecSuccess else {
            if securityError == errSecAuthFailed {
                NSLog("ERROR: SecPKCS12Import returned errSecAuthFailed. Incorrect password?")
            } else {
                NSLog("Failed to open the certificate file: \(certName).p12")
            }
            return nil
        }
        
        guard let theArray = items, CFArrayGetCount(theArray) > 0 else {
            return nil
        }
        
        let dictionary = (theArray as NSArray).object(at: 0)
        guard let identity = (dictionary as AnyObject).value(forKey: kSecImportItemIdentity as String) else {
            return nil
        }
        let certArray = [identity] as CFArray
        
        return certArray
    }
    
    func setupMQTT() {
        let clientID = "your_client_id_here"
        let host = "your_host_here"
        let certPassword = "somepassword"
        let certName = "client"
        
        mqtt = CocoaMQTT(clientID: clientID, host: host, port: 8883)
        guard let mqtt = mqtt else { return }
        
        mqtt.logLevel = .debug
        mqtt.enableSSL = true
        mqtt.allowUntrustCACertificate = false // Disable untrusted CA certificates
        mqtt.delegate = self
        
        if let clientCertArray = getClientCertFromP12File(certName: certName, certPassword: certPassword) {
            var sslSettings: [String: NSObject] = [:]
            sslSettings[kCFStreamSSLCertificates as String] = clientCertArray
            
            // Load the CA certificate
            if let caCertPath = Bundle.main.path(forResource: certName, ofType: "der"),
               let caCertData = try? Data(contentsOf: URL(fileURLWithPath: caCertPath)) {
                
                if let caCert = SecCertificateCreateWithData(nil, caCertData as CFData) {
                    print("CA Certificate Loaded: \(caCert)")
                    // CA certificate is loaded, but manual trust evaluation will be used
                } else {
                    NSLog("Failed to create CA certificate from data")
                }
            } else {
                NSLog("CA certificate not found or failed to load")
            }
            
            // Assign the server hostname for peer name verification
            sslSettings[kCFStreamSSLPeerName as String] = host as NSString  // Use the server hostname here
            
            mqtt.sslSettings = sslSettings
        } else {
            NSLog("Failed to load client certificates")
        }
        
        mqtt.connect(timeout: 30)
    }
    
    // MARK: - CocoaMQTTDelegate Methods (Required)
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        NSLog("Received ConnAck: \(ack)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        NSLog("Published message: \(message.string ?? "") to topic \(message.topic)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        NSLog("Message with id \(id) was acknowledged")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        NSLog("Received message: \(message.string ?? "") on topic \(message.topic)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        NSLog("Subscribed to topics: \(success) with failures: \(failed)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        NSLog("Unsubscribed from topics: \(topics)")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        NSLog("MQTT ping sent")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        NSLog("MQTT pong received")
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        NSLog("Disconnected with error: \(String(describing: err))")
        DispatchQueue.main.async {
            self.connectionStatus = "Disconnected"
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        // Perform manual trust evaluation
        var result = SecTrustResultType.invalid
        let status = SecTrustEvaluate(trust, &result)
        
        if status == errSecSuccess, (result == .unspecified || result == .proceed) {
            NSLog("Server certificate trusted")
            completionHandler(true)  // Trust the certificate
        } else {
            NSLog("Server certificate not trusted")
            completionHandler(false)  // Do not trust the certificate
        }
    }
    
    // Optionally handle URL session challenges (useful in some configurations)
    func mqttUrlSession(_ mqtt: CocoaMQTT, didReceiveTrust trust: SecTrust, didReceiveChallenge challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Handle URL session challenge here if needed
        NSLog("Received URL session challenge for validation")
        completionHandler(.useCredential, nil) // For now, use the default credential
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishComplete id: UInt16) {
        NSLog("Publishing of message with id \(id) is complete")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        NSLog("Connection state changed to \(state)")
    }
}
