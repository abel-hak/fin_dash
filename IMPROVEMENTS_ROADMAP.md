# SMS Transaction App - Improvements Roadmap

## ✅ Phase 1: Critical Fixes (COMPLETED)

### 1. Database Reset Issue
- **Status:** ✅ Fixed
- **File:** `lib/main.dart`
- **Impact:** User data now persists between sessions

### 2. Environment Configuration
- **Status:** ✅ Implemented
- **Files:** `lib/core/env_config.dart`, `.env.example`
- **Impact:** Secure credential management

### 3. Aggressive Polling
- **Status:** ✅ Fixed
- **File:** `lib/features/inbox/inbox_screen.dart`
- **Impact:** Better performance, pull-to-refresh added

### 4. Templates Asset
- **Status:** ✅ Added
- **Files:** `assets/templates.json`, `pubspec.yaml`
- **Impact:** SMS parsing now works out of the box

---

## 🔄 Phase 2: Stability (NEXT)

### Priority 1: Error Handling & Logging
- [ ] Replace all `print()` with proper logger
- [ ] Add structured error tracking
- [ ] Implement user-friendly error messages
- [ ] Add error boundaries for critical sections

**Files to modify:**
- All service files (`lib/services/*.dart`)
- Parser (`lib/domain/parser/sms_parser.dart`)
- Database helper (`lib/data/db/database_helper.dart`)

### Priority 2: Database Query Optimization
- [ ] Add `getTransactionById()` method to DatabaseHelper
- [ ] Implement pagination for transaction lists
- [ ] Add database indexes for common queries
- [ ] Cache frequently accessed data

**Files to modify:**
- `lib/data/db/database_helper.dart`
- `lib/features/review/review_screen.dart`
- `lib/features/inbox/inbox_screen.dart`

### Priority 3: Complete TODO Features
- [ ] Implement date picker in review screen
- [ ] Add trusted senders persistence
- [ ] Complete settings screen functionality
- [ ] Add auto-approve feature

**Files to modify:**
- `lib/features/review/review_screen.dart` (line 410)
- `lib/services/sms_service.dart` (lines 146, 164)
- `lib/features/settings/settings_screen.dart`

### Priority 4: Unit Tests
- [ ] Parser tests (regex patterns, edge cases)
- [ ] Fingerprint generation tests
- [ ] Template matching tests
- [ ] Database CRUD tests

**Files to create:**
- `test/domain/parser/sms_parser_test.dart`
- `test/data/db/database_helper_test.dart`
- `test/services/template_service_test.dart`

---

## 🎯 Phase 3: Performance & UX (FUTURE)

### Priority 1: Performance
- [ ] Implement pagination (50 transactions per page)
- [ ] Add lazy loading for transaction lists
- [ ] Optimize provider invalidation strategy
- [ ] Add transaction caching layer

### Priority 2: User Experience
- [ ] Add loading states for all async operations
- [ ] Implement skeleton loaders
- [ ] Add success/error animations
- [ ] Improve empty states

### Priority 3: Code Quality
- [ ] Remove unused dependencies (drift, flutter_hooks)
- [ ] Extract hardcoded strings to constants
- [ ] Add inline documentation
- [ ] Refactor large widgets into smaller components

---

## 🚀 Phase 4: Long-term (ONGOING)

### Architecture
- [ ] Implement repository pattern
- [ ] Add use cases/interactors layer
- [ ] Implement dependency injection (get_it)
- [ ] Separate business logic from UI

### Features
- [ ] Internationalization (i18n)
- [ ] Dark mode improvements
- [ ] Export transactions (CSV, PDF)
- [ ] Transaction search and filters
- [ ] Analytics dashboard

### DevOps
- [ ] CI/CD pipeline setup
- [ ] Automated testing
- [ ] Crash reporting (Sentry/Firebase)
- [ ] Analytics integration
- [ ] Environment-specific builds

### Documentation
- [ ] API documentation
- [ ] Architecture diagrams
- [ ] Contributing guidelines
- [ ] Code style guide

---

## Quick Wins (Can be done anytime)

- [x] Replace `print()` with logger ⚡
- [x] Remove unused dependencies ⚡
- [x] Make tab counts dynamic ⚡
- [ ] Add semantic labels for accessibility ⚡
- [ ] Extract hardcoded strings to constants ⚡
- [ ] Add inline documentation for regex patterns ⚡
- [ ] Create environment config template ⚡

---

## Metrics to Track

### Performance
- App startup time
- Database query time
- SMS parsing time
- UI frame rate

### Quality
- Test coverage (target: 80%)
- Number of crashes
- Number of ANRs (Application Not Responding)
- Code complexity metrics

### User Experience
- Time to approve transaction
- Number of parsing errors
- Sync success rate
- User retention

---

## Notes

- Each phase builds on the previous one
- Phases can be worked on in parallel for different features
- Quick wins can be tackled opportunistically
- Always test changes on real devices with actual SMS messages

---

**Last Updated:** Phase 1 Completed
**Next Milestone:** Phase 2 - Stability Improvements
