import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:golf_stat_tracker/models/player.dart';
import 'package:golf_stat_tracker/providers/player_provider.dart';
import 'package:golf_stat_tracker/providers/round_provider.dart';
import 'package:golf_stat_tracker/screens/google_sheets_screen.dart';
import 'package:golf_stat_tracker/services/database_manager.dart';
import 'package:golf_stat_tracker/utils/responsive_helper.dart';
import 'package:intl/intl.dart';

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({Key? key}) : super(key: key);

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _handicapController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _handicapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, RoundProvider>(
      builder: (context, playerProvider, roundProvider, child) {
        final currentPlayer = playerProvider.currentPlayer;
        
        if (currentPlayer == null) {
          return _buildCreateProfileView(playerProvider);
        }
        
        // Set controllers if not in editing mode
        if (!_isEditing) {
          _nameController.text = currentPlayer.name;
          _emailController.text = currentPlayer.email;
          _handicapController.text = currentPlayer.handicap.toString();
        }
        
        return SingleChildScrollView(
          padding: ResponsiveHelper.value(
            context,
            mobile: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            tablet: const EdgeInsets.all(16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(_isEditing ? Icons.save : Icons.edit),
                            onPressed: () {
                              if (_isEditing) {
                                _saveProfile(playerProvider, currentPlayer);
                              } else {
                                setState(() {
                                  _isEditing = true;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildProfileForm(currentPlayer),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<Map<String, dynamic>>(
                future: playerProvider.getPlayerStats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  
                  final stats = snapshot.data ?? {};
                  final roundsPlayed = stats['roundsPlayed'] ?? 0;
                  
                  if (roundsPlayed == 0) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.sports_golf, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No rounds played yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start playing to see your statistics!',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Player Stats',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow('Rounds Played', '$roundsPlayed'),
                          _buildStatRow(
                            'Average Score', 
                            '${stats['averageScore']?.toStringAsFixed(1) ?? "N/A"}',
                          ),
                          _buildStatRow(
                            'Best Score', 
                            '${stats['bestScore'] ?? "N/A"}',
                          ),
                          _buildStatRow(
                            'Fairways Hit', 
                            '${stats['fairwayHitPercentage']?.toStringAsFixed(1) ?? "N/A"}%',
                          ),
                          _buildStatRow(
                            'Greens in Regulation', 
                            '${stats['girPercentage']?.toStringAsFixed(1) ?? "N/A"}%',
                          ),
                          _buildStatRow(
                            'Avg. Putts per Round', 
                            '${stats['averagePuttsPerRound']?.toStringAsFixed(1) ?? "N/A"}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<dynamic>>(
                future: Future.wait([
                  roundProvider.getRoundsForPlayer(currentPlayer.id),
                  playerProvider.getPlayerStats(),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  
                  final data = snapshot.data;
                  if (data == null || data.isEmpty || data.length < 2) {
                    return const SizedBox.shrink();
                  }
                  
                  final rounds = data[0] as List;
                  final stats = data[1] as Map<String, dynamic>;
                  
                  if (rounds.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  // Calculate handicap recommendation based on last 5-10 rounds
                  final completedRounds = rounds.where((r) => r.isCompleted).toList();
                  if (completedRounds.length < 5) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Play at least 5 rounds to get a handicap recommendation.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  
                  // Calculate handicap based on a simple algorithm
                  // This is a simplified version, real handicap calculation is more complex
                  final int recommendedHandicap = stats['averageScore'] != null
                      ? (stats['averageScore'] as double).round() - 72
                      : currentPlayer.handicap;
                  
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Handicap Recommendation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Based on your recent rounds, your recommended handicap is:',
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              '$recommendedHandicap',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (recommendedHandicap != currentPlayer.handicap)
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Add haptic feedback for better mobile experience
                                  HapticFeedback.mediumImpact();
                                  
                                  final updatedPlayer = currentPlayer.copyWith(
                                    handicap: recommendedHandicap,
                                  );
                                  playerProvider.updatePlayer(updatedPlayer);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Handicap updated'),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: ResponsiveHelper.value(
                                    context,
                                    mobile: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    tablet: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: Text(
                                  'Update Handicap',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 14),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateProfileView(PlayerProvider playerProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_add,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Create Your Player Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Enter your name',
              prefixIcon: const Icon(Icons.person),
              contentPadding: ResponsiveHelper.value(
                context,
                mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                tablet: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            style: TextStyle(
              fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 16),
            ),
          ),
          SizedBox(height: ResponsiveHelper.value(context, mobile: 20.0, tablet: 16.0)),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email (optional)',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email),
              contentPadding: ResponsiveHelper.value(
                context,
                mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                tablet: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 16),
            ),
          ),
          SizedBox(height: ResponsiveHelper.value(context, mobile: 20.0, tablet: 16.0)),
          TextField(
            controller: _handicapController,
            decoration: InputDecoration(
              labelText: 'Handicap',
              hintText: 'Enter your handicap (0 if unknown)',
              prefixIcon: const Icon(Icons.golf_course),
              contentPadding: ResponsiveHelper.value(
                context,
                mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                tablet: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Add haptic feedback for better touch feedback
              HapticFeedback.mediumImpact();
              
              final name = _nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your name')),
                );
                return;
              }
              
              final email = _emailController.text.trim();
              final handicap = int.tryParse(_handicapController.text) ?? 0;
              
              playerProvider.addPlayer(name, email);
              
              if (playerProvider.currentPlayer != null) {
                // Update handicap if it was entered
                if (handicap > 0) {
                  final updatedPlayer = playerProvider.currentPlayer!.copyWith(
                    handicap: handicap,
                  );
                  playerProvider.updatePlayer(updatedPlayer);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, ResponsiveHelper.value(context, mobile: 56.0, tablet: 50.0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            child: Text(
              'Create Profile',
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(Player player) {
    // Get the current database type
    final dbManager = Provider.of<DatabaseManager>(context, listen: false);
    final storageType = dbManager.storageType.toString().split('.').last;
    
    return Column(
      children: [
        TextField(
          controller: _nameController,
          enabled: _isEditing,
          decoration: InputDecoration(
            labelText: 'Name',
            prefixIcon: const Icon(Icons.person),
            contentPadding: ResponsiveHelper.value(
              context,
              mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              tablet: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          style: TextStyle(
            fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 16),
          ),
        ),
        SizedBox(height: ResponsiveHelper.value(context, mobile: 16.0, tablet: 8.0)),
        TextField(
          controller: _emailController,
          enabled: _isEditing,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email),
            contentPadding: ResponsiveHelper.value(
              context,
              mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              tablet: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(
            fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 16),
          ),
        ),
        SizedBox(height: ResponsiveHelper.value(context, mobile: 16.0, tablet: 8.0)),
        TextField(
          controller: _handicapController,
          enabled: _isEditing,
          decoration: InputDecoration(
            labelText: 'Handicap',
            prefixIcon: const Icon(Icons.golf_course),
            contentPadding: ResponsiveHelper.value(
              context,
              mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              tablet: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          keyboardType: TextInputType.number,
          style: TextStyle(
            fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 16),
          ),
        ),
        const SizedBox(height: 16),
        if (!_isEditing) ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Member Since'),
            subtitle: Text(DateFormat.yMMMd().format(player.joinDate)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Data Storage Settings'),
            subtitle: Text('Current: $storageType'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoogleSheetsScreen(),
                ),
              );
            },
          ),
        ],
        if (_isEditing) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    // Reset controllers to original values
                    _nameController.text = player.name;
                    _emailController.text = player.email;
                    _handicapController.text = player.handicap.toString();
                  });
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _saveProfile(
                  Provider.of<PlayerProvider>(context, listen: false),
                  player,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _saveProfile(PlayerProvider playerProvider, Player currentPlayer) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    
    final email = _emailController.text.trim();
    final handicap = int.tryParse(_handicapController.text) ?? 0;
    
    final updatedPlayer = currentPlayer.copyWith(
      name: name,
      email: email,
      handicap: handicap,
    );
    
    playerProvider.updatePlayer(updatedPlayer);
    
    setState(() {
      _isEditing = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
