//
//  ViewController.swift
//  Multithreading
//
//  Created by Farhan on 08/08/2022.
//

import UIKit

class ViewController: UIViewController {

    //MARK: IBOutlets
    @IBOutlet private var imageViews: [UIImageView]!
    @IBOutlet private var progressBars: [UIProgressView]!
    
    //MARK: Properties
    let imagesURL = ["https://archive.org/download/4kwallpapersforpc110629600312_202003/4k-wallpapers-for-pc_110629600_312.jpg", "https://wallpaperaccess.com/full/2859272.jpg", "https://wallpapercave.com/wp/wp1942922.jpg"]

    //MARK: View Life Cycel
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for (index,urlString) in imagesURL.enumerated() {
            multiDownload(from: urlString, for: imageViews[index], with: progressBars[index])
        }
    }

    //MARK: Download Images
    private func multiDownload(from urlString: String, for imageView: UIImageView, with progressBar: UIProgressView) {
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        var downloadTask: DownloadTask?
        downloadTask = DownloadService.shared.download(request: request)
        
        downloadTask?.completionHandler = { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .failure(let error): print(error)
            case .success(let data): DispatchQueue.main.async { imageView.image = UIImage(data: data) }
            }
            
            downloadTask = nil
        }
        
        downloadTask?.progressHandler = { [weak self] progress in
            guard self != nil else { return }
            progressBar.progress = Float(progress)
        }
        
        imageView.image = UIImage()
        progressBar.progress = 0
        downloadTask?.resume()
    }
}
