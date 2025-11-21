# Ta3afi Referral Program - Implementation Plan

## Overview
This folder contains the complete sprint plan for implementing the Ta3afi referral program. The system rewards users for referring friends who become active, verified users of the app.

## Program Summary

### Verification Requirements
New users must complete within 7 days:
- Account active for 7 days
- Post 3 forum posts
- Comment or interact 5 times
- Join a group + send 3 messages
- Start 1 recovery activity

### Rewards
- **5 verified referrals** = 1 month Premium (via RevenueCat)
- **Paid conversion bonus** = +2 weeks Premium per paying user

### Anti-Fraud
Automatic fraud detection checks for same device, rapid activity, same IP, and suspicious patterns.

---

## Sprint Structure

### Mobile App Implementation (Sprints 1-11)
- **Sprint 01**: Database schema & Firestore security rules
- **Sprint 02**: Referral code generation system
- **Sprint 03**: Referral code input during signup
- **Sprint 04**: Verification checklist Cloud Functions (setup)
- **Sprint 05**: Verification checklist Cloud Functions (tracking)
- **Sprint 06**: Fraud detection system
- **Sprint 07**: User referral dashboard UI
- **Sprint 08**: Checklist progress tracker UI
- **Sprint 09**: Share referral feature
- **Sprint 10**: Notification system for milestones
- **Sprint 11**: RevenueCat reward integration

### Admin Panel Implementation (Sprints 12-17) //Don't care about it, will be handeled by other agent.
- **Sprint 12**: Admin dashboard overview page
- **Sprint 13**: Fraud detection review queue
- **Sprint 14**: User referral lookup & search
- **Sprint 15**: Manual adjustment tools
- **Sprint 16**: Analytics & reporting dashboard
- **Sprint 17**: Admin testing & polish

### Integration & Launch (Sprints 18-20)
- **Sprint 18**: End-to-end testing & bug fixes
- **Sprint 19**: Security audit & performance optimization
- **Sprint 20**: Launch preparation & rollout

---

## Important Notes for Cursor AI Agent

### Before Each Sprint:
1. **Read the previous sprint file** to understand completed work
2. **Use Firestore MCP** to query existing collections and understand schema
3. **Check codebase** for existing patterns, models, and services
4. **Verify dependencies** are installed and compatible

### During Each Sprint:
1. Follow the sprint's task list in order
2. Maintain existing code style and patterns
3. Add proper error handling and validation
4. Write clean, maintainable code
5. DRY! Check for existing utlities and helpers and reusable classes
6. Commit changes after each small change with clear short messages (less than 8 words)

### After Each Sprint:
1. Ensure app is **buildable** (no compilation errors)
2. Hand your notes to the next sprint

---

## Technology Stack

### Mobile App (Flutter)
- **State Management**: Riverpod
- **Navigation**: Go Router
- **Database**: Cloud Firestore
- **Auth**: Firebase Auth
- **Functions**: Cloud Functions (TypeScript)
- **Subscriptions**: RevenueCat
- **Localization**: English & Arabic

### Admin Panel (Next.js)
- **Framework**: Next.js 13+ (App Router)
- **Language**: TypeScript
- **Database**: Cloud Firestore (Firebase Admin SDK)
- **Auth**: Firebase Admin Auth
- **UI**: TailwindCSS (maintain existing style)
- **API Routes**: Next.js API routes

---

## Key Design Principles

### UI/UX
- **Beautiful but minimal**: Clean, modern design that catches attention without being noisy
- **Progress-driven**: Show clear progress indicators and celebrate milestones
- **Bilingual**: All UI text must support English and Arabic
- **Accessible**: Follow Flutter accessibility best practices

### Code Quality
- **Type-safe**: Use strong typing (Dart models, TypeScript interfaces)
- **Error handling**: Graceful degradation and user-friendly error messages
- **Testing**: Each feature should be testable
- **Documentation**: Clear comments for complex logic

### Security
- **Firestore Rules**: Strict rules to prevent unauthorized access
- **Input validation**: Never trust client input
- **Rate limiting**: Prevent abuse of Cloud Functions
- **Fraud detection**: Multi-layered checks for fake accounts

---

## Getting Started

1. Start with **Sprint 01** (`sprint_01_database_schema.md`)
2. Follow sprints in sequential order
3. Each sprint builds on the previous one
4. Do not skip sprints unless explicitly instructed
5. Mark sprints as complete in this README

---

## Sprint Completion Tracker

- [x] Sprint 01 - Database schema & Firestore security rules
- [x] Sprint 02 - Referral code generation system
- [x] Sprint 03 - Referral code input during signup
- [x] Sprint 04 - Verification checklist Cloud Functions (setup)
- [x] Sprint 05 - Verification checklist Cloud Functions (tracking)
- [ ] Sprint 06 - Fraud detection system
- [ ] Sprint 07 - User referral dashboard UI
- [ ] Sprint 08 - Checklist progress tracker UI
- [ ] Sprint 09 - Share referral feature
- [ ] Sprint 10 - Notification system for milestones
- [ ] Sprint 11 - RevenueCat reward integration
- [ ] Sprint 12 - Admin dashboard overview page
- [ ] Sprint 13 - Fraud detection review queue
- [ ] Sprint 14 - User referral lookup & search
- [ ] Sprint 15 - Manual adjustment tools
- [ ] Sprint 16 - Analytics & reporting dashboard
- [ ] Sprint 17 - Admin testing & polish
- [ ] Sprint 18 - End-to-end testing & bug fixes
- [ ] Sprint 19 - Security audit & performance optimization
- [ ] Sprint 20 - Launch preparation & rollout

---

## 📝 Important Notes

### Manual Referral Code Generation (TODO)
Currently, referral codes are automatically generated:
- **New users**: Automatically on signup via `generateReferralCodeOnUserCreation` trigger
- **Existing users**: Admin-only backfill via `backfillReferralCodes` callable function

**Future Enhancement**: Add a user-facing feature to allow users to manually regenerate their referral code if needed (e.g., if they want a more personalized code or if generation failed). This would require:
- A new callable Cloud Function (e.g., `regenerateUserReferralCode`)
- UI button in user profile/settings
- Validation to prevent abuse (e.g., rate limiting, max regenerations)

---

## Contact & Support

For questions about implementation details, refer to:
- Main codebase structure and patterns
- Existing Firestore collections and models
- Firebase project configuration
- RevenueCat setup documentation
