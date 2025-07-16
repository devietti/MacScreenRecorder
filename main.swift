//
//  main.swift
//  MacScreenRecorder
//
// This program records the entire screen to a specified .mov file. When this process receives a
// SIGINT, SIGTERM or SIGUSR1 signal, it will stop the recording and then exit.
//

import Foundation
import AVFoundation

// Global signal flag
var shouldStopRecording = false

// Signal handler
func handleSignal(_ signal: Int32) {
    shouldStopRecording = true
}

class MyRecordingDelegate : NSObject {}
extension MyRecordingDelegate: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        // intentionally empty
    }
}

func main() {
    if CommandLine.arguments.count != 2 {
        print("usage: \(CommandLine.arguments[0]) output/video/path.mov")
        exit(1)
    }

    var moviePath = CommandLine.arguments[1]
    if !moviePath.hasSuffix(".mov") {
        moviePath += ".mov"
    }
    
    signal(SIGINT, handleSignal)
    signal(SIGTERM, handleSignal)
    signal(SIGUSR1, handleSignal)

    print("Recording screen to \(moviePath)...")

    let screenInput = AVCaptureScreenInput()
    screenInput.capturesCursor = true
    screenInput.capturesMouseClicks = true
    let captureSession = AVCaptureSession()
    assert(captureSession.canAddInput(screenInput))
    captureSession.addInput(screenInput)
    let recordingDelegate = MyRecordingDelegate()

    let movieOutput = AVCaptureMovieFileOutput()
    captureSession.addOutput(movieOutput)
    captureSession.startRunning()
    movieOutput.startRecording(to: URL.init(fileURLWithPath: moviePath),
                               recordingDelegate: recordingDelegate)

    while !shouldStopRecording {
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
    }

    movieOutput.stopRecording()
    captureSession.stopRunning()
    captureSession.removeOutput(movieOutput)

    print("Screen recording complete.")
}

main()
