import 'package:flutter/material.dart';

class FocusStatisticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Focus Statistics'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _buildHeaderCard(context),

            SizedBox(height: 24),

            // Charts section
            Text(
              'Focus Activity',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            _buildFocusActivityCard(context),

            SizedBox(height: 24),

            // App blocking section
            Text(
              'App Blocking Stats',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            _buildAppBlockingCard(context),

            SizedBox(height: 24),

            // Detailed stats
            Text(
              'Detailed Stats',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            _buildDetailedStatsCard(context),

            SizedBox(height: 24),

            // Suggestions
            _buildSuggestionsCard(context),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatistic('35', 'Focus Hours', Icons.timer, Colors.blue),
                _buildStatistic('18', 'Day Streak', Icons.local_fire_department, Colors.orange),
                _buildStatistic('243', 'Apps Blocked', Icons.block, Colors.red),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Weekly Focus Champion!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'You focused 15% more this week compared to last week. Keep it up!',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusActivityCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Focus Hours',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            // Placeholder for chart
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('Chart Placeholder'),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildChipStat('Most Productive', 'Monday', Colors.green),
                _buildChipStat('Least Productive', 'Friday', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBlockingCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Blocked Apps',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            _buildAppBlockItem('Instagram', '78 blocks', 0.8, Colors.pink),
            SizedBox(height: 8),
            _buildAppBlockItem('TikTok', '65 blocks', 0.7, Colors.black),
            SizedBox(height: 8),
            _buildAppBlockItem('YouTube', '42 blocks', 0.5, Colors.red),
            SizedBox(height: 8),
            _buildAppBlockItem('Twitter', '35 blocks', 0.4, Colors.blue),
            SizedBox(height: 8),
            _buildAppBlockItem('Facebook', '24 blocks', 0.3, Colors.indigo),
            SizedBox(height: 16),
            Center(
              child: Text(
                '~ 15 hours saved this month ~',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Focus Session Stats',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            _buildDetailRow('Total Sessions', '87'),
            _buildDetailRow('Average Session Length', '28 minutes'),
            _buildDetailRow('Longest Session', '75 minutes'),
            _buildDetailRow('Favorite Focus Time', '9:00 AM - 11:00 AM'),
            _buildDetailRow('Session Completion Rate', '92%'),
            _buildDetailRow('Total Focus Days', '23 out of 30'),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(BuildContext context) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Suggestions for Improvement',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildSuggestionItem(
              'Try to focus earlier in the day',
              'Your most productive sessions are in the morning.',
            ),
            SizedBox(height: 8),
            _buildSuggestionItem(
              'Increase session length gradually',
              'Try 30-minute sessions instead of 25.',
            ),
            SizedBox(height: 8),
            _buildSuggestionItem(
              'Block more entertainment apps',
              'These apps account for 70% of your distractions.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistic(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildChipStat(String label, String value, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          value[0],
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      label: Text('$label: $value'),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildAppBlockItem(String app, String blocks, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  app[0],
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                app,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              blocks,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[700]),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.arrow_right, color: Colors.green),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}