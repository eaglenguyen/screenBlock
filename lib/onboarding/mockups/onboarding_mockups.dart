import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



// ── Phone mockup wrapper ──────────────────────────────

class PhoneMockup extends StatelessWidget {
  final Widget child;

  const PhoneMockup({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 360,
        decoration: BoxDecoration(
          color: const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: const Color(0xFF3A3A5C),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(29),
          child: child,
        ),
      ),
    );
  }
}
// ── Schedule screen mockup ────────────────────────────

class ScheduleScreenMockup extends StatelessWidget {
  const ScheduleScreenMockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF16162A),
      child: Stack(
        children: [
          // background — dimmed schedule list
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Scheduled Sessions',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDB82A).withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Color(0xFF1A1208), size: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E35).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'insta',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Inactive',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // dark overlay
          Container(color: Colors.black.withValues(alpha: 0.5)),

          // bottom sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF252525),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Scheduled Session',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // name row
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Text('🧘', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(
                          'Tiktok',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.edit_outlined,
                            color: Colors.white.withValues(alpha: 0.4), size: 11),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // all day toggle
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFEDB82A).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('☀️', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(
                          'All Day',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 24,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDB82A),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.all(1.5),
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // blocking type
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Blocking Type',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Specific Apps',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFEDB82A),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: const Color(0xFFEDB82A), size: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // block list
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Block List',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDB82A).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '1',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFFEDB82A),
                                        fontSize: 7,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Only these apps will be blocked',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 7,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.white.withValues(alpha: 0.4), size: 14),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // days picker
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'On these days:',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Custom',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFEDB82A),
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                              .asMap()
                              .entries
                              .map((e) {
                            final isSelected = [1, 2, 3].contains(e.key);
                            return Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEDB82A)
                                    : const Color(0xFF1A1A1A),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  e.value,
                                  style: GoogleFonts.poppins(
                                    color: isSelected
                                        ? const Color(0xFF1A1208)
                                        : Colors.white38,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ── Active blocking mockup ────────────────────────────

class ActiveBlockingMockup extends StatelessWidget {
  const ActiveBlockingMockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF16162A),
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scheduled Sessions',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDB82A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Color(0xFF1A1208), size: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // active session card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEDB82A).withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDB82A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Early Bird',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDB82A).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Active',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFEDB82A),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 30,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDB82A),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'All Day · Weekdays',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                const SizedBox(height: 10),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_rounded,
                          color: Colors.white.withValues(alpha: 0.6), size: 12),
                      const SizedBox(width: 6),
                      Text(
                        'Pause blocking',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const _MockBottomNav(activeIndex: 1),
        ],
      ),
    );
  }
}



// ── Shared mock widgets ───────────────────────────────

class MockBadge extends StatelessWidget {
  final String label;
  final bool highlighted;

  const MockBadge({super.key, required this.label, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFFEDB82A).withValues(alpha: 0.15)
            : const Color(0xFF1E1E35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? const Color(0xFFEDB82A).withValues(alpha: 0.4)
              : const Color(0xFF2A2A48),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: highlighted ? const Color(0xFFEDB82A) : Colors.white,
          fontSize: 7,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MockBottomNav extends StatelessWidget {
  final int activeIndex;

  const _MockBottomNav({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.home_rounded,
      Icons.calendar_today_rounded,
      Icons.bar_chart_rounded,
      Icons.settings_rounded,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A48), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(icons.length, (i) {
          final isActive = i == activeIndex;
          return Container(
            width: 24,
            height: 24,
            decoration: isActive
                ? const BoxDecoration(
              color: Color(0xFFEDB82A),
              shape: BoxShape.circle,
            )
                : null,
            child: Icon(
              icons[i],
              color: isActive
                  ? const Color(0xFF1A1208)
                  : Colors.white.withValues(alpha: 0.3),
              size: 13,
            ),
          );
        }),
      ),
    );
  }
}




