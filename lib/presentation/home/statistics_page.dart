part of 'home.dart';

final class Section {
  final List<Item> items;
  final String title;

  Section(
    this.title,
    this.items,
  );
}

final class Item {
  final String content;

  Item(this.content);
}

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  final StatisticsViewModel _viewModel = StatisticsViewModel(getIt());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.statisticsGreeting(
            _viewModel.userName ?? l10n.statisticsDefaultUserName,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          for (final section in [
            Section(
              l10n.statisticsSectionTitle,
              [
                Item("A"),
                Item("B"),
                Item("C"),
                Item("D"),
                Item("E"),
                Item("F"),
                Item("A"),
                Item("B"),
                Item("C"),
                Item("D"),
                Item("E"),
                Item("F"),
                Item("A"),
                Item("B"),
                Item("C"),
                Item("D"),
                Item("E"),
                Item("F"),
              ],
            ),
          ])
            SliverMainAxisGroup(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: Text(
                    section.title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ListTile(
                      title: Text(section.items[index].content),
                    ),
                    childCount: section.items.length,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
