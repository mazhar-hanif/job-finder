import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finder_job/app.dart';
import 'package:finder_job/core/widgets/app_search_bar.dart';
import 'package:finder_job/core/widgets/user_avatar.dart';
import 'package:finder_job/core/router/app_router.dart';
import 'package:finder_job/data/models/application.dart';
import 'package:finder_job/data/repositories/job_repository.dart';
import 'package:finder_job/features/apply/apply_screen.dart';
import 'package:finder_job/features/applications/applications_screen.dart';
import 'package:finder_job/features/company/company_profile_screen.dart';
import 'package:finder_job/features/home/widgets/job_card.dart';
import 'package:finder_job/features/home/widgets/job_post_card.dart';
import 'package:finder_job/features/messages/message_thread_screen.dart';
import 'package:finder_job/features/notifications/notifications_screen.dart';
import 'package:finder_job/features/home/home_screen.dart';
import 'package:finder_job/features/onboarding/onboarding_screen.dart';
import 'package:finder_job/features/search/search_screen.dart';
import 'package:finder_job/providers/job_providers.dart';

void main() {
  testWidgets('JobFinder flows work at supported phone sizes', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      appRouter.go('/onboarding');
    });

    for (final size in const [Size(360, 640), Size(430, 932)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      appRouter.go('/onboarding');
      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey(size.width),
          overrides: [
            jobRepositoryProvider.overrideWithValue(
              const _EmptyApplicationsRepository(),
            ),
          ],
          child: const JobFinderApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(OnboardingScreen),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      if (size.height < 700) {
        await tester.drag(
          find.descendant(
            of: find.byType(OnboardingScreen),
            matching: find.byType(SingleChildScrollView),
          ),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Get Started'));
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Try job seeker demo'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      await tester.ensureVisible(find.text('Already have an account? Sign in'));
      await tester.tap(find.text('Already have an account? Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      appRouter.go('/home');
      await tester.pumpAndSettle();
      expect(find.text('Recommended for you'), findsOneWidget);
      expect(find.text('Senior Frontend Developer'), findsWidgets);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Profile'), findsNothing);
      await tester.tap(find.byType(UserAvatar).first);
      await tester.pumpAndSettle();
      expect(find.text('My profile'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Messages'));
      await tester.pumpAndSettle();
      expect(find.text('Messages'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notifications').last);
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      final homeList = find
          .descendant(
            of: find.byType(HomeScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Latest job posts'),
        250,
        scrollable: homeList,
      );
      expect(find.text('Latest job posts'), findsOneWidget);
      expect(find.byType(JobPostCard), findsWidgets);
      await tester.drag(homeList, const Offset(0, 1000));
      await tester.pumpAndSettle();
      _expectNoLayoutException(tester);

      await tester.ensureVisible(find.byType(JobCard).first);
      await tester.tap(find.bySemanticsLabel('Flip job card').first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('About this role'), findsOneWidget);
      _expectNoLayoutException(tester);
      await tester.tap(find.byTooltip('Flip job card back').first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.bySemanticsLabel('Flip job card'), findsWidgets);

      await tester.ensureVisible(find.text('Senior Frontend Developer').first);
      await tester.tap(find.text('Senior Frontend Developer').first);
      await tester.pumpAndSettle();
      expect(find.text('Senior Frontend Developer'), findsOneWidget);
      expect(find.textContaining(r'$120,000'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Requirements'), findsOneWidget);
      expect(find.text('Benefits'), findsOneWidget);
      expect(find.text('Company'), findsOneWidget);
      _expectNoLayoutException(tester);

      await tester.tap(find.text('Requirements').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('5+ years'), findsOneWidget);
      await tester.tap(find.text('Benefits').first);
      await tester.pumpAndSettle();
      expect(find.text('Flexible remote-first culture'), findsOneWidget);
      await tester.tap(find.text('Apply Now'));
      await tester.pumpAndSettle();
      expect(find.text('Apply for Job'), findsOneWidget);
      _expectNoLayoutException(tester);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Unsave job'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Back').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saved').last);
      await tester.pumpAndSettle();
      expect(find.text('All (3)'), findsOneWidget);
      _expectNoLayoutException(tester);

      appRouter.go('/home');
      await tester.pumpAndSettle();
      expect(appRouter.routeInformationProvider.value.uri.path, '/home');
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.drag(
        find
            .descendant(
              of: find.byType(HomeScreen),
              matching: find.byType(Scrollable),
            )
            .first,
        const Offset(0, 1000),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppSearchBar), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AppSearchBar),
          matching: find.byType(TextField),
        ),
      );
      await tester.pumpAndSettle();
      final searchField = find.descendant(
        of: find.byType(AppSearchBar),
        matching: find.byType(TextField),
      );
      final searchList = find
          .descendant(
            of: find.byType(SearchScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.enterText(searchField, 'designer');
      await tester.pumpAndSettle();
      expect(find.text('2 jobs found'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Product Designer'),
        250,
        scrollable: searchList,
      );
      expect(find.text('Product Designer'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('UX Designer'),
        250,
        scrollable: searchList,
      );
      expect(find.text('UX Designer'), findsOneWidget);
      _expectNoLayoutException(tester);
      await tester.drag(searchList, const Offset(0, 1000));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Popular Searches'), findsOneWidget);
      expect(find.text('Software Engineer'), findsOneWidget);
      expect(find.text('Product Designer'), findsOneWidget);
      expect(find.text('Data Scientist'), findsOneWidget);
      await tester.drag(searchList, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Software Engineer'));
      await tester.pumpAndSettle();
      expect(find.text('1 jobs found'), findsOneWidget);
      expect(find.text('Software Engineer'), findsWidgets);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Worldwide'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Remote');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('2 jobs found'), findsOneWidget);
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();
      expect(find.text('Popular Searches'), findsOneWidget);

      appRouter.go('/apply/j2');
      await tester.pumpAndSettle();
      final applyScreen = find.byType(ApplyScreen);
      final applyList = find
          .descendant(of: applyScreen, matching: find.byType(Scrollable))
          .first;
      final coverLetter = find.descendant(
        of: applyScreen,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText?.startsWith('Share a few words') ==
                  true,
        ),
      );
      await tester.scrollUntilVisible(coverLetter, 250, scrollable: applyList);
      await tester.enterText(coverLetter, 'I am a great fit.');
      await tester.pumpAndSettle();
      expect(find.text('17/500'), findsOneWidget);
      _expectNoLayoutException(tester);
      await tester.tap(find.text('Submit Application'));
      await tester.pumpAndSettle();
      expect(find.text('Demo application recorded'), findsOneWidget);
      await tester.tap(find.text('Track application'));
      await tester.pumpAndSettle();
      expect(find.text('All (1)'), findsOneWidget);
      final applicationsList = find
          .descendant(
            of: find.byType(ApplicationsScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Product Designer'),
        250,
        scrollable: applicationsList,
      );
      expect(find.text('Product Designer'), findsOneWidget);
      expect(find.text('Applied · Just now'), findsOneWidget);
      expect(find.text('Application activity'), findsOneWidget);
      expect(find.text('Interviews'), findsOneWidget);
      expect(find.text('Offer'), findsOneWidget);

      appRouter.go('/apply/no-such-job');
      await tester.pumpAndSettle();
      expect(find.text('Job unavailable'), findsOneWidget);
      _expectNoLayoutException(tester);

      appRouter.go('/company/c1');
      await tester.pumpAndSettle();
      final companyScreen = find.byType(CompanyProfileScreen);
      final companyList = find
          .descendant(of: companyScreen, matching: find.byType(Scrollable))
          .first;
      await tester.drag(companyList, const Offset(0, -1000));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Follow'));
      await tester.pumpAndSettle();
      expect(find.text('Following'), findsOneWidget);
      _expectNoLayoutException(tester);

      appRouter.go('/messages');
      await tester.pumpAndSettle();
      expect(find.text('Sarah Williams'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'microsoft');
      await tester.pumpAndSettle();
      expect(find.text('Michael Chen'), findsOneWidget);
      expect(find.text('Sarah Williams'), findsNothing);
      await tester.tap(find.byTooltip('Clear message search'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recruiters'));
      await tester.pumpAndSettle();
      expect(find.text('Michael Chen'), findsOneWidget);
      expect(find.text('Emma Davis'), findsNothing);
      await tester.ensureVisible(find.text('Unread (2)'));
      await tester.tap(find.text('Unread (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Michael Chen'), findsOneWidget);
      expect(find.text('Olivia Martinez'), findsNothing);
      await tester.tap(find.text('Companies'));
      await tester.pumpAndSettle();
      expect(find.text('Emma Davis'), findsOneWidget);
      expect(find.text('Sarah Williams'), findsNothing);
      await tester.ensureVisible(find.text('All'));
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sarah Williams'));
      await tester.pumpAndSettle();
      expect(find.byType(MessageThreadScreen), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'Thanks, I will reply soon.',
      );
      await tester.tap(find.byTooltip('Send reply'));
      await tester.pumpAndSettle();
      expect(find.text('Thanks, I will reply soon.'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pumpAndSettle();
      _expectNoLayoutException(tester);
    }
  });
}

void _expectNoLayoutException(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

class _EmptyApplicationsRepository extends MockJobRepository {
  const _EmptyApplicationsRepository();

  @override
  List<ApplicationModel> getApplications() => const [];
}
