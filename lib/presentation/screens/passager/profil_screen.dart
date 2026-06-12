import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/profile_service.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});
  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _profileService = ProfileService();

  // Infos controllers
  final _nomCtrl    = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _telCtrl    = TextEditingController();

  // Password controllers
  final _ancienPassCtrl  = TextEditingController();
  final _nouveauPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loadingInfos    = false;
  bool _loadingPassword = false;
  bool _obscureAncien   = true;
  bool _obscureNouveau  = true;
  bool _obscureConfirm  = true;
  int  _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerProfil();
    _nouveauPassCtrl.addListener(_evaluerMotDePasse);
  }

  void _evaluerMotDePasse() {
    final p = _nouveauPassCtrl.text;
    int force = 0;
    if (p.length >= 6)  force++;
    if (p.length >= 10) force++;
    if (p.contains(RegExp(r'[A-Z]'))) force++;
    if (p.contains(RegExp(r'[0-9]'))) force++;
    if (p.contains(RegExp(r'[!@#\$%^&*]'))) force++;
    setState(() => _passwordStrength = force.clamp(0, 4));
  }

  Future<void> _chargerProfil() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _nomCtrl.text    = user['nom']       ?? '';
      _prenomCtrl.text = user['prenom']    ?? '';
      _emailCtrl.text  = user['email']     ?? '';
      _telCtrl.text    = user['telephone'] ?? '';
    }
  }

  Future<void> _sauvegarderInfos() async {
    setState(() => _loadingInfos = true);
    try {
      final result = await _profileService.updateProfil(
        nom:       _nomCtrl.text.trim(),
        prenom:    _prenomCtrl.text.trim(),
        telephone: _telCtrl.text.trim(),
        email:     _emailCtrl.text.trim(),
      );
      if (!mounted) return;
      // Met à jour le provider
      context.read<AuthProvider>().updateCurrentUser(result['user']);
      _showSuccess('Profil mis à jour avec succès !');
    } catch (e) {
      _showError('Erreur : ${e.toString()}');
    }
    setState(() => _loadingInfos = false);
  }

  Future<void> _changerMotDePasse() async {
    if (_nouveauPassCtrl.text != _confirmPassCtrl.text) {
      _showError('Les mots de passe ne correspondent pas');
      return;
    }
    if (_nouveauPassCtrl.text.length < 6) {
      _showError('Minimum 6 caractères');
      return;
    }
    setState(() => _loadingPassword = true);
    try {
      await _profileService.changerMotDePasse(
        ancienPassword:  _ancienPassCtrl.text,
        nouveauPassword: _nouveauPassCtrl.text,
      );
      if (!mounted) return;
      _ancienPassCtrl.clear();
      _nouveauPassCtrl.clear();
      _confirmPassCtrl.clear();
      _showSuccess('Mot de passe modifié avec succès !');
    } catch (e) {
      _showError('Mot de passe actuel incorrect');
    }
    setState(() => _loadingPassword = false);
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg),
      ]),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
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

  void _confirmerSuppression() {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le compte ?',
            style: TextStyle(fontWeight: FontWeight.w800,
                color: AppColors.error)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'Cette action est irréversible. '
                  'Toutes vos données seront supprimées.',
              style: TextStyle(color: AppColors.textMedium,
                  fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: passCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirmez votre mot de passe',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler',
                  style: TextStyle(color: AppColors.textLight))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _profileService.supprimerCompte(passCtrl.text);
                if (!mounted) return;
                await context.read<AuthProvider>().logout();
                context.go('/login');
              } catch (e) {
                _showError('Mot de passe incorrect');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _ancienPassCtrl.dispose();
    _nouveauPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user   = context.watch<AuthProvider>().currentUser;
    final prenom = user?['prenom'] ?? '';
    final nom    = user?['nom'] ?? '';
    final role   = user?['role'] ?? 'passager';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Header
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
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
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              const Text('Mon Profil',
                  style: TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.w800)),
            ]),

            const SizedBox(height: 24),

            // Avatar
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 3),
                  ),
                  child: Center(
                    child: Text(
                      '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}',
                      style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text('$prenom $nom',
                style: const TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),

            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role == 'admin'
                    ? '🛡️ Administrateur'
                    : role == 'agent'
                    ? '🎫 Agent Terminal'
                    : '✈️ Passager',
                style: const TextStyle(color: Colors.white,
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 20),

            // Tabs
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
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Mes informations'),
                  Tab(text: 'Sécurité'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),

        // ── Contenu
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // ── Onglet infos
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
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
                      Row(children: [
                        Expanded(child: _ProfilField(
                          ctrl: _nomCtrl,
                          label: 'Nom',
                          icon: Icons.person_outline,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _ProfilField(
                          ctrl: _prenomCtrl,
                          label: 'Prénom',
                          icon: Icons.person_outline,
                        )),
                      ]),
                      const SizedBox(height: 14),
                      _ProfilField(
                        ctrl: _emailCtrl,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        type: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _ProfilField(
                        ctrl: _telCtrl,
                        label: 'Téléphone',
                        icon: Icons.phone_outlined,
                        type: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _loadingInfos
                                ? null : _sauvegarderInfos,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: _loadingInfos
                                ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.save_rounded,
                                color: Colors.white, size: 18),
                            label: Text(
                              _loadingInfos
                                  ? 'Sauvegarde...'
                                  : 'Sauvegarder',
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 20),

                  // Zone danger
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete_forever_rounded,
                            color: AppColors.error, size: 20),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Supprimer le compte',
                              style: TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error)),
                          Text('Action irréversible',
                              style: TextStyle(fontSize: 12,
                                  color: AppColors.textLight)),
                        ],
                      )),
                      GestureDetector(
                        onTap: _confirmerSuppression,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Supprimer',
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error)),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),

              // ── Onglet sécurité
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
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
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.lock_outline,
                                color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text('Changer le mot de passe',
                              style: TextStyle(fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark)),
                        ]),
                        const SizedBox(height: 20),

                        // Ancien mdp
                        _PasswordField(
                          ctrl:    _ancienPassCtrl,
                          label:   'Mot de passe actuel',
                          obscure: _obscureAncien,
                          onToggle: () => setState(
                                  () => _obscureAncien = !_obscureAncien),
                        ),
                        const SizedBox(height: 14),

                        // Nouveau mdp
                        _PasswordField(
                          ctrl:    _nouveauPassCtrl,
                          label:   'Nouveau mot de passe',
                          obscure: _obscureNouveau,
                          onToggle: () => setState(
                                  () => _obscureNouveau = !_obscureNouveau),
                        ),

                        // Indicateur force
                        if (_nouveauPassCtrl.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _PasswordStrengthIndicator(
                              strength: _passwordStrength),
                        ],

                        const SizedBox(height: 14),

                        // Confirmation mdp
                        _PasswordField(
                          ctrl:    _confirmPassCtrl,
                          label:   'Confirmer le mot de passe',
                          obscure: _obscureConfirm,
                          onToggle: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                          // Vérifie la correspondance
                          errorText: _confirmPassCtrl.text.isNotEmpty &&
                              _confirmPassCtrl.text != _nouveauPassCtrl.text
                              ? 'Les mots de passe ne correspondent pas'
                              : null,
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity, height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _loadingPassword
                                  ? null : _changerMotDePasse,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: _loadingPassword
                                  ? const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.lock_reset_rounded,
                                  color: Colors.white, size: 18),
                              label: Text(
                                _loadingPassword
                                    ? 'Modification...'
                                    : 'Modifier le mot de passe',
                                style: const TextStyle(color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Infos sécurité
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.1)),
                    ),
                    child: Column(children: [
                      _SecuriteItem(
                        icon: Icons.check_circle_rounded,
                        text: 'Minimum 6 caractères',
                        ok: _nouveauPassCtrl.text.length >= 6,
                      ),
                      _SecuriteItem(
                        icon: Icons.check_circle_rounded,
                        text: 'Au moins une majuscule',
                        ok: _nouveauPassCtrl.text.contains(
                            RegExp(r'[A-Z]')),
                      ),
                      _SecuriteItem(
                        icon: Icons.check_circle_rounded,
                        text: 'Au moins un chiffre',
                        ok: _nouveauPassCtrl.text.contains(
                            RegExp(r'[0-9]')),
                      ),
                      _SecuriteItem(
                        icon: Icons.check_circle_rounded,
                        text: 'Au moins un caractère spécial',
                        ok: _nouveauPassCtrl.text.contains(
                            RegExp(r'[!@#\$%^&*]')),
                      ),
                    ]),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Widgets communs
class _ProfilField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType type;

  const _ProfilField({required this.ctrl, required this.label,
    required this.icon, this.type = TextInputType.text});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: type,
    style: const TextStyle(fontSize: 14,
        fontWeight: FontWeight.w500, color: AppColors.textDark),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.accent, size: 16),
      ),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
            color: AppColors.accent, width: 2),
      ),
    ),
  );
}

class _PasswordField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? errorText;

  const _PasswordField({required this.ctrl, required this.label,
    required this.obscure, required this.onToggle,
    this.errorText});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    obscureText: obscure,
    style: const TextStyle(fontSize: 14,
        fontWeight: FontWeight.w500, color: AppColors.textDark),
    decoration: InputDecoration(
      labelText: label,
      errorText: errorText,
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.lock_outline,
            color: AppColors.primary, size: 16),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.textLight, size: 18,
        ),
        onPressed: onToggle,
      ),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
            color: AppColors.primary, width: 2),
      ),
    ),
  );
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final int strength;
  const _PasswordStrengthIndicator({required this.strength});

  Color get _color {
    if (strength <= 1) return AppColors.error;
    if (strength <= 2) return AppColors.warning;
    if (strength <= 3) return AppColors.accent;
    return AppColors.success;
  }

  String get _label {
    if (strength <= 1) return 'Très faible';
    if (strength <= 2) return 'Faible';
    if (strength <= 3) return 'Moyen';
    return 'Fort';
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: List.generate(4, (i) => Expanded(
        child: Container(
          height: 4,
          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
          decoration: BoxDecoration(
            color: i < strength ? _color : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ))),
      const SizedBox(height: 4),
      Text(_label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: _color)),
    ],
  );
}

class _SecuriteItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool ok;
  const _SecuriteItem({required this.icon, required this.text,
    required this.ok});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon,
          color: ok ? AppColors.success : AppColors.textLight,
          size: 16),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: ok ? AppColors.success : AppColors.textLight,
      )),
    ]),
  );
}