# Contributing to SMS Transaction App

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone <your-fork-url>`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Configure credentials (see README.md)
5. Make your changes
6. Test thoroughly
7. Commit with clear messages
8. Push to your fork
9. Open a Pull Request

## Development Setup

### Prerequisites
- Flutter SDK (latest stable)
- Android Studio or VS Code
- Android device/emulator (Android 8.0+)

### First-Time Setup
```bash
flutter pub get
# Configure lib/core/env_config.dart with your credentials
flutter run
```

## Code Style

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter format` before committing
- Keep functions small and focused
- Add comments for complex logic
- Use meaningful variable names

## Commit Messages

Use clear, descriptive commit messages:
- `feat: Add receipt PDF parsing`
- `fix: Resolve SMS permission crash`
- `docs: Update README with setup instructions`
- `refactor: Simplify transaction parser logic`

## Testing

- Test on real Android devices when possible
- Verify SMS parsing with multiple bank formats
- Check offline/online sync behavior
- Test permission flows

## Pull Request Process

1. Update README.md if needed
2. Add/update tests for new features
3. Ensure all tests pass
4. Update documentation
5. Request review from maintainers

## Security

**NEVER commit:**
- API keys or credentials
- `.env` files with real values
- Personal/sensitive data
- Database dumps with real transactions

See SECURITY.md for details.

## Questions?

Open an issue for:
- Bug reports
- Feature requests
- Documentation improvements
- General questions

Thank you for contributing! 🎉
