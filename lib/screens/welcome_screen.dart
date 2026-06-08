
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

 
 


class AppColors {
  static const Color primary = Color(0xff1E3A8A); 
  static const Color accent = Color(0xffE53935);  
  static const Color success = Color(0xff10B981); 
  static const Color background = Color(0xffF8FAFC);
  static const Color textDark = Color(0xff0F172A);
  static const Color textLight = Color(0xff475569);
  static const Color cardBg = Colors.white;
}

class ResponsiveLayout extends StatelessWidget {
  final Widget desktop;
  final Widget? tablet;
  final Widget mobile;

  const ResponsiveLayout({
    super.key,
    required this.desktop,
    this.tablet,
    required this.mobile,
  });

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 768;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1200;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1200;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktop;
        } else if (constraints.maxWidth >= 768) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: NavigationBarComponent(),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: const [
            HeroSection(),
            FeaturesSection(),
            HowItWorksSection(),
            StatsSection(),
            WhyChooseUsSection(),
            TestimonialsSection(),
            FooterSection(),
          ],
        ),
      ),
    );
  }
}

class NavigationBarComponent extends StatelessWidget {
  const NavigationBarComponent({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xff1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.all_inclusive_rounded, color: Color(0xff1E3A8A), size: 28),
              ),
              const SizedBox(width: 12),
              const Text(
                'Green Corridor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          if (!isMobile)
            Row(
              children: [
                _navLink('Features'),
                _navLink('About'),
                _navLink('Contact'),
              ],
            ),
          Row(
            children: [
              TextButton(
                onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const LoginScreen(),
    ),
  );
},
                child: const Text('Login', style: TextStyle(color: Color(0xff1E3A8A), fontWeight: FontWeight.w600)),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 12),
                ElevatedButton(
                onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const RegisterScreen(),
    ),
  );
},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _navLink(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: () {},
        child: Text(
          title,
          style: const TextStyle(color: Color(0xff475569), fontWeight: FontWeight.w500, fontSize: 15),
        ),
      ),
    );
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: _buildDesktopTabletLayout(context, isDesktop: true),
      tablet: _buildDesktopTabletLayout(context, isDesktop: false),
      mobile: _buildMobileLayout(context),
    );
  }

  Widget _buildDesktopTabletLayout(BuildContext context, {required bool isDesktop}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 80 : 40, vertical: 80),
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: _buildHeroTextContent(context, CrossAxisAlignment.start),
          ),
          const Spacer(flex: 1),
          Expanded(
            flex: 10,
            child: _buildHeroIllustration(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeroTextContent(context, CrossAxisAlignment.center, isMobile: true),
          const SizedBox(height: 48),
          _buildHeroIllustration(),
        ],
      ),
    );
  }

  Widget _buildHeroTextContent(BuildContext context, CrossAxisAlignment crossAlignment, {bool isMobile = false}) {
    return Column(
      crossAxisAlignment: crossAlignment,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xffE53935).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.bolt, color: Color(0xffE53935), size: 16),
              SizedBox(width: 6),
              Text(
                "Next-Gen Emergency Response",
                style: TextStyle(color: Color(0xffE53935), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Saving Critical Minutes\nDuring Emergencies",
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 36 : 56,
            fontWeight: FontWeight.bold,
            color: const Color(0xff0F172A),
            height: 1.15,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          "Green Corridor enables real-time coordination between hospitals, ambulance drivers, emergency teams, and citizens.",
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 16 : 19,
            color: const Color(0xff475569),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Our smart cloud routing dynamic platform optimizes lane priorities and syncs trauma units instantly, putting patient survival metrics back where they belong—in safe hands.",
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(fontSize: 15, color: const Color(0xff475569).withOpacity(0.85), height: 1.5),
        ),
        const SizedBox(height: 36),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff1E3A8A),
                side: const BorderSide(color: Color(0xffCBD5E1), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Login Platform', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildHeroIllustration() {
    return AspectRatio(
      aspectRatio: 1.1,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xff1E3A8A).withOpacity(0.05), const Color(0xff1E3A8A).withOpacity(0.01)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.1,
                child: Icon(Icons.grid_4x4, size: 300, color: Color(0xff1E3A8A)),
              ),
            ),
            Positioned(
              left: 20,
              top: 40,
              child: _floatingMockCard(
                icon: Icons.local_shipping_rounded,
                iconColor: const Color(0xffE53935),
                title: "AMB-204 Active Route",
                subtitle: "ETA: 4.2 Mins • Green Wave Active",
                metric: "Speed: 72km/h",
              ),
            ),
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Center(
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    color: const Color(0xff1E3A8A).withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.g_mobiledata, size: 80, color: const Color(0xff1E3A8A).withOpacity(0.3)),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 60,
              child: _floatingMockCard(
                icon: Icons.local_hospital,
                iconColor: const Color(0xff10B981),
                title: "City Trauma Center Tier-1",
                subtitle: "ICU Bed Reserved • ER Team Ready",
                metric: "Status: Locked",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _floatingMockCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String metric,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff0F172A))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xff475569))),
              const SizedBox(height: 4),
              Text(metric, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: iconColor)),
            ],
          )
        ],
      ),
    );
  }
}

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final int crossAxisCount = ResponsiveLayout.isMobile(context)
        ? 1
        : ResponsiveLayout.isTablet(context)
            ? 2
            : 3;

    final List<Map<String, dynamic>> features = [
      {
        'icon': Icons.local_hospital,
        'title': 'Hospital Coordination',
        'desc': 'Instant synchronization with Emergency Rooms. Pre-allocate trauma bays and staff before ambulance arrival.',
      },
      {
        'icon': Icons.local_shipping, 
        'title': 'Ambulance Tracking',
        'desc': 'Precision live streams telemetry of emergency vehicles with direct driver communication dashboards.',
      },
      {
        'icon': Icons.monitor_heart, 
        'title': 'Live Mission Monitoring',
        'desc': 'Command center visibility for city admins to track active green signals and override choke points instantly.',
      },
      {
        'icon': Icons.badge,
        'title': 'Driver Management',
        'desc': 'Simplified login workflows, clear incident reporting metrics, and transparent dispatch queues for drivers.',
      },
      {
        'icon': Icons.alt_route,
        'title': 'Route Optimization',
        'desc': 'AI-driven routing calculates optimal corridors dynamically interacting directly with city smart grids.',
      },
      {
        'icon': Icons.cell_tower,
        'title': 'Citizen Emergency Requests',
        'desc': 'Empower civilians to lodge rapid SOS triggers giving immediate geo-spatial presence to rescuers.',
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        children: [
          const Text(
            "Engineered Platform Features",
            style: TextStyle(fontSize: 14, color: Color(0xff1E3A8A), fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          const Text(
            "Everything Needed for High-Velocity Lifesaving Protocols",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xff0F172A), letterSpacing: -0.5),
          ),
          const SizedBox(height: 48),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (context, index) {
              final item = features[index];
              return _buildFeatureCard(item['icon'], item['title'], item['desc']);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(icon, color: const Color(0xff1E3A8A), size: 24), 
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff0F172A))),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(color: Color(0xff475569), fontSize: 14, height: 1.4),
              overflow: TextOverflow.fade,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Text("Explore feature", style: TextStyle(color: Color(0xff1E3A8A), fontSize: 13, fontWeight: FontWeight.bold)),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 14, color: Color(0xff1E3A8A)),
            ],
          )
        ],
      ),
    );
  }
}

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    final List<Map<String, String>> steps = [
      {'num': '01', 'title': 'Emergency Request', 'desc': 'Citizen or hospital initiates an emergency profile on the platform.'},
      {'num': '02', 'title': 'Mission Assignment', 'desc': 'Nearest optimized fleet receives continuous dispatch cues instantly.'},
      {'num': '03', 'title': 'Live Tracking', 'desc': 'Dynamic route infrastructure aligns lights along coordinates automatically.'},
      {'num': '04', 'title': 'Successful Medical Delivery', 'desc': 'Patients transition seamlessly to pre-notified emergency facilities.'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        children: [
          const Text("The System Process Workflow", style: TextStyle(fontSize: 14, color: Color(0xffE53935), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("How Green Corridor Works", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xff0F172A))),
          const SizedBox(height: 56),
          if (isMobile)
            Column(
              children: steps.map((s) => _buildStepCard(s['num']!, s['title']!, s['desc']!, isMobile: true)).toList(),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps
                  .map((s) => Expanded(child: _buildStepCard(s['num']!, s['title']!, s['desc']!, isMobile: false)))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStepCard(String number, String title, String desc, {required bool isMobile}) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 32 : 0, right: isMobile ? 0 : 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xff1E3A8A)), 
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff0F172A))),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xff475569), height: 1.4)),
        ],
      ),
    );
  }
}

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      color: const Color(0xff1E3A8A),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 64),
      child: Wrap(
        spacing: 40,
        runSpacing: 32,
        alignment: WrapAlignment.spaceAround,
        children: [
          _buildStatItem("50+", "Hospitals Connected", isMobile),
          _buildStatItem("200+", "Ambulances Integrated", isMobile),
          _buildStatItem("1,000+", "Emergency Missions Cleared", isMobile),
          _buildStatItem("24/7", "Autonomous Cloud Monitoring", isMobile),
        ],
      ),
    );
  }

  Widget _buildStatItem(String main, String sub, bool isMobile) {
    return SizedBox(
      width: isMobile ? 150 : 220,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            main,
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }
}

class WhyChooseUsSection extends StatelessWidget {
  const WhyChooseUsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    final List<String> benefits = [
      "Faster Emergency Response Intervals",
      "Real-Time Transit and Asset Visibility",
      "Better Inter-Hospital Network Coordination",
      "Reduced Signal and Grid Transport Delays",
      "Significantly Improved Patient Survival Outcomes",
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        children: [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Platform Value Propositions", style: TextStyle(color: Color(0xff1E3A8A), fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                  "Why Cities Choose Green Corridor Architecture",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xff0F172A), letterSpacing: -0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Traditional infrastructure isolates healthcare endpoints. Our system interconnects hardware layers dynamically so everyone is perfectly in loop.",
                  style: TextStyle(color: Color(0xff475569), fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (!isMobile) const SizedBox(width: 64),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Column(
              children: benefits.map((benefit) => _buildBenefitRow(benefit)).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xff10B981), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Color(0xff0F172A), fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }
}

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final int crossAxisCount = ResponsiveLayout.isMobile(context)
        ? 1
        : ResponsiveLayout.isTablet(context)
            ? 2
            : 3;

    final List<Map<String, String>> testimonials = [
      {
        'role': 'Hospital Administrator',
        'quote': '"The ER predictive coordination stack reduced pre-admission prep backlogs down by 40%. It fundamentally reforms trauma center metrics."',
        'name': 'Dr. Aris Vance',
      },
      {
        'role': 'Emergency Driver',
        'quote': '"Knowing ahead that intersection points are auto-clearing gives me unmatched security while navigating narrow transit systems."',
        'name': 'Marcus Brody',
      },
      {
        'role': 'Healthcare Coordinator',
        'quote': '"Consolidating citizen SOS feeds and asset locations into unified panes eliminated dispatch friction inside regional zones completely."',
        'name': 'Sarah Jenkins',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        children: [
          const Text("Real Ecosystem Validations", style: TextStyle(color: Color(0xff1E3A8A), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Trusted by Medical Operators", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xff0F172A))),
          const SizedBox(height: 48),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: testimonials.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, index) {
              final item = testimonials[index];
              return _buildTestimonialCard(item['role']!, item['quote']!, item['name']!);
            },
          )
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(String role, String quote, String name) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 16, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: const Color(0xffEDF2F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            quote,
            style: const TextStyle(fontSize: 15, color: Color(0xff475569), fontStyle: FontStyle.italic, height: 1.4),
          ),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xff1E3A8A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Color(0xff1E3A8A), size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff0F172A))),
                  Text(role, style: const TextStyle(fontSize: 12, color: Color(0xff475569))),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      color: const Color(0xff0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 64),
      child: Column(
        children: [
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Green Corridor',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Modern Emergency Response Management Ecosystem Platform.',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                  )
                ],
              ),
              if (isMobile) const SizedBox(height: 32),
              Row(
                children: [
                  _footerLink('Features'),
                  _footerLink('About Platform'),
                  _footerLink('Contact Systems'),
                ],
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(color: Color(0xff334155), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2026 Green Corridor Inc. All operational rights reserved.',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Color(0xff10B981), shape: BoxShape.circle),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _footerLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}

