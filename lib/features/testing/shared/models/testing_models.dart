class UpvReadingResult {
  final double distance;
  final double time;
  final double velocity;

  const UpvReadingResult({
    required this.distance,
    required this.time,
    required this.velocity,
  });
}

class UpvResults {
  final List<UpvReadingResult> readings;
  final double averageVelocity;
  final String condition;

  const UpvResults({
    required this.readings,
    required this.averageVelocity,
    required this.condition,
  });

  factory UpvResults.empty() {
    return const UpvResults(
      readings: [],
      averageVelocity: 0,
      condition: 'N/A',
    );
  }
}

class HcpResults {
  final List<double> readings;
  final double average;
  final Map<String, double> distributionPercentages;
  final String condition;

  const HcpResults({
    required this.readings,
    required this.average,
    required this.distributionPercentages,
    required this.condition,
  });

  factory HcpResults.empty() {
    return const HcpResults(
      readings: [],
      average: 0,
      distributionPercentages: {
        'Low': 0,
        'Medium': 0,
        'High': 0,
      },
      condition: 'N/A',
    );
  }
}

class PullOutResults {
  final double area;
  final double strength;

  const PullOutResults({
    required this.area,
    required this.strength,
  });

  factory PullOutResults.empty() {
    return const PullOutResults(area: 0, strength: 0);
  }
}

class TestSummary {
  final String testName;
  String status;

  TestSummary({
    required this.testName,
    required this.status,
  });
}

class InspectionHistoryItem {
  final String id;
  final String date;
  final String summary;
  bool compare;

  InspectionHistoryItem({
    required this.id,
    required this.date,
    required this.summary,
    this.compare = false,
  });
}

class RepairRecommendation {
  final String recommendation;
  String status;
  String comment;

  RepairRecommendation({
    required this.recommendation,
    required this.status,
    this.comment = '',
  });
}
