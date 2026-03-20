import SpriteKit
import UIKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let ball: UInt32 = 1 << 0
        static let obstacle: UInt32 = 1 << 1
    }

    weak var gameState: GameState?

    private let ballRadius: CGFloat = 14
    private let ballXRatio: CGFloat = 0.24
    private var ballNode = SKShapeNode(circleOfRadius: 14)
    private var isBallAtTop = false
    private let topSurfaceInset: CGFloat = 138
    private let bottomSurfaceInset: CGFloat = 114

    private var topSafeZone = SKShapeNode()
    private var bottomSafeZone = SKShapeNode()

    private var obstacleTimer: TimeInterval = 0
    private var particleTimer: TimeInterval = 0
    private var gameTime: TimeInterval = 0
    private var lastUpdate: TimeInterval = 0
    private var gameIsRunning = false
    private var hasInitializedScene = false

    override func didMove(to view: SKView) {
        guard !hasInitializedScene else {
            physicsWorld.contactDelegate = self
            return
        }

        hasInitializedScene = true
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0.01, green: 0.09, blue: 0.12, alpha: 1)

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        configureSafeZones()
        configureBall()
        prepareForMenu()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutSafeZones()
        if ballNode.parent != nil {
            ballNode.position.x = size.width * ballXRatio
        }
    }

    func startNewGame() {
        isPaused = false
        removeAllObstacles()

        gameIsRunning = true
        gameTime = 0
        obstacleTimer = 0
        particleTimer = 0
        lastUpdate = 0
        isBallAtTop = false

        applyCurrentPalette()
        ballNode.removeAllActions()
        ballNode.position = CGPoint(x: size.width * ballXRatio, y: bottomLaneY)
        gameState?.setScore(0)
        gameState?.setGameOver(false)
    }

    func prepareForMenu() {
        isPaused = false
        removeAllObstacles()
        gameIsRunning = false
        gameTime = 0
        obstacleTimer = 0
        particleTimer = 0
        lastUpdate = 0
        isBallAtTop = false
        applyCurrentPalette()
        ballNode.removeAllActions()
        ballNode.position = CGPoint(x: size.width * ballXRatio, y: bottomLaneY)
        gameState?.setGameOver(false)
        isPaused = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameIsRunning else { return }
        isBallAtTop.toggle()
        ballNode.removeAllActions()
        ballNode.run(SKAction.moveTo(y: isBallAtTop ? topLaneY : bottomLaneY, duration: 0.06))

        let flash = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.08)
        ])
        ballNode.run(flash)
    }

    override func update(_ currentTime: TimeInterval) {
        guard gameIsRunning else { return }

        let deltaTime: TimeInterval
        if lastUpdate == 0 {
            deltaTime = 0
        } else {
            deltaTime = min(currentTime - lastUpdate, 1.0 / 25.0)
        }
        lastUpdate = currentTime

        gameTime += deltaTime

        ballNode.position.x = size.width * ballXRatio
        advanceScore()
        spawnObstaclesIfNeeded(delta: deltaTime)
        spawnParticlesIfNeeded(delta: deltaTime)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let collisionMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if collisionMask == (PhysicsCategory.ball | PhysicsCategory.obstacle) {
            triggerGameOver()
        }
    }

    private func configureBall() {
        ballNode.removeFromParent()
        ballNode = SKShapeNode(circleOfRadius: ballRadius)
        ballNode.fillColor = SKColor(red: 0.22, green: 0.86, blue: 0.97, alpha: 1)
        ballNode.strokeColor = SKColor.clear
        ballNode.zPosition = 10

        let body = SKPhysicsBody(circleOfRadius: ballRadius)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.ball
        body.contactTestBitMask = PhysicsCategory.obstacle
        body.collisionBitMask = PhysicsCategory.none
        body.usesPreciseCollisionDetection = true
        ballNode.physicsBody = body

        addChild(ballNode)
        applyCurrentPalette()
    }

    private var topLaneY: CGFloat {
        size.height - topSurfaceInset - ballRadius - 8
    }

    private var bottomLaneY: CGFloat {
        bottomSurfaceInset + ballRadius + 8
    }

    private func advanceScore() {
        let nextScore = Int(gameTime)
        if gameState?.score != nextScore {
            gameState?.setScore(nextScore)
        }
    }

    private func spawnObstaclesIfNeeded(delta: TimeInterval) {
        obstacleTimer += delta

        let difficulty = gameState?.difficulty ?? .moderate
        let dynamicInterval = max(
            difficulty.minSpawnInterval,
            difficulty.baseSpawnInterval - (gameTime * difficulty.spawnDecay)
        )
        // Reduce obstacle distance by half from the previous 3x spacing.
        let spawnInterval = dynamicInterval * 1.5

        guard obstacleTimer >= spawnInterval else { return }
        obstacleTimer = 0

        let obstacleWidth: CGFloat = 64
        let heightRange = difficulty.heightRange
        let obstacleHeight = CGFloat.random(in: heightRange)
        let startX = size.width + obstacleWidth
        let moveDistance = size.width + obstacleWidth * 2
        let obstacleSpeed = difficulty.baseObstacleSpeed + CGFloat(gameTime) * difficulty.speedGrowth
        let duration = TimeInterval(moveDistance / obstacleSpeed)

        // Every spawn chooses its side independently to avoid predictable clusters.
        let spawnOnTop = Bool.random()
        let obstacle = makeObstacle(size: CGSize(width: obstacleWidth, height: obstacleHeight))
        obstacle.position = CGPoint(
            x: startX,
            y: spawnOnTop
                ? (size.height - topSurfaceInset - obstacleHeight * 0.5)
                : (bottomSurfaceInset + obstacleHeight * 0.5)
        )
        addObstacleMovement(node: obstacle, duration: duration)
    }

    private func configureSafeZones() {
        topSafeZone.removeFromParent()
        bottomSafeZone.removeFromParent()

        topSafeZone = SKShapeNode()
        bottomSafeZone = SKShapeNode()
        topSafeZone.zPosition = 2
        bottomSafeZone.zPosition = 2
        addChild(topSafeZone)
        addChild(bottomSafeZone)

        layoutSafeZones()
    }

    private func layoutSafeZones() {
        guard size.width > 0, size.height > 0 else { return }

        let zoneWidth = size.width
        let topZoneHeight = topSurfaceInset
        let bottomZoneHeight = bottomSurfaceInset

        topSafeZone.path = CGPath(
            rect: CGRect(x: -zoneWidth * 0.5, y: -topZoneHeight * 0.5, width: zoneWidth, height: topZoneHeight),
            transform: nil
        )
        topSafeZone.fillColor = SKColor(red: 0.03, green: 0.15, blue: 0.19, alpha: 0.55)
        topSafeZone.strokeColor = SKColor(red: 0.52, green: 0.75, blue: 0.78, alpha: 0.35)
        topSafeZone.lineWidth = 1
        topSafeZone.position = CGPoint(x: size.width * 0.5, y: size.height - topZoneHeight * 0.5)

        bottomSafeZone.path = CGPath(
            rect: CGRect(x: -zoneWidth * 0.5, y: -bottomZoneHeight * 0.5, width: zoneWidth, height: bottomZoneHeight),
            transform: nil
        )
        bottomSafeZone.fillColor = SKColor(red: 0.03, green: 0.15, blue: 0.19, alpha: 0.55)
        bottomSafeZone.strokeColor = SKColor(red: 0.52, green: 0.75, blue: 0.78, alpha: 0.35)
        bottomSafeZone.lineWidth = 1
        bottomSafeZone.position = CGPoint(x: size.width * 0.5, y: bottomZoneHeight * 0.5)
    }

    private func spawnParticlesIfNeeded(delta: TimeInterval) {
        particleTimer += delta
        guard particleTimer >= 0.08 else { return }
        particleTimer = 0

        let dot = SKShapeNode(circleOfRadius: 1.4)
        dot.fillColor = SKColor(red: 0.2, green: 0.63, blue: 0.67, alpha: 0.5)
        dot.strokeColor = .clear
        dot.position = CGPoint(x: size.width + 8, y: CGFloat.random(in: 12...(size.height - 12)))
        dot.zPosition = 1
        addChild(dot)

        let speed: CGFloat = 230
        let duration = TimeInterval((size.width + 22) / speed)
        dot.run(SKAction.sequence([
            SKAction.moveBy(x: -(size.width + 22), y: 0, duration: duration),
            SKAction.removeFromParent()
        ]))
    }

    private func makeObstacle(size obstacleSize: CGSize) -> SKShapeNode {
        let node = SKShapeNode(rectOf: obstacleSize, cornerRadius: 8)
        node.fillColor = obstacleColor
        node.strokeColor = SKColor.clear
        node.zPosition = 5
        node.name = "obstacle"

        let body = SKPhysicsBody(rectangleOf: obstacleSize)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.obstacle
        body.contactTestBitMask = PhysicsCategory.ball
        body.collisionBitMask = PhysicsCategory.none
        body.usesPreciseCollisionDetection = true
        node.physicsBody = body

        return node
    }

    private func addObstacleMovement(node: SKNode, duration: TimeInterval) {
        addChild(node)
        node.run(SKAction.sequence([
            SKAction.moveBy(x: -(size.width + 70), y: 0, duration: duration),
            SKAction.removeFromParent()
        ]))
    }

    private func triggerGameOver() {
        guard gameIsRunning else { return }
        gameIsRunning = false
        isPaused = true
        gameState?.setGameOver(true)
    }

    private func removeAllObstacles() {
        enumerateChildNodes(withName: "obstacle") { node, _ in
            node.removeFromParent()
        }
    }

    private var ballColor: SKColor {
        switch gameState?.palette ?? .neonCyan {
        case .neonCyan: return SKColor(red: 0.22, green: 0.86, blue: 0.97, alpha: 1)
        case .neonPink: return SKColor(red: 1.0, green: 0.26, blue: 0.75, alpha: 1)
        case .neonGreen: return SKColor(red: 0.35, green: 1.0, blue: 0.42, alpha: 1)
        case .neonPurple: return SKColor(red: 0.75, green: 0.42, blue: 1.0, alpha: 1)
        case .sunsetOrange: return SKColor(red: 1.0, green: 0.55, blue: 0.23, alpha: 1)
        case .electricBlue: return SKColor(red: 0.24, green: 0.57, blue: 1.0, alpha: 1)
        }
    }

    private var obstacleColor: SKColor {
        switch gameState?.palette ?? .neonCyan {
        case .neonCyan: return SKColor(red: 0.1, green: 0.72, blue: 0.76, alpha: 1)
        case .neonPink: return SKColor(red: 1.0, green: 0.42, blue: 0.58, alpha: 1)
        case .neonGreen: return SKColor(red: 0.15, green: 0.82, blue: 0.33, alpha: 1)
        case .neonPurple: return SKColor(red: 0.52, green: 0.37, blue: 0.95, alpha: 1)
        case .sunsetOrange: return SKColor(red: 1.0, green: 0.39, blue: 0.21, alpha: 1)
        case .electricBlue: return SKColor(red: 0.14, green: 0.41, blue: 0.92, alpha: 1)
        }
    }

    func applyCurrentPalette() {
        ballNode.fillColor = ballColor
        enumerateChildNodes(withName: "obstacle") { node, _ in
            if let shape = node as? SKShapeNode {
                shape.fillColor = self.obstacleColor
            }
        }
    }
}
