class StepModel {
  final String stepId;
  final int orderNum;
  final String stepType;
  final String title;
  final String instruction;
  final Map<String, dynamic> contentObj;

  StepModel({
    required this.stepId,
    required this.orderNum,
    required this.stepType,
    this.title = '',
    this.instruction = '',
    required this.contentObj,
  });

  factory StepModel.fromJson(Map<String, dynamic> json) {
    return StepModel(
      stepId: json['stepId'] as String? ?? '',
      orderNum: json['orderNum'] as int? ?? 0,
      stepType: json['stepType'] as String? ?? json['step_type'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      instruction: json['instruction'] as String? ?? '',
      contentObj: json['contentObj'] as Map<String, dynamic>? ?? json['content'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepId': stepId,
      'orderNum': orderNum,
      'stepType': stepType,
      'title': title,
      'instruction': instruction,
      'contentObj': contentObj,
    };
  }
}
