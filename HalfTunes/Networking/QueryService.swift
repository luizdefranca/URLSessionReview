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

import Foundation

//
// MARK: - Query Service
//

/// Runs query data task, and stores results in array of Tracks
class QueryService {
  //
  // MARK: - Constants
  //
  let defaultSession = URLSession(configuration: .default)
  let baseURL : String = "https://itunes.apple.com/search"
  
  //
  // MARK: - Variables And Properties
  //
  // TODO 2
  var errorMessage = ""
  var tracks: [Track] = []
  var dataTask: URLSessionDataTask?
  
  //
  // MARK: - Type Alias
  //
  typealias JSONDictionary = [String: Any]
  typealias QueryResult = ([Track]?, String) -> Void
  
  //
  // MARK: - Internal Methods
  //
  func getSearchResults(searchTerm: String, completion: @escaping QueryResult) {
    // TODO 3

    /*
     For a new user query, you cancel any data task that already exists, because you want to reuse
     the data task object for this new query
     */
    dataTask?.cancel()

    /*
     To include the user’s search string in the query URL, you create URLComponents from the iTunes
     Search base URL, then set its query string. This ensures that your search string uses escaped
     characters.
     */
    if var urlComponents = URLComponents(string: baseURL) {
      urlComponents.query = "media=music&entity=song&term=\(searchTerm)"

      /*
       The url property of urlComponents is optional, so you unwrap it to url and return early
       if it’s nil.
       */

      guard let url = urlComponents.url else {
        return
      }

      /*
       From the session you created, you initialize a URLSessionDataTask with the query url and a
       completion handler to call when the data task completes.
       */
      dataTask = defaultSession.dataTask(with: url,
           completionHandler: { [weak self] data, response, error in

            defer {
              self?.dataTask = nil
            }

            /*
             If the request is successful, you call the helper method updateSearchResults, which
             parses the response data into the tracks array.
             */
            if let error = error {
              self?.errorMessage += "Data error: " +
              error.localizedDescription + "\n"
            } else if let data = data,
              let response = response as? HTTPURLResponse,
              response.statusCode == 200 {
              self?.updateSearchResults(data)
            }
      })
    }

    /*
     You switch to the main queue to pass tracks to the completion handler.
     */

    DispatchQueue.main.async {
      completion(self.tracks, self.errorMessage)
    }
    /*
     All tasks start in a suspended state by default. Calling resume() starts the data task.
     */
    dataTask?.resume()
  }
  
  //
  // MARK: - Private Methods
  //
  private func updateSearchResults(_ data: Data) {
    var response: JSONDictionary?
    tracks.removeAll()
    
    do {
      response = try JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary
    } catch let parseError as NSError {
      errorMessage += "JSONSerialization error: \(parseError.localizedDescription)\n"
      return
    }
    
    guard let array = response!["results"] as? [Any] else {
      errorMessage += "Dictionary does not contain results key\n"
      return
    }
    
    var index = 0
    
    for  trackDictionary in array {
      if let trackDictionary = trackDictionary as? JSONDictionary,
        let previewURLString = trackDictionary["previewUrl"] as? String,
        let previewURL = URL(string: previewURLString),
        let name = trackDictionary["trackName"] as? String,
        let artist = trackDictionary["artistName"] as? String {
          tracks.append(Track(name: name, artist: artist, previewURL: previewURL, index: index))
          index += 1
      } else {
        errorMessage += "Problem parsing trackDictionary\n"
      }
    }
  }
}

