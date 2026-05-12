// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../core/providers/theme_provider.dart';
// import '../core/theme/app_theme.dart';

// class SettingsPage extends StatelessWidget {
//   const SettingsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final settings = context.watch<ThemeProvider>();
//     final isDark = settings.isDark;
//     final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
//     final cardColor = isDark ? AppColors.darkCard : Colors.white;
//     final textColor = isDark ? AppColors.darkText : AppColors.lightText;
//     final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;

//     return Scaffold(
//       backgroundColor: bgColor,
//       appBar: AppBar(
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         title: Text(
//           'Settings',
//           style: settings.textStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w800,
//             color: Colors.white,
//           ),
//         ),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
//         children: [
//           _SectionCard(
//             color: cardColor,
//             child: Column(
//               children: [
//                 SwitchListTile(
//                   value: settings.isDark,
//                   activeThumbColor: AppColors.primary,
//                   secondary: const Icon(Icons.dark_mode_rounded),
//                   title: Text(
//                     'Dark mode',
//                     style: settings.textStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w700,
//                       color: textColor,
//                     ),
//                   ),
//                   subtitle: Text(
//                     'Switch between light and dark colors',
//                     style: settings.textStyle(fontSize: 12, color: subColor),
//                   ),
//                   onChanged: settings.setDark,
//                 ),
//                 const Divider(height: 1),
//                 ListTile(
//                   leading: const Icon(Icons.text_fields_rounded),
//                   title: Text(
//                     'Font',
//                     style: settings.textStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w700,
//                       color: textColor,
//                     ),
//                   ),
//                   subtitle: Text(
//                     'Choose the reading font',
//                     style: settings.textStyle(fontSize: 12, color: subColor),
//                   ),
//                   trailing: DropdownButton<String>(
//                     value: settings.fontFamily,
//                     underline: const SizedBox.shrink(),
//                     items: ThemeProvider.fontOptions
//                         .map(
//                           (font) => DropdownMenuItem(
//                             value: font,
//                             child: Text(font, style: settings.textStyle()),
//                           ),
//                         )
//                         .toList(),
//                     onChanged: (value) {
//                       if (value != null) settings.setFontFamily(value);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 14),
//           _SectionCard(
//             color: cardColor,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//                   child: Text(
//                     'Ruqyah list layout',
//                     style: settings.textStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w800,
//                       color: textColor,
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: SegmentedButton<bool>(
//                     segments: const [
//                       ButtonSegment(
//                         value: false,
//                         icon: Icon(Icons.view_agenda_rounded),
//                         label: Text('List'),
//                       ),
//                       ButtonSegment(
//                         value: true,
//                         icon: Icon(Icons.grid_view_rounded),
//                         label: Text('Grid'),
//                       ),
//                     ],
//                     selected: {settings.isGridView},
//                     onSelectionChanged: (values) {
//                       settings.setGridView(values.first);
//                     },
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 ListTile(
//                   enabled: settings.isGridView,
//                   leading: const Icon(Icons.apps_rounded),
//                   title: Text(
//                     'Grid size',
//                     style: settings.textStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w700,
//                       color: textColor,
//                     ),
//                   ),
//                   subtitle: Slider(
//                     value: settings.gridSize.toDouble(),
//                     min: 2,
//                     max: 4,
//                     divisions: 2,
//                     label: '${settings.gridSize}',
//                     activeColor: AppColors.primary,
//                     onChanged: settings.isGridView
//                         ? (value) => settings.setGridSize(value.round())
//                         : null,
//                   ),
//                   trailing: Text(
//                     '${settings.gridSize}',
//                     style: settings.textStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w800,
//                       color: settings.isGridView ? AppColors.primary : subColor,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 14),
//           _PreviewCard(
//             cardColor: cardColor,
//             textColor: textColor,
//             subColor: subColor,
//             settings: settings,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SectionCard extends StatelessWidget {
//   final Color color;
//   final Widget child;

//   const _SectionCard({required this.color, required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primary.withValues(alpha: 0.06),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }
// }

// class _PreviewCard extends StatelessWidget {
//   final Color cardColor;
//   final Color textColor;
//   final Color subColor;
//   final ThemeProvider settings;

//   const _PreviewCard({
//     required this.cardColor,
//     required this.textColor,
//     required this.subColor,
//     required this.settings,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return _SectionCard(
//       color: cardColor,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Container(
//               width: 42,
//               height: 42,
//               decoration: BoxDecoration(
//                 gradient: AppColors.gradient,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Icon(Icons.menu_book_rounded, color: Colors.white),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Preview',
//                     style: settings.textStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w800,
//                       color: textColor,
//                     ),
//                   ),
//                   const SizedBox(height: 3),
//                   Text(
//                     'Font and list layout settings are ready.',
//                     style: settings.textStyle(
//                       fontSize: 12,
//                       color: subColor,
//                       height: 1.4,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
