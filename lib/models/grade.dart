class Grade {
  final String courseCode;
  final String courseName;
  final String semester;
  final String credits;
  final String midterm;
  final String final_;
  final String letterGrade;
  final String status;

  Grade({
    required this.courseCode,
    required this.courseName,
    this.semester = '',
    this.credits = '',
    this.midterm = '-',
    this.final_ = '-',
    this.letterGrade = '-',
    this.status = '',
  });

  @override
  String toString() =>
      '$courseCode | Vize: $midterm | Final: $final_ | HBN: $letterGrade';
}
