import 'package:material_ui/material_ui.dart';

import '../models/stop_ref.dart';
import '../models/table_config.dart';
import '../services/app_store.dart';
import '../widgets/go_to_screen_dialog.dart';
import '../widgets/screen_page.dart';
import 'stop_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
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
        // Taps on the empty parts of the bar (buttons sit on top of this).
        flexibleSpace: InkWell(onTap: _goToScreen),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous screen',
          onPressed: _page > 0 ? () => _animateBy(-1) : null,
        ),
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _goToScreen,
          child: Text('Screen ${_page + 1}'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next screen',
            onPressed: () => _animateBy(1),
          ),
        ],
      ),
      // No itemCount => infinite pages.
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (i) => setState(() => _page = i),
        itemBuilder: (context, index) => ScreenPage(screenIndex: index),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTable,
        child: const Icon(Icons.add),
      ),
    );
  }
}
