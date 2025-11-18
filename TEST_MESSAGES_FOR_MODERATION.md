# Test Messages for Arabic Content Moderation System

## 🧪 **Comprehensive Test Suite**

These messages cover all moderation categories with various detection levels (rule-based vs AI-required).

---

## 📱 **SOCIAL MEDIA SHARING TESTS**

### **✅ Should be BLOCKED (Rule-Based Detection)**

#### **Direct Arabic Sharing Phrases:**
1. **"تابعوني على انستقرام @sara_beauty"**
   - *Expected: BLOCKED immediately*
   - *Reason: Direct sharing phrase + username*

2. **"حسابي في الفيس اسمه أحمد محمد من الرياض"**
   - *Expected: BLOCKED immediately*
   - *Reason: "حسابي في الفيس" phrase*

3. **"ضيفوني سناب: ahmad_snap2024"**
   - *Expected: BLOCKED immediately*
   - *Reason: "ضيفوني سناب" + username*

4. **"لقوني على واتساب عندي صور حلوة"**
   - *Expected: BLOCKED immediately*
   - *Reason: "لقوني على واتساب"*

5. **"شوفوا صوري على تيك توك @dancer_girl"**
   - *Expected: BLOCKED immediately*
   - *Reason: "شوفوا صوري على" + platform + username*

#### **Mixed Arabic/English:**
6. **"follow me on انستا: my.account.2024"**
   - *Expected: BLOCKED immediately*
   - *Reason: "follow me on" + Arabic platform*

7. **"add me on فيسبوك اسمي Sara Ahmed"**
   - *Expected: BLOCKED immediately*
   - *Reason: "add me on" + Arabic platform*

### **🤖 Should Need AI Analysis**

#### **Indirect References:**
8. **"ممكن نتواصل بطريقة أخرى؟ عندي حساب على المنصة الزرقاء"**
   - *Expected: AI analysis (indirect Facebook reference)*
   - *Likely: BLOCKED by AI*

9. **"بحثوا عني في التطبيق اللي فيه الصور المربعة"**
   - *Expected: AI analysis (indirect Instagram reference)*
   - *Likely: BLOCKED by AI*

10. **"عندي حساب خاص للتواصل، ابحثوا عن اسمي"**
    - *Expected: AI analysis (vague sharing attempt)*
    - *Likely: BLOCKED by AI*

### **✅ Should be APPROVED (Legitimate Mentions)**

11. **"شاهدت فيديو رائع على انستقرام عن الطبخ"**
    - *Expected: APPROVED*
    - *Reason: Just mentioning platform, not sharing*

12. **"الفيسبوك معطل عندي اليوم"**
    - *Expected: APPROVED*
    - *Reason: Technical complaint, not sharing*

---

## 🔞 **SEXUAL CONTENT TESTS**

### **✅ Should be BLOCKED (Rule-Based Detection)**

#### **Explicit Arabic Terms:**
13. **"مين يبي يشوف صور عري؟"**
    - *Expected: BLOCKED immediately*
    - *Reason: Contains "عري" (nudity)*

14. **"بدي أتكلم عن الجنس مع بنات"**
    - *Expected: BLOCKED immediately*
    - *Reason: Contains "الجنس" (sex)*

15. **"عندي مقاطع إباحي حلوة"**
    - *Expected: BLOCKED immediately*
    - *Reason: Contains "إباحي" (pornographic)*

#### **Suggestive Phrases:**
16. **"بدي صور خاصة من البنات"**
    - *Expected: BLOCKED immediately*
    - *Reason: "بدي صور" + "خاصة"*

17. **"عندك واتساب؟ بدي أبعتلك شي خاص"**
    - *Expected: BLOCKED immediately*
    - *Reason: "عندك واتساب" + suggestive context*

18. **"ممكن نتكلم خاص عن أشياء حساسة؟"**
    - *Expected: BLOCKED immediately*
    - *Reason: "نتكلم خاص" phrase*

### **🤖 Should Need AI Analysis**

#### **Context-Dependent:**
19. **"نقاش طبي عن التربية الجنسية للأطفال"**
    - *Expected: AI analysis*
    - *Likely: APPROVED (medical/educational context)*

20. **"كتاب علمي عن الصحة الجنسية"**
    - *Expected: AI analysis*
    - *Likely: APPROVED (educational context)*

21. **"بحث أكاديمي عن السلوك الجنسي"**
    - *Expected: AI analysis*
    - *Likely: APPROVED (academic context)*

---

## 🚫 **CUCKOLDRY CONTENT TESTS**

### **✅ Should be BLOCKED (Rule-Based Detection)**

#### **Highly Offensive Terms:**
22. **"مين عنده تجربة مع الديوث؟"**
    - *Expected: BLOCKED immediately*
    - *Reason: Contains "ديوث" (extremely offensive)*

23. **"أبحث عن قواد لزوجتي"**
    - *Expected: BLOCKED immediately*
    - *Reason: Contains "قواد" (pimp)*

24. **"زوجي يحب يشارك زوجته مع الآخرين"**
    - *Expected: BLOCKED immediately*
    - *Reason: "يشارك زوجته" phrase*

25. **"مين يبي تبادل زوجات؟"**
    - *Expected: BLOCKED immediately*
    - *Reason: "تبادل زوجات" phrase*

26. **"زوج يشاهد زوجته مع رجل آخر"**
    - *Expected: BLOCKED immediately*
    - *Reason: "زوج يشاهد" + context*

### **🤖 Should Need AI Analysis**

#### **Indirect References:**
27. **"زوجي مش طبيعي، بيحب يشوف حاجات غريبة"**
    - *Expected: AI analysis*
    - *Likely: BLOCKED by AI*

28. **"مناقشة عن الخيانة الزوجية في المجتمع"**
    - *Expected: AI analysis*
    - *Likely: APPROVED (societal discussion)*

---

## 🏳️‍🌈 **HOMOSEXUALITY CONTENT TESTS**

### **✅ Should be BLOCKED (Rule-Based Detection)**

#### **Derogatory Terms:**
29. **"أي شباب شاذين موجودين هنا؟"**
    - *Expected: BLOCKED immediately*
    - *Reason: Contains "شاذين" (derogatory)*

30. **"مين يعرف لوطي في المنطقة؟"**
    - *Expected: BLOCKED immediately*
    - *Reason: Contains "لوطي" (very offensive)*

31. **"بحب الأولاد الحلوين الخنيثين"**
    - *Expected: BLOCKED immediately*
    - *Reason: Contains "خنيثين" (derogatory)*

#### **Seeking Content:**
32. **"بحث عن أصدقاء من نفس الميول الجنسية"**
    - *Expected: BLOCKED immediately*
    - *Reason: "من نفس الميول" seeking phrase*

33. **"أي بنات تحب بنات موجودة؟"**
    - *Expected: BLOCKED immediately*
    - *Reason: "بنات تحب بنات" pattern*

34. **"رجال يحبون رجال للصداقة الخاصة"**
    - *Expected: BLOCKED immediately*
    - *Reason: "رجال مع رجال" + suggestive*

### **🤖 Should Need AI Analysis**

#### **Context-Dependent:**
35. **"مناقشة حقوق المثليين في المجتمع"**
    - *Expected: AI analysis*
    - *Likely: APPROVED (rights discussion)*

36. **"دراسة علمية عن المثلية الجنسية"**
    - *Expected: AI analysis*
    - *Likely: APPROVED (academic research)*

37. **"الإسلام وموقفه من الشذوذ الجنسي"**
    - *Expected: AI analysis*
    - *Likely: APPROVED (religious discussion)*

---

## ✅ **CLEAN MESSAGES (Should Always Pass)**

### **Normal Conversations:**
38. **"مرحبا يا جماعة، كيف الحال اليوم؟"**
    - *Expected: APPROVED immediately*

39. **"شكراً لكم على المساعدة في الموضوع"**
    - *Expected: APPROVED immediately*

40. **"متى موعد الاجتماع القادم؟"**
    - *Expected: APPROVED immediately*

41. **"الطقس جميل اليوم، الحمد لله"**
    - *Expected: APPROVED immediately*

42. **"أحتاج مساعدة في حل هذه المسألة الرياضية"**
    - *Expected: APPROVED immediately*

---

## 🧪 **EDGE CASES & BYPASS ATTEMPTS**

### **Special Characters & Spacing:**
43. **"ت ا ب ع و ن ي  ع ل ى  ا ن س ت ق ر ا م"**
    - *Expected: AI analysis (spaced letters)*
    - *Likely: BLOCKED by AI*

44. **"تابع0وني على انست@قرام"**
    - *Expected: AI analysis (character substitution)*
    - *Likely: BLOCKED by AI*

45. **"تابعوني على IG: my_account"**
    - *Expected: AI analysis (abbreviation)*
    - *Likely: BLOCKED by AI*

### **Mixed Content:**
46. **"مرحبا يا جماعة، تابعوني على انستقرام @test"**
    - *Expected: BLOCKED immediately*
    - *Reason: Contains violation despite normal greeting*

47. **"شكراً على النصيحة، بالمناسبة عندي حساب فيس"**
    - *Expected: AI analysis*
    - *Likely: BLOCKED by AI*

---

## 🎯 **TESTING STRATEGY**

### **Phase 1: Rule-Based Testing**
Test messages **1-34, 38-42, 46** to verify:
- Immediate blocking of obvious violations
- Fast processing (<50ms)
- Correct violation type detection

### **Phase 2: AI Analysis Testing**
Test messages **8-10, 19-21, 27-28, 35-37, 43-45, 47** to verify:
- AI analysis triggers for uncertain content
- Contextual understanding works
- Processing time (1-3 seconds)

### **Phase 3: Edge Case Testing**
Test bypass attempts and mixed content to verify:
- System resilience
- No false negatives
- Proper fallback mechanisms

### **Phase 4: Performance Testing**
Send multiple messages simultaneously to verify:
- Concurrent processing
- No function timeouts
- Consistent behavior under load

---

## 📊 **Expected Results Summary**

| Category | Rule-Based Blocks | AI Analysis | Auto-Approved |
|----------|------------------|-------------|---------------|
| Social Media | 7 messages | 3 messages | 2 messages |
| Sexual Content | 6 messages | 3 messages | 0 messages |
| Cuckoldry | 5 messages | 2 messages | 0 messages |
| Homosexuality | 6 messages | 3 messages | 0 messages |
| Clean Messages | 0 messages | 0 messages | 5 messages |
| Edge Cases | 1 message | 4 messages | 0 messages |

**Total: 25 immediate blocks, 15 AI analyses, 7 approvals**

---

## 🔍 **How to Test**

1. **Send messages through your Flutter app** to the group chat
2. **Monitor Firebase Functions logs** to see processing:
   ```bash
   firebase functions:log --only moderateMessage
   ```
3. **Check Firestore** for moderation results in message documents
4. **Verify UI behavior** in Flutter app based on moderation status

The system should demonstrate **high accuracy** with **fast processing** for rule-based detection and **intelligent context understanding** for AI-analyzed content!
