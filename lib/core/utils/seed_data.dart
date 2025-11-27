import 'package:cloud_firestore/cloud_firestore.dart';

/// Run this once to populate your Firestore database with sample quotes
Future<void> seedQuotes() async {
  final firestore = FirebaseFirestore.instance;

  final quotes = [
    {
      'quoteText':
          'Code is like humor. When you have to explain it, it\'s bad.',
      'author': 'Cory House',
      'category': 'Code Quality',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'First, solve the problem. Then, write the code.',
      'author': 'John Johnson',
      'category': 'Problem Solving',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'Any fool can write code that a computer can understand. Good programmers write code that humans can understand.',
      'author': 'Martin Fowler',
      'category': 'Code Quality',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'The best error message is the one that never shows up.',
      'author': 'Thomas Fuchs',
      'category': 'UX',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'Walking on water and developing software from a specification are easy if both are frozen.',
      'author': 'Edward V. Berard',
      'category': 'Development',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'It\'s not a bug - it\'s an undocumented feature.',
      'author': 'Anonymous',
      'category': 'Debugging',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'Programming isn\'t about what you know; it\'s about what you can figure out.',
      'author': 'Chris Pine',
      'category': 'Learning',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'The only way to learn a new programming language is by writing programs in it.',
      'author': 'Dennis Ritchie',
      'category': 'Learning',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'Simplicity is the soul of efficiency.',
      'author': 'Austin Freeman',
      'category': 'Code Quality',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'Make it work, make it right, make it fast.',
      'author': 'Kent Beck',
      'category': 'Development',
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
      'category': 'Debugging',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'The most disastrous thing that you can ever learn is your first programming language.',
      'author': 'Alan Kay',
      'category': 'Learning',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'Deleted code is debugged code.',
      'author': 'Jeff Sickel',
      'category': 'Code Quality',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'There are two ways to write error-free programs; only the third one works.',
      'author': 'Alan J. Perlis',
      'category': 'Debugging',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'Talk is cheap. Show me the code.',
      'author': 'Linus Torvalds',
      'category': 'Development',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'Experience is the name everyone gives to their mistakes.',
      'author': 'Oscar Wilde',
      'category': 'Learning',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'In order to be irreplaceable, one must always be different.',
      'author': 'Coco Chanel',
      'category': 'Innovation',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText': 'Java is to JavaScript what car is to carpet.',
      'author': 'Chris Heilmann',
      'category': 'JavaScript',
      'userId': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'quoteText':
          'Software is a great combination between artistry and engineering.',
      'author': 'Bill Gates',
      'category': 'Development',
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
  print('✅ Successfully seeded ${quotes.length} quotes to Firestore!');
}

/// Seed categories
Future<void> seedCategories() async {
  final firestore = FirebaseFirestore.instance;

  final categories = [
    {'name': 'Code Quality', 'icon': 'code', 'color': '8B5CF6'},
    {'name': 'Debugging', 'icon': 'bug_report', 'color': 'EF4444'},
    {'name': 'Learning', 'icon': 'school', 'color': '3B82F6'},
    {'name': 'Development', 'icon': 'construction', 'color': 'F59E0B'},
    {'name': 'JavaScript', 'icon': 'javascript', 'color': 'F7DF1E'},
    {'name': 'Problem Solving', 'icon': 'psychology', 'color': '10B981'},
    {'name': 'UX', 'icon': 'design_services', 'color': 'EC4899'},
    {'name': 'Innovation', 'icon': 'lightbulb', 'color': 'FBBF24'},
  ];

  final batch = firestore.batch();

  for (var category in categories) {
    final docRef = firestore.collection('categories').doc();
    batch.set(docRef, category);
  }

  await batch.commit();
  print('✅ Successfully seeded ${categories.length} categories to Firestore!');
}
