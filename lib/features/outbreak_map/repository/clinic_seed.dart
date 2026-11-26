import 'package:cloud_firestore/cloud_firestore.dart';

const _clinics = <Map<String, Object>>[
  {'id': 'sibu-hospital', 'name': 'Sibu Hospital', 'type': 'hospital', 'latitude': 2.2964682, 'longitude': 111.8917884, 'phone': '084343333'},
  {'id': 'jalan-oya-health-clinic', 'name': 'Jalan Oya Health Clinic', 'type': 'clinic', 'latitude': 2.3005118, 'longitude': 111.8353077, 'phone': '084323355'},
  {'id': 'dr-patrick-ling', 'name': "Dr Patrick Ling's Specialist Clinic", 'type': 'clinic', 'latitude': 2.300186, 'longitude': 111.831403, 'phone': '084319696'},
  {'id': 'klinik-dr-ko', 'name': 'Klinik Dr Ko Sibu', 'type': 'clinic', 'latitude': 2.30049, 'longitude': 111.8434274, 'phone': '0133661684'},
  {'id': 'wongs-medical', 'name': "Wong's Medical Clinic", 'type': 'clinic', 'latitude': 2.3007026, 'longitude': 111.8322469, 'phone': '084333550'},
  {'id': 'dr-lai-boon-foo', 'name': 'Child Specialist Clinic Dr Lai Boon Foo', 'type': 'clinic', 'latitude': 2.2972857, 'longitude': 111.8261181},
  {'id': 'geoffrey-wong', 'name': 'Geoffrey Wong Medical Clinic', 'type': 'clinic', 'latitude': 2.2927316, 'longitude': 111.825288, 'phone': '084336297'},
  {'id': 'yeks-clinic', 'name': "Yek's Clinic", 'type': 'clinic', 'latitude': 2.2914746, 'longitude': 111.8287222, 'phone': '084318203'},
  {'id': 'gohs-medical', 'name': "Goh's Medical Clinic", 'type': 'clinic', 'latitude': 2.2915333, 'longitude': 111.828034, 'phone': '0138989257'},
  {'id': 'teo-specialist', 'name': 'Teo Specialist Clinic', 'type': 'clinic', 'latitude': 2.293665, 'longitude': 111.8280678, 'phone': '084333099'},
  {'id': 'cc-rejang-park', 'name': 'Community Clinic Rejang Park', 'type': 'clinic', 'latitude': 2.3082215, 'longitude': 111.8377589, 'phone': '084318092'},
  {'id': 'rejang-medical', 'name': 'Rejang Medical Clinic', 'type': 'clinic', 'latitude': 2.2920935, 'longitude': 111.8373528, 'phone': '01153304500'},
  {'id': 'kk-jalan-teku', 'name': 'Klinik Komuniti Jalan Teku', 'type': 'clinic', 'latitude': 2.3514528, 'longitude': 111.8723878, 'phone': '084315494'},
  {'id': 'cc-campus-park', 'name': 'Community Clinic Campus Park', 'type': 'clinic', 'latitude': 2.3419895, 'longitude': 111.8255538, 'phone': '0198298766'},
  {'id': 'kk-utc-sibu', 'name': 'Klinik Kesihatan UTC Sibu', 'type': 'clinic', 'latitude': 2.2869923, 'longitude': 111.8289337, 'phone': '084316201'},
  {'id': 'cc-farley-sentosa', 'name': 'Community Clinic Farley-Sentosa', 'type': 'clinic', 'latitude': 2.2670225, 'longitude': 111.8635738, 'phone': '0198297552'},
  {'id': 'kk-soon-hup-permai', 'name': 'Klinik Komuniti Soon Hup Permai', 'type': 'clinic', 'latitude': 2.3061643, 'longitude': 111.8909661, 'phone': '084210876'},
  {'id': 'kk-sungai-bidut', 'name': 'Klinik Komuniti Sungai Bidut', 'type': 'clinic', 'latitude': 2.3090899, 'longitude': 111.8161115, 'phone': '084228066'},
  {'id': 'rejang-medical-centre', 'name': 'Rejang Medical Centre', 'type': 'hospital', 'latitude': 2.2925681, 'longitude': 111.8369918, 'phone': '084323333'},
];

/// One-time import. Fixed IDs mean running it twice just overwrites the same documents.
Future<void> seedClinics() async {
  final db = FirebaseFirestore.instance;
  final batch = db.batch();
  for (final c in _clinics) {
    final data = Map<String, Object>.from(c)..remove('id');
    batch.set(db.collection('facilities').doc(c['id'] as String), data);
  }
  await batch.commit();
}