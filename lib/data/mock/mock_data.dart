import '../models/app_notification.dart';
import '../models/application.dart';
import '../models/company.dart';
import '../models/job.dart';
import '../models/message.dart';

class MockData {
  static const List<AppNotification> notifications = [
    AppNotification(
      id: 'n1',
      title: 'Application update',
      message: 'Your application for Product Designer is under review.',
      time: '2h ago',
      kind: AppNotificationKind.application,
      unread: true,
    ),
    AppNotification(
      id: 'n2',
      title: 'New recruiter message',
      message: 'Sarah Williams from Google sent you a message.',
      time: '5h ago',
      kind: AppNotificationKind.recruiter,
      unread: true,
    ),
    AppNotification(
      id: 'n3',
      title: 'Jobs picked for you',
      message: 'New roles match your product design interests.',
      time: 'Yesterday',
      kind: AppNotificationKind.recommendation,
      unread: false,
    ),
  ];

  static const List<Company> companies = [
    Company(
      id: 'c1',
      name: 'Google',
      tint: 0xFF2F5BFF,
      rating: 4.8,
      reviewsLabel: '12k reviews',
      industry: 'Technology',
      size: '10k+ employees',
      location: 'Mountain View, CA',
      about:
          'Google builds products and services that help people access information and create opportunity across the world.',
      values: [
        CompanyValue(label: 'Innovation', icon: 'spark'),
        CompanyValue(label: 'Diversity', icon: 'people'),
        CompanyValue(label: 'Growth', icon: 'trending_up'),
        CompanyValue(label: 'Impact', icon: 'flag'),
      ],
    ),
    Company(
      id: 'c2',
      name: 'Microsoft',
      tint: 0xFF5C83FF,
      rating: 4.7,
      reviewsLabel: '9k reviews',
      industry: 'Technology',
      size: '180k+ employees',
      location: 'New York, USA',
      about:
          'Microsoft empowers every person and organization on the planet to achieve more through meaningful technology and innovation.',
      values: [
        CompanyValue(label: 'Empathy', icon: 'favorite'),
        CompanyValue(label: 'Learning', icon: 'school'),
        CompanyValue(label: 'Collaboration', icon: 'groups'),
        CompanyValue(label: 'Impact', icon: 'rocket_launch'),
      ],
    ),
    Company(
      id: 'c3',
      name: 'Amazon',
      tint: 0xFFFFA41C,
      rating: 4.5,
      reviewsLabel: '8k reviews',
      industry: 'E-commerce',
      size: '1.5M+ employees',
      location: 'Seattle, USA',
      about:
          'Amazon is guided by four principles: customer obsession, passion for invention, commitment to operational excellence, and long-term thinking.',
      values: [
        CompanyValue(label: 'Customer Obsession', icon: 'support_agent'),
        CompanyValue(label: 'Invent', icon: 'lightbulb'),
        CompanyValue(label: 'Scale', icon: 'speed'),
        CompanyValue(label: 'Ownership', icon: 'check_circle'),
      ],
    ),
    Company(
      id: 'c4',
      name: 'Spotify',
      tint: 0xFF1ED760,
      rating: 4.9,
      reviewsLabel: '7k reviews',
      industry: 'Music',
      size: '7k+ employees',
      location: 'Remote',
      about:
          'Spotify connects listeners with creators and helps culture grow through music, podcasts, and audio experiences.',
      values: [
        CompanyValue(label: 'Creativity', icon: 'palette'),
        CompanyValue(label: 'Culture', icon: 'music_note'),
        CompanyValue(label: 'Belonging', icon: 'groups'),
        CompanyValue(label: 'Lifestyle', icon: 'stadia_controller'),
      ],
    ),
    Company(
      id: 'c5',
      name: 'Apple',
      tint: 0xFF6E7CFF,
      rating: 4.6,
      reviewsLabel: '14k reviews',
      industry: 'Technology',
      size: '150k+ employees',
      location: 'Cupertino, USA',
      about:
          'Apple designs intuitive products and experiences that bring people together in meaningful ways through technology.',
      values: [
        CompanyValue(label: 'Design', icon: 'brush'),
        CompanyValue(label: 'Privacy', icon: 'shield'),
        CompanyValue(label: 'Accessibility', icon: 'accessibility_new'),
        CompanyValue(label: 'Quality', icon: 'verified'),
      ],
    ),
  ];

  static const List<Job> jobs = [
    Job(
      id: 'j1',
      title: 'Senior Frontend Developer',
      companyId: 'c1',
      location: 'Remote',
      isRemote: true,
      type: 'Full-time',
      salaryLabel: '\$120,000 – \$160,000',
      salaryShort: '\$120K – \$160K',
      postedAgo: '2d ago',
      applicantsLabel: '1.2k applicants',
      about:
          'Lead the development of next-generation user experiences for Google Workspace with a focus on performance, accessibility, and modern frontend architecture.',
      responsibilities: [
        'Design and ship polished interfaces for web products used by millions of customers.',
        'Partner with product and design teams to improve user flows and communication.',
        'Improve accessibility and frontend performance across the platform.',
      ],
      requirements: [
        '5+ years in frontend engineering with React, TypeScript, and scalable UI systems.',
        'Experience building accessible interfaces and cross-browser optimization.',
        'Strong collaboration and communication with designers and engineers.',
      ],
      benefits: [
        'Flexible remote-first culture',
        'Annual learning and growth budget',
        'Comprehensive health coverage',
      ],
      skills: ['React', 'TypeScript', 'Accessibility', 'UX architecture'],
    ),
    Job(
      id: 'j2',
      title: 'Product Designer',
      companyId: 'c2',
      location: 'New York, USA',
      isRemote: false,
      type: 'Full-time',
      salaryLabel: '\$90K – \$130K',
      salaryShort: '\$90K – \$130K',
      postedAgo: '3d ago',
      applicantsLabel: '860 applicants',
      about:
          'Shape thoughtful digital products that help teams collaborate, build, and innovate with confidence.',
      responsibilities: [
        'Lead design explorations for productivity and collaboration features.',
        'Build prototypes and partner closely with engineering teams.',
        'Translate customer needs into product strategy and design direction.',
      ],
      requirements: [
        '3+ years of product design experience in SaaS or B2B tools.',
        'Strong Figma and design systems experience.',
        'Ability to think in terms of outcomes, metrics, and usability.',
      ],
      benefits: [
        'Wellness and flexible work options',
        'Learning stipend',
        'Stock and equity package',
      ],
      skills: ['Figma', 'Design systems', 'UX research', 'Product strategy'],
    ),
    Job(
      id: 'j3',
      title: 'Software Engineer',
      companyId: 'c3',
      location: 'Seattle, USA',
      isRemote: false,
      type: 'Full-time',
      salaryLabel: '\$100K – \$150K',
      salaryShort: '\$100K – \$150K',
      postedAgo: '3d ago',
      applicantsLabel: '1.1k applicants',
      about:
          'Build high-scale systems that power customer experiences and core operations for Amazon platforms.',
      responsibilities: [
        'Own critical services with measurable impact on reliability and growth.',
        'Partner with product and infrastructure teams to ship major improvements.',
        'Influence architecture decisions and scalability plans.',
      ],
      requirements: [
        'Experience building distributed backend systems and APIs.',
        'Strong software design and performance optimization skills.',
        'Comfort with ambiguity and solving complex product challenges.',
      ],
      benefits: [
        'Competitive compensation',
        'Growth and mentoring support',
        'Comprehensive benefits package',
      ],
      skills: ['Java', 'AWS', 'Distributed systems', 'Backend'],
    ),
    Job(
      id: 'j4',
      title: 'UX Designer',
      companyId: 'c4',
      location: 'Remote',
      isRemote: true,
      type: 'Full-time',
      salaryLabel: '\$80K – \$120K',
      salaryShort: '\$80K – \$120K',
      postedAgo: '5d ago',
      applicantsLabel: '640 applicants',
      about:
          'Create immersive product experiences for Spotify listeners and creators around the world.',
      responsibilities: [
        'Design user-centered experiences for listening and discovery products.',
        'Run research, prototype, and validate key flows.',
        'Collaborate across product, engineering, and marketing teams.',
      ],
      requirements: [
        'Portfolio with polished UI and UX projects.',
        'Strong understanding of interaction design and mobile patterns.',
        'Experience with experimentation and rapid iteration.',
      ],
      benefits: [
        'Remote-first flexibility',
        'Wellness and team support',
        'Music and culture perks',
      ],
      skills: ['UX design', 'Product thinking', 'Research', 'Prototyping'],
    ),
    Job(
      id: 'j5',
      title: 'iOS Developer',
      companyId: 'c5',
      location: 'Cupertino, USA',
      isRemote: false,
      type: 'Full-time',
      salaryLabel: '\$110K – \$150K',
      salaryShort: '\$110K – \$150K',
      postedAgo: '6d ago',
      applicantsLabel: '930 applicants',
      about:
          'Design and develop iOS experiences with a strong focus on delight, quality, and simplicity.',
      responsibilities: [
        'Build features for world-class mobile experiences used by millions of people.',
        'Work cross-functionally with design and product to refine user journeys.',
        'Ship polished and maintainable code with strong testing practices.',
      ],
      requirements: [
        'Strong Swift and iOS app development experience.',
        'Knowledge of UIKit/SwiftUI and performance profiling.',
        'Ability to ship delightful product features at scale.',
      ],
      benefits: [
        'Industry-leading perk package',
        'Learning and mentorship',
        'Health and retirement benefits',
      ],
      skills: ['Swift', 'SwiftUI', 'UIKit', 'Performance'],
    ),
  ];

  static const List<ApplicationModel> applications = [
    ApplicationModel(
      jobId: 'j1',
      status: ApplicationStatus.applied,
      appliedAgo: '2 days ago',
    ),
    ApplicationModel(
      jobId: 'j2',
      status: ApplicationStatus.applied,
      appliedAgo: '1 day ago',
    ),
    ApplicationModel(
      jobId: 'j3',
      status: ApplicationStatus.applied,
      appliedAgo: '2 hours ago',
    ),
    ApplicationModel(
      jobId: 'j4',
      status: ApplicationStatus.interview,
      appliedAgo: '3 days ago',
    ),
    ApplicationModel(
      jobId: 'j5',
      status: ApplicationStatus.interview,
      appliedAgo: '5 days ago',
    ),
  ];

  static const List<Message> messages = [
    Message(
      id: 'm1',
      name: 'Sarah Williams',
      company: 'Google',
      preview: 'Thanks for sending your portfolio. I would love to learn more.',
      time: '10:24 AM',
      unread: true,
      kind: MessageKind.recruiter,
    ),
    Message(
      id: 'm2',
      name: 'Michael Chen',
      company: 'Microsoft',
      preview: 'The interview slots are open for next Tuesday and Wednesday.',
      time: 'Yesterday',
      unread: true,
      kind: MessageKind.recruiter,
    ),
    Message(
      id: 'm3',
      name: 'Emma Davis',
      company: 'Amazon',
      preview: 'Your application received. We will be in touch soon.',
      time: 'Mon',
      unread: false,
      kind: MessageKind.company,
    ),
    Message(
      id: 'm4',
      name: 'James Wilson',
      company: 'Spotify',
      preview: 'Let’s schedule a quick design review call this afternoon.',
      time: 'Sun',
      unread: false,
      kind: MessageKind.company,
    ),
    Message(
      id: 'm5',
      name: 'Olivia Martinez',
      company: 'Apple',
      preview:
          'We loved your presentation and would like to continue the process.',
      time: 'Sat',
      unread: false,
      kind: MessageKind.recruiter,
    ),
  ];
}
