//
//  MovieDetailViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class MovieDetailViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var watchlistBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var favoriteBarButtonItem: UIBarButtonItem!
    
    var movie: Movie!
    
    var isWatchlist: Bool {
        return MovieModel.watchlist.contains(movie)
    }
    
    var isFavorite: Bool {
        return MovieModel.favorites.contains(movie)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = movie.title
        self.imageView.image = UIImage(named: "PosterPlaceholder")
        TMDBClient.downloadPosterImage(posterPath: movie.posterPath ?? "") { (data, error) in
           
                if let data = data {
                    self.imageView.image = UIImage(data: data)
                }
    
        }
        toggleBarButton(watchlistBarButtonItem, enabled: isWatchlist)
        toggleBarButton(favoriteBarButtonItem, enabled: isFavorite)
        
    }
    
    @IBAction func watchlistButtonTapped(_ sender: UIBarButtonItem) {
        TMDBClient.markWatchlist(movieId: movie.id, watchlist: !isWatchlist, completion: handleWatchlistResponse(success:error:))
        print("The button was tapped")
    }
    
    func handleWatchlistResponse(success: Bool, error: Error?) {
        print("handleWatchlistResponse is called")
        if success {
            if isWatchlist {
                MovieModel.watchlist = MovieModel.watchlist.filter() { $0 != self.movie }
                print("MovieModel is updated")
            
        } else {
            MovieModel.watchlist.append(movie)
            print("the Movie is added")
        }
        toggleBarButton(watchlistBarButtonItem, enabled: isWatchlist)
    }
    }
    
    @IBAction func favoriteButtonTapped(_ sender: UIBarButtonItem) {
        TMDBClient.markWatchlist(movieId: movie.id, watchlist: !isFavorite, completion: handleFavoriteResponse(success:error:))
        print("The button was tapped")
    }
        
    func handleFavoriteResponse(success: Bool, error: Error?) {
        if success {
            if isFavorite {
                MovieModel.favorites = MovieModel.favorites.filter() { $0 != self.movie }
                print("MovieModel is updated")
                
            } else {
                MovieModel.favorites.append(movie)
                print("the Movie is added")
            }
            toggleBarButton(favoriteBarButtonItem, enabled: isFavorite)
        }
    }
    
    func toggleBarButton(_ button: UIBarButtonItem, enabled: Bool) {
        if enabled {
            button.tintColor = UIColor.primaryDark
        } else {
            button.tintColor = UIColor.gray
        }
    }
    
    
}
