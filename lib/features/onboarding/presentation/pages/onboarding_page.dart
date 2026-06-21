import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nanei/core/routes/app_router.dart';

// ─── Illustrations SVG inline ───────────────────────────────────────────────

const _svgEnvoi = '''
<svg viewBox="0 0 340 300" xmlns="http://www.w3.org/2000/svg">
  <!-- Fond dégradé -->
  <defs>
    <radialGradient id="bg1" cx="50%" cy="40%" r="55%">
      <stop offset="0%" stop-color="#FFF3E8"/>
      <stop offset="100%" stop-color="#FFECD5"/>
    </radialGradient>
    <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="8" stdDeviation="10" flood-color="#FF7A00" flood-opacity="0.18"/>
    </filter>
  </defs>
  <ellipse cx="170" cy="150" rx="155" ry="140" fill="url(#bg1)"/>

  <!-- Boîte colis principale -->
  <g filter="url(#shadow)">
    <rect x="80" y="100" width="180" height="130" rx="14" fill="#FF7A00"/>
    <rect x="80" y="100" width="180" height="52" rx="14" fill="#E86E00"/>
    <rect x="80" y="138" width="180" height="14" fill="#E86E00"/>
    <!-- Ruban horizontal -->
    <rect x="158" y="100" width="24" height="130" rx="0" fill="#E06300" opacity="0.6"/>
    <!-- Ruban vertical -->
    <rect x="80" y="145" width="180" height="16" rx="0" fill="#E06300" opacity="0.6"/>
    <!-- Nœud -->
    <circle cx="170" cy="153" r="14" fill="#FF9A40"/>
    <circle cx="170" cy="153" r="8" fill="#FF7A00"/>
    <!-- Étoile sur nœud -->
    <circle cx="170" cy="153" r="4" fill="white" opacity="0.7"/>
  </g>

  <!-- Étiquette -->
  <g transform="translate(94,175)">
    <rect width="90" height="44" rx="8" fill="white" opacity="0.92"/>
    <rect x="8" y="10" width="55" height="5" rx="2.5" fill="#FFD5A8"/>
    <rect x="8" y="20" width="40" height="4" rx="2" fill="#FFD5A8"/>
    <rect x="8" y="29" width="48" height="4" rx="2" fill="#FFD5A8"/>
  </g>

  <!-- Avion -->
  <g transform="translate(228,60) rotate(-20)">
    <ellipse cx="0" cy="0" rx="28" ry="10" fill="white" opacity="0.95"/>
    <polygon points="-10,0 10,-14 12,0" fill="white" opacity="0.95"/>
    <polygon points="-8,2 8,12 10,2" fill="#FFD0A0"/>
    <ellipse cx="14" cy="0" rx="7" ry="3.5" fill="#FFD0A0"/>
    <!-- Hublot -->
    <circle cx="-2" cy="-2" r="2.5" fill="#FFB060"/>
    <circle cx="6" cy="-2" r="2.5" fill="#FFB060"/>
  </g>

  <!-- Points de trajectoire -->
  <circle cx="205" cy="72" r="3" fill="#FF7A00" opacity="0.5"/>
  <circle cx="220" cy="62" r="2" fill="#FF7A00" opacity="0.4"/>
  <circle cx="235" cy="55" r="1.5" fill="#FF7A00" opacity="0.3"/>

  <!-- Étoiles décoratives -->
  <circle cx="52" cy="80" r="4" fill="#FF7A00" opacity="0.25"/>
  <circle cx="290" cy="180" r="5" fill="#FF7A00" opacity="0.2"/>
  <circle cx="64" cy="200" r="3" fill="#FF7A00" opacity="0.15"/>
  <circle cx="300" cy="100" r="3" fill="#FF7A00" opacity="0.2"/>

  <!-- Confettis -->
  <rect x="40" y="120" width="8" height="8" rx="2" fill="#FFB060" opacity="0.5" transform="rotate(20,44,124)"/>
  <rect x="285" y="200" width="7" height="7" rx="2" fill="#FF7A00" opacity="0.4" transform="rotate(-15,288,203)"/>
  <rect x="55" y="230" width="6" height="6" rx="1.5" fill="#FFCF9C" opacity="0.6" transform="rotate(35,58,233)"/>
</svg>
''';

const _svgSuivi = '''
<svg viewBox="0 0 340 300" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="bg2" cx="50%" cy="45%" r="55%">
      <stop offset="0%" stop-color="#FFF3E8"/>
      <stop offset="100%" stop-color="#FFECD5"/>
    </radialGradient>
    <filter id="sh2" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="8" stdDeviation="12" flood-color="#FF7A00" flood-opacity="0.15"/>
    </filter>
  </defs>
  <ellipse cx="170" cy="150" rx="155" ry="140" fill="url(#bg2)"/>

  <!-- Téléphone -->
  <g filter="url(#sh2)">
    <rect x="115" y="60" width="110" height="190" rx="22" fill="white"/>
    <rect x="119" y="64" width="102" height="182" rx="19" fill="#1A1A2E"/>
    <!-- Encoche -->
    <rect x="150" y="66" width="40" height="8" rx="4" fill="white" opacity="0.15"/>
    <!-- Écran carte -->
    <rect x="128" y="82" width="84" height="140" rx="10" fill="#0F1320"/>
    <!-- Carte map fond -->
    <rect x="128" y="82" width="84" height="95" rx="10" fill="#1E2D4A"/>
    <!-- Routes sur map -->
    <path d="M130 130 Q160 110 180 125 Q200 140 210 120" stroke="#FF7A00" stroke-width="2.5" fill="none" opacity="0.7"/>
    <path d="M135 150 Q155 140 175 148 Q195 155 208 145" stroke="#6B8CFF" stroke-width="1.5" fill="none" opacity="0.5"/>
    <!-- Point de localisation -->
    <circle cx="178" cy="122" r="7" fill="#FF7A00"/>
    <circle cx="178" cy="122" r="4" fill="white"/>
    <circle cx="178" cy="122" r="2" fill="#FF7A00"/>
    <!-- Pulse animation (statique) -->
    <circle cx="178" cy="122" r="12" fill="#FF7A00" opacity="0.15"/>
    <circle cx="178" cy="122" r="18" fill="#FF7A00" opacity="0.07"/>
    <!-- Notifications sur l'écran -->
    <rect x="130" y="183" width="80" height="18" rx="6" fill="#FF7A00" opacity="0.9"/>
    <rect x="137" y="188" width="45" height="3" rx="1.5" fill="white" opacity="0.9"/>
    <rect x="137" y="194" width="30" height="2.5" rx="1.25" fill="white" opacity="0.6"/>
    <circle cx="198" cy="192" r="5" fill="white" opacity="0.2"/>
    <!-- Barre inférieure -->
    <rect x="128" y="207" width="84" height="15" rx="5" fill="#1E2D4A" opacity="0.8"/>
    <rect x="155" y="211" width="30" height="7" rx="3.5" fill="#FF7A00" opacity="0.7"/>
    <!-- Bouton home -->
    <circle cx="170" cy="238" r="8" fill="#1A1A2E" stroke="white" stroke-width="1" opacity="0.8"/>
  </g>

  <!-- Notification flottante -->
  <g transform="translate(235,75)">
    <rect width="80" height="42" rx="12" fill="white" opacity="0.97"/>
    <rect x="0" y="0" width="80" height="42" rx="12" fill="none" stroke="#FF7A00" stroke-width="1.5" opacity="0.4"/>
    <circle cx="16" cy="15" r="8" fill="#FF7A00"/>
    <text x="13" y="19" font-size="9" fill="white" font-weight="bold">📦</text>
    <rect x="30" y="9" width="38" height="3.5" rx="1.75" fill="#1A1A1A" opacity="0.7"/>
    <rect x="30" y="16" width="28" height="3" rx="1.5" fill="#999" opacity="0.6"/>
    <rect x="10" y="28" width="60" height="7" rx="3.5" fill="#FF7A00" opacity="0.15"/>
    <rect x="20" y="30" width="40" height="3" rx="1.5" fill="#FF7A00" opacity="0.7"/>
  </g>

  <!-- Ligne connexion téléphone → notification -->
  <path d="M225 90 Q235 88 235 96" stroke="#FF7A00" stroke-width="1.5" fill="none" stroke-dasharray="3,3" opacity="0.4"/>

  <!-- Éléments décoratifs -->
  <circle cx="50" cy="100" r="5" fill="#FF7A00" opacity="0.2"/>
  <circle cx="295" cy="220" r="4" fill="#FF7A00" opacity="0.15"/>
  <rect x="45" y="200" width="8" height="8" rx="2" fill="#FFB060" opacity="0.4" transform="rotate(25,49,204)"/>
  <rect x="288" y="80" width="7" height="7" rx="2" fill="#FF7A00" opacity="0.3" transform="rotate(-10,291,83)"/>
</svg>
''';

const _svgPaiement = '''
<svg viewBox="0 0 340 300" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="bg3" cx="50%" cy="45%" r="55%">
      <stop offset="0%" stop-color="#FFF3E8"/>
      <stop offset="100%" stop-color="#FFECD5"/>
    </radialGradient>
    <filter id="sh3" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="8" stdDeviation="12" flood-color="#FF7A00" flood-opacity="0.18"/>
    </filter>
  </defs>
  <ellipse cx="170" cy="150" rx="155" ry="140" fill="url(#bg3)"/>

  <!-- Carte bancaire principale -->
  <g filter="url(#sh3)">
    <rect x="55" y="85" width="230" height="140" rx="18" fill="#FF7A00"/>
    <!-- Reflet -->
    <rect x="55" y="85" width="230" height="60" rx="18" fill="white" opacity="0.08"/>
    <!-- Puce -->
    <rect x="80" y="115" width="38" height="28" rx="6" fill="#FFD080"/>
    <rect x="80" y="115" width="38" height="9" rx="3" fill="#FFA000" opacity="0.5"/>
    <line x1="80" y1="124" x2="118" y2="124" stroke="#FFA000" stroke-width="0.8" opacity="0.6"/>
    <line x1="99" y1="115" x2="99" y2="143" stroke="#FFA000" stroke-width="0.8" opacity="0.6"/>
    <!-- Numéro carte -->
    <rect x="80" y="158" width="22" height="8" rx="4" fill="white" opacity="0.5"/>
    <rect x="110" y="158" width="22" height="8" rx="4" fill="white" opacity="0.5"/>
    <rect x="140" y="158" width="22" height="8" rx="4" fill="white" opacity="0.5"/>
    <rect x="170" y="158" width="22" height="8" rx="4" fill="white" opacity="0.5"/>
    <!-- Nom et date -->
    <rect x="80" y="182" width="80" height="6" rx="3" fill="white" opacity="0.4"/>
    <rect x="225" y="182" width="40" height="6" rx="3" fill="white" opacity="0.4"/>
    <!-- Logo WiFi sans contact -->
    <path d="M245,108 Q255,98 265,108" stroke="white" stroke-width="2.5" fill="none" opacity="0.7"/>
    <path d="M248,114 Q255,107 262,114" stroke="white" stroke-width="2.5" fill="none" opacity="0.7"/>
    <circle cx="255" cy="120" r="3" fill="white" opacity="0.7"/>
  </g>

  <!-- Badge Wave -->
  <g transform="translate(240,70)">
    <rect width="72" height="36" rx="18" fill="#1A9BF0"/>
    <text x="10" y="23" font-size="12" fill="white" font-weight="bold" font-family="Arial">Wave</text>
  </g>

  <!-- Badge Orange Money -->
  <g transform="translate(30,175)">
    <rect width="80" height="36" rx="18" fill="#FF6600"/>
    <circle cx="18" cy="18" r="12" fill="white" opacity="0.2"/>
    <text x="30" y="23" font-size="10" fill="white" font-weight="bold" font-family="Arial">OM</text>
  </g>

  <!-- Checkmark succès -->
  <g transform="translate(245,185)">
    <circle cx="22" cy="22" r="22" fill="#22C55E" opacity="0.15"/>
    <circle cx="22" cy="22" r="16" fill="#22C55E"/>
    <polyline points="13,22 19,28 31,16" stroke="white" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
  </g>

  <!-- Cercles déco -->
  <circle cx="48" cy="85" r="4" fill="#FF7A00" opacity="0.2"/>
  <circle cx="300" cy="150" r="5" fill="#FF7A00" opacity="0.15"/>
  <rect x="42" y="225" width="8" height="8" rx="2" fill="#FFB060" opacity="0.5" transform="rotate(20,46,229)"/>
</svg>
''';

const _svgLivraison = '''
<svg viewBox="0 0 340 300" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="bg4" cx="50%" cy="45%" r="55%">
      <stop offset="0%" stop-color="#FFF3E8"/>
      <stop offset="100%" stop-color="#FFECD5"/>
    </radialGradient>
    <filter id="sh4" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="8" stdDeviation="14" flood-color="#FF7A00" flood-opacity="0.2"/>
    </filter>
  </defs>
  <ellipse cx="170" cy="155" rx="155" ry="138" fill="url(#bg4)"/>

  <!-- Livreur stylisé -->
  <!-- Corps -->
  <g filter="url(#sh4)">
    <!-- Casquette -->
    <ellipse cx="170" cy="72" rx="30" ry="8" fill="#FF7A00"/>
    <rect x="140" y="68" width="60" height="6" rx="3" fill="#E06300"/>
    <rect x="134" y="72" width="8" height="4" rx="2" fill="#E06300"/>
    <!-- Tête -->
    <circle cx="170" cy="88" r="22" fill="#FFDAB9"/>
    <!-- Yeux -->
    <circle cx="162" cy="86" r="3" fill="#333"/>
    <circle cx="178" cy="86" r="3" fill="#333"/>
    <!-- Sourire -->
    <path d="M163,95 Q170,101 177,95" stroke="#333" stroke-width="1.5" fill="none" stroke-linecap="round"/>
    <!-- Torse uniforme -->
    <rect x="138" y="108" width="64" height="72" rx="12" fill="#FF7A00"/>
    <!-- Badge Nanei -->
    <rect x="148" y="118" width="44" height="20" rx="6" fill="white" opacity="0.9"/>
    <rect x="154" y="123" width="20" height="4" rx="2" fill="#FF7A00"/>
    <rect x="154" y="130" width="14" height="3" rx="1.5" fill="#FFB060"/>
    <!-- Bras gauche -->
    <rect x="108" y="110" width="32" height="14" rx="7" fill="#FF7A00"/>
    <!-- Main gauche avec colis -->
    <rect x="90" y="118" width="22" height="22" rx="4" fill="#E06300"/>
    <rect x="90" y="118" width="22" height="8" rx="4" fill="#CC5900"/>
    <!-- Bras droit -->
    <rect x="202" y="110" width="32" height="14" rx="7" fill="#FF7A00"/>
    <!-- Jambes -->
    <rect x="148" y="176" width="18" height="50" rx="9" fill="#E06300"/>
    <rect x="174" y="176" width="18" height="50" rx="9" fill="#E06300"/>
    <!-- Chaussures -->
    <ellipse cx="157" cy="226" rx="14" ry="6" fill="#333"/>
    <ellipse cx="183" cy="226" rx="14" ry="6" fill="#333"/>
  </g>

  <!-- Grande étoile succès -->
  <g transform="translate(226,48)">
    <circle cx="22" cy="22" r="22" fill="#FF7A00" opacity="0.12"/>
    <circle cx="22" cy="22" r="16" fill="#FF7A00"/>
    <!-- Étoile 5 branches -->
    <polygon points="22,8 25,18 36,18 27,25 30,36 22,29 14,36 17,25 8,18 19,18"
      fill="white" opacity="0.95"/>
  </g>

  <!-- Éléments décoratifs -->
  <circle cx="52" cy="110" r="5" fill="#FF7A00" opacity="0.2"/>
  <circle cx="295" cy="90" r="4" fill="#FF7A00" opacity="0.18"/>
  <circle cx="40" cy="220" r="3" fill="#FFB060" opacity="0.4"/>
  <rect x="285" y="200" width="8" height="8" rx="2" fill="#FF7A00" opacity="0.3" transform="rotate(15,289,204)"/>
  <rect x="55" y="170" width="7" height="7" rx="1.5" fill="#FFD5A8" opacity="0.6" transform="rotate(-20,58,173)"/>

  <!-- Confettis joyeux -->
  <circle cx="75" cy="65" r="4" fill="#FF7A00" opacity="0.3"/>
  <circle cx="255" cy="240" r="3" fill="#FFB060" opacity="0.4"/>
  <rect x="295" y="175" width="6" height="6" rx="1" fill="#FF7A00" opacity="0.25" transform="rotate(30,298,178)"/>
</svg>
''';

// ─── Données onboarding ──────────────────────────────────────────────────────

class _OnboardingData {
  final String svg;
  final String title;
  final String subtitle;
  final String description;

  const _OnboardingData({
    required this.svg,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}

const _pages = [
  _OnboardingData(
    svg: _svgEnvoi,
    title: 'Envoyez vos colis',
    subtitle: 'Partout en Afrique',
    description:
        'Déposez vos colis en agence et nous les livrons dans plus de 15 pays africains en toute sécurité.',
  ),
  _OnboardingData(
    svg: _svgSuivi,
    title: 'Suivi en temps réel',
    subtitle: 'Notifié à chaque étape',
    description:
        'Recevez des alertes push à chaque changement de statut. Votre colis est toujours à portée de main.',
  ),
  _OnboardingData(
    svg: _svgPaiement,
    title: 'Payez facilement',
    subtitle: 'Wave · Orange Money',
    description:
        'Réglez en quelques secondes via Wave ou Orange Money. Sécurisé et rapide, sans frais cachés.',
  ),
  _OnboardingData(
    svg: _svgLivraison,
    title: 'Livraison garantie',
    subtitle: 'Satisfaction assurée',
    description:
        'Chaque colis est suivi jusqu\'à la porte. Rejoignez des milliers de clients qui nous font confiance.',
  ),
];

// ─── Page principale ──────────────────────────────────────────────────────────

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  static const _orange = Color(0xFFFF7A00);
  static const _autoDelay = Duration(seconds: 5);

  final _controller = PageController();
  int _current = 0;
  Timer? _timer;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_autoDelay, (_) => _next());
  }

  void _next() {
    if (!mounted) return;
    if (_current < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _terminer();
    }
  }

  Future<void> _terminer() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
  }

  void _onPageChanged(int i) {
    setState(() => _current = i);
    _fadeCtrl.forward(from: 0);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Fond dégradé subtil ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF8F2), Colors.white],
                  stops: [0.0, 0.45],
                ),
              ),
            ),
          ),

          // ── Contenu principal ──
          SafeArea(
            child: Column(
              children: [
                // ── Header : logo + bouton Passer ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo texte
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Nanei',
                              style: GoogleFonts.plusJakartaSans(
                                color: _orange,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bouton Passer
                      GestureDetector(
                        onTap: _terminer,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Passer',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Illustrations (PageView) ──
                SizedBox(
                  height: size.height * 0.42,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (_, i) => _IllustrationSlide(
                      data: _pages[i],
                      isActive: i == _current,
                    ),
                  ),
                ),

                // ── Dots indicateurs ──
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final active = i == _current;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? _orange : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                // ── Texte (titre + description) ──
                const SizedBox(height: 32),
                Expanded(
                  child: FadeTransition(
                    opacity: _fade,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          // Subtitle badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: _orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _pages[_current].subtitle,
                              style: GoogleFonts.plusJakartaSans(
                                color: _orange,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Titre
                          Text(
                            _pages[_current].title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1A1A1A),
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          // Description
                          Text(
                            _pages[_current].description,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              color: Colors.grey.shade500,
                              height: 1.65,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bouton Suivant / Commencer ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    children: [
                      // Barre de progression auto
                      _ProgressBar(
                        current: _current,
                        total: _pages.length,
                        autoDelay: _autoDelay,
                        orange: _orange,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _current < _pages.length - 1
                              ? () {
                                  _controller.nextPage(
                                    duration:
                                        const Duration(milliseconds: 450),
                                    curve: Curves.easeInOutCubic,
                                  );
                                }
                              : _terminer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 8,
                            shadowColor: _orange.withValues(alpha: 0.45),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _current < _pages.length - 1
                                    ? 'Suivant'
                                    : 'Commencer',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _current < _pages.length - 1
                                    ? Icons.arrow_forward_rounded
                                    : Icons.rocket_launch_rounded,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide illustration ──────────────────────────────────────────────────────

class _IllustrationSlide extends StatelessWidget {
  final _OnboardingData data;
  final bool isActive;

  const _IllustrationSlide({required this.data, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.0 : 0.92,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: SvgPicture.string(
          data.svg,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ─── Barre de progression automatique ────────────────────────────────────────

class _ProgressBar extends StatefulWidget {
  final int current;
  final int total;
  final Duration autoDelay;
  final Color orange;

  const _ProgressBar({
    required this.current,
    required this.total,
    required this.autoDelay,
    required this.orange,
  });

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.autoDelay);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_ProgressBar old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.total, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Container(
                height: 3,
                color: Colors.grey.shade200,
                child: i == widget.current
                    ? AnimatedBuilder(
                        animation: _ctrl,
                        builder: (_, __) => FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _ctrl.value,
                          child: Container(color: widget.orange),
                        ),
                      )
                    : i < widget.current
                        ? Container(color: widget.orange)
                        : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}
