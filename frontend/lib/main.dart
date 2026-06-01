import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const apiBase = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:3000/api/v1',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  runApp(const GestaoDomesticaApp());
}

class GestaoDomesticaApp extends StatelessWidget {
  const GestaoDomesticaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final publicSlug = _publicSlugFromUrl();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestao Domestica',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0d7c66),
          primary: const Color(0xff0d7c66),
          secondary: const Color(0xfff29f58),
          tertiary: const Color(0xff7c3aed),
          surface: const Color(0xfffffbf7),
        ),
        scaffoldBackgroundColor: const Color(0xfffffbf7),
        useMaterial3: true,
        inputDecorationTheme:
            const InputDecorationTheme(border: OutlineInputBorder()),
        cardTheme: CardTheme(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.black.withOpacity(.08)),
          ),
        ),
      ),
      home: publicSlug == null
          ? const AdminShell()
          : PublicSchedulePage(slug: publicSlug),
    );
  }
}

String? _publicSlugFromUrl() {
  final fragment = Uri.base.fragment;
  final path = fragment.isEmpty ? Uri.base.path : fragment;
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  if (parts.length >= 2 && parts.first == 'public') return parts[1];
  return null;
}

class ApiClient {
  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await http.get(Uri.parse('$apiBase$path'));
    return _decode(response);
  }

  Future<Map<String, dynamic>> postJson(
      String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$apiBase$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> patchJson(
      String path, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse('$apiBase$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final data = jsonDecode(response.body.isEmpty ? '{}' : response.body)
        as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Erro de comunicacao.');
    }
    return data;
  }
}

final api = ApiClient();
final dateLabel = DateFormat('dd/MM/yyyy', 'pt_BR');
final moneyLabel = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

String isoDate(DateTime value) => DateFormat('yyyy-MM-dd').format(value);
String monthKey(DateTime value) => DateFormat('yyyy-MM').format(value);

class AvailabilityDay {
  AvailabilityDay({required this.date, required this.status, this.note});

  final DateTime date;
  final String status;
  final String? note;

  factory AvailabilityDay.fromJson(Map<String, dynamic> json) {
    return AvailabilityDay(
      date: DateTime.parse(json['work_date'] as String),
      status: json['status'] as String,
      note: json['note'] as String?,
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const AgendaAdminPage(),
      const RequestsPage(),
      const FinancePage(),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Icon(Icons.cleaning_services,
                    color: Color(0xff0d7c66), size: 30),
              ),
              destinations: const [
                NavigationRailDestination(
                    icon: Icon(Icons.event_available), label: Text('Agenda')),
                NavigationRailDestination(
                    icon: Icon(Icons.inbox), label: Text('Pedidos')),
                NavigationRailDestination(
                    icon: Icon(Icons.payments), label: Text('Financeiro')),
              ],
            ),
          Expanded(child: pages[index]),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.event_available), label: 'Agenda'),
                NavigationDestination(
                    icon: Icon(Icons.inbox), label: 'Pedidos'),
                NavigationDestination(
                    icon: Icon(Icons.payments), label: 'Financeiro'),
              ],
            ),
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame(
      {required this.title,
      required this.subtitle,
      required this.child,
      super.key});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 150,
          backgroundColor: const Color(0xff0d7c66),
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff0d7c66), Color(0xfff29f58)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 56),
                  child: Text(subtitle,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14)),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(18),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );
  }
}

class AgendaAdminPage extends StatefulWidget {
  const AgendaAdminPage({super.key});

  @override
  State<AgendaAdminPage> createState() => _AgendaAdminPageState();
}

class _AgendaAdminPageState extends State<AgendaAdminPage> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, AvailabilityDay> days = {};
  String publicSlug = 'sara-lima';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    final data = await api.getJson('/availability?month=${monthKey(month)}');
    final rows = (data['days'] as List).cast<Map<String, dynamic>>();
    setState(() {
      days = {
        for (final day in rows.map(AvailabilityDay.fromJson))
          isoDate(day.date): day
      };
      publicSlug = data['publicSlug'] as String? ?? publicSlug;
      loading = false;
    });
  }

  Future<void> saveDay(DateTime date, String status) async {
    await api.postJson('/availability', {
      'workDate': isoDate(date),
      'status': status,
      'note': status == 'available' ? 'Disponivel para contratar' : null,
    });
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final publicLink = '${Uri.base.origin}${Uri.base.path}#/public/$publicSlug';
    return PageFrame(
      title: 'Agenda',
      subtitle: 'Controle os dias que aparecem no link enviado ao cliente.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(
            icon: Icons.link,
            title: 'Link para clientes',
            text: publicLink,
            action: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share),
              label: const Text('Enviar'),
            ),
          ),
          const SizedBox(height: 16),
          CalendarPanel(
            month: month,
            days: days,
            loading: loading,
            onPrevious: () {
              setState(() => month = DateTime(month.year, month.month - 1));
              load();
            },
            onNext: () {
              setState(() => month = DateTime(month.year, month.month + 1));
              load();
            },
            onSelectStatus: saveDay,
          ),
        ],
      ),
    );
  }
}

class CalendarPanel extends StatelessWidget {
  const CalendarPanel({
    required this.month,
    required this.days,
    required this.loading,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectStatus,
    super.key,
  });

  final DateTime month;
  final Map<String, AvailabilityDay> days;
  final bool loading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Future<void> Function(DateTime date, String status) onSelectStatus;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final startOffset = first.weekday % 7;
    final totalDays = DateTime(month.year, month.month + 1, 0).day;
    final cells = List<DateTime?>.filled(startOffset, null, growable: true)
      ..addAll(List.generate(
          totalDays, (index) => DateTime(month.year, month.month, index + 1)));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy', 'pt_BR').format(month),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                    onPressed: onNext, icon: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: 12),
            if (loading) const LinearProgressIndicator(),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width < 560 ? 2 : 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio:
                  MediaQuery.sizeOf(context).width < 560 ? 1.9 : 1.15,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                for (final date in cells)
                  date == null
                      ? const SizedBox.shrink()
                      : DayTile(
                          date: date,
                          status: days[isoDate(date)]?.status ?? 'unavailable',
                          onSelect: (status) => onSelectStatus(date, status),
                        ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DayTile extends StatelessWidget {
  const DayTile(
      {required this.date,
      required this.status,
      required this.onSelect,
      super.key});

  final DateTime date;
  final String status;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final style = switch (status) {
      'available' => (
          const Color(0xffe6f7ef),
          const Color(0xff0d7c66),
          'Livre'
        ),
      'booked' => (const Color(0xffffeedf), const Color(0xffc15d12), 'Ocupado'),
      _ => (const Color(0xfff1f1f1), const Color(0xff646464), 'Indisp.'),
    };
    return PopupMenuButton<String>(
      onSelected: onSelect,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'available', child: Text('Marcar livre')),
        PopupMenuItem(value: 'booked', child: Text('Marcar ocupado')),
        PopupMenuItem(value: 'unavailable', child: Text('Marcar indisponivel')),
      ],
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: style.$1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: style.$2.withOpacity(.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${date.day}',
                style: TextStyle(
                    color: style.$2,
                    fontWeight: FontWeight.w900,
                    fontSize: 20)),
            Text(style.$3,
                style: TextStyle(color: style.$2, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  List<Map<String, dynamic>> requests = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await api.getJson('/booking-requests');
    setState(() {
      requests = (data['requests'] as List).cast<Map<String, dynamic>>();
      loading = false;
    });
  }

  Future<void> updateStatus(int id, String status) async {
    await api.patchJson('/booking-requests/$id', {'status': status});
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Pedidos',
      subtitle: 'Solicitacoes recebidas pelo link publico.',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? const EmptyState(
                  icon: Icons.inbox, text: 'Nenhum pedido recebido ainda.')
              : Column(
                  children: [
                    for (final item in requests)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(item['client_name'] as String),
                          subtitle: Text(
                              '${dateLabel.format(DateTime.parse(item['requested_date']))} - ${item['client_phone']}'),
                          trailing: DropdownButton<String>(
                            value: item['status'] as String,
                            items: const [
                              DropdownMenuItem(
                                  value: 'new', child: Text('Novo')),
                              DropdownMenuItem(
                                  value: 'accepted', child: Text('Aceito')),
                              DropdownMenuItem(
                                  value: 'declined', child: Text('Recusado')),
                              DropdownMenuItem(
                                  value: 'done', child: Text('Feito')),
                            ],
                            onChanged: (value) => value == null
                                ? null
                                : updateStatus(item['id'] as int, value),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic> summary = {'income': 0, 'expense': 0, 'balance': 0};
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final results = await Future.wait([
      api.getJson('/financial-summary?month=${monthKey(month)}'),
      api.getJson('/financial-transactions?month=${monthKey(month)}'),
    ]);
    setState(() {
      summary = results[0];
      transactions =
          (results[1]['transactions'] as List).cast<Map<String, dynamic>>();
    });
  }

  Future<void> addTransaction() async {
    final result = await showDialog<Map<String, dynamic>>(
        context: context, builder: (_) => const TransactionDialog());
    if (result == null) return;
    await api.postJson('/financial-transactions', result);
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Financeiro',
      subtitle: 'Entradas, saidas e saldo do mes em poucos toques.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              MetricCard(
                  label: 'Receitas',
                  value: moneyLabel.format(summary['income']),
                  color: const Color(0xff0d7c66)),
              MetricCard(
                  label: 'Despesas',
                  value: moneyLabel.format(summary['expense']),
                  color: const Color(0xffb42318)),
              MetricCard(
                  label: 'Saldo',
                  value: moneyLabel.format(summary['balance']),
                  color: const Color(0xff7c3aed)),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: addTransaction,
              icon: const Icon(Icons.add),
              label: const Text('Novo lancamento')),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            const EmptyState(
                icon: Icons.receipt_long, text: 'Sem lancamentos neste mes.')
          else
            for (final item in transactions)
              Card(
                child: ListTile(
                  leading: Icon(item['type'] == 'income'
                      ? Icons.arrow_downward
                      : Icons.arrow_upward),
                  title: Text(item['title'] as String),
                  subtitle: Text(
                      '${item['category']} - ${dateLabel.format(DateTime.parse(item['transaction_date']))}'),
                  trailing: Text(
                    moneyLabel.format(NumberFormat.decimalPattern()
                        .parse('${item['amount']}')),
                    style: TextStyle(
                      color: item['type'] == 'income'
                          ? const Color(0xff0d7c66)
                          : const Color(0xffb42318),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class TransactionDialog extends StatefulWidget {
  const TransactionDialog({super.key});

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  final title = TextEditingController();
  final amount = TextEditingController();
  final category = TextEditingController(text: 'Diarista');
  String type = 'income';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo lancamento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'income',
                  label: Text('Entrada'),
                  icon: Icon(Icons.add)),
              ButtonSegment(
                  value: 'expense',
                  label: Text('Saida'),
                  icon: Icon(Icons.remove)),
            ],
            selected: {type},
            onSelectionChanged: (value) => setState(() => type = value.first),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Descricao')),
          const SizedBox(height: 12),
          TextField(
              controller: amount,
              decoration: const InputDecoration(labelText: 'Valor'),
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          TextField(
              controller: category,
              decoration: const InputDecoration(labelText: 'Categoria')),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'title': title.text,
              'amount': double.tryParse(amount.text.replaceAll(',', '.')) ?? 0,
              'type': type,
              'category': category.text,
              'transactionDate': isoDate(DateTime.now()),
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class PublicSchedulePage extends StatefulWidget {
  const PublicSchedulePage({required this.slug, super.key});

  final String slug;

  @override
  State<PublicSchedulePage> createState() => _PublicSchedulePageState();
}

class _PublicSchedulePageState extends State<PublicSchedulePage> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, AvailabilityDay> days = {};
  Map<String, dynamic>? professional;
  DateTime? selectedDate;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final results = await Future.wait([
      api.getJson('/public/${widget.slug}/profile'),
      api.getJson(
          '/public/${widget.slug}/availability?month=${monthKey(month)}'),
    ]);
    final rows = (results[1]['days'] as List).cast<Map<String, dynamic>>();
    setState(() {
      professional = results[0]['professional'] as Map<String, dynamic>;
      days = {
        for (final day in rows.map(AvailabilityDay.fromJson))
          isoDate(day.date): day
      };
      loading = false;
    });
  }

  Future<void> requestBooking(DateTime date) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => BookingDialog(date: date),
    );
    if (result == null) return;
    await api.postJson('/public/${widget.slug}/booking-requests', {
      ...result,
      'requestedDate': isoDate(date),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitacao enviada com sucesso.')));
  }

  @override
  Widget build(BuildContext context) {
    final name = professional?['name'] ?? 'Agenda';
    final service = professional?['service_title'] ?? 'Servicos domesticos';
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              constraints: const BoxConstraints(minHeight: 300),
              padding: const EdgeInsets.fromLTRB(24, 42, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff0d7c66), Color(0xffffb26b)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.cleaning_services,
                          color: Colors.white, size: 42),
                      const SizedBox(height: 18),
                      Text(
                        name,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(service,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20)),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: selectedDate == null
                            ? null
                            : () => requestBooking(selectedDate!),
                        icon: const Icon(Icons.calendar_month),
                        label: Text(selectedDate == null
                            ? 'Escolha um dia livre'
                            : 'Solicitar ${dateLabel.format(selectedDate!)}'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(18),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() => month =
                                      DateTime(month.year, month.month - 1));
                                  load();
                                },
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Expanded(
                                child: Text(
                                  DateFormat('MMMM yyyy', 'pt_BR')
                                      .format(month),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() => month =
                                      DateTime(month.year, month.month + 1));
                                  load();
                                },
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                          if (loading) const LinearProgressIndicator(),
                          PublicCalendar(
                            month: month,
                            days: days,
                            selectedDate: selectedDate,
                            onSelected: (date) =>
                                setState(() => selectedDate = date),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PublicCalendar extends StatelessWidget {
  const PublicCalendar(
      {required this.month,
      required this.days,
      required this.selectedDate,
      required this.onSelected,
      super.key});

  final DateTime month;
  final Map<String, AvailabilityDay> days;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final startOffset = first.weekday % 7;
    final totalDays = DateTime(month.year, month.month + 1, 0).day;
    final cells = List<DateTime?>.filled(startOffset, null, growable: true)
      ..addAll(List.generate(
          totalDays, (index) => DateTime(month.year, month.month, index + 1)));

    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width < 560 ? 2 : 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: MediaQuery.sizeOf(context).width < 560 ? 2 : 1.25,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        for (final date in cells)
          if (date == null)
            const SizedBox.shrink()
          else
            _PublicDayButton(
              date: date,
              available: days[isoDate(date)]?.status == 'available',
              selected: selectedDate != null &&
                  isoDate(selectedDate!) == isoDate(date),
              onTap: () => onSelected(date),
            ),
      ],
    );
  }
}

class _PublicDayButton extends StatelessWidget {
  const _PublicDayButton(
      {required this.date,
      required this.available,
      required this.selected,
      required this.onTap});

  final DateTime date;
  final bool available;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = available ? const Color(0xff0d7c66) : const Color(0xff8a8a8a);
    return InkWell(
      onTap: available ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xff0d7c66)
              : (available ? const Color(0xffe6f7ef) : const Color(0xfff3f3f3)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${date.day}',
                style: TextStyle(
                    color: selected ? Colors.white : color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            Text(
              available ? 'Disponivel' : 'Fechado',
              style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingDialog extends StatefulWidget {
  const BookingDialog({required this.date, super.key});

  final DateTime date;

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final details = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Solicitar ${dateLabel.format(widget.date)}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Seu nome')),
            const SizedBox(height: 12),
            TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'WhatsApp')),
            const SizedBox(height: 12),
            TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Endereco')),
            const SizedBox(height: 12),
            TextField(
                controller: details,
                decoration:
                    const InputDecoration(labelText: 'Detalhes do servico'),
                maxLines: 3),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'clientName': name.text,
            'clientPhone': phone.text,
            'address': address.text,
            'details': details.text,
          }),
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner(
      {required this.icon,
      required this.title,
      required this.text,
      this.action,
      super.key});

  final IconData icon;
  final String title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xff0d7c66)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  SelectableText(text),
                ],
              ),
            ),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard(
      {required this.label,
      required this.value,
      required this.color,
      super.key});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 42, color: const Color(0xff0d7c66)),
            const SizedBox(height: 8),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
