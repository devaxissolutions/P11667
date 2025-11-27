import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for selected topics
class SelectedTopicsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void toggleTopic(String topic) {
    if (state.contains(topic)) {
      state = state.where((t) => t != topic).toList();
    } else {
      state = [...state, topic];
    }
  }

  void clear() {
    state = [];
  }
}

final selectedTopicsProvider =
    NotifierProvider<SelectedTopicsNotifier, List<String>>(() {
  return SelectedTopicsNotifier();
});

// Provider for current page index
class CurrentPageNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setPage(int page) {
    state = page;
  }
}

final currentPageProvider = NotifierProvider<CurrentPageNotifier, int>(() {
  return CurrentPageNotifier();
});

// Provider for onboarding completion status
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') ?? false;
});

// Controller for onboarding actions
class OnboardingController {
  final Ref ref;

  OnboardingController(this.ref);

  void nextPage() {
    final currentPage = ref.read(currentPageProvider);
    if (currentPage < 4) {
      ref.read(currentPageProvider.notifier).setPage(currentPage + 1);
    }
  }

  void previousPage() {
    final currentPage = ref.read(currentPageProvider);
    if (currentPage > 0) {
      ref.read(currentPageProvider.notifier).setPage(currentPage - 1);
    }
  }

  void goToPage(int page) {
    if (page >= 0 && page <= 4) {
      ref.read(currentPageProvider.notifier).setPage(page);
    }
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    // Save selected topics if any
    final selectedTopics = ref.read(selectedTopicsProvider);
    if (selectedTopics.isNotEmpty) {
      await prefs.setStringList('selected_topics', selectedTopics);
    }
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', false);
    await prefs.remove('selected_topics');
    ref.read(currentPageProvider.notifier).setPage(0);
    ref.read(selectedTopicsProvider.notifier).clear();
  }
}

// Provider for the controller
final onboardingControllerProvider = Provider<OnboardingController>((ref) {
  return OnboardingController(ref);
});

