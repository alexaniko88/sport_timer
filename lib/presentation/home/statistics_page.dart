part of 'home.dart';

final class Section {
  Section(
    this.title,
    this.items,
  );

  final List<Item> items;
  final String title;
}

final class Item {
  Item(this.content);

  final String content;
}

class StatisticPage extends StatelessWidget {
  const StatisticPage({super.key});

  @override
  Widget build(BuildContext context) {
    final timerStyle = Theme.of(context).extension<TimerStyle>()!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Check out your statistics'),
      ),
      body: SafeArea(
        child: BlocBuilder<StatisticsCubit, StatisticsState>(
          builder: (context, state) {
            return switch (state.status) {
              StatisticsStatus.success => ListView.separated(
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = state.statistics[index];
                    return ListTile(
                      leading: Text('${item.rounds} rounds'),
                      title: Text('Date: ${item.date}'),
                      subtitle: Text('Total time: ${item.totalTime}'),
                    );
                  },
                  itemCount: state.statistics.length,
                ),
              StatisticsStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
              _ => Center(
                  child: Text('Error: ${state.exception}'),
                ),
            };
          },
        ),
      ),
    );
  }
}
