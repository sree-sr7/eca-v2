import 'package:flutter/material.dart';
import '../models/caregiver.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';

class CaregiverDetailScreen extends StatelessWidget {
  final Caregiver caregiver;

  const CaregiverDetailScreen({
    Key? key,
    required this.caregiver,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final cardColor = isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor;
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                caregiver.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Hero(
                tag: 'caregiver_image_${caregiver.id}',
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(caregiver.imageUrl),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) => Container(
                        color: AppColors.primaryColor.withOpacity(0.8),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(
                        context: context,
                        title: 'Contact Information',
                        icon: Icons.contact_phone,
                        cardColor: cardColor,
                        textColor: textColor,
                        content: Column(
                          children: [
                            _buildInfoRow(
                              icon: Icons.phone,
                              title: 'Phone',
                              value: caregiver.phone,
                              iconColor: Colors.green,
                              textColor: textColor,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              icon: Icons.email,
                              title: 'Email',
                              value: caregiver.email,
                              iconColor: Colors.blue,
                              textColor: textColor,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              icon: Icons.location_on,
                              title: 'Address',
                              value: caregiver.address,
                              iconColor: Colors.red,
                              textColor: textColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        context: context,
                        title: 'Professional Information',
                        icon: Icons.work,
                        cardColor: cardColor,
                        textColor: textColor,
                        content: Column(
                          children: [
                            _buildInfoRow(
                              icon: Icons.category,
                              title: 'Category',
                              value: caregiver.category,
                              iconColor: Colors.orange,
                              textColor: textColor,
                            ),
                            if (caregiver.specialization != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                icon: Icons.star,
                                title: 'Specialization',
                                value: caregiver.specialization!,
                                iconColor: Colors.amber,
                                textColor: textColor,
                              ),
                            ],
                            if (caregiver.relation != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                icon: Icons.people,
                                title: 'Relation',
                                value: caregiver.relation!,
                                iconColor: Colors.purple,
                                textColor: textColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              text: 'Call Now',
                              icon: Icons.call,
                              bgColor: Colors.green,
                              onPressed: () {
                                // Implement call functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Calling ${caregiver.name}...'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: PrimaryButton(
                              text: 'Send Message',
                              icon: Icons.message,
                              bgColor: AppColors.accentColor,
                              onPressed: () {
                                // Implement message functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Messaging ${caregiver.name}...'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        text: 'Edit Caregiver Information',
                        icon: Icons.edit,
                        bgColor: Colors.grey[600],
                        onPressed: () {
                          // Implement edit functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edit functionality coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required Color textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}