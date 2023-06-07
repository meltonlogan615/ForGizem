//
//  ViewController.swift
//  GizemMovieSearch
//
//  Created by Logan Melton on 6/7/23.
//

import UIKit

class ViewController: UIViewController {
  
  var searchBox: UITextField!
  var searchButton: UIButton!
  var table: UITableView!
  var searchResult: MovieResults?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    styleView()
    layoutView()
  }
}

extension ViewController {
  private func styleView() {
    searchBox = UITextField()
    searchBox.translatesAutoresizingMaskIntoConstraints = false
    searchBox.placeholder = "Search Movies"
    searchBox.tintColor = .darkGray
    
    searchButton = UIButton()
    searchButton.translatesAutoresizingMaskIntoConstraints = false
    var config = UIButton.Configuration.filled()
    config.title = "Search"
    config.buttonSize = .large
    searchButton.configuration = config
    searchButton.addTarget(self, action: #selector(searchButtonBooped), for: .touchUpInside)
    
    table = UITableView()
    table.translatesAutoresizingMaskIntoConstraints = false
    table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    table.dataSource = self
    table.backgroundColor = .systemPink
  }
  
  private func layoutView() {
    view.addSubview(searchBox)
    NSLayoutConstraint.activate([
      searchBox.topAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 2),
      searchBox.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 4),
      view.trailingAnchor.constraint(equalToSystemSpacingAfter: searchBox.trailingAnchor, multiplier: 4)
    ])
    
    view.addSubview(searchButton)
    NSLayoutConstraint.activate([
      searchButton.topAnchor.constraint(equalToSystemSpacingBelow: searchBox.bottomAnchor, multiplier: 2),
      searchButton.leadingAnchor.constraint(equalTo: searchBox.leadingAnchor),
      searchButton.trailingAnchor.constraint(equalTo: searchBox.trailingAnchor)
    ])
    
    view.addSubview(table)
    NSLayoutConstraint.activate([
      table.topAnchor.constraint(equalToSystemSpacingBelow: searchButton.bottomAnchor, multiplier: 2),
      table.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 2),
      view.trailingAnchor.constraint(equalToSystemSpacingAfter: table.trailingAnchor, multiplier: 2),
      table.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    ])
  }
}

extension ViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let results = searchResult?.results else {
      return 0
//      Because searchResult is an optional and if nothing is there... you get the idea.
    }
    return results.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = table.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    if let movie = searchResult?.results[indexPath.item] {
      config.text = movie.title
    }
    cell.contentConfiguration = config
    return cell
  }
}

extension ViewController {
  @objc
  func searchButtonBooped() {
    guard searchBox.text != "", let movie = searchBox.text else {
      // show error if empty textfield
      print("nope")
      return
    }
    getMovie(named: movie)
  }
}

// Using an Enum for your endpoint desitations makes your networking methods a bit more flexible
enum EndPoint: String {
  case search
}

// same
enum Language: String {
  case englishUS = "en-US"
}

extension ViewController {
  private func getMovie(named name: String) {
//    from tmdb documentation
    let headers = [
      "accept": "application/json",
      "Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJmNDZkMGY5ZjZiNzdkNTUxYzM5OWQ4Y2M4M2Y3YjA3YiIsInN1YiI6IjYxNmYxYzdjMTNhMzIwMDA0NGUxNjQ0ZSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.rjEtdhTPaqiaw6klq6nMkE2_7V0Cn8qAGbWtIfsv6Xo"
    ]

//    I prefer to break things up rather than have a huge string of meaningless gibberish
    let baseURL = "https://api.themoviedb.org/3/"
    let endpoint = EndPoint.search.rawValue
    let include_adult: Bool = true
    let language = Language.englishUS.rawValue
    let currentPage = 1
    
//    This is not recommended, but it's quick and easy.
    let url = "\(baseURL)\(endpoint)/movie?query=\(name)&include_adult\(include_adult)&language=\(language)&page=\(currentPage)"
    
//    This a better way to do the same: https://cocoacasts.com/working-with-nsurlcomponents-in-swift
    
//    from tmdb documentation
    let request = NSMutableURLRequest(url: NSURL(string: url)! as URL,
                                      cachePolicy: .useProtocolCachePolicy,
                                      timeoutInterval: 10.0)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
//      I think this might be the part you're missing. Gotta make sure it's all happening on the main thread and then reloading the table data before exiting.
      DispatchQueue.main.async {
        guard let data = data, error == nil else {
          return
        }
        do {
          let decodedData = try JSONDecoder().decode(MovieResults.self, from: data)
          self.searchResult = decodedData
        } catch {
          print("ggwp parsing error: \(error)")
        }
        self.table.reloadData()
      }
    })
    dataTask.resume()
  }
}
