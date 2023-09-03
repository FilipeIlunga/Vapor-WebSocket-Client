import SwiftUI
import SpriteKit
import Starscream


protocol ReceivedMessageProtocol: AnyObject {
    func receivedMessage(message: String)
}

final class WebsocketGameViewModel: ObservableObject, WebSocketDelegate {
    @AppStorage("userID") var userID = ""
    @Published var user = CurrentUser(userName: UUID().uuidString)
    
    @Published var isSockedConnected: Bool = false
    
    private var hasReceivedPong = false
    private var isFirstPing = true
    var timer: Timer?

    init() {
        
        if userID.isEmpty {
            self.userID = UUID().uuidString
            self.user = CurrentUser(userName: userID)
        } else {
            self.user = CurrentUser(userName: self.userID)

        }
        
        setupWebSocket()

    }
    
    
    func startPingTimer() {
        timer =  Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
           
            
            if self.isFirstPing {
                self.socket?.write(ping: Data())
                print("mandou")
                self.hasReceivedPong = false
                self.isFirstPing = false
            } else if self.hasReceivedPong  {
                    self.socket?.write(ping: Data())
                    self.hasReceivedPong = false
                    print("mandou")
            } else if !self.isSockedConnected {
                    self.setupWebSocket()
                    print("Tentou conecao")
            } else {
                self.socket?.write(ping: Data())
                self.hasReceivedPong = false
                print("Mandou apos conexao")
            }
        }
    }
    
   
    func minhaFuncao() {
        // Coloque aqui o código da sua função
        print("Minha função foi chamada!")
    }
    
    private var socket: WebSocket?
    
    weak var delegate: ReceivedMessageProtocol?
    
    func setupWebSocket() {
        var request = URLRequest(url: URL(string: "\(APIKeys.websocketAddress.rawValue)/spriteKitGame")!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
    
    func sendAlive() {
        socket?.write(string: "\(user.userName)Hey socket i am alive|3")
    }
    
    func sendMessage(message: String) {
        socket?.write(string: message)
    }
    
    func sendMessage(message: Data) {
        socket?.write(data: message)
    }
}

extension WebsocketGameViewModel {
        
        func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
            switch event {
            case .connected(let headers):
                isSockedConnected = true
                
                    sendMessage(message: "\(user.userName)|0|0|null|1")
                
                print("websocket is connected: \(headers)")
            case .disconnected(let reason, let code):
               // isConnected = false
                print("websocket is disconnected: \(reason) with code: \(code)")
            case .text(let message):
                delegate?.receivedMessage(message: message)
                print("New message received: \(message)")
            case .binary(let data):
                print("New message received: \(data)")
            case .ping(_):
              print("Received ping")
            case .pong(_):
                hasReceivedPong = true
                print("Received pong")
            case .viabilityChanged(_):
                break
            case .reconnectSuggested(_):
                break
            case .cancelled:
                isSockedConnected = false
                print("Cancelou")
            case .error(let error):
                isSockedConnected = false
                print("Error: \(String(describing: error?.localizedDescription))")
            case .peerClosed:
                       break
            }
        }
}

class RecycleGame: SKScene, SKPhysicsContactDelegate, ReceivedMessageProtocol {
    
    var isDragging = false
    
    @State var viewModel: WebsocketGameViewModel = WebsocketGameViewModel()
    
    @Binding var plasticCounter: Double
    @Binding var paperCounter: Double
    @Binding var organicCounter: Double
        
    var nodePlastic1 = SKSpriteNode()
    var nodePlastic2 = SKSpriteNode()
    var nodePlastic3 = SKSpriteNode()
    
    var selectedNode = SKSpriteNode()
    
    private let background = SKSpriteNode()

    override func didMove(to view: SKView) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.affectedByGravity = true
        nodePlastic1.physicsBody =  SKPhysicsBody(edgeLoopFrom: frame)
        nodePlastic1.physicsBody?.affectedByGravity = true
        
        viewModel.sendAlive()
    }

    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactAName = contact.bodyA.node?.name
        let contactBName = contact.bodyB.node?.name
        if (contactAName == "node1") || (contactBName == "node1") {
            
            if (contactAName == "node2") || (contactBName == "node2") {
                print("node1 contact with node2")
                return
            }
        }
    }
    
    func receivedMessage(message: String) {
        let splitedMessage = message.components(separatedBy: "|")
        
        guard splitedMessage.count > 4 else {
            return
        }
        
        let userID = splitedMessage[0]
        let nodeName = splitedMessage[1]
        let messageType =  splitedMessage[4]
        guard let positionX = Double(splitedMessage[2]),
              let positionY = Double(splitedMessage[3]) else {
            return
        }
        
        guard messageType == "0" else {
            return
        }
        
        switch nodeName {
        case nodePlastic1.name:
            nodePlastic1.position = CGPoint(x: positionX, y: positionY)
        case nodePlastic2.name:
            nodePlastic2.position = CGPoint(x: positionX, y: positionY)
        case nodePlastic3.name:
            nodePlastic3.position = CGPoint(x: positionX, y: positionY)
        default:
            print("Node invalido")
        }
        
    }
    
    func setSize() {
        nodePlastic1.size = CGSize(width: 70, height: 50)
        nodePlastic2.size = CGSize(width: 60, height: 60)
        nodePlastic3.size = CGSize(width: 70, height: 50)
        
        nodePlastic1.color = .red
        nodePlastic2.color = .yellow
        nodePlastic3.color = .green
                
    }
    
    init(size: CGSize, plasticCount: Binding<Double>, paperCounter: Binding<Double>, organicCounter: Binding<Double>) {
        _organicCounter =  organicCounter
        _plasticCounter = plasticCount
        _paperCounter = paperCounter
        super.init(size: size)
        viewModel.delegate = self
        background.scale(to: self.frame.size)
        background.position = CGPoint(x: self.frame.midX, y: self.frame.midY)

        addChild(background)
        
        self.setSize()

        nodePlastic1.name = "plastic-1"
        nodePlastic2.name = "plastic-2"
        nodePlastic3.name = "plastic-3"
     
        
        let myLabel = SKLabelNode(fontNamed: "Helvetica")
        myLabel.text = "SpriteKit with Websocket"
        myLabel.fontSize = 20
        myLabel.fontColor = SKColor.white
        myLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        self.addChild(myLabel)

        nodePlastic1.position = CGPoint(x: size.width * 0.5, y: size.height * 0.15)
        nodePlastic2.position = CGPoint(x: size.width * 0.7, y: size.height * 0.15)
        nodePlastic3.position = CGPoint(x: size.width * 0.3, y: size.height * 0.15)
  
        addChild(nodePlastic1)
        addChild(nodePlastic2)
        addChild(nodePlastic3)

    }

    required init?(coder aDecoder: NSCoder) {
        _organicCounter = .constant(0)
        _plasticCounter = .constant(0)
        _paperCounter = .constant(0)
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let positionInScene = touches.first!.location(in: self)
        selectNodeForTouch(touchLocation: positionInScene)
        super.touchesBegan(touches, with: event)
    }

    func selectNodeForTouch(touchLocation: CGPoint) {
        // 1
        let touchedNode = self.atPoint(touchLocation)
        if touchedNode is SKSpriteNode {
               isDragging = true         // 2
            if !selectedNode.isEqual(touchedNode) {
               
                selectedNode.removeAllActions()
                selectedNode.run(SKAction.rotate(byAngle: 0.0, duration: 0.1))
                selectedNode = touchedNode as! SKSpriteNode
                
            }
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {

    }

    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let positionInScene = touches.first!.location(in: self)
        let previousPosition = touches.first!.previousLocation(in: self)
        let translation = CGPoint(x: positionInScene.x - previousPosition.x, y: positionInScene.y - previousPosition.y)
        
        panForTranslation(translation: translation)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
    }
    
    func panForTranslation(translation: CGPoint) {
        guard isDragging else {
            return
        }
        let position = selectedNode.position
        
        guard let selectedNodeName = selectedNode.name else {
            return
        }

        selectedNode.position = CGPoint(x: position.x + translation.x, y: position.y + translation.y)
        let user = viewModel.user.userName
        let positionX = position.x
        let positionY = position.y
        guard let selectedNodeName = selectedNode.name else {return}
        
        viewModel.sendMessage(message: "\(user)|\(selectedNodeName)|\(positionX)|\(positionY)|0")
    }

    
    
}


