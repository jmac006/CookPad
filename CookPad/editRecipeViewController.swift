//
//  editRecipeViewController.swift
//  CookPad
//

import UIKit
import Firebase

class editRecipeViewController: UIViewController {
    
    @IBOutlet weak var viewHeight: NSLayoutConstraint!
    @IBOutlet weak var imageView = UIImageView()
    @IBOutlet weak var nameLabel = UILabel()
    @IBOutlet weak var ingredientsList = UITextView() //lists steps to follow for recipe
    @IBOutlet weak var directionsTextView: UITextView!
    @IBOutlet weak var overlayImageView = UIImageView()
    
    var recipe : Recipe?
    
    let likeOverlay = UIImage(named: "like button")
    var reference : DatabaseReference?
    let storage = Storage.storage()
    let currentUserId = Auth.auth().currentUser?.uid
    var myRecipes : NSArray?
    var userNumberOfLikedRecipes: Int! = 0
    let currentUserID = Auth.auth().currentUser?.uid
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        reference = Database.database().reference()
        self.imageView?.image = self.recipe?.image
        self.nameLabel?.text = self.recipe?.name
        self.ingredientsList?.text = self.recipe?.ingredients
        self.directionsTextView?.text = self.recipe?.directions
        var numDirectionsLines = (directionsTextView.contentSize.height / (directionsTextView.font?.lineHeight)!) as? CGFloat
        var numIngredientsLines = ((ingredientsList?.contentSize.height)! / (ingredientsList?.font?.lineHeight)!) as? CGFloat
        let numOfLines = numDirectionsLines! + numIngredientsLines!
        print(numOfLines)
        viewHeight.constant = numOfLines > 8 ? 667 + numOfLines*(directionsTextView.font?.lineHeight)! : 667
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        
        let alert = UIAlertController(title: "Edit Recipe", message: "What do you want to edit?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Title of Recipe", style: .default, handler: editRecipeTitle))
        //alert.addAction(UIAlertAction(title: "Description", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Ingredients", style: .default, handler: editRecipeIngredients))
        alert.addAction(UIAlertAction(title: "Directions", style: .default, handler: editRecipeDirections))
        alert.addAction(UIAlertAction(title: "Delete Recipe", style: .default, handler: deleteRecipe))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            self.performSegue(withIdentifier: "showMyRecipes", sender: self)
        }))
        self.present(alert, animated: true)
    }
    
    func editRecipeTitle(alertAction: UIAlertAction) -> Void {
        let alert = UIAlertController(title: "Edit Recipe", message: "What do you want to rename it to?", preferredStyle: .alert)
        alert.addTextField { (textField : UITextField) -> Void in
            textField.text = self.recipe?.name ?? ""
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            //edit title
            self.reference?.child("Recipes").child((self.recipe?.firebaseId)!).child("Name").setValue(alert.textFields?.first?.text)
            self.performSegue(withIdentifier: "showMyRecipes", sender: self)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    func editRecipeIngredients(alertAction: UIAlertAction) -> Void {
        let alert = UIAlertController(title: "Edit Recipe", message: "What do you want to change it to?", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = self.recipe?.ingredients ?? ""
            let heightConstraint = NSLayoutConstraint(item: textField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100)
            textField.addConstraint(heightConstraint)
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            //edit Ingredients
            print((self.recipe?.ingredients)!)
            print((alert.textFields?.first?.text)!)
            self.performSegue(withIdentifier: "showMyRecipes", sender: self)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    func editRecipeDirections(alertAction: UIAlertAction) -> Void {
        let alert = UIAlertController(title: "Edit Recipe", message: "What do you want to change it to?", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = self.recipe?.ingredients ?? ""
            let heightConstraint = NSLayoutConstraint(item: textField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100)
            textField.addConstraint(heightConstraint)
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            //Edit Directions to Firebase
            //self.performSegue(withIdentifier: "showMyRecipes", sender: self)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }

    func deleteRecipe(alertAction: UIAlertAction) -> Void {
        let alert = UIAlertController(title: "Are you sure?", message: "Are you sure you want to delete this recipe?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            //Delete the recipe from Firebase
            //self.reference?.child("Users").child(currentUserID).child("MyRecipes")
            self.grabMyRecipesFromFirebase {
                var i: Int = 0
                for each in self.myRecipes! {
                    let x: String = each as! String
                    if x == self.recipe?.firebaseId {
                        print("found")
                        self.reference?.child("Users").child(self.currentUserID!).child("MyRecipes").child(String(i)).setValue("N/A")
                    } else {
                        i += 1
                    }
                }
                
            }
            let storageRef = self.storage.reference()
            self.reference?.child("Recipes").child((self.recipe?.firebaseId)!).removeValue()
            storageRef.child("Images").child((self.recipe?.firebaseId)!).delete { error in
                if let error = error{
                    print("Error:\(error)")
                } else {
                    //success
                }
            }
            self.performSegue(withIdentifier: "showMyRecipes", sender: self)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        //Implement share
    }
    
    func myFirebaseNetworkDataRequest(finished: @escaping () -> Void){ // the function thats going to take a little moment
        //this func grabs this data from the database and make sure that it waits for the fetch
        let userID = Auth.auth().currentUser?.uid
        reference?.child("Users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() && snapshot.hasChild("numOfLikedRecipes") {
                let value = snapshot.value as? NSDictionary
                let numRecipes: String = (value?["numOfLikedRecipes"] as? String)!
                self.userNumberOfLikedRecipes = Int(numRecipes)! + 1
            }
            else{
                self.userNumberOfLikedRecipes = 1
            }
            finished()
        })
        
    }
    
    func grabMyRecipesFromFirebase(finished: @escaping () -> Void){ // the function thats going to take a little moment
        reference?.child("Users").child(currentUserId!).observeSingleEvent(of: .value, with: {(UserRecipeSnap) in
            if UserRecipeSnap.exists(){
                if UserRecipeSnap.hasChild("MyRecipes") {
                    let Dict : NSDictionary = UserRecipeSnap.value as! NSDictionary
                    print("entered")
                    self.myRecipes = Dict["MyRecipes"] as? NSArray
                    finished()
                }
                else {
                    print("LikedRecipes DOES NOT EXIST")
                    finished()
                }
            }
            else {
                print("Error with retrieving snapshot from Firebase")
            }
            
        })
    }
    
}


