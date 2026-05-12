import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';

class HijamaPage extends StatefulWidget {
  const HijamaPage({super.key});

  @override
  State<HijamaPage> createState() => _HijamaPageState();
}

class _HijamaPageState extends State<HijamaPage> {
  static const _apiUrls = [
    'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/main/MyApi/My_Ruqiya/hijama.json',
    'https://raw.githubusercontent.com/prodhan2/App_Backend_Data/refs/heads/main/MyApi/My_Ruqiya/hijama.json',
    'https://github.com/prodhan2/App_Backend_Data/raw/refs/heads/main/MyApi/My_Ruqiya/hijama.json',
  ];
  static const _cacheKey = 'hijama_content_cache';
  static const _bookmarkKey = 'hijama_bookmarked';

  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _offline = false;
  bool _bookmarked = false;
  String? _error;
  String _query = '';
  String _category = 'all';

  @override
  void initState() {
    super.initState();
    _loadBookmark();
    _fetchHijama();
  }

  Future<void> _loadBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _bookmarked = prefs.getBool(_bookmarkKey) ?? false);
    }
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final next = !_bookmarked;
    await prefs.setBool(_bookmarkKey, next);
    if (mounted) setState(() => _bookmarked = next);
  }

  Future<void> _fetchHijama() async {
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      if (_looksCorrupt(cached)) {
        await prefs.remove(_cacheKey);
      } else {
        _parseAndSet(cached, fromCache: true);
      }
    }

    try {
      int? lastStatusCode;
      for (final url in _apiUrls) {
        final response = await http
            .get(Uri.parse(url), headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));
        lastStatusCode = response.statusCode;

        if (response.statusCode != 200) continue;

        final raw = utf8.decode(response.bodyBytes, allowMalformed: true);
        if (_looksLikeJson(raw)) {
          await prefs.setString(_cacheKey, raw);
          _parseAndSet(raw, fromCache: false);
          return;
        }
      }

      _handleFetchFailure(
        lastStatusCode == null
            ? 'Could not load Hijama data from server'
            : 'Could not load Hijama data from server ($lastStatusCode)',
      );
    } catch (_) {
      _handleFetchFailure('Please check your internet connection');
    }
  }

  void _parseAndSet(String raw, {required bool fromCache}) {
    try {
      final cleaned = _cleanJson(raw);
      final decoded = jsonDecode(cleaned);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid Hijama data');
      }
      if (_looksCorrupt(cleaned)) {
        throw const FormatException('Corrupt Hijama text');
      }
      if (mounted) {
        setState(() {
          _data = decoded;
          _loading = false;
          _offline = fromCache;
        });
      }
    } catch (_) {
      if (!fromCache && mounted) {
        setState(() {
          _error = 'Could not read Hijama data';
          _loading = false;
        });
      }
    }
  }

  void _handleFetchFailure(String message) {
    if (!mounted) return;
    if (_data == null) {
      setState(() {
        _error = message;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final appSection = _map(_data?['app_section']);
    final accent = _parseColor(appSection['theme_color']?.toString());
    final title = _text(appSection['title'], fallback: 'Hijama');
    final subtitle = _text(
      appSection['subtitle'],
      fallback: 'Prophetic treatment',
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: accent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.hindSiliguri(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.hindSiliguri(
                fontSize: 10,
                color: Colors.white70,
                height: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: Colors.white,
            ),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchHijama,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : _error != null
          ? _ErrorView(message: _error!, accent: accent, onRetry: _fetchHijama)
          : RefreshIndicator(
              color: accent,
              onRefresh: _fetchHijama,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  if (_offline) ...[
                    const _OfflineBanner(),
                    const SizedBox(height: 12),
                  ],
                  _HeaderCard(
                    data: _data!,
                    accent: accent,
                    cardColor: cardColor,
                    textColor: textColor,
                    subColor: subColor,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    style: GoogleFonts.hindSiliguri(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: GoogleFonts.hindSiliguri(color: subColor),
                      prefixIcon: Icon(Icons.search_rounded, color: accent),
                      filled: true,
                      fillColor: cardColor,
                      border: _inputBorder(accent),
                      enabledBorder: _inputBorder(accent),
                      focusedBorder: _inputBorder(accent, focused: true),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CategoryChips(
                    selected: _category,
                    accent: accent,
                    onChanged: (value) => setState(() => _category = value),
                  ),
                  const SizedBox(height: 14),
                  ..._filteredSections().map(
                    (section) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SectionCard(
                        section: section,
                        accent: accent,
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                      ),
                    ),
                  ),
                  if (_filteredSections().isEmpty)
                    _EmptyView(cardColor: cardColor, textColor: textColor),
                ],
              ),
            ),
    );
  }

  OutlineInputBorder _inputBorder(Color accent, {bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: accent.withValues(alpha: focused ? 0.5 : 0.16),
      ),
    );
  }

  List<_SectionData> _filteredSections() {
    final sections = _sections(_data ?? {});
    final q = _query.trim().toLowerCase();
    return sections.where((section) {
      final matchesCategory = _category == 'all' || section.category == _category;
      final matchesQuery =
          q.isEmpty ||
          section.title.toLowerCase().contains(q) ||
          section.items.any((item) => item.toLowerCase().contains(q));
      return matchesCategory && matchesQuery;
    }).toList();
  }
}

class _HeaderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color accent;
  final Color cardColor;
  final Color textColor;
  final Color subColor;

  const _HeaderCard({
    required this.data,
    required this.accent,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    final appSection = _map(data['app_section']);
    final intro = _map(data['intro']);
    final title = _text(appSection['title'], fallback: 'Hijama');
    final subtitle = _text(
      appSection['subtitle'],
      fallback: 'Prophetic treatment',
    );
    final banner = _text(appSection['banner_image']);
    final description = _text(intro['description']);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 8,
            child: banner.isEmpty
                ? _ImageFallback(accent: accent)
                : Image.network(
                    banner,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ImageFallback(accent: accent),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13,
                      color: subColor,
                      height: 1.6,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final Color accent;

  const _ImageFallback({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent.withValues(alpha: 0.14),
      child: Icon(Icons.medical_services_outlined, color: accent, size: 54),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final String selected;
  final Color accent;
  final ValueChanged<String> onChanged;

  const _CategoryChips({
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  static const _items = [
    ('all', 'All'),
    ('intro', 'Intro'),
    ('benefits', 'Benefits'),
    ('time', 'Time'),
    ('prep', 'Preparation'),
    ('safety', 'Safety'),
    ('process', 'Process'),
    ('faq', 'FAQ'),
    ('hadith', 'Hadith'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _items.map((item) {
          final isSelected = selected == item.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                item.$2,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : accent,
                ),
              ),
              selected: isSelected,
              selectedColor: accent,
              backgroundColor: accent.withValues(alpha: 0.08),
              side: BorderSide(color: accent.withValues(alpha: 0.16)),
              onSelected: (_) => onChanged(item.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final _SectionData section;
  final Color accent;
  final Color cardColor;
  final Color textColor;
  final Color subColor;

  const _SectionCard({
    required this.section,
    required this.accent,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(section.icon, color: accent, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.title,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...section.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BulletLine(
                text: item,
                textColor: item.contains('\n') ? textColor : subColor,
                accent: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color accent;

  const _BulletLine({
    required this.text,
    required this.textColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 9),
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            style: GoogleFonts.hindSiliguri(
              fontSize: isArabic ? 16 : 13,
              color: textColor,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 15, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline mode - showing saved data',
              style: GoogleFonts.hindSiliguri(
                fontSize: 11,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Color accent;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.accent,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Try again',
                style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final Color cardColor;
  final Color textColor;

  const _EmptyView({required this.cardColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'No information found',
        textAlign: TextAlign.center,
        style: GoogleFonts.hindSiliguri(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _SectionData {
  final String title;
  final IconData icon;
  final String category;
  final List<String> items;

  const _SectionData({
    required this.title,
    required this.icon,
    required this.category,
    required this.items,
  });
}

List<_SectionData> _sections(Map<String, dynamic> data) {
  return [
    _introSection(data['intro']),
    _listSection(data['history'], Icons.history_rounded, 'history'),
    _nobobiSection(data['nobobi_treatment']),
    _listSection(
      data['benefits'],
      Icons.health_and_safety_outlined,
      'benefits',
    ),
    _recommendedTimeSection(data['recommended_time']),
    _listSection(
      data['before_hijama'],
      Icons.check_circle_outline_rounded,
      'prep',
    ),
    _listSection(data['after_hijama'], Icons.spa_outlined, 'prep'),
    _listSection(
      data['avoid_conditions'],
      Icons.warning_amber_rounded,
      'safety',
    ),
    _stepsSection(data['therapy_process']),
    _listSection(data['hijama_points'], Icons.place_outlined, 'points'),
    _topicSection(data['special_topics']),
    _faqSection(data['faq']),
    _hadithSection(data['hadiths']),
    _SectionData(
      title: 'References',
      icon: Icons.menu_book_outlined,
      category: 'hadith',
      items: _stringList(data['references']),
    ),
  ].where((section) => section.items.isNotEmpty).toList();
}

_SectionData _introSection(dynamic value) {
  final data = _map(value);
  return _SectionData(
    title: _text(data['title'], fallback: 'What is Hijama?'),
    icon: Icons.info_outline_rounded,
    category: 'intro',
    items: [
      _text(data['arabic']),
      _text(data['english']),
      _text(data['description']),
    ].where((item) => item.isNotEmpty).toList(),
  );
}

_SectionData _listSection(dynamic value, IconData icon, String category) {
  final data = _map(value);
  return _SectionData(
    title: _text(data['title']),
    icon: icon,
    category: category,
    items: _stringList(data['items'] ?? data['content'] ?? data['points']),
  );
}

_SectionData _nobobiSection(dynamic value) {
  final data = _map(value);
  return _SectionData(
    title: _text(data['title'], fallback: 'Prophetic treatment'),
    icon: Icons.favorite_outline_rounded,
    category: 'intro',
    items: [
      _text(data['description']),
      ..._stringList(data['used_for']),
    ].where((item) => item.isNotEmpty).toList(),
  );
}

_SectionData _recommendedTimeSection(dynamic value) {
  final data = _map(value);
  final dates = _stringList(data['best_dates_hijri']);
  final days = _stringList(data['best_days']);
  return _SectionData(
    title: _text(data['title'], fallback: 'Recommended time'),
    icon: Icons.calendar_month_outlined,
    category: 'time',
    items: [
      if (dates.isNotEmpty) 'Hijri dates: ${dates.join(', ')}',
      if (days.isNotEmpty) 'Best days: ${days.join(', ')}',
      _text(data['note']),
    ].where((item) => item.isNotEmpty).toList(),
  );
}

_SectionData _stepsSection(dynamic value) {
  final data = _map(value);
  final steps = data['steps'];
  final items = <String>[];
  if (steps is List) {
    for (final item in steps) {
      final step = _map(item);
      final number = (step['step'] as num?)?.toInt();
      final title = _text(step['title']);
      final description = _text(step['description']);
      final prefix = number == null ? '' : '$number. ';
      final text = '$prefix$title\n$description'.trim();
      if (text.isNotEmpty) items.add(text);
    }
  }
  return _SectionData(
    title: _text(data['title'], fallback: 'Hijama process'),
    icon: Icons.format_list_numbered_rounded,
    category: 'process',
    items: items,
  );
}

_SectionData _topicSection(dynamic value) {
  final items = <String>[];
  if (value is List) {
    for (final item in value) {
      final topic = _map(item);
      final title = _text(topic['title']);
      final description = _text(topic['description']);
      final text = '$title\n$description'.trim();
      if (text.isNotEmpty) items.add(text);
    }
  }
  return _SectionData(
    title: 'Special topics',
    icon: Icons.auto_awesome_outlined,
    category: 'benefits',
    items: items,
  );
}

_SectionData _faqSection(dynamic value) {
  final items = <String>[];
  if (value is List) {
    for (final item in value) {
      final faq = _map(item);
      final question = _text(faq['question']);
      final answer = _text(faq['answer']);
      final text = '$question\n$answer'.trim();
      if (text.isNotEmpty) items.add(text);
    }
  }
  return _SectionData(
    title: 'FAQ',
    icon: Icons.help_outline_rounded,
    category: 'faq',
    items: items,
  );
}

_SectionData _hadithSection(dynamic value) {
  final items = <String>[];
  if (value is List) {
    for (final item in value) {
      final hadith = _map(item);
      final parts = [
        _text(hadith['arabic']),
        _text(hadith['bangla']),
        _text(hadith['reference']),
      ].where((part) => part.isNotEmpty).toList();
      if (parts.isNotEmpty) items.add(parts.join('\n'));
    }
  }
  return _SectionData(
    title: 'Hadith',
    icon: Icons.menu_book_outlined,
    category: 'hadith',
    items: items,
  );
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return {};
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String _text(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _cleanJson(String raw) {
  return raw
      .replaceFirst(RegExp(r'^\uFEFF'), '')
      .replaceAllMapped(RegExp(r',\s*([}\]])'), (match) => match.group(1)!)
      .trim();
}

bool _looksLikeJson(String raw) {
  final cleaned = _cleanJson(raw);
  return cleaned.startsWith('{') || cleaned.startsWith('[');
}

bool _looksCorrupt(String raw) {
  return RegExp(r'[\u00E0\u00C2\u00C3\u00D8\u00D9]').hasMatch(raw);
}

Color _parseColor(String? value) {
  final normalized = value?.replaceFirst('#', '').trim();
  if (normalized == null || normalized.length != 6) {
    return const Color(0xFF1E6F5C);
  }
  try {
    return Color(int.parse('FF$normalized', radix: 16));
  } catch (_) {
    return const Color(0xFF1E6F5C);
  }
}
