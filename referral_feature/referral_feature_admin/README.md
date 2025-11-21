# Admin Panel for Ta3afi Referral Program

## Overview
This folder contains sprints for building the Next.js admin panel to manage the referral program.

## Admin Panel Features

### Core Pages
1. **Dashboard Overview** - Stats, charts, and key metrics
2. **Fraud Detection Queue** - Review flagged accounts
3. **User Lookup** - Search and view individual referral details
4. **Manual Adjustments** - Admin tools for edge cases
5. **Analytics & Reporting** - Comprehensive program insights

### Technology Stack
- **Framework**: Next.js 13+ (App Router)
- **Language**: TypeScript
- **Database**: Cloud Firestore
  - **Server-side**: Firebase Admin SDK (for API routes)
  - **Client-side**: react-firebase-hooks (for real-time React components)
- **Auth**: Firebase Admin Auth
- **UI**: TailwindCSS
- **Charts**: Recharts
- **Tables**: TanStack Table (React Table v8)

---

## Sprint List

- **Sprint 12**: Admin Dashboard Overview
- **Sprint 13**: Fraud Detection Review Queue
- **Sprint 14**: User Referral Lookup & Search
- **Sprint 15**: Manual Adjustment Tools
- **Sprint 16**: Analytics & Reporting Dashboard
- **Sprint 17**: Admin Testing & Polish

---

## Setup Prerequisites

Before starting admin panel sprints:
1. Firebase Admin SDK initialized in Next.js app
2. Admin authentication working
3. Firestore connection established
4. Environment variables configured

---

## Admin Access Control

**Security Rules**:
- Only users with `role: 'admin'` in Firestore can access admin panel
- Server-side authentication checks on all API routes
- No client-side admin role bypassing

**Implementation**:
```typescript
// middleware.ts or API route
export async function verifyAdmin(token: string): Promise<boolean> {
  const decodedToken = await admin.auth().verifyIdToken(token);
  const userDoc = await admin.firestore().collection('users').doc(decodedToken.uid).get();
  return userDoc.data()?.role === 'admin';
}
```

---

## Navigation Structure

```
/admin
├── /referrals
│   ├── /dashboard          (Sprint 12)
│   ├── /fraud-queue        (Sprint 13)
│   ├── /users              (Sprint 14)
│   ├── /adjustments        (Sprint 15)
│   └── /analytics          (Sprint 16)
```

---

## Design Guidelines

- **Clean & functional**: Admin tools, not marketing site
- **Data-dense**: Show as much relevant info as possible
- **Fast**: Optimize queries and loading states
- **Responsive**: Works on laptop/desktop (mobile optional)
- **Accessible**: Keyboard navigation, proper ARIA labels

---

## Important Notes

- All admin routes should be server-side rendered or use server components
- Always verify admin role before showing sensitive data
- Log all admin actions for audit trail
- Use React Server Components where possible for performance
- Add loading states for all async operations

### Firebase Usage Guidelines

**IMPORTANT: Clear Separation of Concerns**

**API Routes (`/app/api/**/*.ts`):**
- ✅ Use Firebase Admin SDK ONLY
- For: Aggregations, privileged operations, complex queries
- Never use react-firebase-hooks in API routes

**React Components (`"use client"`):**
- ✅ Use react-firebase-hooks ONLY
- For: Real-time data, live updates, direct Firestore reads
- Hooks: `useCollection`, `useDocument`, `useCollectionData`
- Components fetch from API routes OR subscribe to Firestore directly

**React Server Components (RSC):**
- Fetch from API routes (which use Admin SDK)
- No direct Firebase operations in RSC
