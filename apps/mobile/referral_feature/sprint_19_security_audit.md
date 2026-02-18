# Sprint 19: Security Audit & Performance Optimization

**Status**: Not Started
**Previous Sprint**: `sprint_18_end_to_end_testing.md`
**Next Sprint**: `sprint_20_launch_prep.md`
**Estimated Duration**: 8-10 hours

---

## Objectives
Comprehensive security audit of the referral system, fix vulnerabilities, and optimize performance for production.

---

## Tasks

### Task 1: Firestore Security Rules Audit

**Review and test**:
- [ ] Only code owners can read their own codes
- [ ] Users cannot write to referralCodes (Cloud Functions only)
- [ ] Users cannot modify verification documents directly
- [ ] Users can only read their own verification status
- [ ] Referrers can read their referees' verification status
- [ ] Only admins can access all verification documents
- [ ] Stats documents properly secured
- [ ] Reward logs properly secured
- [ ] Audit log only accessible by admins

**Test with**:
- Firebase Emulator Suite
- Manual testing with different user roles
- Automated security rules tests

**Fix any vulnerabilities found**.

---

### Task 2: Cloud Functions Security Audit

**Check all functions for**:
- [ ] Authentication verification (all callable functions)
- [ ] Input validation (never trust client input)
- [ ] Rate limiting (prevent abuse)
- [ ] SQL injection prevention (not applicable but check)
- [ ] XSS prevention in generated content
- [ ] Proper error handling (don't leak sensitive info)
- [ ] Admin role verification for admin functions
- [ ] Secrets not hardcoded (use Firebase Config)

**Specific checks**:
```typescript
// ✅ Good
export const someFunction = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  // Validate input
  if (!data.code || typeof data.code !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid code');
  }

  // Sanitize input
  const code = data.code.trim().toUpperCase();

  // Continue...
});

// ❌ Bad
export const someFunction = functions.https.onCall(async (data, context) => {
  // No auth check
  // No input validation
  const code = data.code; // Unsanitized
});
```

---

### Task 3: API Routes Security Audit (Admin Panel)

**Check all API routes for**:
- [ ] Admin authentication on every route
- [ ] Input validation and sanitization
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] CSRF protection
- [ ] Rate limiting
- [ ] Proper CORS configuration
- [ ] Sensitive data not exposed in responses

**Example secure route**:
```typescript
export async function POST(request: NextRequest) {
  // 1. Verify authentication
  const token = request.headers.get('authorization')?.split('Bearer ')[1];
  if (!token) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  // 2. Verify admin role
  if (!(await verifyAdmin(token))) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }

  // 3. Validate input
  const body = await request.json();
  if (!body.userId || typeof body.userId !== 'string') {
    return NextResponse.json({ error: 'Invalid input' }, { status: 400 });
  }

  // 4. Sanitize
  const userId = body.userId.trim();

  // 5. Process
  // ...

  return NextResponse.json({ success: true });
}
```

---

### Task 4: Sensitive Data Protection

**Audit what data is exposed**:
- [ ] Email addresses properly masked in public views
- [ ] User IDs not leaked unnecessarily
- [ ] Referral code patterns not predictable
- [ ] Fraud detection algorithms not exposed
- [ ] Admin notes not visible to users
- [ ] RevenueCat API keys secure
- [ ] Firebase config secure

**PII Protection**:
- Ensure GDPR compliance
- Allow users to delete their data
- Don't expose unnecessary PII

---

### Task 5: Fraud Prevention Security

**Check exploit attempts**:
- [ ] User cannot manipulate fraud score
- [ ] User cannot bypass verification requirements
- [ ] User cannot redeem rewards multiple times
- [ ] User cannot fake completion timestamps
- [ ] Device ID spoofing detected
- [ ] Referral code generation not predictable
- [ ] RevenueCat entitlement grants verified server-side

---

### Task 6: Rate Limiting Implementation

Add rate limits to prevent abuse:

**Cloud Functions**:
```typescript
// Use Firebase Extensions or custom middleware
const rateLimiter = require('express-rate-limit');

const limiter = rateLimiter({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Limit each IP to 10 requests per windowMs
});

// Apply to callable functions
```

**API Routes**:
```typescript
// Next.js middleware for rate limiting
import { rateLimiter } from '@/lib/rateLimiter';

export async function middleware(request: NextRequest) {
  const limitResult = await rateLimiter(request);
  if (!limitResult.success) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
  }
  return NextResponse.next();
}
```

**Limits to set**:
- Referral code redemption: 3 attempts per hour per user
- Reward redemption: Once per day
- Admin searches: 100 per hour
- Fraud queue queries: 50 per minute

---

### Task 7: Performance Optimization

**Firestore Query Optimization**:
- [ ] All queries have proper indexes
- [ ] No N+1 query problems
- [ ] Batch reads where possible
- [ ] Use pagination for large result sets
- [ ] Cache frequently accessed data

**Cloud Functions Optimization**:
- [ ] Minimize cold starts (use min instances for critical functions)
- [ ] Optimize function memory allocation
- [ ] Use connection pooling
- [ ] Avoid unnecessary Firestore reads
- [ ] Batch writes where possible

**Admin Panel Optimization**:
- [ ] Server-side rendering for initial load
- [ ] Client-side caching
- [ ] Code splitting
- [ ] Image optimization
- [ ] Lazy loading non-critical components

**Mobile App Optimization**:
- [ ] Minimize Firestore listeners
- [ ] Cache data locally
- [ ] Optimize images
- [ ] Reduce bundle size
- [ ] Use pagination in lists

---

### Task 8: Monitor Setup

**Set up monitoring for**:
- Cloud Functions errors and latency
- Firestore read/write costs
- API route response times
- Failed authentication attempts
- Fraud detection triggers
- Unusual activity patterns

**Tools**:
- Firebase Console monitoring
- Cloud Functions logs
- Sentry or similar error tracking
- Custom analytics

---

### Task 9: Secrets Management Audit

**Verify**:
- [ ] No API keys in code
- [ ] RevenueCat keys in Firebase Config or environment variables
- [ ] Admin passwords hashed
- [ ] JWT secrets secure
- [ ] No credentials in Git history

---

### Task 10: Compliance Check

**GDPR Compliance**:
- [ ] User can delete their account and data
- [ ] User can export their data
- [ ] Privacy policy updated
- [ ] Cookie consent (if applicable)
- [ ] Referral data properly handled on account deletion

**App Store Compliance**:
- [ ] Privacy manifest (iOS)
- [ ] Data usage declarations
- [ ] Terms of service

### Task 10.1: User Deletion & Referral System

**When a referred user (referee) deletes their account**:
- [ ] Referrer is notified
- [ ] Verification status updated to 'deleted'
- [ ] Referrer's stats decremented (totalReferred, totalVerified)
- [ ] Referral code redemption count decremented
- [ ] Audit log created for tracking
- [ ] Data preserved (not deleted) for audit purposes

**When a referrer deletes their account**:
- [ ] Referral code deactivated
- [ ] Referral stats marked as deleted
- [ ] All verifications marked with referrerDeleted flag
- [ ] All rewards marked with referrerDeleted flag
- [ ] Data preserved (not deleted) for audit purposes

**Implementation**: 
- File: `functions/src/referral/handlers/userDeletionHandler.ts`
- Integrated into: `functions/src/index.ts` (deleteUserAccount function)
- Collections affected:
  - `referralVerifications` (status updated to 'deleted')
  - `referralStats` (decremented/marked deleted)
  - `referralCodes` (redemptions decremented/deactivated)
  - `referralRewards` (marked as referrer deleted)
  - `referralFraudLogs` (audit entries created)

---

### Task 11: Penetration Testing

**Test for vulnerabilities**:
- SQL injection (not applicable but good practice)
- XSS attacks
- CSRF attacks
- Authentication bypass attempts
- Authorization bypass attempts
- API endpoint enumeration
- Sensitive data exposure
- Rate limit bypass attempts

**Use tools**:
- OWASP ZAP
- Burp Suite
- Manual testing

---

### Task 12: Create Security Incident Response Plan

Document procedures for:
- Detecting security breach
- Containing the damage
- Notifying affected users
- Fixing vulnerability
- Post-incident review

---

## Security Checklist

### Authentication & Authorization
- [ ] All protected endpoints verify authentication
- [ ] Admin endpoints verify admin role
- [ ] Token validation working
- [ ] Session management secure

### Input Validation
- [ ] All user inputs validated
- [ ] Inputs sanitized
- [ ] Type checking enforced
- [ ] Length limits enforced

### Data Protection
- [ ] Sensitive data encrypted
- [ ] PII properly handled
- [ ] Secrets not exposed
- [ ] Logs don't contain sensitive info

### API Security
- [ ] HTTPS only
- [ ] CORS properly configured
- [ ] Rate limiting in place
- [ ] Error messages don't leak info

### Code Security
- [ ] No hardcoded secrets
- [ ] Dependencies up to date
- [ ] Known vulnerabilities patched
- [ ] Code reviewed

---

## Performance Benchmarks

Target metrics:
- Cloud Function execution: < 5 seconds (99th percentile)
- API response time: < 1 second (95th percentile)
- Mobile app interactions: < 100ms (perceived)
- Firestore queries: < 500ms
- Admin dashboard load: < 2 seconds

Run load tests and optimize until targets met.

---

## Success Criteria

- [ ] No critical security vulnerabilities
- [ ] All sensitive data protected
- [ ] Rate limiting prevents abuse
- [ ] Performance targets met
- [ ] Monitoring in place
- [ ] Compliance requirements met
- [ ] Incident response plan ready
- [ ] Security documentation complete

---

## Notes for Next Sprint

Sprint 20 will prepare for launch: documentation, rollout plan, and launch checklist.

---

**Next Sprint**: `sprint_20_launch_prep.md`
