import 'package:traxx_wepapp/models/organisation_user_role.dart';
import 'package:traxx_wepapp/models/user_model.dart';

class UserWithRole {
  final UserModel user;
  final OrganisationUserRole role;

  UserWithRole({required this.user, required this.role});
}
