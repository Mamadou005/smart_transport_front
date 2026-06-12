import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/bagage_model.dart';
import '../../../data/models/reservation_model.dart';
import '../../../data/providers/bagage_provider.dart';

class BagageSuiviScreen extends StatefulWidget {
  const BagageSuiviScreen({super.key});
  @override
  State<BagageSuiviScreen> createState() => _BagageSuiviScreenState();
}

class _BagageSuiviScreenState extends State<BagageSuiviScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<BagageProvider>();
      p.chargerMesBagages();
      p.chargerReservations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
          child: Column(children: [
            Row(children: [
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mes Bagages',
                      style: TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('Suivi en temps réel',
                      style: TextStyle(color: Colors.white70,
                          fontSize: 12)),
                ],
              ),
            ]),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: AppColors.accent,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Mes bagages'),
                  Tab(text: 'Enregistrer'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _ListeBagagesTab(),
              _EnregistrerBagageTab(),
            ],
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════
//  ONGLET LISTE BAGAGES
// ════════════════════════════════
class _ListeBagagesTab extends StatelessWidget {
  const _ListeBagagesTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BagageProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(
          color: AppColors.accent));
    }

    if (provider.bagages.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.luggage_outlined,
                    color: AppColors.accent, size: 48)),
            const SizedBox(height: 16),
            const Text('Aucun bagage enregistré',
                style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 6),
            const Text('Enregistrez votre premier bagage',
                style: TextStyle(fontSize: 13,
                    color: AppColors.textLight)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => context.read<BagageProvider>().chargerMesBagages(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: provider.bagages.length,
        itemBuilder: (_, i) =>
            _BagageCard(bagage: provider.bagages[i]),
      ),
    );
  }
}

// ════════════════════════════════
//  CARTE BAGAGE ✅ avec flutter_map
// ════════════════════════════════
class _BagageCard extends StatelessWidget {
  final BagageModel bagage;
  const _BagageCard({required this.bagage});

  Color get _statutColor {
    switch (bagage.statut) {
      case 'enregistre': return AppColors.primary;
      case 'en_transit': return AppColors.warning;
      case 'arrive':     return AppColors.success;
      case 'perdu':      return AppColors.error;
      case 'recupere':   return AppColors.accent;
      default:           return AppColors.textLight;
    }
  }

  IconData get _statutIcon {
    switch (bagage.statut) {
      case 'enregistre': return Icons.inventory_2_rounded;
      case 'en_transit': return Icons.local_shipping_rounded;
      case 'arrive':     return Icons.check_circle_rounded;
      case 'perdu':      return Icons.help_rounded;
      case 'recupere':   return Icons.celebration_rounded;
      default:           return Icons.luggage_rounded;
    }
  }

  String get _statutLabel {
    switch (bagage.statut) {
      case 'enregistre': return 'Enregistré';
      case 'en_transit': return 'En transit';
      case 'arrive':     return 'Arrivé';
      case 'perdu':      return 'Perdu';
      case 'recupere':   return 'Récupéré';
      default:           return bagage.statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation  = bagage.derniereLocalisation != null;
    final lat = bagage.derniereLocalisation?.latitude  ?? 14.6937;
    final lng = bagage.derniereLocalisation?.longitude ?? -17.4441;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 16, offset: const Offset(0, 4),
        )],
      ),
      child: Column(children: [
        // Header statut
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _statutColor.withOpacity(0.06),
            borderRadius: const BorderRadius.only(
              topLeft:  Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _statutColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_statutIcon,
                    color: _statutColor, size: 16)),
            const SizedBox(width: 10),
            Text(_statutLabel,
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _statutColor)),
            const Spacer(),
            Text('${bagage.poids} kg',
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMedium)),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bagage.description,
                            style: const TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                        const SizedBox(height: 4),
                        Text(bagage.codeQr,
                            style: const TextStyle(fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ]),
                  GestureDetector(
                    onTap: () => _showQrDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0)),
                      ),
                      child: QrImageView(
                        data: bagage.codeQr,
                        version: QrVersions.auto,
                        size: 52,
                      ),
                    ),
                  ),
                ]),

            if (bagage.voyageOrigine != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.route_rounded,
                    color: AppColors.textLight, size: 14),
                const SizedBox(width: 6),
                Text(
                    '${bagage.voyageOrigine} → ${bagage.voyageDestination}',
                    style: const TextStyle(fontSize: 12,
                        color: AppColors.textMedium,
                        fontWeight: FontWeight.w500)),
              ]),
            ],

            const SizedBox(height: 12),

            // ✅ flutter_map — OpenStreetMap
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasLocation
                      ? AppColors.accent.withOpacity(0.3)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(children: [
                // Header carte
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: hasLocation
                              ? AppColors.accent.withOpacity(0.1)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                            hasLocation
                                ? Icons.location_on_rounded
                                : Icons.location_off_outlined,
                            color: hasLocation
                                ? AppColors.accent : AppColors.textLight,
                            size: 16)),
                    const SizedBox(width: 8),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            hasLocation
                                ? 'Position actuelle du bagage'
                                : 'Position GPS non disponible',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: hasLocation
                                    ? AppColors.accent
                                    : AppColors.textLight)),
                        if (hasLocation)
                          Text(
                              'Lat: ${lat.toStringAsFixed(4)}, '
                                  'Lng: ${lng.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 10,
                                  color: AppColors.textLight)),
                      ],
                    )),
                    // Bouton plein écran
                    if (hasLocation)
                      GestureDetector(
                        onTap: () => _ouvrirCartePleinEcran(
                            context, lat, lng),
                        child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                                Icons.fullscreen_rounded,
                                color: AppColors.accent, size: 16)),
                      ),
                  ]),
                ),

                // ✅ Carte OpenStreetMap via flutter_map
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft:  Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  child: SizedBox(
                    height: 180,
                    child: hasLocation
                        ? FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat, lng),
                        initialZoom:   14,
                        interactionOptions:
                        const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        // ✅ Tuiles OpenStreetMap
                        TileLayer(
                          urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                          'com.example.smart_transport',
                        ),
                        // ✅ Marqueur bagage
                        MarkerLayer(markers: [
                          Marker(
                            point: LatLng(lat, lng),
                            width: 48,
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _statutColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white,
                                    width: 3),
                                boxShadow: [BoxShadow(
                                  color: _statutColor
                                      .withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )],
                              ),
                              child: Icon(_statutIcon,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ]),
                      ],
                    )
                    // Placeholder si pas de GPS
                        : Container(
                      color: const Color(0xFFF5F5F5),
                      child: Center(
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined,
                                color: AppColors.textLight
                                    .withOpacity(0.4),
                                size: 40),
                            const SizedBox(height: 8),
                            const Text(
                                'Aucune position GPS enregistrée',
                                style: TextStyle(fontSize: 12,
                                    color: AppColors.textLight)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 16),
            _StatutProgressBar(statut: bagage.statut),
          ]),
        ),
      ]),
    );
  }

  void _ouvrirCartePleinEcran(
      BuildContext context, double lat, double lng) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CarteFullScreen(
          bagage:      bagage,
          lat:         lat,
          lng:         lng,
          statutLabel: _statutLabel,
          statutColor: _statutColor,
          statutIcon:  _statutIcon,
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(bagage.description,
                style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text(bagage.codeQr,
                style: const TextStyle(fontSize: 12,
                    color: AppColors.accent)),
            const SizedBox(height: 20),
            QrImageView(
              data: bagage.codeQr,
              version: QrVersions.auto,
              size: 220,
            ),
            const SizedBox(height: 16),
            Text('Poids : ${bagage.poids} kg',
                style: const TextStyle(fontSize: 13,
                    color: AppColors.textMedium)),
          ]),
        ),
      ),
    );
  }
}

// ════════════════════════════════
//  CARTE PLEIN ÉCRAN ✅ flutter_map
// ════════════════════════════════
class _CarteFullScreen extends StatefulWidget {
  final BagageModel bagage;
  final double      lat, lng;
  final String      statutLabel;
  final Color       statutColor;
  final IconData    statutIcon;

  const _CarteFullScreen({
    required this.bagage,
    required this.lat,
    required this.lng,
    required this.statutLabel,
    required this.statutColor,
    required this.statutIcon,
  });

  @override
  State<_CarteFullScreen> createState() => _CarteFullScreenState();
}

class _CarteFullScreenState extends State<_CarteFullScreen> {
  final MapController _mapCtrl = MapController();
  Position? _maPosition;
  bool _loadingGPS = false;

  @override
  void initState() {
    super.initState();
    // Pas de GPS sur web
    if (!kIsWeb) _obtenirMaPosition();
  }

  Future<void> _obtenirMaPosition() async {
    setState(() => _loadingGPS = true);
    try {
      bool actif = await Geolocator.isLocationServiceEnabled();
      if (!actif) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _maPosition = pos);
    } catch (_) {}
    if (mounted) setState(() => _loadingGPS = false);
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      // ✅ Marqueur bagage
      Marker(
        point: LatLng(widget.lat, widget.lng),
        width: 56, height: 56,
        child: Column(children: [
          Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: widget.statutColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(
                  color: widget.statutColor.withOpacity(0.4),
                  blurRadius: 10, offset: const Offset(0, 4),
                )],
              ),
              child: Icon(widget.statutIcon,
                  color: Colors.white, size: 22)),
        ]),
      ),
    ];

    // ✅ Marqueur ma position (mobile uniquement)
    if (_maPosition != null) {
      markers.add(Marker(
        point: LatLng(
            _maPosition!.latitude, _maPosition!.longitude),
        width: 44, height: 44,
        child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 10, offset: const Offset(0, 4),
              )],
            ),
            child: const Icon(Icons.person_pin_circle_rounded,
                color: Colors.white, size: 22)),
      ));
    }

    return Scaffold(
      body: Stack(children: [
        // ✅ Carte OpenStreetMap plein écran
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: LatLng(widget.lat, widget.lng),
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.smart_transport',
            ),
            MarkerLayer(markers: markers),
          ],
        ),

        // ✅ Header transparent
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 8,
                16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textDark, size: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.bagage.description,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  Text(widget.bagage.codeQr,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.statutColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(widget.statutLabel,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),

        // ✅ Boutons flottants droite
        Positioned(
          right: 16, bottom: 130,
          child: Column(children: [
            // Centrer sur bagage
            _FabRond(
              icon: Icons.luggage_rounded,
              color: widget.statutColor,
              tooltip: 'Centrer sur le bagage',
              onTap: () => _mapCtrl.move(
                  LatLng(widget.lat, widget.lng), 15),
            ),
            const SizedBox(height: 10),
            // Ma position (mobile uniquement)
            if (!kIsWeb)
              _FabRond(
                icon: _loadingGPS
                    ? Icons.hourglass_empty_rounded
                    : Icons.my_location_rounded,
                color: AppColors.primary,
                tooltip: 'Ma position',
                onTap: _loadingGPS ? null : () async {
                  await _obtenirMaPosition();
                  if (_maPosition != null) {
                    _mapCtrl.move(
                      LatLng(_maPosition!.latitude,
                          _maPosition!.longitude),
                      15,
                    );
                  }
                },
              ),
            const SizedBox(height: 10),
            // Zoom +
            _FabRond(
              icon: Icons.add_rounded,
              color: AppColors.textMedium,
              tooltip: 'Zoom +',
              onTap: () => _mapCtrl.move(
                  _mapCtrl.camera.center,
                  _mapCtrl.camera.zoom + 1),
            ),
            const SizedBox(height: 6),
            // Zoom -
            _FabRond(
              icon: Icons.remove_rounded,
              color: AppColors.textMedium,
              tooltip: 'Zoom -',
              onTap: () => _mapCtrl.move(
                  _mapCtrl.camera.center,
                  _mapCtrl.camera.zoom - 1),
            ),
          ]),
        ),

        // ✅ Info card en bas
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20,
                MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24)),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20, offset: const Offset(0, -4),
              )],
            ),
            child: Column(mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 14),
                  Row(children: [
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.statutColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.statutIcon,
                            color: widget.statutColor, size: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.bagage.description,
                            style: const TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark)),
                        Text(
                            'Lat: ${widget.lat.toStringAsFixed(5)}, '
                                'Lng: ${widget.lng.toStringAsFixed(5)}',
                            style: const TextStyle(fontSize: 11,
                                color: AppColors.textLight)),
                      ],
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.statutColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${widget.bagage.poids} kg',
                          style: TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: widget.statutColor)),
                    ),
                  ]),

                  // Attribution OpenStreetMap (obligatoire)
                  const SizedBox(height: 8),
                  Text('© OpenStreetMap contributors',
                      style: TextStyle(fontSize: 9,
                          color: AppColors.textLight.withOpacity(0.6))),
                ]),
          ),
        ),
      ]),
    );
  }
}

class _FabRond extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       tooltip;
  final VoidCallback? onTap;
  const _FabRond({required this.icon, required this.color,
    required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Tooltip(
      message: tooltip,
      child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8, offset: const Offset(0, 3),
            )],
          ),
          child: Icon(icon, color: color, size: 20)),
    ),
  );
}

// ════════════════════════════════
//  BARRE PROGRESSION STATUT
// ════════════════════════════════
class _StatutProgressBar extends StatelessWidget {
  final String statut;
  const _StatutProgressBar({required this.statut});

  int get _step {
    switch (statut) {
      case 'enregistre': return 0;
      case 'en_transit': return 1;
      case 'arrive':     return 2;
      case 'recupere':   return 3;
      default:           return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (statut == 'perdu') {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_rounded,
                  color: AppColors.error, size: 16),
              const SizedBox(width: 8),
              const Text('Bagage signalé comme perdu',
                  style: TextStyle(fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w700)),
            ]),
      );
    }

    final steps = ['Enregistré', 'En transit', 'Arrivé', 'Récupéré'];
    final step  = _step;

    return Row(
      children: List.generate(steps.length, (i) {
        final isActive  = i <= step;
        final isCurrent = i == step;
        return Expanded(
          child: Row(children: [
            Column(children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppColors.accent : const Color(0xFFE2E8F0),
                  border: isCurrent
                      ? Border.all(
                      color: AppColors.accent, width: 2)
                      : null,
                ),
                child: isActive
                    ? const Icon(Icons.check,
                    color: Colors.white, size: 12)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(steps[i],
                  style: TextStyle(fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppColors.accent : AppColors.textLight)),
            ]),
            if (i < steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  color: i < step
                      ? AppColors.accent : const Color(0xFFE2E8F0),
                ),
              ),
          ]),
        );
      }),
    );
  }
}

// ════════════════════════════════
//  ONGLET ENREGISTRER BAGAGE
// ════════════════════════════════
class _EnregistrerBagageTab extends StatefulWidget {
  const _EnregistrerBagageTab();
  @override
  State<_EnregistrerBagageTab> createState() =>
      _EnregistrerBagageTabState();
}

class _EnregistrerBagageTabState extends State<_EnregistrerBagageTab> {
  final _formKey   = GlobalKey<FormState>();
  final _descCtrl  = TextEditingController();
  final _poidsCtrl = TextEditingController();
  ReservationModel? _selectedReservation;

  @override
  void dispose() {
    _descCtrl.dispose();
    _poidsCtrl.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedReservation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez sélectionner une réservation'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final provider = context.read<BagageProvider>();
    final bagage   = await provider.enregistrerBagage(
      reservationId: _selectedReservation!.id,
      poids:         double.parse(_poidsCtrl.text),
      description:   _descCtrl.text.isEmpty
          ? 'Bagage' : _descCtrl.text,
    );

    if (!mounted) return;
    if (bagage != null) {
      _showSuccessDialog(bagage);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.errorMessage ?? 'Erreur'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  void _showSuccessDialog(bagage) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.luggage_rounded,
                    color: AppColors.success, size: 40)),
            const SizedBox(height: 16),
            const Text('Bagage enregistré !',
                style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text('Code : ${bagage.codeQr}',
                style: const TextStyle(fontSize: 13,
                    color: AppColors.textMedium)),
            const SizedBox(height: 16),
            QrImageView(
              data: bagage.codeQr,
              version: QrVersions.auto,
              size: 160,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Parfait !',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BagageProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(children: [
          // Sélection réservation
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16, offset: const Offset(0, 4),
              )],
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rattacher à une réservation',
                      style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  if (provider.reservations.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.warning, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(child: Text(
                          'Aucune réservation. '
                              'Faites d\'abord une réservation.',
                          style: TextStyle(fontSize: 12,
                              color: AppColors.warning),
                        )),
                      ]),
                    )
                  else
                    ...provider.reservations
                        .where((r) => r.statut == 'confirmee')
                        .map((r) => GestureDetector(
                      onTap: () => setState(
                              () => _selectedReservation = r),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedReservation?.id == r.id
                              ? AppColors.accent.withOpacity(0.08)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedReservation?.id == r.id
                                ? AppColors.accent
                                : const Color(0xFFE2E8F0),
                            width: _selectedReservation?.id == r.id
                                ? 2 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Icon(Icons.confirmation_num_rounded,
                              color: _selectedReservation?.id == r.id
                                  ? AppColors.accent : AppColors.textLight,
                              size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.codeQr,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedReservation?.id == r.id
                                          ? AppColors.accent
                                          : AppColors.textDark)),
                              if (r.voyage != null)
                                Text(
                                    '${r.voyage!.origine} → '
                                        '${r.voyage!.destination}',
                                    style: const TextStyle(fontSize: 11,
                                        color: AppColors.textLight)),
                            ],
                          )),
                          if (_selectedReservation?.id == r.id)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.accent, size: 18),
                        ]),
                      ),
                    )),
                ]),
          ),

          const SizedBox(height: 16),

          // Formulaire bagage
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16, offset: const Offset(0, 4),
              )],
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informations du bagage',
                      style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Ex: Valise bleue, sac à dos...',
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.luggage_rounded,
                            color: AppColors.accent, size: 18),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _poidsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Poids (kg)',
                      hintText: 'Ex: 23.5',
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.monitor_weight_outlined,
                            color: AppColors.accentOrange, size: 18),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Poids requis';
                      if (double.tryParse(v) == null)
                        return 'Poids invalide';
                      return null;
                    },
                  ),
                ]),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity, height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                  color: AppColors.accent.withOpacity(0.35),
                  blurRadius: 16, offset: const Offset(0, 6),
                )],
              ),
              child: ElevatedButton.icon(
                onPressed: provider.isLoading ? null : _enregistrer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: provider.isLoading
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.luggage_rounded,
                    color: Colors.white),
                label: Text(
                  provider.isLoading
                      ? 'Enregistrement...'
                      : 'Enregistrer le bagage',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}