import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey            = GlobalKey<FormState>();
  final _nomController      = TextEditingController();
  final _prenomController   = TextEditingController();
  final _emailController    = TextEditingController();
  final _telController      = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure             = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.register(
      nom:       _nomController.text.trim(),
      prenom:    _prenomController.text.trim(),
      email:     _emailController.text.trim(),
      telephone: _telController.text.trim(),
      password:  _passwordController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage ?? 'Erreur lors de l\'inscription'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Stack(children: [
        // Fond dégradé haut
        Container(
          height: MediaQuery.of(context).size.height * 0.32,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(48),
              bottomRight: Radius.circular(48),
            ),
          ),
        ),
        // Cercles décoratifs
        Positioned(top: -30, right: -30,
            child: Container(width: 130, height: 130,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: AppColors.accent.withOpacity(0.12)))),
        Positioned(top: 50, right: 50,
            child: Container(width: 50, height: 50,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: AppColors.accent.withOpacity(0.2)))),

        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Bouton retour
                    GestureDetector(
                      onTap: () => context.go('/login'),
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
                    const SizedBox(height: 20),
                    const Text('Créer un\ncompte',
                        style: TextStyle(
                          fontSize: 32, fontWeight: FontWeight.w800,
                          color: Colors.white, height: 1.15,
                          letterSpacing: -0.5,
                        )),
                    const SizedBox(height: 6),
                    Text('Rejoignez Smart Transport',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7))),
                    const SizedBox(height: 32),

                    // Carte formulaire
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.12),
                            blurRadius: 40, offset: const Offset(0, 16),
                          )
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(children: [
                          // Nom & Prénom côte à côte
                          Row(children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _nomController,
                                label: 'Nom',
                                hint: 'Diallo',
                                prefixIcon: Icons.person_outline,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Requis' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                controller: _prenomController,
                                label: 'Prénom',
                                hint: 'Mamadou',
                                prefixIcon: Icons.person_outline,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Requis' : null,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _emailController,
                            label: 'Adresse email',
                            hint: 'exemple@email.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email requis';
                              if (!v.contains('@')) return 'Email invalide';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _telController,
                            label: 'Téléphone',
                            hint: '+221 77 000 00 00',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Téléphone requis' : null,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Mot de passe',
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscure,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textLight, size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Mot de passe requis';
                              if (v.length < 6) return 'Minimum 6 caractères';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          // Indicateur force mot de passe
                          _PasswordStrengthBar(
                              password: _passwordController.text),
                          const SizedBox(height: 24),
                          CustomButton(
                            label: 'Créer mon compte',
                            isLoading: auth.isLoading,
                            onPressed: _handleRegister,
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: 'Déjà un compte ?  ',
                          style: const TextStyle(
                              color: AppColors.textMedium, fontSize: 14),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => context.go('/login'),
                                child: const Text('Se connecter',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    )),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// Indicateur de force du mot de passe
class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  const _PasswordStrengthBar({required this.password});

  int get _strength {
    if (password.length < 4) return 0;
    if (password.length < 6) return 1;
    if (password.length < 8) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['', 'Faible', 'Moyen', 'Fort'];
    final colors = [
      Colors.transparent,
      AppColors.error,
      AppColors.warning,
      AppColors.success,
    ];
    final s = _strength;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: List.generate(3, (i) => Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
            decoration: BoxDecoration(
              color: i < s ? colors[s] : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ))),
        if (s > 0) ...[
          const SizedBox(height: 4),
          Text(labels[s],
              style: TextStyle(fontSize: 11,
                  color: colors[s], fontWeight: FontWeight.w600)),
        ]
      ],
    );
  }
}