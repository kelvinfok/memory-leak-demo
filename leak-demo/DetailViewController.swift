//
//  DetailViewController.swift
//  leak-demo
//
//  Created by Kelvin Fok on 17/12/22.
//

import UIKit

class DetailViewController: UIViewController {
  
  @IBOutlet weak var label: UILabel!
  var text: String?

  override func viewDidLoad() {
    super.viewDidLoad()
    label.text = text
  }
}
