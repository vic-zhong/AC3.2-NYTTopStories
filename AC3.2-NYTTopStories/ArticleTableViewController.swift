//
//  ArticleTableViewController.swift
//  AC3.2-NYTTopStories
//
//  Created by Jason Gresh on 11/19/16.
//  Copyright © 2016 C4Q. All rights reserved.
//

import UIKit

class ArticleTableViewController: UITableViewController, UITextFieldDelegate {
    var allArticles = [Article]()
    var articles = [Article]()
    
    var sectionTitles: [String] {
        get {
            var sectionSet = Set<String>()
            for article in articles {
                sectionSet.insert(article.section)
            }
            return Array(sectionSet).sorted()
        }
    }
    
    let identifier = "articleCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Home"
        
        self.tableView.estimatedRowHeight = 200
        self.tableView.rowHeight = UITableViewAutomaticDimension

        APIRequestManager.manager.getData(endPoint: "https://api.nytimes.com/svc/topstories/v2/home.json?api-key=f41c1b23419a4f55b613d0a243ed3243")  { (data: Data?) in
            if let validData = data {
                if let jsonData = try? JSONSerialization.jsonObject(with: validData, options:[]) {
                    if let wholeDict = jsonData as? [String:Any],
                        let records = wholeDict["results"] as? [[String:Any]] {
                        self.allArticles = Article.parseArticles(from: records)
                        
                        // start off with everything
                        self.articles = self.allArticles
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionTitles.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionPredicate = NSPredicate(format: "section = %@", self.sectionTitles[section])
        return self.articles.filter { sectionPredicate.evaluate(with: $0)}.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.identifier, for: indexPath) as! ArticleTableViewCell
        
        let sectionPredicate = NSPredicate(format: "section = %@", self.sectionTitles[indexPath.section])
        let article = self.articles.filter { sectionPredicate.evaluate(with: $0)}[indexPath.row]
        
        cell.titleLabel.text = article.title
        cell.abstractLabel.text = article.abstract + "PER: " + article.per_facet.joined(separator: " ")
        cell.bylineAndDateLabel.text = "\(article.byline)\n\(article.published_date)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionTitles[section]
    }
    
    func applyPredicate(search: String) {
        //let predicate = NSPredicate(format:"abstract contains[c] %@ or title contains[c] %@", search, search)
        let predicate = NSPredicate(format:"ANY per_facet contains[c] %@", search) // Trump, Donald J
        
        self.articles = self.allArticles.filter { predicate.evaluate(with: $0) }
        self.tableView.reloadData()
    }
    
    // MARK: - TextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            if text.characters.count > 0 {
                applyPredicate(search: text)
            }
            else {
                self.articles = self.allArticles
                self.tableView.reloadData()
            }
        }
        return true
    }
}
