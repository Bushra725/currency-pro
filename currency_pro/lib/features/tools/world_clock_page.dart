import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/rate_app_bar.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/world_clock.dart';
import '../../routes.dart';
import '../../state/clocks_provider.dart';

/// Live clocks for the cities the user cares about.
class WorldClockPage extends StatefulWidget {
  const WorldClockPage({super.key});

  @override
  State<WorldClockPage> createState() => _WorldClockPageState();
}

class _WorldClockPageState extends State<WorldClockPage> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final ClocksProvider clocks = context.watch<ClocksProvider>();

    return Scaffold(
      drawer: const AppDrawer(current: Routes.clock),
      appBar: RateAppBar(
        title: l10n.worldClock,
        showUpdated: false,
        showRefresh: false,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: FilledButton.icon(
              onPressed: _addCity,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addEditClocks),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
          ),
          Expanded(
            child: clocks.all.isEmpty
                ? EmptyState(
                    icon: Icons.public_off,
                    title: l10n.noCitiesTitle,
                    message: l10n.noCitiesBody,
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: clocks.all.length,
                    onReorder: clocks.reorder,
                    itemBuilder: (BuildContext context, int index) {
                      final ClockEntry c = clocks.all[index];
                      final DateTime now = c.nowThere();
                      final DateTime here = DateTime.now();
                      final int diffMinutes =
                          c.offsetMinutes - here.timeZoneOffset.inMinutes;

                      return Padding(
                        key: ValueKey<String>(c.id),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SectionCard(
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      c.city,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: p.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      c.region,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: p.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      Fmt.time(now),
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                        color: p.primary,
                                      ),
                                    ),
                                    Text(
                                      '${Fmt.weekday(now)}, ${Fmt.date(now)} · '
                                      '${c.offsetLabel}'
                                      '${diffMinutes == 0 ? ' · ${l10n.sameAsYou}' : ''}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: p.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: <Widget>[
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: p.textSecondary,
                                    ),
                                    onPressed: () => clocks.remove(c.id),
                                  ),
                                  Icon(
                                    Icons.drag_handle,
                                    size: 18,
                                    color: p.textSecondary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCity() async {
    final ClocksProvider clocks = context.read<ClocksProvider>();
    final ClockEntry? picked = await showModalBottomSheet<ClockEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) => const _CityPickerSheet(),
    );
    if (picked != null) await clocks.add(picked);
  }
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet();

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final ClocksProvider clocks = context.watch<ClocksProvider>();
    final String q = _search.text.trim().toLowerCase();
    final List<ClockEntry> results = kWorldCities
        .where(
          (ClockEntry c) =>
              q.isEmpty ||
              c.city.toLowerCase().contains(q) ||
              c.region.toLowerCase().contains(q),
        )
        .toList();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cap = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.85;
        final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
        final double height = (cap - keyboard).clamp(0.0, cap);
        return SizedBox(
          height: height,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: L10n.read(context).searchCityCountry,
                    prefixIcon: const Icon(Icons.search, size: 19),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: p.outline.withOpacity(0.5)),
                  itemBuilder: (BuildContext context, int index) {
                    final ClockEntry c = results[index];
                    final bool added = clocks.contains(c.id);
                    return ListTile(
                      dense: true,
                      title: Text(c.city),
                      subtitle: Text(
                        '${c.region} · ${c.offsetLabel}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        Fmt.time(c.nowThere()),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: added ? p.textSecondary : p.primary,
                        ),
                      ),
                      enabled: !added,
                      onTap: () => Navigator.of(context).pop(c),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
