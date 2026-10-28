class Company {
  const Company({
    required this.id,
    required this.name,
    required this.tint,
    required this.rating,
    required this.reviewsLabel,
    required this.industry,
    required this.size,
    required this.location,
    required this.about,
    required this.values,
  });

  final String id;
  final String name;
  final int tint;
  final double rating;
  final String reviewsLabel;
  final String industry;
  final String size;
  final String location;
  final String about;
  final List<CompanyValue> values;
}

class CompanyValue {
  const CompanyValue({required this.label, required this.icon});

  final String label;
  final String icon;
}
