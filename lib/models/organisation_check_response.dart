/// Model representing the response from the checkOrganisationInfo cloud function
class OrganisationCheckResponse {
  /// Whether the user has an organisation
  final bool hasOrganisation;

  /// The organisation ID if the user has one, null otherwise
  final String? organisationId;

  /// The user's role in the organisation if they have one, null otherwise
  final String? role;

  const OrganisationCheckResponse({
    required this.hasOrganisation,
    this.organisationId,
    this.role,
  });

  /// Creates an OrganisationCheckResponse from a JSON map
  factory OrganisationCheckResponse.fromJson(Map<String, dynamic> json) {
    return OrganisationCheckResponse(
      hasOrganisation: json['hasOrganisation'] as bool,
      organisationId: json['organisationId'] as String?,
      role: json['role'] as String?,
    );
  }

  /// Converts the OrganisationCheckResponse to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'hasOrganisation': hasOrganisation,
      'organisationId': organisationId,
      'role': role,
    };
  }

  @override
  String toString() {
    return 'OrganisationCheckResponse(hasOrganisation: $hasOrganisation, organisationId: $organisationId, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OrganisationCheckResponse &&
        other.hasOrganisation == hasOrganisation &&
        other.organisationId == organisationId &&
        other.role == role;
  }

  @override
  int get hashCode =>
      hasOrganisation.hashCode ^ organisationId.hashCode ^ role.hashCode;
}
