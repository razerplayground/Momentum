import 'package:bussiness_management/data/models/user_model.dart';
import 'package:bussiness_management/data/providers/workspace_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('organization plan can create multiple businesses', () {
    final user = UserModel(
      id: 'user-1',
      email: 'jane@example.com',
      name: 'Jane Doe',
      plan: ' Organization ',
    );

    expect(canCreateMultipleBusinesses(user), isTrue);
  });

  test('individual plan remains limited to one business', () {
    final user = UserModel(
      id: 'user-1',
      email: 'jane@example.com',
      name: 'Jane Doe',
      plan: 'individual',
    );

    expect(canCreateMultipleBusinesses(user), isFalse);
  });

  test('organization name also grants multi-business access', () {
    final user = UserModel(
      id: 'user-1',
      email: 'jane@example.com',
      name: 'Jane Doe',
      organizationName: 'Example Organization',
    );

    expect(canCreateMultipleBusinesses(user), isTrue);
  });
}
