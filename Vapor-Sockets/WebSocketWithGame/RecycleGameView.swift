import SwiftUI
import SpriteKit

struct RecycleGameView: View {
    @State var organicCounter = 0.0
    @State var plasticCounter = 0.0
    @State var paperCounter = 0.0
    
    var scene: SKScene {
        let scene = RecycleGame(size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height),plasticCount: $plasticCounter, paperCounter: $paperCounter, organicCounter: $organicCounter)
        scene.scaleMode = .aspectFit
        
        return scene
    }
    
    
    var body: some View {
        VStack {
            
            ZStack(alignment: .bottom) {
                
                ZStack(alignment: .top) {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                    .frame(width: UIScreen.main.bounds.width , height: UIScreen.main.bounds.height)
                        .cornerRadius(40, antialiased: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                        .ignoresSafeArea()
                }
            }
       }
    }
}
