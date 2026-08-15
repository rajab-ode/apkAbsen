import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/absensi_model.dart';
import '../../../data/services/absensi_service.dart';

class SemuaKehadiranScreen extends StatefulWidget {
  final String tanggal;
  const SemuaKehadiranScreen({super.key, required this.tanggal});

  @override
  State<SemuaKehadiranScreen> createState() => _SemuaKehadiranScreenState();
}

class _SemuaKehadiranScreenState extends State<SemuaKehadiranScreen> {
  final _service = AbsensiService();
  final _searchCtrl = TextEditingController();

  late DateTime _selectedDate;
  List<AbsensiModel> _list = [];
  int _hadir = 0, _izin = 0, _tidakHadir = 0;
  int _page = 1;
  int _total = 0;
  bool _isLoading = true;
  String _search = '';
  String _filterStatus = 'semua';

  static const _perPage = 10;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.tryParse(widget.tanggal) ?? DateTime.now();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _tanggalFormatted => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getAll(
        tanggal: _tanggalFormatted,
        search: _search.isEmpty ? null : _search,
        page: _page,
      );
      if (mounted) {
        setState(() {
          _list = result['data'];
          _total = result['total'];
          _hadir = result['hadir'];
          _izin = result['izin'];
          _tidakHadir = result['tidakHadir'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _page = 1;
      });
      _load();
    }
  }

  List<AbsensiModel> get _filtered {
    if (_filterStatus == 'semua') return _list;
    return _list.where((a) => a.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Kehadiran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _pickDate,
            tooltip: 'Pilih tanggal',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(child: _buildList()),
            if (_total > _perPage) _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStat('Hadir', _hadir, AppTheme.success),
              const SizedBox(width: 8),
              _buildMiniStat('Izin', _izin, AppTheme.warning),
              const SizedBox(width: 8),
              _buildMiniStat('Tidak Hadir', _tidakHadir, AppTheme.error),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              setState(() {
                _search = v;
                _page = 1;
              });
              _load();
            },
            decoration: InputDecoration(
              hintText: 'Cari nama atau NIS siswa',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _search = '';
                          _page = 1;
                        });
                        _load();
                      })
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    const statuses = [
      ('semua', 'Semua'),
      ('hadir', 'Hadir'),
      ('izin', 'Izin'),
      ('tidak_hadir', 'Tidak Hadir'),
    ];
    return Container(
      height: 40,
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: statuses.map((s) {
          final selected = _filterStatus == s.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(s.$2, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppTheme.textPrimary)),
              selected: selected,
              onSelected: (_) => setState(() => _filterStatus = s.$1),
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primary,
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_outlined, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text('Tidak ada data kehadiran', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildRow(i + 1 + (_page - 1) * _perPage, items[i]),
    );
  }

  Widget _buildRow(int no, AbsensiModel a) {
    final color = a.status == 'hadir'
        ? AppTheme.success
        : a.status == 'izin'
            ? AppTheme.warning
            : AppTheme.error;
    final label = a.status == 'hadir'
        ? 'Hadir'
        : a.status == 'izin'
            ? 'Izin'
            : 'Tidak Hadir';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$no',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.namaSiswa,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Text(a.nis,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(label,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 3),
              Text(a.waktu,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (_total / _perPage).ceil();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 1
                ? () {
                    setState(() => _page--);
                    _load();
                  }
                : null,
          ),
          Text('$_page / $totalPages',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < totalPages
                ? () {
                    setState(() => _page++);
                    _load();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
