import UIKit
import AVFoundation

class VideoSaver: NSObject {
    
    private var completion: ((Bool) -> Void)?
    
    // MARK: - Saving Video to Gallery
    
    func saveVideoToGallery(videoURL: URL, completion: @escaping (Bool) -> Void) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: videoURL.path) {
            self.completion = completion
            UISaveVideoAtPathToSavedPhotosAlbum(videoURL.path, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            print("Video file does not exist at path: \(videoURL.path)")
            completion(false)
        }
    }
    
    @objc private func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving video: \(error.localizedDescription)")
            completion?(false)
        } else {
            print("Video saved successfully to gallery.")
            completion?(true)
        }
        completion = nil
    }
}
