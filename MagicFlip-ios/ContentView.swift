import SwiftUI
import SpriteKit

struct ContentView: View {
    enum Screen {
        case menu
        case playing
        case highScore
        case howToPlay
        case colorSelect
    }

    @StateObject private var gameState = GameState()
    @State private var scene = GameScene(size: UIScreen.main.bounds.size)
    @State private var screen: Screen = .menu
    @State private var animateBackground = false
    @State private var didConfigureScene = false

    var body: some View {
        ZStack {
            animatedBackground
                .ignoresSafeArea()

            SpriteView(scene: scene)
                .ignoresSafeArea()
                .opacity(screen == .playing ? 1 : 0)

            if screen == .playing {
                inGameHud
                    .allowsHitTesting(false)
            }

            if gameState.isGameOver {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("PAUSED")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("SCORE \(gameState.score)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))

                    Text("BEST \(gameState.bestScore)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))

                    Button {
                        scene.startNewGame()
                    } label: {
                        Text("RESTART")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(red: 0.08, green: 0.69, blue: 0.73))
                            )
                    }

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            gameState.setGameOver(false)
                            gameState.resetForNewRun()
                            screen = .menu
                        }
                        scene.prepareForMenu()
                    } label: {
                        Text("MENU")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(.white.opacity(0.95))
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.15))
                            )
                    }
                }
                .padding(24)
                .frame(maxWidth: 330)
                .background(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(Color.black.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .transition(.scale(scale: 0.92).combined(with: .opacity))
            }

            if screen != .playing {
                menuLayer
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: screen)
        .animation(.easeInOut(duration: 0.2), value: gameState.isGameOver)
        .onAppear {
            // Always boot into menu state, even if SwiftUI restores @State.
            screen = .menu
            gameState.setGameOver(false)
            gameState.resetForNewRun()

            if !didConfigureScene {
                scene.scaleMode = .resizeFill
                scene.gameState = gameState
                scene.prepareForMenu()
                didConfigureScene = true
            } else {
                scene.prepareForMenu()
            }

            withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: true)) {
                animateBackground = true
            }
        }
        .onChange(of: gameState.palette) {
            scene.applyCurrentPalette()
        }
    }

    private var inGameHud: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SCORE \(gameState.score)")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("HIGH SCORE")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))

                    Text("\(gameState.bestScore)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)

            Spacer()
        }
    }

    private var menuLayer: some View {
        VStack(spacing: 20) {
            Text("GRAVITY FLIP")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .tracking(1.2)
                .padding(.bottom, 4)

            Group {
                switch screen {
                case .menu:
                    menuButtons
                case .highScore:
                    highScoreCard
                case .howToPlay:
                    howToPlayCard
                case .colorSelect:
                    colorSelectCard
                case .playing:
                    EmptyView()
                }
            }
            .frame(maxWidth: 360)

            Spacer()

            if screen == .menu {
                difficultyWheelPicker
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    private var menuButtons: some View {
        VStack(spacing: 14) {
            menuButton(title: "START", color: Color(red: 0.08, green: 0.69, blue: 0.73)) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    screen = .playing
                }
                gameState.resetForNewRun()
                scene.startNewGame()
            }

            menuButton(title: "COLOR SELECT", color: Color(red: 0.86, green: 0.29, blue: 0.78)) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    screen = .colorSelect
                }
            }

            menuButton(title: "HIGHSCORE", color: Color(red: 0.13, green: 0.47, blue: 0.76)) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    screen = .highScore
                }
            }

            menuButton(title: "HOW TO PLAY", color: Color(red: 0.24, green: 0.33, blue: 0.67)) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    screen = .howToPlay
                }
            }
        }
    }

    private var colorSelectCard: some View {
        VStack(spacing: 16) {
            Text("COLOR SELECT")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("Choose a bright color theme for both the ball and obstacles.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.86))
                .multilineTextAlignment(.center)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(GamePalette.allCases, id: \.self) { palette in
                        colorPaletteButton(palette)
                    }
                }
            }
            .frame(maxHeight: 250)

            menuButton(title: "BACK", color: Color.white.opacity(0.2)) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    screen = .menu
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private func colorPaletteButton(_ palette: GamePalette) -> some View {
        let isSelected = gameState.palette == palette

        return Button {
            gameState.setPalette(palette)
        } label: {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(palette.swatchGradient)
                    .frame(height: 34)

                Text(palette.rawValue)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.white.opacity(0.55) : Color.white.opacity(0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var difficultyWheelPicker: some View {
        VStack(spacing: 8) {
            Text("DIFFICULTY")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))

            Picker("Difficulty", selection: Binding(
                get: { gameState.difficulty },
                set: { gameState.setDifficulty($0) }
            )) {
                ForEach(GameDifficulty.allCases, id: \.self) { level in
                    Text(level.rawValue)
                        .tag(level)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 128)
            .colorScheme(.dark)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black.opacity(0.38))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    private var highScoreCard: some View {
        VStack(spacing: 16) {
            Text("BEST SCORE")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("\(gameState.bestScore)")
                .font(.system(size: 54, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.32, green: 0.95, blue: 1.0))

            menuButton(title: "BACK", color: Color.white.opacity(0.2)) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    screen = .menu
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var howToPlayCard: some View {
        VStack(spacing: 16) {
            Text("HOW TO PLAY")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("Tap to switch between top and bottom lanes. Avoid incoming blocks. If the ball touches any obstacle, the run stops instantly.")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)

            menuButton(title: "BACK", color: Color.white.opacity(0.2)) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    screen = .menu
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var animatedBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.08, blue: 0.15),
                    Color(red: 0.02, green: 0.16, blue: 0.23),
                    Color(red: 0.01, green: 0.07, blue: 0.12)
                ],
                startPoint: animateBackground ? .topLeading : .bottomLeading,
                endPoint: animateBackground ? .bottomTrailing : .topTrailing
            )

            Circle()
                .fill(Color(red: 0.05, green: 0.72, blue: 0.78).opacity(0.32))
                .frame(width: 340, height: 340)
                .blur(radius: 42)
                .offset(x: animateBackground ? -130 : 110, y: animateBackground ? -300 : -240)

            Circle()
                .fill(Color(red: 0.14, green: 0.41, blue: 0.92).opacity(0.24))
                .frame(width: 320, height: 320)
                .blur(radius: 38)
                .offset(x: animateBackground ? 120 : -90, y: animateBackground ? 270 : 200)
        }
    }

    private func menuButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 21, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(color)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .shadow(color: color.opacity(0.35), radius: 10, y: 4)
    }
}

private extension GamePalette {
    var swatchGradient: LinearGradient {
        switch self {
        case .neonCyan:
            return LinearGradient(colors: [Color(red: 0.22, green: 0.86, blue: 0.97), Color(red: 0.1, green: 0.72, blue: 0.76)], startPoint: .leading, endPoint: .trailing)
        case .neonPink:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.26, blue: 0.75), Color(red: 1.0, green: 0.42, blue: 0.58)], startPoint: .leading, endPoint: .trailing)
        case .neonGreen:
            return LinearGradient(colors: [Color(red: 0.35, green: 1.0, blue: 0.42), Color(red: 0.15, green: 0.82, blue: 0.33)], startPoint: .leading, endPoint: .trailing)
        case .neonPurple:
            return LinearGradient(colors: [Color(red: 0.75, green: 0.42, blue: 1.0), Color(red: 0.52, green: 0.37, blue: 0.95)], startPoint: .leading, endPoint: .trailing)
        case .sunsetOrange:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.55, blue: 0.23), Color(red: 1.0, green: 0.39, blue: 0.21)], startPoint: .leading, endPoint: .trailing)
        case .electricBlue:
            return LinearGradient(colors: [Color(red: 0.24, green: 0.57, blue: 1.0), Color(red: 0.14, green: 0.41, blue: 0.92)], startPoint: .leading, endPoint: .trailing)
        }
    }
}

#Preview {
    ContentView()
}
