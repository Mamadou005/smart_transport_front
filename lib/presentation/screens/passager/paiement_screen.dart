import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/paiement_service.dart';

class PaiementScreen extends StatefulWidget {
  final int    reservationId;
  final double montant;
  final String origine;
  final String destination;

  const PaiementScreen({
    super.key,
    required this.reservationId,
    required this.montant,
    required this.origine,
    required this.destination,
  });

  @override
  State<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends State<PaiementScreen> {
  final _paiementService = PaiementService();
  final _telCtrl         = TextEditingController();
  String _methode        = 'wave';
  bool   _isLoading      = false;
  bool   _isPaid         = false;
  String? _reference;
  String? _instructions;

  Future<void> _initierPaiement() async {
    if (_telCtrl.text.trim().isEmpty && _methode != 'cash') {
      _showError('Entrez votre numéro de téléphone');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _paiementService.initierPaiement(
        reservationId: widget.reservationId,
        methode:       _methode,
        telephone:     _telCtrl.text.trim(),
      );
      setState(() {
        _reference    = result['reference'];
        _instructions = result['message'];
      });
      // ✅ Affiche dialog de confirmation
      _showConfirmationDialog();
    } catch (e) {
      _showError('Erreur : ${e.toString()}');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _confirmerPaiement() async {
    if (_reference == null) return;
    setState(() => _isLoading = true);
    try {
      await _paiementService.confirmerPaiement(_reference!);
      setState(() => _isPaid = true);
      _showSuccessDialog();
    } catch (e) {
      _showError('Erreur confirmation : ${e.toString()}');
    }
    setState(() => _isLoading = false);
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          Icon(_methodeIcon, color: _methodeColor, size: 24),
          const SizedBox(width: 10),
          Text(_methodeLabel,
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _methodeColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _methodeColor.withOpacity(0.2)),
            ),
            child: Column(children: [
              Text(_instructions ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14,
                      color: AppColors.textMedium, height: 1.5)),
              const SizedBox(height: 12),
              // Montant à payer
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _methodeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                    '${_formatMontant(widget.montant)} XOF',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.w900,
                    )),
              ),
              const SizedBox(height: 8),
              // Référence
              Text('Réf: $_reference',
                  style: TextStyle(fontSize: 11,
                      color: _methodeColor,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler',
                  style: TextStyle(color: AppColors.textLight))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmerPaiement();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _methodeColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("J'ai payé",
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        content: Column(mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 56)),
              const SizedBox(height: 16),
              const Text('Paiement réussi !',
                  style: TextStyle(fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              Text(
                  'Votre réservation ${widget.origine} → '
                      '${widget.destination} est confirmée.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13,
                      color: AppColors.textMedium, height: 1.4)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Réf: $_reference',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.success)),
              ),
            ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Voir mes voyages',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _formatMontant(double m) =>
      m.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]} ',
      );

  Color get _methodeColor {
    switch (_methode) {
      case 'wave':         return const Color(0xFF1DA1F2);
      case 'orange_money': return const Color(0xFFFF6600);
      default:             return AppColors.success;
    }
  }

  IconData get _methodeIcon {
    switch (_methode) {
      case 'wave':         return Icons.waves_rounded;
      case 'orange_money': return Icons.phone_android_rounded;
      default:             return Icons.money_rounded;
    }
  }

  String get _methodeLabel {
    switch (_methode) {
      case 'wave':         return 'Wave';
      case 'orange_money': return 'Orange Money';
      default:             return 'Espèces';
    }
  }

  @override
  void dispose() { _telCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_methodeColor.withOpacity(0.8), _methodeColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft:  Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
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
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Paiement',
                      style: TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('Sécurisé & rapide',
                      style: TextStyle(color: Colors.white70,
                          fontSize: 12)),
                ],
              ),
            ]),
            const SizedBox(height: 20),

            // Récapitulatif voyage
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.directions_bus_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${widget.origine} → ${widget.destination}',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const Text('Billet de voyage',
                        style: TextStyle(color: Colors.white70,
                            fontSize: 11)),
                  ],
                )),
                Text(
                    '${_formatMontant(widget.montant)} XOF',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w900,
                    )),
              ]),
            ),
          ]),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [

              // ── Choisir méthode de paiement
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Méthode de paiement',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
              ),
              const SizedBox(height: 14),

              // Wave
              _MethodeCard(
                label:       'Wave',
                description: 'Paiement rapide via Wave',
                icon:        Icons.waves_rounded,
                color:       const Color(0xFF1DA1F2),
                isSelected:  _methode == 'wave',
                logoWidget:  Image.asset(
                  'assets/images/wave.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.waves_rounded,
                      color: Color(0xFF1DA1F2), size: 28),
                ),
                onTap: () => setState(() => _methode = 'wave'),
              ),
              const SizedBox(height: 10),

              // Orange Money
              _MethodeCard(
                label:       'Orange Money',
                description: 'Paiement via Orange Money',
                icon:        Icons.phone_android_rounded,
                color:       const Color(0xFFFF6600),
                isSelected:  _methode == 'orange_money',
                logoWidget:  Image.asset(
                  'assets/images/orange_money.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.phone_android_rounded,
                      color: Color(0xFFFF6600), size: 28),
                ),
                onTap: () => setState(() => _methode = 'orange_money'),
              ),
              const SizedBox(height: 10),

              // Espèces
              _MethodeCard(
                label:       'Espèces',
                description: 'Payer en liquide à l\'agence',
                icon:        Icons.money_rounded,
                color:       AppColors.success,
                isSelected:  _methode == 'cash',
                logoWidget:  Container(
                  alignment: Alignment.center,
                  child: const Icon(Icons.money_rounded,
                      color: AppColors.success, size: 30),
                ),
                onTap: () => setState(() => _methode = 'cash'),
              ),
              const SizedBox(height: 24),

              // ── Numéro de téléphone (Wave / Orange Money)
              if (_methode != 'cash') ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Numéro de téléphone',
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12, offset: const Offset(0, 3),
                    )],
                  ),
                  child: TextField(
                    controller: _telCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: _methode == 'wave'
                          ? 'Ex: 77 000 00 00'
                          : 'Ex: 77 000 00 00',
                      hintStyle: TextStyle(
                          color: AppColors.textLight, fontSize: 14),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _methodeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.phone_rounded,
                            color: _methodeColor, size: 18),
                      ),
                      // Préfixe pays
                      prefix: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text('+221 ',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _methodeColor)),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.info_outline_rounded,
                      color: _methodeColor, size: 14),
                  const SizedBox(width: 6),
                  Text(
                      _methode == 'wave'
                          ? 'Numéro Wave enregistré sur votre compte'
                          : 'Numéro Orange Money actif',
                      style: TextStyle(fontSize: 11,
                          color: _methodeColor)),
                ]),
                const SizedBox(height: 24),
              ],

              // ── Récapitulatif final
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
                child: Column(children: [
                  const Text('Récapitulatif',
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  const SizedBox(height: 16),
                  _RecapRow(label: 'Trajet',
                      value: '${widget.origine} → ${widget.destination}'),
                  const Divider(height: 16),
                  _RecapRow(label: 'Méthode', value: _methodeLabel),
                  const Divider(height: 16),
                  _RecapRow(
                    label: 'Total à payer',
                    value: '${_formatMontant(widget.montant)} XOF',
                    isTotal: true,
                    color: _methodeColor,
                  ),
                ]),
              ),

              const SizedBox(height: 28),

              // ── Bouton payer
              SizedBox(
                width: double.infinity, height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _methodeColor,
                        _methodeColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(
                      color: _methodeColor.withOpacity(0.4),
                      blurRadius: 16, offset: const Offset(0, 6),
                    )],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _initierPaiement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    icon: _isLoading
                        ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : Icon(_methodeIcon, color: Colors.white),
                    label: Text(
                        _isLoading
                            ? 'Traitement...'
                            : 'Payer ${_formatMontant(widget.montant)} XOF',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Widgets
class _MethodeCard extends StatelessWidget {
  final String   label, description;
  final IconData icon;
  final Color    color;
  final bool     isSelected;
  final Widget   logoWidget; // ✅ Widget au lieu de String emoji
  final VoidCallback onTap;

  const _MethodeCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.logoWidget, // ✅
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? [BoxShadow(
          color: color.withOpacity(0.15),
          blurRadius: 12, offset: const Offset(0, 4),
        )] : [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Row(children: [
        // ✅ Container logo avec vrai image
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: color.withOpacity(0.15), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: logoWidget,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: isSelected ? color : AppColors.textDark,
            )),
            Text(description, style: const TextStyle(
                fontSize: 12, color: AppColors.textLight)),
          ],
        )),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: 2,
            ),
            color: isSelected ? color : Colors.transparent,
          ),
          child: isSelected
              ? const Icon(Icons.check_rounded,
              color: Colors.white, size: 14)
              : null,
        ),
      ]),
    ),
  );
}

class _RecapRow extends StatelessWidget {
  final String label, value;
  final bool isTotal;
  final Color? color;
  const _RecapRow({required this.label, required this.value,
    this.isTotal = false, this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(
        fontSize: isTotal ? 15 : 13,
        color: isTotal ? AppColors.textDark : AppColors.textLight,
        fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
      )),
      Text(value, style: TextStyle(
        fontSize: isTotal ? 16 : 13,
        fontWeight: FontWeight.w800,
        color: isTotal ? (color ?? AppColors.textDark) : AppColors.textDark,
      )),
    ],
  );
}