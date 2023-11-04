//
//  AVURLAsset+Extension.swift
//  Voli XD
//
//  Created by Tao Man Kit on 19/12/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import AVKit

extension AVURLAsset {
    func processVideoAssets(_ completionHandler: ((String, String) -> Void)? = nil) {
        let destinationPath = URL(
            fileURLWithPath: NSTemporaryDirectory()
        ).appendingPathComponent("compressed.mp4")
        
        let destinationThumbnailPath = URL(
            fileURLWithPath: NSTemporaryDirectory()
        ).appendingPathComponent("compressedThumbnail.jpg")
        try? FileManager.default.removeItem(at: destinationPath)
        try? FileManager.default.removeItem(at: destinationThumbnailPath)
        // Compress
        guard let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetMediumQuality) else { return }
        exportSession.outputURL = destinationPath
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            
            switch exportSession.status {
            case .unknown:
                print("unknown")
                break
            case .waiting:
                print("waiting")
                break
            case .exporting:
                print("exporting")
                break
            case .completed:
                print(destinationPath)
                let assetImgGenerate = AVAssetImageGenerator(asset: self)
                assetImgGenerate.appliesPreferredTrackTransform = true
                let time = CMTimeMake(value: 1, timescale: 30)
                if let img = try? assetImgGenerate.copyCGImage(at: time, actualTime: nil) {
                    do {
                        try UIImage(cgImage: img).resizeToNormal().saveToPath(destinationThumbnailPath.path)
                        completionHandler?(destinationPath.path, destinationThumbnailPath.path)
                    } catch {
                        completionHandler?(destinationPath.path, "")
                    }
                    
                } else {
                    completionHandler?(destinationPath.path, "")
                }
                
                break

            case .failed:
                print("failed")
                completionHandler?("", "")
                break
            case .cancelled:
                print("cancelled")
                completionHandler?("", "")
                break
            }
        }
    }
}

