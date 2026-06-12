import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey          = GlobalKey<FormState>();
  final _emailController  = TextEditingController();
  final _passController   = TextEditingController();
  bool _obscure           = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(
        _emailController.text.trim(), _passController.text.trim());
    if (!mounted) return;
    if (ok) {
      switch (auth.userRole) {
        case 'admin':  context.go('/dashboard'); break;
        case 'agent':  context.go('/agent');     break;
        default:       context.go('/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage ?? 'Erreur de connexion'),
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
        // ── Fond dégradé
        Container(
          height: MediaQuery.of(context).size.height * 0.45,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(48),
              bottomRight: Radius.circular(48),
            ),
          ),
        ),
        // ── Cercles décoratifs
        Positioned(top: -40, right: -40,
            child: Container(width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.12),
                ))),
        Positioned(top: 60, right: 40,
            child: Container(width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.2),
                ))),
        // ── Contenu principal
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
                    const SizedBox(height: 32),
                    // Logo
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1.5),
                      ),
                      child: const Icon(Icons.directions_bus_rounded,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 20),
                    const Text('Smart\nTransport',
                        style: TextStyle(
                          fontSize: 36, fontWeight: FontWeight.w800,
                          color: Colors.white, height: 1.1, letterSpacing: -0.5,
                        )),
                    const SizedBox(height: 6),
                    Text('Traçabilité intelligente des voyages',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 0.3)),
                    const SizedBox(height: 48),
                    // ── Carte formulaire
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Connexion',
                                style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                )),
                            const SizedBox(height: 4),
                            Text('Accédez à votre espace personnel',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.textLight)),
                            const SizedBox(height: 24),
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
                              controller: _passController,
                              label: 'Mot de passe',
                              hint: '••••••••',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscure,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_off_outlined
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
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero),
                                child: const Text('Mot de passe oublié ?',
                                    style: TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              label: 'Se connecter',
                              isLoading: auth.isLoading,
                              onPressed: _handleLogin,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Lien inscription
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: 'Pas encore de compte ?  ',
                          style: const TextStyle(
                              color: AppColors.textMedium, fontSize: 14),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => context.go('/register'),
                                child: const Text('S\'inscrire',
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
                    const SizedBox(height: 24),
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