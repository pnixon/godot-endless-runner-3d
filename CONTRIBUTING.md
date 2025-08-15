# Contributing to Godot Endless Runner

Thank you for your interest in contributing to this project! Here are some guidelines to help you get started.

## How to Contribute

### Reporting Bugs
1. Check if the bug has already been reported in the [Issues](https://github.com/pnixon/godot-endless-runner/issues)
2. If not, create a new issue using the bug report template
3. Include as much detail as possible, including steps to reproduce

### Suggesting Features
1. Check if the feature has already been suggested
2. Create a new issue using the feature request template
3. Explain the use case and potential implementation

### Code Contributions

#### Prerequisites
- Godot 4.4.1 or later
- Basic knowledge of GDScript
- Git for version control

#### Development Setup
1. Fork the repository
2. Clone your fork: `git clone git@github.com:yourusername/godot-endless-runner.git`
3. Open the project in Godot
4. Make your changes
5. Test thoroughly

#### Pull Request Process
1. Create a new branch for your feature: `git checkout -b feature/your-feature-name`
2. Make your changes with clear, descriptive commit messages
3. Test your changes thoroughly
4. Update documentation if needed
5. Push to your fork: `git push origin feature/your-feature-name`
6. Create a Pull Request with a clear description of your changes

#### Code Style
- Follow GDScript style conventions
- Use meaningful variable and function names
- Comment complex logic
- Keep functions focused and small
- Use signals for component communication

#### Testing
- Test all new features thoroughly
- Ensure existing functionality still works
- Test on different screen resolutions if UI changes are made
- Verify performance impact of changes

## Project Structure

### Key Components
- **GameManager.gd**: Main game loop and state management
- **Player.gd**: Player movement and health system
- **HazardData.gd**: Hazard type definitions
- **EnhancedObstacle.gd**: Hazard behavior and effects
- **CombatGrid.gd**: Turn-based combat system

### Adding New Features

#### New Hazard Types
1. Add to `HazardType` enum in `HazardData.gd`
2. Create factory method in `HazardData.gd`
3. Add handling in `EnhancedObstacle.gd`
4. Add player collision response in `Player.gd`
5. Update spawn weights in `GameManager.gd`

#### New Combat Features
1. Modify `CombatGrid.gd` for new mechanics
2. Update enemy formations and abilities
3. Test balance thoroughly

#### Audio/Visual Features
1. Add assets to appropriate folders
2. Update loading code in relevant scripts
3. Ensure proper cleanup and memory management

## Questions?

Feel free to open an issue for questions about contributing or the codebase structure.

Thank you for contributing!
