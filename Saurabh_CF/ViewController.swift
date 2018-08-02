//
//  ViewController.swift
//  Saurabh_CF
//
//  Created by saurabh srivastava on 31/07/18.
//  Copyright © 2018 saurabh. All rights reserved.
//

import UIKit
import Starscream

class ViewController: UIViewController, WebSocketDelegate {
    var socket:WebSocket!
    
    @IBOutlet weak var transAmount: UILabel!
    @IBOutlet weak var transHash: UILabel!
    @IBOutlet weak var blockView: UIStackView!
    @IBOutlet weak var stackHeight: NSLayoutConstraint!
    @IBOutlet weak var blocklabel: UILabel!
    @IBOutlet weak var reward: UILabel!
    @IBOutlet weak var sentLabel: UILabel!
    @IBOutlet weak var height: UILabel!
    @IBOutlet weak var hashlabel: UILabel!
    @IBOutlet weak var connectingView: UIView!
    
    @IBOutlet weak var connectingHeight: NSLayoutConstraint!
    @IBOutlet weak var connectingLabel: UILabel!
    
    var stackOpen = false
    
    var timer:Timer!
    
    var sgt:Int = 2000000
    var newTrans:Double = 0.0
    var currentRate:Double = 0.0
    var hideConnectingView = false
    
    @objc func animateView(){
        if hideConnectingView == false{
            hideConnectingView = true
            self.connectingHeight.constant = 0
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            })
        }
        else{
            hideConnectingView = false
            self.connectingHeight.constant = 30
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func animateStack(){
        if stackOpen == false{
            stackOpen = true
            blocklabel.text = "New Block"
            self.stackHeight.constant = 200
            self.blockView.alpha = 1
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stackHeight.constant = 0
        self.blockView.alpha = 0
        socket = WebSocket(url: URL(string: "wss://ws.blockchain.info/inv")!)
        socket.delegate = self
        socket.connect()
    }
    func websocketDidConnect(socket: WebSocketClient) {
        connectingLabel.text = "Connected"
        connectingView.backgroundColor = UIColor.green
       timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(animateView), userInfo: nil, repeats: false)
        let dict = ["op":"ping"]
        socket.write(string: stringify(dict))
        
        let dict1 = ["op":"unconfirmed_sub"]
        
        socket.write(string: stringify(dict1))
        
        let dict2 = ["op":"blocks_sub"]
        socket.write(string: stringify(dict2))
        
    }
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        connectingLabel.text = "Disconnected"
        connectingView.backgroundColor = UIColor.red
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(animateView), userInfo: nil, repeats: false)
    }
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
    //    print(text)
        let data = convertToDictionary(text: text)
        if data != nil{
            if let op = data!["op"] as? String{
                if op.lowercased() == "block"{
                   updateBlock(data!)
                }
                if op.lowercased() == "utx"{
                    updateTransactions(data!)
                }
            }
        }
    }
    
    func updateBlock(_ data:[String:Any]){
        animateStack()
        if let dict = data["x"] as? [String:Any]{
            if let sent = dict["totalBTCSent"] as? Int{
                sentLabel.text = String(sent)
            }
            if let sent = dict["reward"] as? Int{
                reward.text = String(sent)
            }
            if let sent = dict["height"] as? Int{
                height.text = String(sent)
            }
            if let sent = dict["hash"] as? String{
                hashlabel.text = String(sent)
            }
        }
    }
    
    func updateTransactions(_ data:[String:Any]){
        if let dict = data["x"] as? [String:Any]{
            if let outDict = dict["out"] as? [[String:Any]]{
                if outDict.count > 0{
                if let value = outDict[0]["value"] as? Int{
                    if value > sgt{
                        newTrans = Double(value)/Double(100000000)
                        getBitcoinrate()
                    }
                    else{
                        return
                    }
                }
                }
            }
            if let sent = dict["hash"] as? String{
                transHash.text = String(sent)
            }
        }
    }
    
    func getBitcoinrate(){
        let url = URL(string: "https://api.coindesk.com/v1/bpi/currentprice.json")!
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                return
            }
            do{
                
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]{
                    print(json)
                    if let bpi = json["bpi"] as? [String:Any]{
                        if let us = bpi["USD"] as? [String:Any]{
                            if let rate = us["rate_float"] as? Double{
                                self.currentRate = Double(rate)
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        let total = self.newTrans*self.currentRate
                        self.transAmount.text = String(total)+" USD"
                    }
                    
                    
                }
            }
            catch{
                
            }
        }
        task.resume()
    }
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
       // print(data)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

    @IBAction func recoonect(_ sender: Any) {
        if socket != nil{
            connectingLabel.text = "Connecting..."
            connectingView.backgroundColor = UIColor.green
            animateView()
            socket.connect()
        }
    }
    func stringify(_ data:[String:String]) -> String{
        var convertedString = ""
        do{
            let data1 =  try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            convertedString = String(data: data1, encoding: String.Encoding.utf8)!
            //   print(convertedString)
        }
        catch{
            
        }
        return convertedString
    }

    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}

