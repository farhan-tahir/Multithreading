//
//  DownloadService.swift
//  Multithreading
//
//  Created by Farhan on 09/08/2022.
//

import Foundation
import UIKit

public enum ResultType<T> {
    
    public typealias Completion = (ResultType<T>) -> Void
    
    case success(T)
    case failure(Swift.Error)
    
}

protocol DownloadTask {
    
    var completionHandler: ResultType<Data>.Completion? { get set }
    var progressHandler: ((Double) -> Void)? { get set }
    
    func resume()
    func suspend()
    func cancel()
}

class GenericDownloadTask {
    
    var completionHandler: ResultType<Data>.Completion?
    var progressHandler: ((Double) -> Void)?
    
    private(set) var task: URLSessionDataTask
    var expectedContentLength: Int64 = 0
    var buffer = Data()
    
    init(task: URLSessionDataTask) { self.task = task }
    
    deinit { print("Deinit: \(task.originalRequest?.url?.absoluteString ?? "")") }
    
}

extension GenericDownloadTask: DownloadTask {
    
    func resume() { task.resume() }
    
    func suspend() { task.suspend() }
    
    func cancel() { task.cancel() }
}

final class DownloadService: NSObject {
    
    private var session: URLSession!
    private var downloadTasks = [GenericDownloadTask]()
    
    public static let shared = DownloadService()
    
    private override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
    }
    
    func download(request: URLRequest) -> DownloadTask {
        let task = session.dataTask(with: request)
        let downloadTask = GenericDownloadTask(task: task)
        downloadTasks.append(downloadTask)
        return downloadTask
    }
}


extension DownloadService: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        guard let task = downloadTasks.first(where: { $0.task == dataTask }) else {
            completionHandler(.cancel)
            return
        }
        task.expectedContentLength = response.expectedContentLength
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let task = downloadTasks.first(where: { $0.task == dataTask }) else {
            return
        }
        task.buffer.append(data)
        let percentageDownloaded = Double(task.buffer.count) / Double(task.expectedContentLength)
        DispatchQueue.main.async { task.progressHandler?(percentageDownloaded) }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let index = downloadTasks.firstIndex(where: { $0.task == task }) else { return }
        let task = downloadTasks.remove(at: index)
        DispatchQueue.main.async {
            if let error = error { task.completionHandler?(.failure(error)) }
            else { task.completionHandler?(.success(task.buffer)) }
        }
    }
}
