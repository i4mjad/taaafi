import { collection, addDoc, getDocs, query } from 'firebase/firestore';
import { db } from '@/lib/firebase';

const defaultCategories = [
  {
    name: 'Discussion',
    nameAr: 'نقاش',
    iconName: 'MessageSquare',
    colorHex: '#10B981',
    isActive: true,
    sortOrder: 1,
  },
  {
    name: 'Question',
    nameAr: 'سؤال',
    iconName: 'HelpCircle',
    colorHex: '#3B82F6',
    isActive: true,
    sortOrder: 2,
  },
  {
    name: 'Support',
    nameAr: 'دعم',
    iconName: 'Users',
    colorHex: '#F59E0B',
    isActive: true,
    sortOrder: 3,
  },
  {
    name: 'Announcement',
    nameAr: 'إعلان',
    iconName: 'Megaphone',
    colorHex: '#EF4444',
    isActive: true,
    sortOrder: 4,
  },
  {
    name: 'General',
    nameAr: 'عام',
    iconName: 'Hash',
    colorHex: '#8B5CF6',
    isActive: true,
    sortOrder: 5,
  },
];

export async function seedPostCategories() {
  try {
    // Check if collection already has data
    const snapshot = await getDocs(query(collection(db, 'postCategories')));
    
    if (snapshot.empty) {
      console.log('Seeding postCategories collection...');
      
      // Add default categories
      for (const category of defaultCategories) {
        await addDoc(collection(db, 'postCategories'), category);
      }
      
      console.log('Successfully seeded postCategories collection');
    } else {
      console.log('postCategories collection already has data');
    }
  } catch (error) {
    console.error('Error seeding postCategories:', error);
  }
}

// Call this function once to initialize the collection
// You can run this manually or call it from a setup script
export default seedPostCategories; 