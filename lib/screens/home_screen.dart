import 'package:material_ui/material_ui.dart';

import '../models/stop_ref.dart';
import '../models/table_config.dart';
import '../services/app_store.dart';
import '../widgets/go_to_screen_dialog.dart';
import '../widgets/screen_page.dart';
import 'stop_search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _controller;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = store.currentScreen;
    _controller = PageController(initialPage: _page);
    store.addListener(_syncRestoredScreen);
  }

  void _syncRestoredScreen() {
    if (_page == store.currentScreen) return;
    _page = store.currentScreen;
    if (_controller.hasClients) _controller.jumpToPage(_page);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    store.removeListener(_syncRestoredScreen);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goToScreen() async {
    final number = await GoToScreenDialog.show(context);
    if (number != null && number >= 1) {
      _controller.jumpToPage(number - 1);
    }
  }

  Future<void> _addTable() async {
    final screen = _page;
    final stop = await Navigator.of(context).push<StopRef>(
      MaterialPageRoute(
        builder: (_) => const StopSearchScreen(title: 'Add table'),
      ),
    );
    if (stop != null) {
      store.addTable(screen, TableConfig(name: stop.name, id: stop.id));
    }
  }

  void _animateBy(int delta) {
    _controller.animateToPage(
      _page + delta,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        flexibleSpace: InkWell(onTap: _goToScreen),
        leadingWidth: 96,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous screen',
              onPressed: _page > 0 ? () => _animateBy(-1) : null,
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _goToScreen,
          child: Column(
            children: [
              Text(
                'TransiTables',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text('Screen ${_page + 1}'),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next screen',
            onPressed: () => _animateBy(1),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (i) {
          setState(() => _page = i);
          store.setCurrentScreen(i);
        },
        itemBuilder: (context, index) => ScreenPage(screenIndex: index),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTable,
        child: const Icon(Icons.add),
      ),
    );
  }
}
