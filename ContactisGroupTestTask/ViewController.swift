//
//  ViewController.swift
//  ContactisGroupTestTask
//
//  Created by Siarhei Yakushevich on 7/26/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var resultOfExpressions: UILabel!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    
    let analyzer = TextAnalyzer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        microphoneButton.isEnabled = false
        let queue = OperationQueue()
        queue.name = "vc.queue"
        queue.maxConcurrentOperationCount = 20
        speechRecognizer.queue = OperationQueue()
        speechRecognizer.delegate = self
        
        
        if SFSpeechRecognizer.authorizationStatus() == .notDetermined {
            SFSpeechRecognizer.requestAuthorization { (authStatus) in
                
                var isButtonEnabled = false
                
                switch authStatus {
                case .authorized:
                    isButtonEnabled = true
                    
                case .denied:
                    isButtonEnabled = false
                    print("User denied access to speech recognition")
                    
                case .restricted:
                    isButtonEnabled = false
                    print("Speech recognition restricted on this device")
                    
                case .notDetermined:
                    isButtonEnabled = false
                    print("Speech recognition not yet authorized")
                }
                
                OperationQueue.main.addOperation() {
                    self.microphoneButton.isEnabled = isButtonEnabled
                }
            }
        }
        else if SFSpeechRecognizer.authorizationStatus() != .authorized {
            let alertVC = UIAlertController(title: "Warning", message: "Please allow speech recognition", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertVC.addAction(okAction)
            if (self.presentedViewController != nil) {
                self.dismiss(animated: false, completion: nil)
            }
            self.present(alertVC, animated: true, completion: nil)
        }
        else {
            microphoneButton.isEnabled = true
        }
    }
    
    @IBAction func microphoneTapped(_ sender: AnyObject) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    func startRecording() {
        
        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }  //4
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        } //5
        
        recognitionRequest.shouldReportPartialResults = true  //6
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
            
            var isFinal = false  //8
            var detectedText: String? = nil
            
            if result != nil {
                detectedText = result?.bestTranscription.formattedString//.first?.formattedString  //9
                isFinal = (result?.isFinal)!
                DispatchQueue.main.async { [unowned self]  in
                   self.textView.text = detectedText
                }
            }
            
            if error != nil || isFinal {  //10
                DispatchQueue.main.async { [unowned self]  in
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    
                    self.microphoneButton.isEnabled = true
                }
                
                if let text = detectedText {
                    let convertedText = NativeSpeechAdapter.convertToWords(mixedText: text)
                    self.analyzer.text = convertedText
                    self.analyzer.analyze(completion: {(value) in
                        let valueStr = TextAnalyzer.convertToString(value)
                        DispatchQueue.main.async { [unowned self]  in
                            self.resultOfExpressions.text = valueStr
                        }
                    })
                }
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()  //12
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView.text = "Say something, I'm listening!"
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        OperationQueue.main.addOperation() {
            self.microphoneButton.isEnabled = available
        }
        
    }
}

