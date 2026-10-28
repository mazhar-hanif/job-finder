import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finder_job/app.dart';
import 'package:finder_job/core/router/app_router.dart';
import 'package:finder_job/data/models/application.dart';
import 'package:finder_job/data/repositories/job_repository.dart';
import 'package:finder_job/features/profile/profile_screen.dart';
import 'package:finder_job/providers/job_providers.dart';

void main() {
  testWidgets('auth and employer routes explain Supabase setup', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      appRouter.go('/onboarding');
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    appRouter.go('/auth');
    await tester.pumpWidget(const ProviderScope(child: JobFinderApp()));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsOneWidget);
    expect(find.textContaining('Set SUPABASE_URL'), findsOneWidget);
    expect(find.text('Try job seeker demo'), findsOneWidget);
    expect(find.text('Try employer demo'), findsOneWidget);
    final authError = tester.takeException();
    if (authError is FlutterError) debugPrint(authError.toStringDeep());
    expect(authError, isNull);

    await tester.tap(find.text('Try employer demo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Employer demo'), findsOneWidget);
    expect(find.text('Add a job post'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Recommended for you'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile information and preferences can be edited', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      appRouter.go('/onboarding');
    });
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    appRouter.go('/profile');
    await tester.pumpWidget(const ProviderScope(child: JobFinderApp()));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byTooltip('Choose profile photo'), findsOneWidget);

    await tester.tap(find.text('Personal Information'));
    await tester.pumpAndSettle();
    final personalFields = find.byType(TextField);
    await tester.enterText(personalFields.at(0), 'Sam Applicant');
    await tester.enterText(personalFields.at(1), 'Flutter Developer');
    await tester.enterText(personalFields.at(2), '+1 555 0100');
    await tester.enterText(personalFields.at(3), 'Austin, TX');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Sam Applicant'), findsOneWidget);
    expect(find.text('Flutter Developer'), findsOneWidget);
    expect(find.text('Austin, TX'), findsOneWidget);

    await tester.ensureVisible(find.text('My Resume'));
    await tester.tap(find.text('My Resume'));
    await tester.pumpAndSettle();
    expect(find.text('My resumes'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Skills & Experience'));
    await tester.tap(find.text('Skills & Experience'));
    await tester.pumpAndSettle();
    final skillsFields = find.byType(TextField);
    await tester.enterText(skillsFields.at(0), 'Flutter, Dart');
    await tester.enterText(skillsFields.at(1), '3');
    await tester.enterText(
      skillsFields.at(2),
      'Built production mobile applications.',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('2 skills · 3 years experience'), findsOneWidget);
    expect(find.text('Built production mobile applications.'), findsOneWidget);

    await tester.ensureVisible(find.text('Career Preferences'));
    await tester.tap(find.text('Career Preferences'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full-time'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Full-time'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('local employer-to-applicant demo workflow is interactive', (
    tester,
  ) async {
    Finder field(String label) => find
        .ancestor(of: find.text(label), matching: find.byType(TextFormField))
        .first;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      appRouter.go('/onboarding');
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    appRouter.go('/employer');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          jobRepositoryProvider.overrideWithValue(
            const _NoApplicationsRepository(),
          ),
        ],
        child: const JobFinderApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a job post'));
    await tester.pumpAndSettle();

    await tester.enterText(field('Company name'), 'Acme Studio');
    await tester.enterText(field('Company location'), 'Karachi');
    await tester.enterText(field('Company industry (optional)'), 'Technology');
    await tester.enterText(field('Job title'), 'Flutter Engineer');
    await tester.enterText(
      field('Location (city, region or country)'),
      'Karachi',
    );
    await tester.enterText(field('Minimum'), '1200000');
    await tester.enterText(field('Maximum'), '1800000');
    await tester.enterText(
      field('Job summary'),
      'Build and maintain customer-focused mobile applications.',
    );
    await tester.enterText(
      field('Key responsibilities (one per line)'),
      'Develop and maintain Flutter applications',
    );
    await tester.enterText(
      field('Requirements / qualifications (one per line)'),
      'Three years of professional Flutter experience',
    );
    await tester.enterText(
      field('Required skills (comma separated)'),
      'Flutter, Dart, REST APIs',
    );
    await tester.enterText(
      field('Benefits (optional, one per line)'),
      'Health insurance',
    );
    final employerList = find.byType(ListView).first;
    for (var attempt = 0; attempt < 3; attempt++) {
      await tester.drag(employerList, const Offset(0, -900));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Publish job'));
    await tester.pumpAndSettle();
    expect(find.text('Flutter Engineer'), findsOneWidget);

    appRouter.go('/home');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flutter Engineer').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('PKR 1200000 – 1800000 / year'), findsOneWidget);
    expect(find.text('On-site'), findsOneWidget);
    await tester.tap(find.text('Requirements').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Three years of professional Flutter experience'),
      findsOneWidget,
    );
    await tester.tap(find.text('Benefits').first);
    await tester.pumpAndSettle();
    expect(find.text('Health insurance'), findsOneWidget);
    await tester.tap(find.text('Overview').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Develop and maintain Flutter applications'),
      findsOneWidget,
    );
    await tester.tap(find.text('Apply Now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit Application'));
    await tester.pumpAndSettle();
    expect(find.text('Demo application recorded'), findsOneWidget);
    await tester.tap(find.text('Track application'));
    await tester.pumpAndSettle();
    expect(find.text('Message employer (local demo)'), findsNothing);
    expect(find.text('Withdraw application'), findsOneWidget);

    appRouter.go('/employer');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Review applicants'));
    await tester.tap(find.text('Review applicants').first);
    await tester.pumpAndSettle();
    expect(find.text('Applicants for selected job'), findsOneWidget);
    await tester.ensureVisible(find.text('Alex Carter'));
    expect(find.text('alex.carter@email.com'), findsOneWidget);
    await tester.tap(find.text('Interview').last);
    await tester.pumpAndSettle();
    expect(find.text('Interview'), findsWidgets);
    appRouter.go('/applications');
    await tester.pumpAndSettle();
    expect(find.text('Message employer (local demo)'), findsOneWidget);
    await tester.tap(find.text('Message employer (local demo)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Messages stay on this device'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Hello from the applicant.');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(find.text('Hello from the applicant.'), findsOneWidget);
    await tester.tap(find.text('Employer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Thanks for applying.');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(find.text('Thanks for applying.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
    await tester.pumpAndSettle();

    appRouter.go('/employer');
    await tester.pumpAndSettle();
    final employerWorkflowList = find.byType(ListView).first;
    await tester.drag(employerWorkflowList, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.drag(employerWorkflowList, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offer').last);
    await tester.pumpAndSettle();
    expect(find.text('Offer'), findsWidgets);
    appRouter.go('/applications');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept offer'));
    await tester.pumpAndSettle();
    expect(find.text('Offer accepted'), findsOneWidget);
    expect(find.text('Withdraw application'), findsNothing);

    appRouter.go('/job/j1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply Now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit Application'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Track application'));
    await tester.pumpAndSettle();
    expect(find.text('Withdraw application'), findsOneWidget);
    await tester.tap(find.text('Withdraw application'));
    await tester.pumpAndSettle();
    expect(find.text('Withdrawn'), findsOneWidget);

    appRouter.go('/employer');
    await tester.pumpAndSettle();
    final employerReviewList = find.byType(ListView).first;
    await tester.drag(employerReviewList, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.drag(employerReviewList, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Message applicant').first);
    await tester.pumpAndSettle();
    expect(find.text('Flutter Engineer'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

class _NoApplicationsRepository extends MockJobRepository {
  const _NoApplicationsRepository();

  @override
  List<ApplicationModel> getApplications() => const [];
}
