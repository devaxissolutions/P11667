/**
 * Firestore Security Rules Test Suite
 * 
 * To run these tests:
 * 1. npm install --save-dev @firebase/rules-unit-testing firebase-admin
 * 2. firebase emulators:start --only firestore
 * 3. npm test
 */

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc } = require('firebase/firestore');
const fs = require('fs');

describe('Firestore Security Rules', () => {
  let testEnv;

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'devquotes-310a9-test',
      firestore: {
        rules: fs.readFileSync('../firestore.rules', 'utf8'),
      },
    });
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  describe('Users Collection', () => {
    it('allows users to read their own profile', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertSucceeds(
        getDoc(doc(alice.firestore(), 'users', 'alice'))
      );
    });

    it('allows authenticated users to read other user profiles', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertSucceeds(
        getDoc(doc(alice.firestore(), 'users', 'bob'))
      );
    });

    it('denies unauthenticated users from reading profiles', async () => {
      const unauthenticated = testEnv.unauthenticatedContext();
      await assertFails(
        getDoc(doc(unauthenticated.firestore(), 'users', 'alice'))
      );
    });

    it('allows users to create their own profile', async () => {
      const alice = testEnv.authenticatedContext('alice', { email: 'alice@example.com' });
      await assertSucceeds(
        setDoc(doc(alice.firestore(), 'users', 'alice'), {
          email: 'alice@example.com',
          username: 'Alice',
        })
      );
    });

    it('denies users from creating profiles for others', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertFails(
        setDoc(doc(alice.firestore(), 'users', 'bob'), {
          email: 'bob@example.com',
          username: 'Bob',
        })
      );
    });

    it('allows users to update their own profile', async () => {
      const alice = testEnv.authenticatedContext('alice', { email: 'alice@example.com' });
      await setDoc(doc(alice.firestore(), 'users', 'alice'), {
        email: 'alice@example.com',
        username: 'Alice',
      });
      
      await assertSucceeds(
        updateDoc(doc(alice.firestore(), 'users', 'alice'), {
          username: 'Alice Updated',
        })
      );
    });

    it('denies users from updating other profiles', async () => {
      const alice = testEnv.authenticatedContext('alice');
      const bob = testEnv.authenticatedContext('bob');
      
      await setDoc(doc(bob.firestore(), 'users', 'bob'), {
        email: 'bob@example.com',
        username: 'Bob',
      });
      
      await assertFails(
        updateDoc(doc(alice.firestore(), 'users', 'bob'), {
          username: 'Hacked',
        })
      );
    });
  });

  describe('Quotes Collection', () => {
    beforeEach(async () => {
      // Seed test data
      const admin = testEnv.authenticatedContext('admin');
      
      // Public quote
      await setDoc(doc(admin.firestore(), 'quotes', 'public1'), {
        quoteText: 'Public quote',
        author: 'Author',
        category: 'Wisdom',
        userId: 'alice',
        timestamp: new Date(),
        isPublic: true,
        isDefault: false,
      });
      
      // Private quote
      await setDoc(doc(admin.firestore(), 'quotes', 'private1'), {
        quoteText: 'Private quote',
        author: 'Author',
        category: 'Wisdom',
        userId: 'alice',
        timestamp: new Date(),
        isPublic: false,
        isDefault: false,
      });
      
      // Default quote
      await setDoc(doc(admin.firestore(), 'quotes', 'default1'), {
        quoteText: 'Default quote',
        author: 'System',
        category: 'Wisdom',
        userId: 'system',
        timestamp: new Date(),
        isPublic: true,
        isDefault: true,
      });
    });

    it('allows reading public quotes', async () => {
      const bob = testEnv.authenticatedContext('bob');
      await assertSucceeds(
        getDoc(doc(bob.firestore(), 'quotes', 'public1'))
      );
    });

    it('allows reading default quotes', async () => {
      const bob = testEnv.authenticatedContext('bob');
      await assertSucceeds(
        getDoc(doc(bob.firestore(), 'quotes', 'default1'))
      );
    });

    it('allows owner to read their private quotes', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertSucceeds(
        getDoc(doc(alice.firestore(), 'quotes', 'private1'))
      );
    });

    it('denies non-owners from reading private quotes', async () => {
      const bob = testEnv.authenticatedContext('bob');
      await assertFails(
        getDoc(doc(bob.firestore(), 'quotes', 'private1'))
      );
    });

    it('allows authenticated users to create quotes', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertSucceeds(
        setDoc(doc(alice.firestore(), 'quotes', 'newquote'), {
          quoteText: 'New quote',
          author: 'Alice',
          category: 'Wisdom',
          userId: 'alice',
          timestamp: new Date(),
          isPublic: true,
          isDefault: false,
        })
      );
    });

    it('denies creating quotes with missing required fields', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertFails(
        setDoc(doc(alice.firestore(), 'quotes', 'badquote'), {
          quoteText: 'Missing fields',
          // Missing author, category, userId, timestamp
        })
      );
    });

    it('denies creating quotes that exceed character limit', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertFails(
        setDoc(doc(alice.firestore(), 'quotes', 'longquote'), {
          quoteText: 'a'.repeat(1000),
          author: 'Alice',
          category: 'Wisdom',
          userId: 'alice',
          timestamp: new Date(),
          isPublic: true,
          isDefault: false,
        })
      );
    });

    it('allows owner to update their quote', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertSucceeds(
        updateDoc(doc(alice.firestore(), 'quotes', 'public1'), {
          quoteText: 'Updated quote',
        })
      );
    });

    it('denies non-owner from updating quote', async () => {
      const bob = testEnv.authenticatedContext('bob');
      await assertFails(
        updateDoc(doc(bob.firestore(), 'quotes', 'public1'), {
          quoteText: 'Hacked!',
        })
      );
    });

    it('denies changing quote ownership', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertFails(
        updateDoc(doc(alice.firestore(), 'quotes', 'public1'), {
          userId: 'hacker',
        })
      );
    });

    it('allows owner to delete their quote', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertSucceeds(
        deleteDoc(doc(alice.firestore(), 'quotes', 'public1'))
      );
    });

    it('denies non-owner from deleting quote', async () => {
      const bob = testEnv.authenticatedContext('bob');
      await assertFails(
        deleteDoc(doc(bob.firestore(), 'quotes', 'public1'))
      );
    });
  });

  describe('Favorites Collection', () => {
    it('allows users to read their own favorites', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertSucceeds(
        getDoc(doc(alice.firestore(), 'favorites/alice/items/quote1'))
      );
    });

    it('denies users from reading others favorites', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertFails(
        getDoc(doc(alice.firestore(), 'favorites/bob/items/quote1'))
      );
    });

    it('allows users to add to their own favorites', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertSucceeds(
        setDoc(doc(alice.firestore(), 'favorites/alice/items/quote1'), {
          addedAt: new Date(),
        })
      );
    });

    it('denies users from adding to others favorites', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertFails(
        setDoc(doc(alice.firestore(), 'favorites/bob/items/quote1'), {
          addedAt: new Date(),
        })
      );
    });
  });

  describe('Categories Collection', () => {
    it('allows anyone to read categories', async () => {
      const unauthenticated = testEnv.unauthenticatedContext();
      await assertSucceeds(
        getDoc(doc(unauthenticated.firestore(), 'categories', 'wisdom'))
      );
    });

    it('allows authenticated users to write categories', async () => {
      const alice = testEnv.authenticatedContext('alice');
      await assertSucceeds(
        setDoc(doc(alice.firestore(), 'categories', 'newcat'), {
          name: 'New Category',
        })
      );
    });

    it('denies unauthenticated users from writing categories', async () => {
      const unauthenticated = testEnv.unauthenticatedContext();
      await assertFails(
        setDoc(doc(unauthenticated.firestore(), 'categories', 'newcat'), {
          name: 'New Category',
        })
      );
    });
  });
});
