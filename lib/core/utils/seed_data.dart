import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dev_quotes/core/utils/logger.dart';

/// Run this once to populate your Firestore database with sample quotes
Future<void> seedQuotes() async {
  final firestore = FirebaseFirestore.instance;

  final quotes = [
    {
      'quoteText':
          'Code is like humor. When you have to explain it, it\'s bad.',
      'author': 'Cory House',
      'category': 'Wisdom',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'First, solve the problem. Then, write the code.',
      'author': 'John Johnson',
      'category': 'Productivity',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'Any fool can write code that a computer can understand. Good programmers write code that humans can understand.',
      'author': 'Martin Fowler',
      'category': 'Wisdom',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'The best error message is the one that never shows up.',
      'author': 'Thomas Fuchs',
      'category': 'Productivity',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'Walking on water and developing software from a specification are easy if both are frozen.',
      'author': 'Edward V. Berard',
      'category': 'Mindset',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'It\'s not a bug - it\'s an undocumented feature.',
      'author': 'Anonymous',
      'category': 'Productivity',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'Programming isn\'t about what you know; it\'s about what you can figure out.',
      'author': 'Chris Pine',
      'category': 'Growth',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'The only way to learn a new programming language is by writing programs in it.',
      'author': 'Dennis Ritchie',
      'category': 'Growth',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'Simplicity is the soul of efficiency.',
      'author': 'Austin Freeman',
      'category': 'Wisdom',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'Make it work, make it right, make it fast.',
      'author': 'Kent Beck',
      'category': 'Mindset',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'Clean code always looks like it was written by someone who cares.',
      'author': 'Robert C. Martin',
      'category': 'Code Quality',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'Debugging is twice as hard as writing the code in the first place.',
      'author': 'Brian Kernighan',
      'category': 'Wisdom',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'The most disastrous thing that you can ever learn is your first programming language.',
      'author': 'Alan Kay',
      'category': 'Growth',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'Deleted code is debugged code.',
      'author': 'Jeff Sickel',
      'category': 'Wisdom',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'There are two ways to write error-free programs; only the third one works.',
      'author': 'Alan J. Perlis',
      'category': 'Mindset',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'Talk is cheap. Show me the code.',
      'author': 'Linus Torvalds',
      'category': 'Mindset',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'Experience is the name everyone gives to their mistakes.',
      'author': 'Oscar Wilde',
      'category': 'Growth',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'In order to be irreplaceable, one must always be different.',
      'author': 'Coco Chanel',
      'category': 'Inspiration',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'Java is to JavaScript what car is to carpet.',
      'author': 'Chris Heilmann',
      'category': 'Success',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'Software is a great combination between artistry and engineering.',
      'author': 'Bill Gates',
      'category': 'Mindset',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
  ];

  final batch = firestore.batch();

  for (var quote in quotes) {
    final docRef = firestore.collection('quotes').doc();
    batch.set(docRef, quote);
  }

  await batch.commit();
  Logger.d('✅ Successfully seeded ${quotes.length} quotes to Firestore!');
}

/// Seed categories
Future<void> seedCategories() async {
  final firestore = FirebaseFirestore.instance;

  // Clear existing categories first to ensure we have the new ones
  final existing = await firestore.collection('categories').get();
  if (existing.docs.isNotEmpty) {
    final deleteBatch = firestore.batch();
    for (var doc in existing.docs) {
      deleteBatch.delete(doc.reference);
    }
    await deleteBatch.commit();
  }

  final categories = [
    {'name': 'Wisdom', 'icon': 'psychology', 'color': '8B5CF6'},
    {'name': 'Success', 'icon': 'trending_up', 'color': 'EF4444'},
    {'name': 'Life', 'icon': 'favorite', 'color': '3B82F6'},
    {'name': 'Mindset', 'icon': 'lightbulb', 'color': 'F59E0B'},
    {'name': 'Happiness', 'icon': 'sentiment_very_satisfied', 'color': 'F7DF1E'},
    {'name': 'Growth', 'icon': 'auto_graph', 'color': '10B981'},
    {'name': 'Inspiration', 'icon': 'auto_awesome', 'color': 'EC4899'},
    {'name': 'Productivity', 'icon': 'shutter_speed', 'color': 'FBBF24'},
  ];

  final batch = firestore.batch();

  for (var category in categories) {
    final docRef = firestore.collection('categories').doc();
    batch.set(docRef, category);
  }

  await batch.commit();
  Logger.d('✅ Successfully seeded ${categories.length} categories to Firestore!');
}
