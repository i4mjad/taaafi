# Firebase AI Message Moderation - Integration TODOs

## 🚀 Critical Setup Tasks

### 1. Firebase Functions Setup
- [ ] **Initialize Firebase Functions** (if not already done)
  ```bash
  npm install -g firebase-tools
  firebase login
  firebase init functions
  ```

- [ ] **Install Required Dependencies**
  ```bash
  cd functions
  npm install @google-cloud/vertexai firebase-functions firebase-admin
  ```

- [ ] **Configure Environment Variables**
  ```bash
  firebase functions:config:set vertexai.project_id="your-project-id"
  firebase functions:config:set vertexai.location="us-central1"
  ```

### 2. Google Cloud / Vertex AI Setup
- [ ] **Enable Required APIs**
  - Vertex AI API
  - Cloud Functions API  
  - Firestore API
  - Cloud Logging API

- [ ] **Set up Service Account**
  - Create service account with Vertex AI permissions
  - Download service account key
  - Set GOOGLE_APPLICATION_CREDENTIALS environment variable

- [ ] **Configure Vertex AI Model Access**
  - Enable Gemini 1.5 Flash model
  - Set up billing account
  - Configure usage quotas

### 3. Firestore Database Schema Updates

#### 3.1 Update Message Document Structure
```javascript
// Add to existing group_messages collection
{
  // ... existing fields
  moderation: {
    status: 'pending' | 'approved' | 'blocked' | 'manual_review',
    violationType?: 'social_media_sharing' | 'sexual_content' | 'cuckoldry_content' | 'homosexuality_content',
    reason?: string,
    detectedContent?: string,
    moderatedBy: 'rule-based' | 'ai' | 'human' | 'auto' | 'error-fallback',
    confidence?: number,
    aiProcessingTime?: number,
    processingTimeMs: number,
    moderatedAt: timestamp,
    error?: string
  }
}
```

#### 3.2 Create Moderation Queue Collection
```javascript
// Create new collection: moderation_queue
{
  messageId: string,
  groupId: string,
  senderCpId: string,
  messageBody: string,
  aiAnalysis?: object,
  priority: 'low' | 'medium' | 'high' | 'critical',
  status: 'pending' | 'in_review' | 'completed',
  reviewedBy?: string,
  reviewedAt?: timestamp,
  createdAt: timestamp,
  error?: string
}
```

#### 3.3 Create Moderation Stats Collection
```javascript
// Create new collection: moderation_stats (for analytics)
{
  date: string, // YYYY-MM-DD
  totalMessages: number,
  autoApproved: number,
  ruleBlocked: number,
  aiAnalyzed: number,
  aiBlocked: number,
  manualReview: number,
  falsePositives: number,
  falseNegatives: number,
  averageProcessingTime: number,
  aiCost: number
}
```

### 4. Firestore Security Rules Updates
```javascript
// Add to firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Existing rules...
    
    // Moderation queue - admin only
    match /moderation_queue/{document} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Moderation stats - admin only
    match /moderation_stats/{document} {
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow write: if false; // Only cloud functions can write
    }
    
    // Messages with moderation status
    match /group_messages/{messageId} {
      allow read: if request.auth != null && (
        // Show approved messages to all group members
        resource.data.moderation.status == 'approved' ||
        // Show own messages regardless of status
        resource.data.senderCpId == request.auth.uid ||
        // Show all to admins
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
      );
    }
  }
}
```

### 5. Frontend Integration Tasks

#### 5.1 Update Message Component
- [ ] **Add Moderation Status Display**
  ```typescript
  // Add to message component
  interface MessageModerationStatus {
    status: 'pending' | 'approved' | 'blocked' | 'manual_review';
    reason?: string;
    violationType?: string;
  }
  ```

- [ ] **Handle Blocked Messages UI**
  ```typescript
  // Show different UI for blocked messages
  if (message.moderation?.status === 'blocked') {
    return <BlockedMessageComponent reason={message.moderation.reason} />;
  }
  ```

#### 5.2 Admin Dashboard Updates
- [ ] **Create Moderation Queue Component**
  - Display pending manual reviews
  - Allow approve/block decisions
  - Show AI analysis results

- [ ] **Add Moderation Analytics**
  - Daily/weekly moderation stats
  - AI performance metrics
  - Cost tracking dashboard

#### 5.3 Real-time Updates
- [ ] **Set up Firestore Listeners**
  ```typescript
  // Listen for moderation status changes
  useEffect(() => {
    const unsubscribe = onSnapshot(
      doc(db, 'group_messages', messageId),
      (doc) => {
        const message = doc.data();
        if (message.moderation?.status !== 'pending') {
          updateMessageStatus(message);
        }
      }
    );
    return unsubscribe;
  }, [messageId]);
  ```

### 6. Testing & Validation

#### 6.1 Create Test Data
- [ ] **Arabic Test Messages**
  ```javascript
  const testMessages = [
    'تابعوني على انستقرام @test_user',
    'حسابي في الفيس اسمه أحمد',
    'مرحبا يا جماعة كيف الحال؟', // Clean message
    'بدي صور خاصة واتساب',
    'ديوث يبحث عن تجربة',
    // Add more test cases...
  ];
  ```

- [ ] **Unit Tests for Pattern Detection**
  ```javascript
  const { performQuickCheck } = require('./messageModeration');
  
  describe('Arabic Pattern Detection', () => {
    test('should detect social media sharing', () => {
      const result = performQuickCheck('تابعوني على انستقرام');
      expect(result.definiteViolation).toBe(true);
      expect(result.type).toBe('social_media_sharing');
    });
  });
  ```

#### 6.2 Integration Testing
- [ ] **Test Cloud Function Deployment**
- [ ] **Test AI API Integration**
- [ ] **Test Database Updates**
- [ ] **Test Error Handling**

### 7. Monitoring & Analytics Setup

#### 7.1 Cloud Function Monitoring
- [ ] **Set up Cloud Logging Filters**
  ```
  resource.type="cloud_function"
  resource.labels.function_name="moderateMessage"
  ```

- [ ] **Create Custom Metrics**
  - Processing time distribution
  - AI vs rule-based detection rates
  - Error rates by type

#### 7.2 Cost Monitoring
- [ ] **Track Vertex AI Usage**
- [ ] **Set up Billing Alerts**
- [ ] **Monitor Function Execution Costs**

### 8. Performance Optimization

#### 8.1 Caching Strategy
- [ ] **Cache Arabic Patterns**
  ```javascript
  // Cache compiled regex patterns
  const compiledPatterns = {
    socialMedia: ARABIC_PATTERNS.socialMedia.followPhrases.map(p => new RegExp(p, 'i')),
    // ... other patterns
  };
  ```

- [ ] **Cache AI Results** (for identical messages)
  ```javascript
  const messageHash = crypto.createHash('md5').update(text).digest('hex');
  // Check cache before AI call
  ```

#### 8.2 Function Optimization
- [ ] **Optimize Cold Starts**
  - Move initialization outside handler
  - Use connection pooling

- [ ] **Batch Processing** (for high volume)
  - Process multiple messages in single function call
  - Use Pub/Sub for queuing

### 9. Security & Compliance

#### 9.1 Data Privacy
- [ ] **PII Detection & Masking**
  - Detect phone numbers, emails
  - Mask sensitive data in logs

- [ ] **Data Retention Policies**
  - Auto-delete moderation logs after X days
  - Anonymize stored content

#### 9.2 Audit Trail
- [ ] **Log All Moderation Decisions**
- [ ] **Track Admin Overrides**
- [ ] **Monitor False Positive/Negative Rates**

### 10. Deployment Checklist

#### 10.1 Pre-deployment
- [ ] Test all functions locally
- [ ] Validate environment variables
- [ ] Check service account permissions
- [ ] Review security rules

#### 10.2 Deployment
- [ ] Deploy to staging environment first
- [ ] Run integration tests
- [ ] Deploy to production
- [ ] Monitor initial performance

#### 10.3 Post-deployment
- [ ] Verify function is triggering correctly
- [ ] Check AI API calls are working
- [ ] Monitor error rates
- [ ] Validate moderation accuracy

### 11. Configuration Files Needed

#### 11.1 Firebase Configuration
```json
// firebase.json
{
  "functions": {
    "source": "functions",
    "runtime": "nodejs18",
    "predeploy": ["npm --prefix \"$RESOURCE_DIR\" run build"],
    "environmentVariables": {
      "GCLOUD_PROJECT": "your-project-id"
    }
  }
}
```

#### 11.2 Package.json Updates
```json
// functions/package.json
{
  "dependencies": {
    "firebase-functions": "^4.5.0",
    "firebase-admin": "^11.11.0",
    "@google-cloud/vertexai": "^0.4.0"
  }
}
```

### 12. Documentation Tasks
- [ ] **API Documentation** for moderation endpoints
- [ ] **Admin User Guide** for moderation dashboard
- [ ] **Developer Guide** for extending patterns
- [ ] **Troubleshooting Guide** for common issues

### 13. Training & Fine-tuning
- [ ] **Collect False Positives/Negatives**
- [ ] **Update Arabic Patterns** based on real usage
- [ ] **Fine-tune AI Prompts** for better accuracy
- [ ] **A/B Test** different moderation strategies

---

## 🚨 Critical Dependencies

### External Services
1. **Google Cloud Vertex AI** - Core AI functionality
2. **Firebase Functions** - Cloud function hosting
3. **Firestore** - Database storage
4. **Cloud Logging** - Monitoring and debugging

### Internal Dependencies
1. **User Authentication System** - For sender identification
2. **Group Management System** - For group context
3. **Admin Panel** - For manual moderation
4. **Notification System** - For user alerts

---

## 📊 Success Metrics

### Performance Targets
- **Processing Time**: <2 seconds for 95% of messages
- **Accuracy**: >90% correct moderation decisions
- **False Positive Rate**: <5%
- **Uptime**: >99.9%

### Cost Targets
- **AI Cost**: <$0.001 per message analyzed
- **Function Cost**: <$0.0001 per message processed
- **Total Daily Cost**: <$10 for 10,000 messages

---

## 🔧 Troubleshooting Common Issues

### Function Not Triggering
- Check Firestore trigger path matches collection structure
- Verify function deployment status
- Check Cloud Function logs

### AI API Errors
- Verify Vertex AI API is enabled
- Check service account permissions
- Monitor API quotas and limits

### High Processing Times
- Check for cold starts
- Monitor AI API response times
- Optimize pattern matching algorithms

### False Positives
- Review and update Arabic patterns
- Adjust AI prompt for better context understanding
- Implement feedback loop for continuous improvement
