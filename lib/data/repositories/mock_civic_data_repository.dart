// lib/data/repositories/mock_civic_data_repository.dart
// In-memory mock implementation of ICivicRepository.
// Contains exactly 55 seed IncidentReport entries covering Accra, Ghana.
// Used during development/testing before Firebase is wired up.

import 'dart:async';

import 'package:civic_voice/data/models/incident_report.dart';
import 'package:civic_voice/data/repositories/i_civic_repository.dart';
import 'package:civic_voice/domain/enums/incident_category.dart';
import 'package:civic_voice/domain/enums/incident_status.dart';

/// In-memory mock repository pre-seeded with 55 realistic incident reports
/// located within the Accra, Ghana metropolitan area.
///
/// Status distribution  : 17 Submitted | 11 Reviewed | 14 Dispatched | 13 Resolved
/// Category distribution: 19 Pothole   | 14 WaterLeak | 11 LightFailure | 6 DrainageBlockage | 5 RoadDamage
/// All coordinates are within bounding box: lat 5.45–5.75, lng -0.35–0.10
class MockCivicDataRepository implements ICivicRepository {
  MockCivicDataRepository() {
    _reports = _buildSeedData();
    // Emit initial state to any eager subscribers.
    Future.microtask(() => _controller.add(List.from(_reports)));
  }

  static List<IncidentReport> get seedData => _buildSeedData();

  late List<IncidentReport> _reports;

  final StreamController<List<IncidentReport>> _controller =
      StreamController<List<IncidentReport>>.broadcast();

  // ──────────────────────────────────────────────────────────────────────────
  // ICivicRepository implementation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<IncidentReport>> fetchAllReports() {
    return Future.value(List.from(_reports));
  }

  @override
  Future<IncidentReport?> fetchReportById(String id) {
    final report = _reports.cast<IncidentReport?>().firstWhere(
          (r) => r?.id == id,
          orElse: () => null,
        );
    return Future.value(report);
  }

  @override
  Future<void> updateReportStatus(String id, IncidentStatus status) {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index == -1) {
      return Future.error(
        ArgumentError('No report found with id: $id'),
        StackTrace.current,
      );
    }
    _reports[index] = _reports[index].copyWith(status: status);
    _controller.add(List.from(_reports));
    return Future.value();
  }

  @override
  Future<String> submitReport(IncidentReport report) {
    final newId = _generateId();
    final newReport = report.copyWith(
      id: newId,
      timestamp: DateTime.now(),
    );
    _reports.add(newReport);
    _controller.add(List.from(_reports));
    return Future.value(newId);
  }

  @override
  Stream<List<IncidentReport>> watchReports() {
    // Emit current state on every new subscription via an async microtask.
    Future.microtask(() {
      if (!_controller.isClosed) {
        _controller.add(List.from(_reports));
      }
    });
    return _controller.stream;
  }

  /// Releases the StreamController. Call this when the repository is no longer needed.
  void dispose() {
    _controller.close();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Generates a simple incrementing string ID for new submissions.
  String _generateId() {
    return 'cv_${DateTime.now().millisecondsSinceEpoch}';
  }

  static DateTime _daysAgo(int days) =>
      DateTime(2026, 7, 4).subtract(Duration(days: days));

  // ──────────────────────────────────────────────────────────────────────────
  // Seed Data  (exactly 55 entries)
  // ──────────────────────────────────────────────────────────────────────────

  static List<IncidentReport> _buildSeedData() {
    return [
      // ── User Mock Submissions (One for each Category) ──
      IncidentReport(
        id: 'cv_usr_pothole_01',
        category: IncidentCategory.pothole,
        title: 'Deep pothole on Oxford Street near Danquah Circle',
        description:
            'A very deep pothole has formed in the middle of Oxford Street. Vehicles are swerving into oncoming traffic to avoid damaging their tires.',
        latitude: 5.5562,
        longitude: -0.1812,
        imageUrl: 'https://picsum.photos/seed/cv_usr_pothole/400/300',
        status: IncidentStatus.submitted,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        reporterName: 'User Account (user@civicvoice.org)',
        district: 'Osu Klottey',
      ),
      IncidentReport(
        id: 'cv_usr_water_01',
        category: IncidentCategory.waterLeak,
        title: 'Burst pipe flooding main street in East Legon',
        description:
            'Water is gushing out heavily from an underground pipe leak on Boundary Road, eroding the road shoulder and wasting clean water.',
        latitude: 5.6354,
        longitude: -0.1601,
        imageUrl: 'https://picsum.photos/seed/cv_usr_water/400/300',
        status: IncidentStatus.submitted,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        reporterName: 'User Account (citizen.user@gmail.com)',
        district: 'Ayawaso West',
      ),
      IncidentReport(
        id: 'cv_usr_light_01',
        category: IncidentCategory.structuralLightFailure,
        title: 'Non-functional streetlights on Liberation Road',
        description:
            'Several consecutive streetlights near the Airport junction are dark, creating dangerous night-time driving conditions for commuters.',
        latitude: 5.6011,
        longitude: -0.1764,
        imageUrl: 'https://picsum.photos/seed/cv_usr_light/400/300',
        status: IncidentStatus.submitted,
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        reporterName: 'User Account (user.app@civicvoice.org)',
        district: 'Ayawaso West',
      ),
      IncidentReport(
        id: 'cv_usr_drain_01',
        category: IncidentCategory.drainageBlockage,
        title: 'Clogged roadside storm drain near Kaneshie Market',
        description:
            'Debris and plastic refuse have completely blocked the primary gutter, causing standing water to accumulate across the road.',
        latitude: 5.5645,
        longitude: -0.2311,
        imageUrl: 'https://picsum.photos/seed/cv_usr_drain/400/300',
        status: IncidentStatus.submitted,
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        reporterName: 'User Account (resident.user@yahoo.com)',
        district: 'Okaikwei South',
      ),
      IncidentReport(
        id: 'cv_usr_road_01',
        category: IncidentCategory.roadDamage,
        title: 'Collapsed asphalt shoulder along Spintex Road',
        description:
            'Heavy rain has eroded the edge of the asphalt shoulder near Papaye, leaving a steep drop-off next to the main driving lane.',
        latitude: 5.6201,
        longitude: -0.1198,
        imageUrl: 'https://picsum.photos/seed/cv_usr_road/400/300',
        status: IncidentStatus.submitted,
        timestamp: DateTime.now().subtract(const Duration(hours: 10)),
        reporterName: 'User Account (user.civic@gmail.com)',
        district: 'Ledzokuku',
      ),
      // ── 1 ──
      IncidentReport(
        id: 'cv_001',
        category: IncidentCategory.pothole,
        title: 'Large pothole on Ring Road Central',
        description:
            'A deep pothole approximately 60 cm in diameter has formed near the junction of Ring Road Central and Farrar Avenue. Vehicles are swerving into oncoming traffic to avoid it, creating a serious safety hazard.',
        latitude: 5.5717,
        longitude: -0.2107,
        imageUrl: 'https://picsum.photos/seed/cv_001/400/300',
        status: IncidentStatus.dispatched,
        timestamp: _daysAgo(165),
        reporterName: 'Kwame Asante',
        district: 'Ayawaso Central',
      ),
      // ── 2 ──
      IncidentReport(
        id: 'cv_002',
        category: IncidentCategory.waterLeak,
        title: 'Burst pipe flooding Abbosey Okai road',
        description:
            'A water main has burst at Abbosey Okai, causing water to flood the road surface and adjacent properties. The leak has been running for over 48 hours and the pavement is beginning to collapse.',
        latitude: 5.5603,
        longitude: -0.2498,
        imageUrl: 'https://picsum.photos/seed/cv_002/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(160),
        reporterName: 'Abena Mensah',
        district: 'Ablekuma North',
      ),
      // ── 3 ──
      IncidentReport(
        id: 'cv_003',
        category: IncidentCategory.structuralLightFailure,
        title: 'Street lights out on Dansoman Highway',
        description:
            'Approximately 8 consecutive street lights along Dansoman Highway between Mallam Junction and Obuom have been non-functional for 3 weeks. The stretch is extremely dark at night, attracting criminal activity.',
        latitude: 5.5522,
        longitude: -0.2715,
        imageUrl: 'https://picsum.photos/seed/cv_003/400/300',
        status: IncidentStatus.reviewed,
        timestamp: _daysAgo(155),
        reporterName: 'Kofi Boateng',
        district: 'Ablekuma North',
      ),
      // ── 4 ──
      IncidentReport(
        id: 'cv_004',
        category: IncidentCategory.drainageBlockage,
        title: 'Blocked drain causing flooding near Nungua market',
        description:
            'The main drainage channel running alongside Nungua market is completely blocked with refuse and silt. During the last rainfall, market stalls were flooded up to ankle height, destroying goods worth thousands of cedis.',
        latitude: 5.6012,
        longitude: -0.0598,
        imageUrl: 'https://picsum.photos/seed/cv_004/400/300',
        status: IncidentStatus.resolved,
        timestamp: _daysAgo(150),
        reporterName: 'Ama Owusu',
        district: 'Tema West',
      ),
      // ── 5 ──
      IncidentReport(
        id: 'cv_005',
        category: IncidentCategory.pothole,
        title: 'Pothole cluster on Spintex Road',
        description:
            'A cluster of 4 interconnected potholes near the Shell filling station on Spintex Road is causing significant vehicle damage. Motorcyclists have been particularly affected — two accidents have already been reported by neighbours.',
        latitude: 5.6278,
        longitude: -0.1105,
        imageUrl: 'https://picsum.photos/seed/cv_005/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(148),
        reporterName: 'Yaw Darko',
        district: 'Tema West',
      ),
      // ── 6 ──
      IncidentReport(
        id: 'cv_006',
        category: IncidentCategory.roadDamage,
        title: 'Road surface collapse near East Legon hills',
        description:
            'A section of road near the East Legon hills residential area has subsided by approximately 30 cm, likely due to underground erosion. The road is partially passable but poses a risk to heavy vehicles.',
        latitude: 5.6437,
        longitude: -0.1623,
        imageUrl: 'https://picsum.photos/seed/cv_006/400/300',
        status: IncidentStatus.dispatched,
        timestamp: _daysAgo(145),
        reporterName: 'Akosua Amponsah',
        district: 'Ayawaso Central',
      ),
      // ── 7 ──
      IncidentReport(
        id: 'cv_007',
        category: IncidentCategory.pothole,
        title: 'Dangerous pothole at Lapaz Interchange',
        description:
            'A pothole at the Lapaz interchange approach road has grown to nearly 80 cm across. It is positioned in the fast lane and causes vehicles to brake suddenly, leading to near-miss incidents during peak hours.',
        latitude: 5.5899,
        longitude: -0.2321,
        imageUrl: 'https://picsum.photos/seed/cv_007/400/300',
        status: IncidentStatus.resolved,
        timestamp: _daysAgo(142),
        reporterName: 'Nana Osei',
        district: 'Okaikwei North',
      ),
      // ── 8 ──
      IncidentReport(
        id: 'cv_008',
        category: IncidentCategory.waterLeak,
        title: 'Underground pipe leak at Adabraka',
        description:
            'Water is seeping up through the asphalt on Kojo Thompson Road near Adabraka police station. The consistent dampness is causing the road surface to crack and buckle. Residents have reported low water pressure in the area.',
        latitude: 5.5634,
        longitude: -0.2012,
        imageUrl: 'https://picsum.photos/seed/cv_008/400/300',
        status: IncidentStatus.reviewed,
        timestamp: _daysAgo(140),
        reporterName: 'Efua Bannerman',
        district: 'Korle Klottey',
      ),
      // ── 9 ──
      IncidentReport(
        id: 'cv_009',
        category: IncidentCategory.drainageBlockage,
        title: 'Overflowing gutter on Liberation Road',
        description:
            'The roadside gutter on Liberation Road between the Airport roundabout and Nkrumah Circle overflows with every rainfall. Plastic waste and vegetation have created a complete blockage. Standing water breeds mosquitoes.',
        latitude: 5.5731,
        longitude: -0.1897,
        imageUrl: 'https://picsum.photos/seed/cv_009/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(137),
        reporterName: 'Kwesi Amoah',
        district: 'Ayawaso Central',
      ),
      // ── 10 ──
      IncidentReport(
        id: 'cv_010',
        category: IncidentCategory.structuralLightFailure,
        title: 'Street lamp pole leaning dangerously at Madina',
        description:
            'A street lamp pole at Madina Station Road is tilted at approximately 45 degrees following a road accident last month. The electrical connections are exposed and pose an electrocution risk, especially during rainfall.',
        latitude: 5.6793,
        longitude: -0.1702,
        imageUrl: 'https://picsum.photos/seed/cv_010/400/300',
        status: IncidentStatus.dispatched,
        timestamp: _daysAgo(134),
        reporterName: 'Adwoa Frimpong',
        district: 'Ga East',
      ),
      // ── 11 ──
      IncidentReport(
        id: 'cv_011',
        category: IncidentCategory.pothole,
        title: 'Pothole on Accra-Tema Motorway access road',
        description:
            'Several deep potholes have appeared on the access road leading to the Accra-Tema motorway at Tetteh Quarshie. The heaviest one is approximately 40 cm deep and causes extreme vibration. Trucks frequently break axles here.',
        latitude: 5.6612,
        longitude: -0.1563,
        imageUrl: 'https://picsum.photos/seed/cv_011/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(131),
        reporterName: 'Kojo Mensah',
        district: 'Ga East',
      ),
      // ── 12 ──
      IncidentReport(
        id: 'cv_012',
        category: IncidentCategory.waterLeak,
        title: 'Water main burst at Kaneshie Market',
        description:
            'A water main serving Kaneshie Market has burst, creating a river of water across the market access road. Traders are unable to bring goods to their stalls. The Ghana Water Company has been notified but has not yet responded.',
        latitude: 5.5589,
        longitude: -0.2389,
        imageUrl: 'https://picsum.photos/seed/cv_012/400/300',
        status: IncidentStatus.resolved,
        timestamp: _daysAgo(128),
        reporterName: 'Araba Quaye',
        district: 'Ablekuma North',
      ),
      // ── 13 ──
      IncidentReport(
        id: 'cv_013',
        category: IncidentCategory.roadDamage,
        title: 'Severely eroded road shoulder at Teshie',
        description:
            'The road shoulder along the Teshie-Nungua Estate road has been severely eroded by recent heavy rains. The carriageway has narrowed to a single lane in parts. A child on a bicycle nearly fell into the erosion gully yesterday.',
        latitude: 5.5901,
        longitude: -0.0712,
        imageUrl: 'https://picsum.photos/seed/cv_013/400/300',
        status: IncidentStatus.dispatched,
        timestamp: _daysAgo(125),
        reporterName: 'Fiifi Amoako',
        district: 'Tema West',
      ),
      // ── 14 ──
      IncidentReport(
        id: 'cv_014',
        category: IncidentCategory.pothole,
        title: 'Pothole at Oxford Street junction, Osu',
        description:
            'The junction of Oxford Street and Cantonments Road in Osu has a wide pothole that fills with water during rain, making its depth impossible to judge. Several motorcycles have sustained tyre damage here in the past week.',
        latitude: 5.5568,
        longitude: -0.1789,
        imageUrl: 'https://picsum.photos/seed/cv_014/400/300',
        status: IncidentStatus.reviewed,
        timestamp: _daysAgo(122),
        reporterName: 'Mabel Acheampong',
        district: 'Korle Klottey',
      ),
      // ── 15 ──
      IncidentReport(
        id: 'cv_015',
        category: IncidentCategory.structuralLightFailure,
        title: 'All lights failed on Ashaiman Market road',
        description:
            'The entire stretch of street lighting on the main Ashaiman market road has failed. The fault appears to be in the distribution board. Night traders pack up early for safety, and the market economy is suffering.',
        latitude: 5.7012,
        longitude: -0.0213,
        imageUrl: 'https://picsum.photos/seed/cv_015/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(119),
        reporterName: 'Emmanuel Tetteh',
        district: 'Tema West',
      ),
      // ── 16 ──
      IncidentReport(
        id: 'cv_016',
        category: IncidentCategory.pothole,
        title: 'Deep pothole on Dzorwulu residential road',
        description:
            'A large pothole on Airport Residential road near the Dzorwulu extension has been growing steadily for two months. It now spans the full width of the left lane and is approximately 25 cm deep. Water pools there after rain.',
        latitude: 5.6001,
        longitude: -0.1978,
        imageUrl: 'https://picsum.photos/seed/cv_016/400/300',
        status: IncidentStatus.dispatched,
        timestamp: _daysAgo(116),
        reporterName: 'Serwa Asante',
        district: 'Ayawaso Central',
      ),
      // ── 17 ──
      IncidentReport(
        id: 'cv_017',
        category: IncidentCategory.waterLeak,
        title: 'Leaking hydrant at Kotobabi junction',
        description:
            'A fire hydrant at the Kotobabi main junction is leaking continuously, wasting significant amounts of treated water. The road surface around it is waterlogged and sinking. Children play in the water, which is a safety hazard.',
        latitude: 5.5712,
        longitude: -0.2234,
        imageUrl: 'https://picsum.photos/seed/cv_017/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(113),
        reporterName: 'Yaa Kumah',
        district: 'Okaikwei North',
      ),
      // ── 18 ──
      IncidentReport(
        id: 'cv_018',
        category: IncidentCategory.drainageBlockage,
        title: 'Silted drainage channel at Achimota',
        description:
            'The open drainage channel running parallel to the Achimota road near the DVLA office is filled with silt and plastic waste to the brim. During last week\'s rainstorm, water overtopped and entered three residential compounds.',
        latitude: 5.6187,
        longitude: -0.2145,
        imageUrl: 'https://picsum.photos/seed/cv_018/400/300',
        status: IncidentStatus.resolved,
        timestamp: _daysAgo(110),
        reporterName: 'Kwame Attah',
        district: 'Ayawaso Central',
      ),
      // ── 19 ──
      IncidentReport(
        id: 'cv_019',
        category: IncidentCategory.pothole,
        title: 'Pothole cluster near Tema Community 1',
        description:
            'A cluster of 6 potholes in Community 1, Tema, near the community centre has made the road virtually impassable for smaller vehicles. The aggregate base layer is exposed and breaking up further with each passing truck.',
        latitude: 5.6698,
        longitude: -0.0145,
        imageUrl: 'https://picsum.photos/seed/cv_019/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(107),
        reporterName: 'Akua Dankwa',
        district: 'Tema West',
      ),
      // ── 20 ──
      IncidentReport(
        id: 'cv_020',
        category: IncidentCategory.waterLeak,
        title: 'Exposed and broken water pipe at Abelemkpe',
        description:
            'A water supply pipe has fractured and is fully exposed at the intersection near Abelemkpe police station. The pipe sprays water intermittently. Supply to at least 200 homes in the area has been disrupted.',
        latitude: 5.5948,
        longitude: -0.2001,
        imageUrl: 'https://picsum.photos/seed/cv_020/400/300',
        status: IncidentStatus.reviewed,
        timestamp: _daysAgo(104),
        reporterName: 'Paa Kwesi Nyarko',
        district: 'Ayawaso Central',
      ),
      // ── 21 ──
      IncidentReport(
        id: 'cv_021',
        category: IncidentCategory.structuralLightFailure,
        title: 'Faulty street light flickering at Dzorwulu',
        description:
            'A street light at the entrance to Dzorwulu Phase 2 flickers erratically throughout the night. The intermittent flashing is causing distress to residents, including a reported epilepsy trigger incident. The ballast needs replacement.',
        latitude: 5.6021,
        longitude: -0.1945,
        imageUrl: 'https://picsum.photos/seed/cv_021/400/300',
        status: IncidentStatus.dispatched,
        timestamp: _daysAgo(101),
        reporterName: 'Abena Korsah',
        district: 'Ayawaso Central',
      ),
      // ── 22 ──
      IncidentReport(
        id: 'cv_022',
        category: IncidentCategory.pothole,
        title: 'Pothole on Burma Camp road approach',
        description:
            'The approach road to Burma Camp from the Ring Road roundabout side has a severe pothole that has been widening over the past 3 months. Military and civilian vehicles are both at risk. The road sees extremely high traffic.',
        latitude: 5.5812,
        longitude: -0.1812,
        imageUrl: 'https://picsum.photos/seed/cv_022/400/300',
        status: IncidentStatus.resolved,
        timestamp: _daysAgo(98),
        reporterName: 'Kofi Asare',
        district: 'Korle Klottey',
      ),
      // ── 23 ──
      IncidentReport(
        id: 'cv_023',
        category: IncidentCategory.waterLeak,
        title: 'Gushing pipe leak near Pig Farm roundabout',
        description:
            'A major pipe leak near the Pig Farm roundabout is sending a jet of water across the road. Motorists are slowing and changing lanes, causing congestion extending back to Kwame Nkrumah Circle. The volume of water loss is alarming.',
        latitude: 5.5501,
        longitude: -0.2301,
        imageUrl: 'https://picsum.photos/seed/cv_023/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(95),
        reporterName: 'Adjoa Asante',
        district: 'Ablekuma North',
      ),
      // ── 24 ──
      IncidentReport(
        id: 'cv_024',
        category: IncidentCategory.pothole,
        title: 'Pothole near Kwame Nkrumah Circle underpass',
        description:
            'Under the Kwame Nkrumah Circle flyover on the Graphic Road side there are two very deep potholes that are filled with dark water and impossible to see until it\'s too late. Two cars have blown tyres here in one week.',
        latitude: 5.5487,
        longitude: -0.2176,
        imageUrl: 'https://picsum.photos/seed/cv_024/400/300',
        status: IncidentStatus.dispatched,
        timestamp: _daysAgo(92),
        reporterName: 'Kwabena Boateng',
        district: 'Korle Klottey',
      ),
      // ── 25 ──
      IncidentReport(
        id: 'cv_025',
        category: IncidentCategory.structuralLightFailure,
        title: 'Broken street light housing at North Industrial Area',
        description:
            'A street lamp in the North Industrial Area near the Guinness factory has had its housing completely broken off, leaving bare electrical wires dangling in the air. This is a severe electrocution hazard, especially in the rainy season.',
        latitude: 5.5801,
        longitude: -0.2398,
        imageUrl: 'https://picsum.photos/seed/cv_025/400/300',
        status: IncidentStatus.reviewed,
        timestamp: _daysAgo(89),
        reporterName: 'Esi Andoh',
        district: 'Ablekuma North',
      ),
      // ── 26 ──
      IncidentReport(
        id: 'cv_026',
        category: IncidentCategory.pothole,
        title: 'Road pitting on Dome-Kwabenya road',
        description:
            'The Dome-Kwabenya road section near Atomic Junction has severe pitting across both lanes. The surface appears to have completely delaminated from the base. The road is being used heavily as a bypass for the Accra-Kumasi highway works.',
        latitude: 5.6712,
        longitude: -0.2001,
        imageUrl: 'https://picsum.photos/seed/cv_026/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(86),
        reporterName: 'Nana Ama Ofori',
        district: 'Ga East',
      ),
      // ── 27 ──
      IncidentReport(
        id: 'cv_027',
        category: IncidentCategory.waterLeak,
        title: 'Broken valve leaking at Haatso',
        description:
            'A water valve on the main distribution line at Haatso near the Catholic church is leaking. Water has been running along the roadside gutter for 5 days. The surrounding soil is waterlogged and is undermining the road base.',
        latitude: 5.6634,
        longitude: -0.1834,
        imageUrl: 'https://picsum.photos/seed/cv_027/400/300',
        status: IncidentStatus.resolved,
        timestamp: _daysAgo(83),
        reporterName: 'Kofi Danso',
        district: 'Ga East',
      ),
      // ── 28 ──
      IncidentReport(
        id: 'cv_028',
        category: IncidentCategory.roadDamage,
        title: 'Cracked road surface on Graphic Road',
        description:
            'Graphic Road between Accra Ring Road and the Daily Graphic junction has severe longitudinal cracking along both edges of the carriageway. The cracks are wide enough to catch motorcycle wheels. The road needs full rehabilitation.',
        latitude: 5.5542,
        longitude: -0.2078,
        imageUrl: 'https://picsum.photos/seed/cv_028/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(80),
        reporterName: 'Abena Duah',
        district: 'Korle Klottey',
      ),
      // ── 29 ──
      IncidentReport(
        id: 'cv_029',
        category: IncidentCategory.pothole,
        title: 'Pothole impeding school bus on Madina-Ritz road',
        description:
            'A large pothole on the Madina-Ritz road has been reported by three school bus drivers as causing damage to their vehicles. The school term is in session and children are at risk due to the violent jolting when the bus hits the hole.',
        latitude: 5.6845,
        longitude: -0.1689,
        imageUrl: 'https://picsum.photos/seed/cv_029/400/300',
        status: IncidentStatus.dispatched,
        timestamp: _daysAgo(77),
        reporterName: 'Yaw Turkson',
        district: 'Ga East',
      ),
      // ── 30 ──
      IncidentReport(
        id: 'cv_030',
        category: IncidentCategory.drainageBlockage,
        title: 'Culvert blocked at Agbogbloshie',
        description:
            'The culvert crossing under the road at the entrance to Agbogbloshie market is completely blocked by scrap metal, plastic and organic waste. Water during rains has nowhere to go and floods the market causing commercial losses daily.',
        latitude: 5.5456,
        longitude: -0.2245,
        imageUrl: 'https://picsum.photos/seed/cv_030/400/300',
        status: IncidentStatus.reviewed,
        timestamp: _daysAgo(74),
        reporterName: 'Abenaa Ansah',
        district: 'Korle Klottey',
      ),
      // ── 31 ──
      IncidentReport(
        id: 'cv_031',
        category: IncidentCategory.structuralLightFailure,
        title: 'Lights out on Nsawam Road at night',
        description:
            'The street lighting from Accra-Nsawam Road junction near Pokuase has been completely out for three weeks. The 2 km dark stretch has reportedly been a scene of multiple robberies targeting motorists. Community leaders have complained to no avail.',
        latitude: 5.7198,
        longitude: -0.2512,
        imageUrl: 'https://picsum.photos/seed/cv_031/400/300',
        status: IncidentStatus.dispatched,
        timestamp: _daysAgo(71),
        reporterName: 'Kwame Baffour',
        district: 'Ga East',
      ),
      // ── 32 ──
      IncidentReport(
        id: 'cv_032',
        category: IncidentCategory.waterLeak,
        title: 'Pipe joint leak at Mataheko',
        description:
            'A pipe joint failure at Mataheko has created a steady stream of water across the road for 4 days. Ghana Water Company trucks have come twice but have not resolved the issue. Residents say supply to the area is now intermittent.',
        latitude: 5.5234,
        longitude: -0.2634,
        imageUrl: 'https://picsum.photos/seed/cv_032/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(68),
        reporterName: 'Amerley Laryea',
        district: 'Ablekuma North',
      ),
      // ── 33 ──
      IncidentReport(
        id: 'cv_033',
        category: IncidentCategory.pothole,
        title: 'Pothole causing traffic chaos at Adenta roundabout',
        description:
            'A pothole directly on the Adenta roundabout has caused motorists to hesitate and create a bottleneck at this already busy junction. Peak-hour queues now extend back 1 km. The roundabout island kerb stones are also displaced.',
        latitude: 5.7101,
        longitude: -0.1534,
        imageUrl: 'https://picsum.photos/seed/cv_033/400/300',
        status: IncidentStatus.resolved,
        timestamp: _daysAgo(65),
        reporterName: 'Kwesi Gyimah',
        district: 'Ga East',
      ),
      // ── 34 ──
      IncidentReport(
        id: 'cv_034',
        category: IncidentCategory.waterLeak,
        title: 'Water seeping under road at Tesano',
        description:
            'Residents of Tesano near the Sacred Heart School have noticed the road surface bubbling and weeping with water. The groundwater seepage is caused by a sub-surface pipe failure. A large sinkhole appears to be forming beneath the road.',
        latitude: 5.5989,
        longitude: -0.2134,
        imageUrl: 'https://picsum.photos/seed/cv_034/400/300',
        status: IncidentStatus.dispatched,
        timestamp: _daysAgo(62),
        reporterName: 'Akosua Ofori',
        district: 'Ayawaso Central',
      ),
      // ── 35 ──
      IncidentReport(
        id: 'cv_035',
        category: IncidentCategory.pothole,
        title: 'Pothole at Weija road near tollbooth',
        description:
            'A substantial pothole has formed at the approach road to the Weija tollbooth. The heavy volume of traffic using this route to the western suburbs means it deteriorates rapidly. It has been reported before but only received superficial patching.',
        latitude: 5.5478,
        longitude: -0.3212,
        imageUrl: 'https://picsum.photos/seed/cv_035/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(59),
        reporterName: 'Serwah Amponsah',
        district: 'Ablekuma North',
      ),
      // ── 36 ──
      IncidentReport(
        id: 'cv_036',
        category: IncidentCategory.structuralLightFailure,
        title: 'Collapsed lamp post at Shiashie',
        description:
            'A lamp post on the main Shiashie road near the Goil filling station has fallen over, possibly due to vehicle impact. It is currently lying partially across the pavement and is a serious hazard for pedestrians and cyclists.',
        latitude: 5.6342,
        longitude: -0.1756,
        imageUrl: 'https://picsum.photos/seed/cv_036/400/300',
        status: IncidentStatus.reviewed,
        timestamp: _daysAgo(56),
        reporterName: 'Yaw Antwi',
        district: 'Ayawaso Central',
      ),
      // ── 37 ──
      IncidentReport(
        id: 'cv_037',
        category: IncidentCategory.pothole,
        title: 'Pothole endangering Kasoa road traffic',
        description:
            'On the Kasoa highway near the Mallam Junction flyover, two potholes in the fast lane are invisible at night and at highway speeds. Vehicles have been badly damaged. Media reports suggest a fatal accident risk is imminent.',
        latitude: 5.5612,
        longitude: -0.3301,
        imageUrl: 'https://picsum.photos/seed/cv_037/400/300',
        status: IncidentStatus.dispatched,
        timestamp: _daysAgo(53),
        reporterName: 'Nana Afia Adu',
        district: 'Ablekuma North',
      ),
      // ── 38 ──
      IncidentReport(
        id: 'cv_038',
        category: IncidentCategory.drainageBlockage,
        title: 'Drain overflowing at Roman Ridge',
        description:
            'The drain along the Roman Ridge access road overflows with the slightest rainfall, blocking access to the residential area. Residents with cars have to use an alternate route 4 km longer. The blockage is caused by compacted organic matter.',
        latitude: 5.5867,
        longitude: -0.1923,
        imageUrl: 'https://picsum.photos/seed/cv_038/400/300',
        status: IncidentStatus.resolved,
        timestamp: _daysAgo(50),
        reporterName: 'Kwamena Laryea',
        district: 'Korle Klottey',
      ),
      // ── 39 ──
      IncidentReport(
        id: 'cv_039',
        category: IncidentCategory.waterLeak,
        title: 'Cracked water main at Odorkor',
        description:
            'A water main has cracked along the Odorkor road near the Health Centre, releasing a steady flow of water for 7 days. The road surface has already started sinking in places. Supply to the Odorkor health centre has been reduced.',
        latitude: 5.5523,
        longitude: -0.2778,
        imageUrl: 'https://picsum.photos/seed/cv_039/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(47),
        reporterName: 'Adwoa Mensah',
        district: 'Ablekuma North',
      ),
      // ── 40 ──
      IncidentReport(
        id: 'cv_040',
        category: IncidentCategory.pothole,
        title: 'Pothole at Trade Fair overpass approach',
        description:
            'The approach to the Trade Fair overpass from the Labadi direction has developed a deep pothole that is nearly invisible when approaching at speed. Two motorcyclists have had accidents here in the past two weeks.',
        latitude: 5.5623,
        longitude: -0.1323,
        imageUrl: 'https://picsum.photos/seed/cv_040/400/300',
        status: IncidentStatus.resolved,
        timestamp: _daysAgo(44),
        reporterName: 'Ama Baidoo',
        district: 'Tema West',
      ),
      // ── 41 ──
      IncidentReport(
        id: 'cv_041',
        category: IncidentCategory.structuralLightFailure,
        title: 'Dark junction at Abofu crossroads',
        description:
            'The Abofu crossroads junction, which sees high pedestrian traffic especially in the evenings due to its proximity to a school, has been completely unlit for a month. Pedestrian near-misses are occurring regularly at night.',
        latitude: 5.6312,
        longitude: -0.2234,
        imageUrl: 'https://picsum.photos/seed/cv_041/400/300',
        status: IncidentStatus.dispatched,
        timestamp: _daysAgo(41),
        reporterName: 'Kwame Boafo',
        district: 'Okaikwei North',
      ),
      // ── 42 ──
      IncidentReport(
        id: 'cv_042',
        category: IncidentCategory.waterLeak,
        title: 'Meter box flooding on Labone road',
        description:
            'Multiple water meter boxes on Labone road near the National Service Secretariat are flooded and overflowing. A connection appears to have burst underground. The water company\'s emergency line has been called three times with no response.',
        latitude: 5.5723,
        longitude: -0.1812,
        imageUrl: 'https://picsum.photos/seed/cv_042/400/300',
        status: IncidentStatus.reviewed,
        timestamp: _daysAgo(38),
        reporterName: 'Akua Nyarko',
        district: 'Korle Klottey',
      ),
      // ── 43 ──
      IncidentReport(
        id: 'cv_043',
        category: IncidentCategory.pothole,
        title: 'Pothole on Nima road near Nima Highway',
        description:
            'A very deep pothole on the Nima road near the main Nima highway junction sits at the centre of a sharp corner. It is partially concealed by shadow at night and has caused 3 separate motorcycle falls in the past 10 days.',
        latitude: 5.5812,
        longitude: -0.2167,
        imageUrl: 'https://picsum.photos/seed/cv_043/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(35),
        reporterName: 'Kwabena Asante',
        district: 'Okaikwei North',
      ),
      // ── 44 ──
      IncidentReport(
        id: 'cv_044',
        category: IncidentCategory.roadDamage,
        title: 'Bridge surface deteriorating at Kpeshie lagoon',
        description:
            'The surface of the small bridge over the Kpeshie lagoon on the La Road has cracked severely. Sections of the road surface have been lost, exposing reinforcement bars. The bridge deck is at risk of complete failure under heavy loads.',
        latitude: 5.5634,
        longitude: -0.1568,
        imageUrl: 'https://picsum.photos/seed/cv_044/400/300',
        status: IncidentStatus.dispatched,
        timestamp: _daysAgo(32),
        reporterName: 'Esi Barimah',
        district: 'Korle Klottey',
      ),
      // ── 45 ──
      IncidentReport(
        id: 'cv_045',
        category: IncidentCategory.waterLeak,
        title: 'Leaking standpipe at Korle-Bu road',
        description:
            'A public standpipe near the Korle-Bu Teaching Hospital is continuously leaking at its base joint. Patients and visitors walking to the hospital are getting wet. The area around the pipe has eroded into a muddy hazard.',
        latitude: 5.5401,
        longitude: -0.2234,
        imageUrl: 'https://picsum.photos/seed/cv_045/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(29),
        reporterName: 'Ama Abankwah',
        district: 'Korle Klottey',
      ),
      // ── 46 ──
      IncidentReport(
        id: 'cv_046',
        category: IncidentCategory.pothole,
        title: 'Pothole at Nungua Barrier junction',
        description:
            'The Nungua Barrier junction has a large pothole at its northernmost exit that is causing taxis and trotros to bottleneck as they navigate around it. The waiting time at the junction during peak hours has doubled in the past month.',
        latitude: 5.5956,
        longitude: -0.0623,
        imageUrl: 'https://picsum.photos/seed/cv_046/400/300',
        status: IncidentStatus.resolved,
        timestamp: _daysAgo(26),
        reporterName: 'Kobina Brew',
        district: 'Tema West',
      ),
      // ── 47 ──
      IncidentReport(
        id: 'cv_047',
        category: IncidentCategory.drainageBlockage,
        title: 'Flooding at Kaneshie first light intersection',
        description:
            'The drainage at the Kaneshie First Light junction floods the road during every rainfall. The drain inlet is blocked by a combination of market waste and sandbags left by construction workers. Pedestrians wade through dirty water.',
        latitude: 5.5601,
        longitude: -0.2345,
        imageUrl: 'https://picsum.photos/seed/cv_047/400/300',
        status: IncidentStatus.reviewed,
        timestamp: _daysAgo(23),
        reporterName: 'Akosua Quansah',
        district: 'Ablekuma North',
      ),
      // ── 48 ──
      IncidentReport(
        id: 'cv_048',
        category: IncidentCategory.pothole,
        title: 'Pothole near Tema Community 7 school',
        description:
            'A significant pothole on the road leading to the Community 7 school in Tema causes school children to walk in the road to avoid muddy puddles. Parents have made multiple complaints to the local assembly with no action taken.',
        latitude: 5.6712,
        longitude: -0.0056,
        imageUrl: 'https://picsum.photos/seed/cv_048/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(20),
        reporterName: 'Kwame Koomson',
        district: 'Tema West',
      ),
      // ── 49 ──
      IncidentReport(
        id: 'cv_049',
        category: IncidentCategory.structuralLightFailure,
        title: 'Vandalised street lights at Sakumono',
        description:
            'Multiple street lights on the Sakumono estate road have been vandalised — cables stripped and bulbs smashed. The vandalism was reported to the police but no suspects have been found. The entire estate road is now dark at night.',
        latitude: 5.6234,
        longitude: -0.0312,
        imageUrl: 'https://picsum.photos/seed/cv_049/400/300',
        status: IncidentStatus.dispatched,
        timestamp: _daysAgo(17),
        reporterName: 'Akua Antwi',
        district: 'Tema West',
      ),
      // ── 50 ──
      IncidentReport(
        id: 'cv_050',
        category: IncidentCategory.pothole,
        title: 'Pothole on Haatso-Atomic road',
        description:
            'The Haatso-Atomic road has developed a wide and deep pothole directly in front of the Total filling station. The station\'s manager has already sent a complaint to the municipal assembly. Fuel tanker drivers are refusing to enter.',
        latitude: 5.6701,
        longitude: -0.1912,
        imageUrl: 'https://picsum.photos/seed/cv_050/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(14),
        reporterName: 'Aba Acquah',
        district: 'Ga East',
      ),
      // ── 51 ──
      IncidentReport(
        id: 'cv_051',
        category: IncidentCategory.waterLeak,
        title: 'Pipe fracture at East Legon A&C Mall area',
        description:
            'A large-diameter pipe has fractured near the A&C Mall in East Legon. The resulting water flow has carved a channel into the road surface. Road users are diverting onto mall property, disrupting shoppers and businesses.',
        latitude: 5.6523,
        longitude: -0.1745,
        imageUrl: 'https://picsum.photos/seed/cv_051/400/300',
        status: IncidentStatus.reviewed,
        timestamp: _daysAgo(11),
        reporterName: 'Kwesi Opoku',
        district: 'Ayawaso Central',
      ),
      // ── 52 ──
      IncidentReport(
        id: 'cv_052',
        category: IncidentCategory.pothole,
        title: 'Road breaking apart on Boundary Road, Tema',
        description:
            'The Boundary Road in Tema Industrial Area has multiple large potholes that are coalescing into one wide expanse of damaged road. The heavy trucks serving the industrial area are accelerating the deterioration. Emergency patching is needed now.',
        latitude: 5.6489,
        longitude: 0.0312,
        imageUrl: 'https://picsum.photos/seed/cv_052/400/300',
        status: IncidentStatus.dispatched,
        timestamp: _daysAgo(8),
        reporterName: 'Nana Kwame Osei',
        district: 'Tema West',
      ),
      // ── 53 ──
      IncidentReport(
        id: 'cv_053',
        category: IncidentCategory.drainageBlockage,
        title: 'Clogged drain causing mosquito breeding at Alajo',
        description:
            'An open drainage channel at Alajo running behind the main market has been clogged with solid waste for 2 months. Stagnant water has produced a large mosquito breeding site. Cases of malaria have risen in the past 4 weeks in the community.',
        latitude: 5.5734,
        longitude: -0.2134,
        imageUrl: 'https://picsum.photos/seed/cv_053/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(5),
        reporterName: 'Adwoa Bediako',
        district: 'Okaikwei North',
      ),
      // ── 54 ──
      IncidentReport(
        id: 'cv_054',
        category: IncidentCategory.roadDamage,
        title: 'Pothole and road edge collapse at Achimota Forest road',
        description:
            'The road edge along the Achimota Forest access road has collapsed following recent heavy rains, reducing the usable carriageway to a single lane. Sections of the drainage wall have also fallen onto the road surface. Urgent repair needed.',
        latitude: 5.6201,
        longitude: -0.2267,
        imageUrl: 'https://picsum.photos/seed/cv_054/400/300',
        status: IncidentStatus.resolved,
        timestamp: _daysAgo(3),
        reporterName: 'Kwame Sarpong',
        district: 'Ayawaso Central',
      ),
      // ── 55 ──
      IncidentReport(
        id: 'cv_055',
        category: IncidentCategory.structuralLightFailure,
        title: 'Street lights out near Labone estate entrance',
        description:
            'The decorative street lights at the main entrance of the Labone estate have been non-functional for 6 days. The estate has a large elderly population that relies on these lights for safe evening walks. The homeowners\' association has escalated to the city.',
        latitude: 5.5767,
        longitude: -0.1845,
        imageUrl: 'https://picsum.photos/seed/cv_055/400/300',
        status: IncidentStatus.submitted,
        timestamp: _daysAgo(1),
        reporterName: 'Abena Owusu',
        district: 'Korle Klottey',
      ),
    ];
  }
}
