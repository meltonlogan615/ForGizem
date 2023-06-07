//
//  Movie.swift
//  GizemMovieSearch
//
//  Created by Logan Melton on 6/7/23.
//

import Foundation

struct Movie: Codable, Identifiable {
  var id: Int
  var title: String
}

struct MovieResults: Codable {
  var page: Int
  var results: [Movie]
}
