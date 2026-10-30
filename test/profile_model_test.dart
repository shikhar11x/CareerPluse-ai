import 'package:careerpulse_ai/features/profile/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const complete = Profile(
    id: 'u1',
    fullName: 'Asha Rao',
    education: "Bachelor's",
    targetRole: 'Flutter Developer',
    experienceLevel: 'fresher',
  );

  group('Profile', () {
    test('isComplete needs all four fields', () {
      expect(complete.isComplete, isTrue);
      expect(const Profile(id: 'u1').isComplete, isFalse);
      expect(
        const Profile(id: 'u1', fullName: 'A', education: 'B', targetRole: ' ')
            .isComplete,
        isFalse,
      );
    });

    test('firstName and initials', () {
      expect(complete.firstName, 'Asha');
      expect(complete.initials, 'AR');
      expect(const Profile(id: 'u1').firstName, 'there');
      expect(const Profile(id: 'u1').initials, '?');
      expect(const Profile(id: 'u1', fullName: '  madonna ').initials, 'M');
    });

    test('experienceLabel maps known levels and ignores unknown ones', () {
      expect(complete.experienceLabel, 'Fresher');
      expect(const Profile(id: 'u1', experienceLevel: 'mid').experienceLabel, '3-5 years');
      expect(const Profile(id: 'u1', experienceLevel: 'zzz').experienceLabel, '');
    });

    test('fromJson fills missing fields with empty strings', () {
      final p = Profile.fromJson({'id': 'u1', 'fullName': 'Asha'});
      expect(p.id, 'u1');
      expect(p.fullName, 'Asha');
      expect(p.targetRole, '');
      expect(p.isComplete, isFalse);
    });
  });
}