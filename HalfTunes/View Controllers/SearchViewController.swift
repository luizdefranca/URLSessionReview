/// Copyright (c) 2019 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import AVFoundation
import AVKit
import UIKit

//
// MARK: - Search View Controller
//
class SearchViewController: UIViewController {
  //
  // MARK: - Constants
  //
  
  /// Get local file path: download task stores tune here; AV player plays it.
  let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
  
  let downloadService = DownloadService()
  let queryService = QueryService()
  
  //
  // MARK: - IBOutlets
  //
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var searchBar: UISearchBar!
  
  //
  // MARK: - Variables And Properties
  //
  // TODO 6
  lazy var downloadsSession: URLSession = {
    let configuration = URLSessionConfiguration.default
    return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
  }()

  var searchResults: [Track] = []
  
  lazy var tapRecognizer: UITapGestureRecognizer = {
    var recognizer = UITapGestureRecognizer(target:self, action: #selector(dismissKeyboard))
    return recognizer
  }()
  
  //
  // MARK: - Internal Methods
  //
  @objc func dismissKeyboard() {
    searchBar.resignFirstResponder()
  }
  
  func localFilePath(for url: URL) -> URL {
    return documentsPath.appendingPathComponent(url.lastPathComponent)
  }
  
  func playDownload(_ track: Track) {
    let playerViewController = AVPlayerViewController()
    present(playerViewController, animated: true, completion: nil)
    
    let url = localFilePath(for: track.previewURL)
    let player = AVPlayer(url: url)
    playerViewController.player = player
    player.play()
  }
  
  func position(for bar: UIBarPositioning) -> UIBarPosition {
    return .topAttached
  }
  
  func reload(_ row: Int) {
    tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
  }
  
  //
  // MARK: - View Controller
  //
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.tableFooterView = UIView()
    
    // TODO 7
    /*
     This sets the downloadsSession property of DownloadService to the session you just defined.
     */
    downloadService.downloadsSession = downloadsSession
  }
  
}

//
// MARK: - Search Bar Delegate
//
extension SearchViewController: UISearchBarDelegate {
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    dismissKeyboard()
    
    guard let searchText = searchBar.text, !searchText.isEmpty else {
      return
    }
    
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    
    queryService.getSearchResults(searchTerm: searchText) { [weak self] results, errorMessage in
      UIApplication.shared.isNetworkActivityIndicatorVisible = false
      
      if let results = results {
        self?.searchResults = results
        self?.tableView.reloadData()
        self?.tableView.setContentOffset(CGPoint.zero, animated: false)
      }
      
      if !errorMessage.isEmpty {
        print("Search error: " + errorMessage)
      }
    }
  }
  
  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    view.addGestureRecognizer(tapRecognizer)
  }
  
  func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    view.removeGestureRecognizer(tapRecognizer)
  }
}

//
// MARK: - Table View Data Source
//
extension SearchViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: TrackCell = tableView.dequeueReusableCell(withIdentifier: TrackCell.identifier,
                                                        for: indexPath) as! TrackCell
    // Delegate cell button tap events to this view controller.
    cell.delegate = self
    
    let track = searchResults[indexPath.row]
    // TODO 13
    cell.configure(track: track, downloaded: track.downloaded)
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return searchResults.count
  }
}

//
// MARK: - Table View Delegate
//
extension SearchViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    //When user taps cell, play the local file, if it's downloaded.
    
    let track = searchResults[indexPath.row]
    
    if track.downloaded {
      playDownload(track)
    }
    
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 62.0
  }
}

//
// MARK: - Track Cell Delegate
//
extension SearchViewController: TrackCellDelegate {
  func cancelTapped(_ cell: TrackCell) {
    if let indexPath = tableView.indexPath(for: cell) {
      let track = searchResults[indexPath.row]
      downloadService.cancelDownload(track)
      reload(indexPath.row)
    }
  }
  
  func downloadTapped(_ cell: TrackCell) {
    if let indexPath = tableView.indexPath(for: cell) {
      let track = searchResults[indexPath.row]
      downloadService.startDownload(track)
      reload(indexPath.row)
    }
  }
  
  func pauseTapped(_ cell: TrackCell) {
    if let indexPath = tableView.indexPath(for: cell) {
      let track = searchResults[indexPath.row]
      downloadService.pauseDownload(track)
      reload(indexPath.row)
    }
  }
  
  func resumeTapped(_ cell: TrackCell) {
    if let indexPath = tableView.indexPath(for: cell) {
      let track = searchResults[indexPath.row]
      downloadService.resumeDownload(track)
      reload(indexPath.row)
    }
  }
}

// TODO 19

// TODO 5
extension SearchViewController: URLSessionDownloadDelegate {

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                  didFinishDownloadingTo location: URL) {
    print("Finished download to \(location)")

    /*
     You extract the original request URL from the task, look up the corresponding Download in your
     active downloads and remove it from that dictionary.
     */
    guard let sourceURL = downloadTask.originalRequest?.url else {
      return
    }
    let download = downloadService.activeDownloads[sourceURL]
    downloadService.activeDownloads[sourceURL] = nil

    /*
     You then pass the URL to localFilePath(for:), which generates a permanent local file path to
     save to by appending the lastPathComponent of the URL (the file name and extension of the file)
     to the path of the app’s Documents directory.
     */
    let destinationURL = localFilePath(for: sourceURL)
    print(destinationURL)

    /*
     Using fileManager, you move the downloaded file from its temporary file location to the desired
     destination file path, first clearing out any item at that location before you start the copy
     task. You also set the download track’s downloaded property to true.
     */
    let fileManager = FileManager.default
    try? fileManager.removeItem(at: destinationURL)

    do {
      try fileManager.copyItem(at: location, to: destinationURL)
      download?.track.downloaded = true
    } catch let error {
      print("Could not copy file to disk: \(error.localizedDescription)" +
        "/n\(#file) - \(#function) - \(#line)")
    }

    /*
     Finally, you use the download track’s index property to reload the corresponding cell.
     */
    if let index = download?.track.index {
      DispatchQueue.main.async { [weak self] in
        self?.reload(index)
      }
    }
  }
}
