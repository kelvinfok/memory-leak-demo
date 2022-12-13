//
//  ViewController.swift
//  leak-demo
//
//  Created by Kelvin Fok on 13/12/22.
//

import UIKit
import SDWebImage
import Combine

class UserTableViewController: UITableViewController {
  
  // TOPIC - MEMORY LEAK
  // Common areas where leak happens
  //  - closures
  //  - delegates
  //  - notification centers
  //  - diposeBag/cancellables in cells
  // How to resolve them
  // - Memory graph
  // - https://github.com/Janneman84/LeakedViewControllerDetector
  
  private var users: [User] = []
  private var cancellables = Set<AnyCancellable>()
  private let fetchUserNotificationName = Notification.Name(rawValue: "fetchUsers")

  override func viewDidLoad() {
    super.viewDidLoad()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(fetchUsers),
      name: fetchUserNotificationName,
      object: nil)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      NotificationCenter.default.post(name: self.fetchUserNotificationName, object: nil)
    }
  }
    
  @objc private func fetchUsers() {
    print(">>>> fetch users")
    URLSession.shared.dataTask(
      with: .init(url: URL(string:"https://dummyjson.com/users")!)) { data, res, error in
        let response = try! JSONDecoder().decode(UsersResponse.self, from: data!)
        self.users = response.users
        DispatchQueue.main.async {
          self.navigationItem.title = "Users - \(response.users.count)"
          print(">>>> reload tableView")
          self.tableView.reloadData()
        }
      }.resume()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let destination = segue.destination as! DetailViewController
    destination.text = sender as? String
  }
  
  private func showAlert(email: String) {
    let alertController = UIAlertController(title: email, message: nil, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default)
    alertController.addAction(okAction)
    present(alertController, animated: true)
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! UserCell
    cell.configure(user: users[indexPath.item])
    cell.eventPublisher.sink { event in
      switch event {
      case .showDetailButtonTapped(let fullName):
        print(">>>> show detail")
        self.performSegue(withIdentifier: "showDetail", sender: fullName)
      case .showEmailButtonTapped(let email):
        print(">>>> showAlert \(email)")
        self.showAlert(email: email)
      }
    }.store(in: &cancellables)
    return cell
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return users.count
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 100
  }
  
}

enum UserCellEvent {
  case showEmailButtonTapped(email: String)
  case showDetailButtonTapped(fullName: String)
}

class UserCell: UITableViewCell, InfoViewDelegate {
  
  @IBOutlet weak var profileImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var infoView: InfoView!
  
  private let eventSubject = PassthroughSubject<UserCellEvent, Never>()
  var eventPublisher: AnyPublisher<UserCellEvent, Never> { eventSubject.eraseToAnyPublisher() }
  
  private(set) var cancellabes = Set<AnyCancellable>()
  private var user: User?
  
  func configure(user: User) {
    self.user = user
    profileImageView.sd_setImage(with: .init(string: user.image))
    nameLabel.text = user.fullName
    infoView.delegate = self
  }
  
  @IBAction func showEmailButtonTapped() {
    guard let email = user?.email else { return }
    eventSubject.send(.showEmailButtonTapped(email: email))
  }
  
  func infoViewDidTap() {
    eventSubject.send(.showDetailButtonTapped(fullName: user!.fullName))
  }
}

struct UsersResponse: Decodable {
  let users: [User]
}

struct User: Decodable {
  let firstName: String
  let lastName: String
  let image: String
  let email: String
  
  var fullName: String {
    "\(firstName) \(lastName)"
  }
}

protocol InfoViewDelegate {
  func infoViewDidTap()
}

class InfoView: UIView {
  
  @IBOutlet weak var imageView: UIImageView!
  
  var delegate: InfoViewDelegate?
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupGesture()
  }
  
  private func setupGesture() {
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    addGestureRecognizer(tapGesture)
  }
  
  @objc private func handleTap() {
    delegate?.infoViewDidTap()
  }
}
